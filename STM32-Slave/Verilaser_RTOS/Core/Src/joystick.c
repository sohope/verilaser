/*
 * joystick.c
 * ADC DMA로 조이스틱 값을 읽어 화면 좌표로 변환
 * (LeeJae 코드 참고)
 */

#include "joystick.h"

extern ADC_HandleTypeDef hadc1;

/* DMA 버퍼: uint32_t (HAL_ADC_Start_DMA가 uint32_t* 요구) */
static volatile uint32_t adc_val[2];   /* [0]=X축(PA0), [1]=Y축(PA1) */

void Joystick_Init(void)
{
	HAL_ADC_Start_DMA(&hadc1, (uint32_t*)adc_val, 2);
}

void Joystick_Read(uint16_t *cx, uint16_t *cy)
{
	/* ADC(0~4095) → 화면 좌표(0~319, 0~239) 매핑 */
	*cx = 319 - (uint16_t)((adc_val[0] / 4095.0f) * 319.0f);
	*cy = 239 - (uint16_t)((adc_val[1] / 4095.0f) * 239.0f);
}
