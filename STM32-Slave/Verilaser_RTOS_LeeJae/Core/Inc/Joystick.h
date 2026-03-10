/* Joystick.h */
#ifndef INC_JOYSTICK_H_
#define INC_JOYSTICK_H_

#include "main.h"  // uint16_t 등을 인식하기 위해 필요

#define ADC_BUF_LEN 2

/* USER CODE BEGIN PTD */
typedef struct {
    uint16_t x_raw;
    uint16_t y_raw;
    uint8_t sw_state;
} JoystickData_t;
/* USER CODE END PTD */

/* --- 이 부분을 추가하세요 --- */
/* StartTask_Joystick 함수가 다른 파일(Joystick.c)에 있다고 알려주는 선언 */
void StartTask_Joystick(void *argument);
/* -------------------------- */

#endif /* INC_JOYSTICK_H_ */
