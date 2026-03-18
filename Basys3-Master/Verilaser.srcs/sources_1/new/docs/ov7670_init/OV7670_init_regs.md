# OV7670_init_regs.mem

OV7670 QVGA RGB565 초기화 레지스터 테이블. `$readmemh`로 로드.

포맷: `{reg_addr[7:0], reg_data[7:0]}` = 16비트 hex

## 구성 (총 66개)

### [0] SW Reset
| # | hex | reg_addr | reg_data | 설명 |
|---|-----|----------|----------|------|
| 0 | 1280 | 0x12 (COM7) | 0x80 | 소프트웨어 리셋. 30ms 딜레이 필요 |

### [1~42] Defaults
기본 튜닝값 (감마, AEC/AGC, AWB, 스케일링 등). STM32 reference 기반.

| # | hex | reg_addr | reg_data | 설명 |
|---|-----|----------|----------|------|
| 1 | 3A04 | 0x3A (TSLB) | 0x04 | OV 필수 설정 |
| 2 | 1200 | 0x12 (COM7) | 0x00 | VGA (기본값) |
| 3 | 13E7 | 0x13 (COM8) | 0xE7 | Fast AGC/AEC, AGC=1, AWB=1, AEC=1 |
| 4 | 6F9F | 0x6F (AWBCTR0) | 0x9F | White balance |
| 5 | B084 | 0xB0 | 0x84 | 색상 보정 (undocumented) |
| 6-9 | 703A~73F0 | 0x70~0x73 | - | 스케일링 기본값 |
| 10-25 | 7A20~89E8 | 0x7A~0x89 | - | 감마 커브 |
| 26-27 | 0000, 1000 | GAIN, AECH | 0x00 | 게인/노출 초기화 |
| 28 | 0D40 | 0x0D (COM4) | 0x40 | Reserved bit |
| 29 | 1418 | 0x14 (COM9) | 0x18 | 4x gain ceiling |
| 30-42 | A505~AA94 | - | - | AEC/AGC 제어 레지스터 |

### [43~50] RES_QVGA
QVGA (320x240) 해상도 설정. Implementation Guide Table 2-2 기반.

| # | hex | reg_addr | reg_data | 설명 |
|---|-----|----------|----------|------|
| 43 | 1211 | 0x12 (COM7) | 0x11 | QVGA 모드 |
| 44 | 0C04 | 0x0C (COM3) | 0x04 | DCW enable |
| 45 | 3E19 | 0x3E (COM14) | 0x19 | PCLK divider |
| 46-49 | 703A~73F1 | 0x70~0x73 | - | 스케일링 |
| 50 | A202 | 0xA2 | 0x02 | PCLK delay |

### [51~56] Frame Control
STM32 `SetFrameControl(168, 24, 12, 492)` 에 해당하는 이미지 윈도우 설정.

| # | hex | reg_addr | reg_data | 설명 |
|---|-----|----------|----------|------|
| 51 | 1715 | 0x17 (HSTART) | 0x15 | 수평 시작 |
| 52 | 1803 | 0x18 (HSTOP) | 0x03 | 수평 종료 |
| 53 | 3200 | 0x32 (HREF) | 0x00 | HREF 하위 비트 |
| 54 | 1903 | 0x19 (VSTART) | 0x03 | 수직 시작 |
| 55 | 1A7B | 0x1A (VSTOP) | 0x7B | 수직 종료 |
| 56 | 0300 | 0x03 (VREF) | 0x00 | VREF 하위 비트 |

### [57~58] RGB565
| # | hex | reg_addr | reg_data | 설명 |
|---|-----|----------|----------|------|
| 57 | 1214 | 0x12 (COM7) | 0x14 | QVGA + RGB (QVGA 비트 유지 필수) |
| 58 | 40D0 | 0x40 (COM15) | 0xD0 | RGB565, full range |

### [59~65] Color Matrix
RGB 색상 매트릭스 계수.

| # | hex | reg_addr | reg_data | 설명 |
|---|-----|----------|----------|------|
| 59 | 4FB3 | 0x4F (MTX1) | 0xB3 | |
| 60 | 50B3 | 0x50 (MTX2) | 0xB3 | |
| 61 | 5100 | 0x51 (MTX3) | 0x00 | |
| 62 | 523D | 0x52 (MTX4) | 0x3D | |
| 63 | 53B0 | 0x53 (MTX5) | 0xB0 | |
| 64 | 54E4 | 0x54 (MTX6) | 0xE4 | |
| 65 | 589E | 0x58 (MTX_SIGN) | 0x9E | 부호 비트 |
