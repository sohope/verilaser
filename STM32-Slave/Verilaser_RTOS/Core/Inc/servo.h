/*
 * servo.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_SERVO_H_
#define INC_SERVO_H_

#include "main.h"

#define SCREEN_CX    160
#define SCREEN_CY    120
#define SCREEN_W     320
#define SCREEN_H     240
#define JOY_GAIN     0.005f		// 조이스틱 속도 조절 요소 1
#define DEADZONE_JOY 15			// 조이스틱 속도 조절 요소 2
#define CCR_MIN      500
#define CCR_MAX      2500
#define PAN_GAIN     0.095f   /* pan: 절반 (0.5 * 0.5) */
#define TILT_GAIN    0.125f  /* tilt: 3/4 (0.5 * 0.75) */

/* 물리 파라미터 (mm) */
#define WALL_DIST_MM    750.0f
#define TURRET1_DX_MM   (-140.0f)
#define TURRET2_DX_MM   (-20.0f)
#define TURRET3_DX_MM   (90.0f)
#define TURRET_DY_MM    (65.0f)   /* 세 터렛 모두 동일 */

/* I2C 주소로 터렛 자동 선택 */
#if   (I2C_SLAVE_ADDR == 0x20)
  #define _TURRET_DX   TURRET1_DX_MM
#elif (I2C_SLAVE_ADDR == 0x22)
  #define _TURRET_DX   TURRET2_DX_MM
#elif (I2C_SLAVE_ADDR == 0x24)
  #define _TURRET_DX   TURRET3_DX_MM
#else
  #error "I2C_SLAVE_ADDR must be 0x20, 0x22, or 0x24"
#endif

/* 픽셀 오프셋 계산 (런타임, servo.c Servo_Init에서 사용) */
#define CALC_OFFSET_X()  ( atanf(-(_TURRET_DX) / WALL_DIST_MM) * (180.0f / 3.14159f) / PAN_GAIN )
#define CALC_OFFSET_Y()  ( atanf(-(TURRET_DY_MM) / WALL_DIST_MM) * (180.0f / 3.14159f) / TILT_GAIN )

// turret dependancy
//	R
//#define OFFSET_X     0       /* 카메라-터렛 X 오프셋 (픽셀) */
//#define OFFSET_Y     0      /* 카메라-터렛 Y 오프셋 (레이저가 80px 아래) */
//#define PAN_GAIN     0.125f   /* pan: 절반 (0.5 * 0.5) */
//#define TILT_GAIN    0.125f  /* tilt: 3/4 (0.5 * 0.75) */

//	G
 #define OFFSET_X     80       /* 카메라-터렛 X 오프셋 (픽셀) */
 #define OFFSET_Y     -60      /* 카메라-터렛 Y 오프셋 (레이저가 80px 아래) */


//	B
// #define OFFSET_X     0       /* 카메라-터렛 X 오프셋 (픽셀) */
// #define OFFSET_Y     0      /* 카메라-터렛 Y 오프셋 (레이저가 80px 아래) */
// #define PAN_GAIN     0.125f   /* pan: 절반 (0.5 * 0.5) */
// #define TILT_GAIN    0.125f  /* tilt: 3/4 (0.5 * 0.75) */

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
