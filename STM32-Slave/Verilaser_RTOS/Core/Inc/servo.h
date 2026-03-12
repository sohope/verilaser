/*
 * servo.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_SERVO_H_
#define INC_SERVO_H_

#define SCREEN_CX    160
#define SCREEN_CY    120
#define JOY_GAIN     0.05f
#define DEADZONE_JOY 15
#define CCR_MIN      500
#define CCR_MAX      2500

// turret dependancy
#define OFFSET_X     0       /* 카메라-터렛 X 오프셋 (픽셀) */
#define OFFSET_Y     0      /* 카메라-터렛 Y 오프셋 (레이저가 80px 아래) */
#define PAN_GAIN     0.125f   /* pan: 절반 (0.5 * 0.5) */
#define TILT_GAIN    0.125f  /* tilt: 3/4 (0.5 * 0.75) */

// #define OFFSET_X     0       /* 카메라-터렛 X 오프셋 (픽셀) */
// #define OFFSET_Y     0      /* 카메라-터렛 Y 오프셋 (레이저가 80px 아래) */
// #define PAN_GAIN     0.125f   /* pan: 절반 (0.5 * 0.5) */
// #define TILT_GAIN    0.125f  /* tilt: 3/4 (0.5 * 0.75) */

// #define OFFSET_X     0       /* 카메라-터렛 X 오프셋 (픽셀) */
// #define OFFSET_Y     0      /* 카메라-터렛 Y 오프셋 (레이저가 80px 아래) */
// #define PAN_GAIN     0.125f   /* pan: 절반 (0.5 * 0.5) */
// #define TILT_GAIN    0.125f  /* tilt: 3/4 (0.5 * 0.75) */

#include "main.h"

typedef enum {
	MODE_MANUAL  = 0,   // 수동 모드 (조이스틱)
	MODE_ZEROING = 1,   // 영점 조절 모드
	MODE_TRACK   = 2,   // 자동 추적 모드
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
