# PC-Monitor 설정 및 실행 가이드

## 개요

Basys3 FPGA의 VGA 출력을 VGA-USB 캡처 카드를 통해 PC에서 수신하고,
OpenCV로 영상을 표시하는 모니터링 프로그램.
UART를 통해 FPGA의 타겟 좌표를 수신하여 터렛 상태를 오버레이로 표시.

## 시스템 구성

```
OV7670 → Basys3(영상처리) → VGA  → 캡처카드(USB) → PC(OpenCV)
                          → UART → USB-Serial     → PC(pyserial)
                          → I2C  → STM32(서보/레이저)
```

## 하드웨어 요구사항

- VGA to USB 캡처 카드 (UVC 지원)
- USB-Serial 어댑터 (UART 수신용, Pmod JA 연결)
- Basys3 VGA 출력 → 캡처 카드 VGA 입력 연결
- 캡처 카드 USB → PC USB 포트 연결

## 소프트웨어 설치

### Python 확인

```bash
python --version
```

Python 3.8 이상 필요.

### 패키지 설치

```bash
pip install -r requirements.txt
```

또는 개별 설치:

```bash
pip install opencv-python pyserial
```

## 실행 방법

### 기본 실행 (캡처 장치 자동 탐색, UART 포트 자동 탐색)

```bash
cd PC-Monitor/src
python capture.py
```

### 장치 번호 지정

```bash
python capture.py 1
```

### 장치 번호 + COM 포트 지정

```bash
python capture.py 1 COM9
```

실행 시 연결된 장치 목록이 출력됨.
보통 `[0]`은 노트북 웹캠, `[1]`이 외장 캡처 카드.

## 단축키

| 키 | 기능 |
|---|---|
| `f` | 전체화면 / 윈도우 토글 |
| `o` | 오버레이 on/off 토글 |
| `ESC` 또는 `q` | 종료 |

## 오버레이 정보

### 좌상단 표시

- 현재 시간: `YYYY-MM-DD HH:MM:SS`
- FPS: 실시간 프레임 레이트

### 터렛 상태 (UART 수신 시)

각 색상 채널별 타겟 추적 상태:

```
Turret #1 (R)  Pan: 90.0  Tilt: 90.0  (160,120)
Turret #2 (G)  -- lost --
Turret #3 (B)  Pan: 85.0  Tilt: 95.0  (200,080)
```

- Pan/Tilt: STM32 `Servo_Track` 로직 재현 (0~180도)
- 좌표: FPGA에서 검출된 타겟 중심 좌표 (320x240 기준)
- `-- lost --`: 해당 색상 타겟 미검출 (status=0)

### UART 패킷 구조 (18 bytes, 115200 baud)

| Byte | 내용 |
|------|------|
| 0 | `0xFF` (start) |
| 1-2 | Red X (MSB 2bit + LSB 8bit) |
| 3-4 | Red Y |
| 5 | Red status |
| 6-7 | Green X |
| 8-9 | Green Y |
| 10 | Green status |
| 11-12 | Blue X |
| 13-14 | Blue Y |
| 15 | Blue status |
| 16 | Checksum (합산 하위 8bit) |
| 17 | `0xFE` (end) |

## 트러블슈팅

### 캡처 장치를 찾을 수 없음

- 장치 관리자에서 "카메라" 또는 "이미징 장치" 항목 확인
- 캡처 카드가 UVC 지원인지 확인 (드라이버 불필요)
- USB 케이블을 다른 포트에 연결해보기

### 화면이 검은색으로 나옴

- Basys3 VGA 출력이 정상인지 모니터에 먼저 연결해 확인
- VGA 케이블 연결 상태 확인

### UART 수신 안됨

- 장치 관리자에서 COM 포트 번호 확인
- `python capture.py 1 COM9` 처럼 포트 직접 지정
- 보드레이트: 115200 (고정)

## 폴더 구조

```
PC-Monitor/
├── docs/
│   └── setup.md           ← 현재 문서
├── src/
│   └── capture.py         ← 캡처 뷰어 + UART 오버레이
└── requirements.txt       ← Python 의존성
```
