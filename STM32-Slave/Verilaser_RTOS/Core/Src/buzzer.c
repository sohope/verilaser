/*
 * buzzer.c
 * 부저 제어 모듈
 */

#include "buzzer.h"
#include "cmsis_os.h"

void Buzzer_Init(void)
{
	HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_RESET);
}

void Buzzer_On(void)
{
	HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_SET);
}

void Buzzer_Off(void)
{
	HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_RESET);
}

void Buzzer_Beep(uint32_t on_ms, uint32_t off_ms)
{
	Buzzer_On();
	osDelay(on_ms);
	Buzzer_Off();
	osDelay(off_ms);
}
