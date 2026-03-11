/*
 * servo.c
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#include "servo.h"
#include <stdlib.h>

extern TIM_HandleTypeDef htim3;

#define SCREEN_CX    160
#define SCREEN_CY    120
#define TRACK_GAIN   0.5f
#define JOY_GAIN     0.05f
#define DEADZONE_JOY 15
#define CCR_MIN      500
#define CCR_MAX      2500

static float current_pan  = 90.0f;
static float current_tilt = 90.0f;

static void Servo_SetAngle(float pan, float tilt);
static void Servo_Clamp(void);

void Servo_Init(void)
{
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1); //pan
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2); //tilt

	Servo_SetAngle(90.0f, 90.0f);
}

/* Mode 2: 자동 추적 — I2C 좌표 기반 절대 위치 제어 */
void Servo_Track(uint16_t cx, uint16_t cy)
{
	int16_t err_x = (int16_t)cx - SCREEN_CX;
	int16_t err_y = (int16_t)cy - SCREEN_CY;

	current_pan  = 90.0f + ((float)err_x * -TRACK_GAIN);
	current_tilt = 90.0f + ((float)err_y * TRACK_GAIN);

	Servo_Clamp();
	Servo_SetAngle(current_pan, current_tilt);
}

/* Mode 0: 수동 모드 — 조이스틱 누적 제어 (LeeJae 방식) */
void Servo_Manual(uint16_t cx, uint16_t cy)
{
	int16_t err_x = (int16_t)cx - SCREEN_CX;
	int16_t err_y = (int16_t)cy - SCREEN_CY;

	/* 데드존: 조이스틱 중립일 때 떨림 방지 */
	if (abs(err_x) < DEADZONE_JOY && abs(err_y) < DEADZONE_JOY)
		return;

	/* 누적 제어: 밀고 있는 동안 각도가 계속 변함 */
	current_pan  -= (float)err_x * JOY_GAIN;
	current_tilt += (float)err_y * JOY_GAIN;

	Servo_Clamp();
	Servo_SetAngle(current_pan, current_tilt);
}

/* Mode 1: 영점 조절 — 서보를 90°/90° 기준점으로 이동 */
void Servo_GoCenter(void)
{
	current_pan  = 90.0f;
	current_tilt = 90.0f;
	Servo_SetAngle(current_pan, current_tilt);
}

static void Servo_Clamp(void)
{
	if (current_pan  < 0.0f)   current_pan  = 0.0f;
	if (current_pan  > 180.0f) current_pan  = 180.0f;
	if (current_tilt < 0.0f)   current_tilt = 0.0f;
	if (current_tilt > 180.0f) current_tilt = 180.0f;
}

static void Servo_SetAngle(float pan, float tilt)
{
	uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * (CCR_MAX - CCR_MIN));
	uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * (CCR_MAX - CCR_MIN));

	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, ccr_pan);
	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, ccr_tilt);
}
