/*
 * servo.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_SERVO_H_
#define INC_SERVO_H_

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
