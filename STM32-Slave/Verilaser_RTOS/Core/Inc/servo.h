/*
 * servo.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */
#ifndef INC_SERVO_H_
#define INC_SERVO_H_

#include "main.h"

/* ── 화면 파라미터 ─────────────────────── */
#define SCREEN_CX       160
#define SCREEN_CY       120
#define SCREEN_W        320
#define SCREEN_H        240

/* ── PWM 파라미터 ──────────────────────── */
#define CCR_MIN         500
#define CCR_MAX         2500

/* ── 조이스틱 파라미터 ─────────────────── */
#define JOY_GAIN        0.005f
#define DEADZONE_JOY    15

/* 물리 파라미터 (mm) */
#define WALL_DIST_MM    680.0f
#define TURRET1_DX_MM   (-110.0f)
#define TURRET2_DX_MM   (10.0f)
#define TURRET3_DX_MM   (125.0f)
#define TURRET_DY_MM    (65.0f)   /* 세 터렛 모두 동일 */

/* ── 터렛별 파라미터 (I2C 주소로 자동 선택) ── */
#if (I2C_SLAVE_ADDR == 0x20)
  #define _TURRET_DX      TURRET1_DX_MM
  #define CENTER_TRIM_X   -2.0f     // 영점 좌/우 보정 (°)	+/- 좌/우
  #define CENTER_TRIM_Y    5.0f     // 영점 상/하 보정 (°)	+/- 하강/상승
  #define PAN_GAIN         0.100f   // 추적 속도 (pan)		+/- 빨라짐/느려짐
  #define TILT_GAIN        0.140f   // 추적 속도 (tilt)
  #define TRACK_TRIM_X    -120.0f   // 추적 좌/우 보정 (px)	+/- 좌/우
  #define TRACK_TRIM_Y     12.0f    // 추적 상/하 보정 (px)	+/- 상승/하강

#elif (I2C_SLAVE_ADDR == 0x22)
  #define _TURRET_DX      TURRET2_DX_MM
  #define CENTER_TRIM_X    7.0f
  #define CENTER_TRIM_Y    1.0f
  #define PAN_GAIN         0.100f
  #define TILT_GAIN        0.125f
  #define TRACK_TRIM_X     81.0f
  #define TRACK_TRIM_Y     30.0f

#elif (I2C_SLAVE_ADDR == 0x24)
  #define _TURRET_DX      TURRET3_DX_MM
  #define CENTER_TRIM_X    20.0f
  #define CENTER_TRIM_Y     4.0f
  #define PAN_GAIN          0.125f
  #define TILT_GAIN         0.130f
  #define TRACK_TRIM_X     240.0f
  #define TRACK_TRIM_Y      10.0f
#else
  #error "I2C_SLAVE_ADDR must be 0x20, 0x22, or 0x24"
#endif

/* 픽셀 오프셋 계산 (런타임, servo.c Servo_Init에서 사용) */
#define CALC_OFFSET_X()  ( atanf(-(_TURRET_DX) / WALL_DIST_MM) * (180.0f / 3.14159f) / PAN_GAIN )
#define CALC_OFFSET_Y()  ( atanf(-(TURRET_DY_MM) / WALL_DIST_MM) * (180.0f / 3.14159f) / TILT_GAIN )

typedef enum {
	MODE_TRACK  = 0,    // 자동 추적 모드
	MODE_MANUAL = 1,    // 수동 모드 (조이스틱)
	MODE_ZEROING = 2, // 영점 조절 모드
} SystemMode_t;

typedef struct{
	uint16_t x;
	uint16_t y;
	uint8_t  status;
} TargetData_t;

void Servo_Init(void);
void Servo_Track(uint16_t cx, uint16_t cy);
void Servo_Manual(uint16_t cx, uint16_t cy);
void Servo_GoCenter(void);

#endif /* INC_SERVO_H_ */
