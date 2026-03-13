import cv2
import sys
import time
import threading
import serial
import serial.tools.list_ports


# ── UART 패킷 파서 ──────────────────────────────────────────
# 패킷 구조 (18 bytes):
#   [0]    0xFF (start)
#   [1-2]  Red   X (MSB[1:0], LSB[7:0])
#   [3-4]  Red   Y
#   [5]    Red   status
#   [6-7]  Green X
#   [8-9]  Green Y
#   [10]   Green status
#   [11-12] Blue X
#   [13-14] Blue Y
#   [15]   Blue status
#   [16]   Checksum (하위 8bit)
#   [17]   0xFE (end)

PACKET_LEN = 18
SCREEN_CX = 160
SCREEN_CY = 120
OFFSET_X = 0
OFFSET_Y = 80
PAN_GAIN = 0.125
TILT_GAIN = 0.125


def parse_packet(buf):
    """18바이트 패킷을 파싱하여 3채널 좌표/상태 반환. 실패 시 None."""
    if len(buf) != PACKET_LEN:
        return None
    if buf[0] != 0xFF or buf[17] != 0xFE:
        return None

    # checksum 검증
    chk = sum(buf[1:16]) & 0xFF
    if chk != buf[16]:
        return None

    def coord(msb, lsb):
        return ((msb & 0x03) << 8) | lsb

    return {
        'r': {'x': coord(buf[1], buf[2]),   'y': coord(buf[3], buf[4]),   'status': buf[5] & 1},
        'g': {'x': coord(buf[6], buf[7]),   'y': coord(buf[8], buf[9]),   'status': buf[10] & 1},
        'b': {'x': coord(buf[11], buf[12]), 'y': coord(buf[13], buf[14]), 'status': buf[15] & 1},
    }


def calc_pan_tilt(cx, cy):
    """STM32 Servo_Track 로직 재현 — 좌표 → Pan/Tilt 각도"""
    err_x = cx - SCREEN_CX - OFFSET_X
    err_y = cy - SCREEN_CY - OFFSET_Y
    pan = 90.0 + err_x * (-PAN_GAIN)
    tilt = 90.0 + err_y * TILT_GAIN
    pan = max(0.0, min(180.0, pan))
    tilt = max(0.0, min(180.0, tilt))
    return pan, tilt


class UartReceiver:
    """별도 스레드에서 UART 패킷을 수신하여 최신 데이터를 유지"""

    def __init__(self, port, baud=115200):
        self.port = port
        self.baud = baud
        self.data = None
        self.lock = threading.Lock()
        self._running = False
        self._thread = None

    def start(self):
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)

    def get(self):
        with self.lock:
            return self.data

    def _run(self):
        try:
            ser = serial.Serial(self.port, self.baud, timeout=0.1)
        except serial.SerialException as e:
            print(f"[UART] 포트 열기 실패: {e}")
            return

        print(f"[UART] {self.port} @ {self.baud} 연결됨")
        buf = bytearray()

        while self._running:
            chunk = ser.read(64)
            if not chunk:
                continue
            buf.extend(chunk)

            # 패킷 동기화: 0xFF 시작 마커 찾기
            while len(buf) >= PACKET_LEN:
                start = buf.find(0xFF)
                if start == -1:
                    buf.clear()
                    break
                if start > 0:
                    buf = buf[start:]
                if len(buf) < PACKET_LEN:
                    break

                pkt = bytes(buf[:PACKET_LEN])
                buf = buf[PACKET_LEN:]

                result = parse_packet(pkt)
                if result:
                    r, g, b = result['r'], result['g'], result['b']
                    print(f"\r[UART] R({r['x']:3d},{r['y']:3d})s={r['status']} "
                          f"G({g['x']:3d},{g['y']:3d})s={g['status']} "
                          f"B({b['x']:3d},{b['y']:3d})s={b['status']}", end="")
                    with self.lock:
                        self.data = result

        ser.close()
        print("[UART] 연결 종료")


# ── 오버레이 그리기 ──────────────────────────────────────────

FONT = cv2.FONT_HERSHEY_SIMPLEX
COLOR_WHITE = (255, 255, 255)
COLOR_BG = (0, 0, 0)
COLOR_R = (0, 0, 255)
COLOR_G = (0, 255, 0)
COLOR_B = (255, 0, 0)


def draw_text(frame, text, pos, color=COLOR_WHITE, scale=0.6, thickness=1):
    """텍스트를 배경 박스와 함께 그림"""
    (tw, th), baseline = cv2.getTextSize(text, FONT, scale, thickness)
    x, y = pos
    cv2.rectangle(frame, (x - 2, y - th - 4), (x + tw + 2, y + baseline + 2), COLOR_BG, -1)
    cv2.putText(frame, text, (x, y), FONT, scale, color, thickness, cv2.LINE_AA)
    return th + baseline + 6  # 다음 줄 오프셋


