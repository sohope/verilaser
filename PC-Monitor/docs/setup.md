# PC-Monitor 설정 및 실행 가이드

## 개요

Basys3 FPGA의 VGA 출력을 VGA-USB 캡처 카드를 통해 PC에서 수신하고,
OpenCV로 영상을 표시하는 모니터링 프로그램.

## 시스템 구성

```
OV7670 → Basys3(영상처리) → VGA → 캡처카드(USB) → PC(OpenCV)
                           → I2C → STM32(서보/레이저)
```

## 하드웨어 요구사항

- VGA to USB 캡처 카드 (UVC 지원)
- Basys3 VGA 출력 → 캡처 카드 VGA 입력 연결
- 캡처 카드 USB → PC USB 포트 연결

## 소프트웨어 설치

### 1. Python 확인

```bash
python --version
```

Python 3.8 이상 필요.

### 2. OpenCV 설치

```bash
pip install opencv-python
```

### 3. (선택) 시리얼 통신용 패키지

추후 STM32 데이터 수신 시 필요.

```bash
pip install pyserial
```

## 실행 방법

### 캡처 영상 보기

```bash
cd PC-Monitor/src
python capture.py
```

### 장치 번호 직접 지정

```bash
python capture.py 1
```

실행 시 연결된 장치 목록이 출력됨.
보통 `[0]`은 노트북 웹캠, `[1]`이 외장 캡처 카드.

## 단축키

| 키 | 기능 |
|---|---|
| `f` | 전체화면 / 윈도우 토글 |
| `ESC` 또는 `q` | 종료 |

## 트러블슈팅

### 장치를 찾을 수 없음

- 장치 관리자에서 "카메라" 또는 "이미징 장치" 항목 확인
- 캡처 카드가 UVC 지원인지 확인 (드라이버 불필요)
- USB 케이블을 다른 포트에 연결해보기

### 화면이 검은색으로 나옴

- Basys3 VGA 출력이 정상인지 모니터에 먼저 연결해 확인
- VGA 케이블 연결 상태 확인

### FPS가 0으로 표시됨

- 일부 캡처 카드에서 FPS 속성을 반환하지 않음 (정상 동작에 영향 없음)

## 폴더 구조

```
PC-Monitor/
├── docs/
│   └── setup.md        ← 현재 문서
└── src/
    └── capture.py      ← 캡처 뷰어 프로그램
```
