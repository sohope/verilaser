/*
 * servo.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_SERVO_H_
#define INC_SERVO_H_

#include "main.h"

typedef struct{
	uint16_t x;
	uint16_t y;
	uint8_t  status;
} TargetData_t;

void Servo_Init(void);
void Servo_Track(uint16_t cx, uint16_t cy);

#endif /* INC_SERVO_H_ */
