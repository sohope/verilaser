/*
 * Servo.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_SERVO_H_
#define INC_SERVO_H_


#include <stdint.h>

/* LaserTask, BuzzerTask가 읽는 조준완료 플래그 */
extern volatile uint8_t aimed_flag;

void StartTask_Servo(void *argument);

#endif /* SERVO_H */










































