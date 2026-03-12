import cv2
import sys

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


def main():
    print("=== VGA Capture Viewer ===")
    print("연결된 캡처 장치 탐색 중...")
    devices = find_capture_device()

    if not devices:
        print("캡처 장치를 찾을 수 없습니다.")
        sys.exit(1)

    # 인자로 장치 번호 지정 가능, 없으면 마지막 장치 사용 (보통 외장 캡처)
    idx = int(sys.argv[1]) if len(sys.argv) > 1 else devices[-1]
    print(f"\n장치 [{idx}] 열기...")

    cap = cv2.VideoCapture(idx, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print(f"장치 [{idx}]를 열 수 없습니다.")
        sys.exit(1)

    # VGA 해상도 설정 (640x480)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    print(f"캡처 해상도: {w}x{h}, FPS: {fps}")
    print("종료: ESC 또는 q | 전체화면 토글: f")

    window_name = "VGA Capture - Verilaser3"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    while True:
        ret, frame = cap.read()
        if not ret:
            print("프레임 수신 실패")
            continue

        cv2.imshow(window_name, frame)

        key = cv2.waitKey(1) & 0xFF
        if key == 27 or key == ord('q'):  # ESC or q
            break
        elif key == ord('f'):  # 전체화면 토글
            prop = cv2.getWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN)
            if prop == cv2.WINDOW_FULLSCREEN:
                cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_NORMAL)
            else:
                cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