def draw_overlay(frame, uart_data, fps):
    """프레임에 정보 오버레이를 그림"""
    y = 20

    # 시간
    now = time.strftime("%Y-%m-%d %H:%M:%S")
    y += draw_text(frame, now, (10, y))

    # FPS
    y += draw_text(frame, f"FPS: {fps:.1f}", (10, y))

    # UART 데이터가 없으면 대기 표시
    if uart_data is None:
        y += draw_text(frame, "UART: waiting...", (10, y), (128, 128, 128))
        return

    y += 4  # 간격

    # 터렛 정보 (R, G, B 각각)
    channels = [
        ('Turret #1 (R)', 'r', COLOR_R),
        ('Turret #2 (G)', 'g', COLOR_G),
        ('Turret #3 (B)', 'b', COLOR_B),
    ]

    h, w = frame.shape[:2]
    scale_x = w / 640.0
    scale_y = h / 480.0
    cross_size = 20

    for label, ch, color in channels:
        d = uart_data[ch]
        if d['status']:
            pan, tilt = calc_pan_tilt(d['x'], d['y'])
            text = f"{label}  Pan:{pan:5.1f}  Tilt:{tilt:5.1f}  ({d['x']:3d},{d['y']:3d})"

            # 십자 표시
            cx = int(d['x'] * scale_x)
            cy = int(d['y'] * scale_y)
            cv2.line(frame, (cx - cross_size, cy), (cx + cross_size, cy), color, 2)
            cv2.line(frame, (cx, cy - cross_size), (cx, cy + cross_size), color, 2)
        else:
            text = f"{label}  Pan: 90.0  Tilt: 90.0  (no target)"
        y += draw_text(frame, text, (10, y), color)


# ── 캡처 장치 탐색 ──────────────────────────────────────────

def find_capture_device(max_index=5):
    """연결된 캡처 장치를 탐색"""
    available = []
    for i in range(max_index):
        cap = cv2.VideoCapture(i, cv2.CAP_DSHOW)
        if cap.isOpened():
            w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            print(f"[{i}] {w}x{h}")
            available.append(i)
            cap.release()
    return available


def find_uart_port():
    """연결된 시리얼 포트 중 첫 번째 반환"""
    ports = serial.tools.list_ports.comports()
    for p in ports:
        print(f"[Serial] {p.device}: {p.description}")
    return ports[0].device if ports else None


# ── 메인 ────────────────────────────────────────────────────

def main():
    print("=== VGA Capture Viewer ===")
    print("연결된 캡처 장치 탐색 중...")
    devices = find_capture_device()

    if not devices:
        print("캡처 장치를 찾을 수 없습니다.")
        sys.exit(1)

    # 인자: [장치번호] [COM포트]
    idx = int(sys.argv[1]) if len(sys.argv) > 1 else devices[-1]
    print(f"\n장치 [{idx}] 열기...")

    cap = cv2.VideoCapture(idx, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print(f"장치 [{idx}]를 열 수 없습니다.")
        sys.exit(1)

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print(f"캡처 해상도: {w}x{h}")

    # UART 설정
    uart = None
    uart_port = sys.argv[2] if len(sys.argv) > 2 else find_uart_port()
    if uart_port:
        uart = UartReceiver(uart_port)
        uart.start()
    else:
        print("[UART] 시리얼 포트 없음 — 오버레이만 표시")

    # 모니터 해상도로 업스케일 (INTER_CUBIC 보간법)
    DISPLAY_W, DISPLAY_H = 2560, 1440

    window_name = "VGA Capture - Verilaser3"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    print(f"출력 해상도: {DISPLAY_W}x{DISPLAY_H}")
    print("종료: ESC/q | 전체화면: f | 오버레이: o")

    show_overlay = True
    prev_time = time.time()
    fps = 0.0

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        # FPS 계산
        now = time.time()
        dt = now - prev_time
        if dt > 0:
            fps = 0.9 * fps + 0.1 * (1.0 / dt)
        prev_time = now

        # 업스케일 (bicubic 보간)
        frame = cv2.resize(frame, (DISPLAY_W, DISPLAY_H), interpolation=cv2.INTER_CUBIC)

        # 오버레이 (업스케일 후 그리기 → 선명한 텍스트)
        if show_overlay:
            uart_data = uart.get() if uart else None
            draw_overlay(frame, uart_data, fps)

        cv2.imshow(window_name, frame)

        key = cv2.waitKey(1) & 0xFF
        if key == 27 or key == ord('q'):
            break
        elif key == ord('f'):
            prop = cv2.getWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN)
            if prop == cv2.WINDOW_FULLSCREEN:
                cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_NORMAL)
            else:
                cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
        elif key == ord('o'):
            show_overlay = not show_overlay

    if uart:
        uart.stop()
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
