/*
 * laser.c
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */


#include "laser.h"

void Laser_Init(void)
{
	Laser_Off();
}

void Laser_On(void)
{
	HAL_GPIO_WritePin(GPIOA, Laser_Pin, GPIO_PIN_SET);
}

void Laser_Off(void)
{
	HAL_GPIO_WritePin(GPIOA, Laser_Pin, GPIO_PIN_RESET);
}
