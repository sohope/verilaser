/*
 * servo.c
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#include "servo.h"
#include <stdlib.h> //abs함수 사용

extern TIM_HandleTypeDef htim3;

#define SCREEN_CX   160
#define SCREEN_CY   120
#define GAIN	    0.5f
#define DEADZONE_PX 10
#define CCR_MIN         50 // 0 degree
#define CCR_MID         75 // 90 degree
#define CCR_MAX         100 //180 degree

static float pan_angle = 90.0f;
static float tilt_angle = 90.0f;

static void Servo_SetAngle(float pan, float tilt);

void Servo_Init(void)
{
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1); //pan
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2); //tilt

	Servo_SetAngle(90.0f, 90.0f); //초기값을 정렬
}

void Servo_Track(uint16_t cx, uint16_t cy)
{
	int16_t err_x = (int16_t)cx - SCREEN_CX;
	int16_t err_y = (int16_t)cy - SCREEN_CY;

	pan_angle = 90.0f + ((float)err_x * -GAIN);
	tilt_angle = 90.0f + ((float)err_y * GAIN);

	if(pan_angle < 0.0f) pan_angle = 0.0f;
	if(pan_angle > 180.0f) pan_angle = 180.0f;
	if(tilt_angle < 0.0f) tilt_angle = 0.0f;
	if(tilt_angle > 180.0f) tilt_angle = 180.0f;

	Servo_SetAngle(pan_angle, tilt_angle);
}

static void Servo_SetAngle(float pan, float tilt)
{
	uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * 50.0f);
	uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * 50.0f);

	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, ccr_pan);
	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, ccr_tilt);
}

































