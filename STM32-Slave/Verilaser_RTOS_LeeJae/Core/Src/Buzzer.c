/* Buzzer.c
 * aimed_flag 보고 부저 제어
 *   조준완료 → 부저 짧게 ON
 *   추적중   → 부저 OFF
 */

#include "main.h"
#include "cmsis_os.h"
#include "Servo.h"
#include "Buzzer.h"

/* ════════════════════════════════════════════════════
 *  Task_Buzzer 본체
 * ════════════════════════════════════════════════════ */
void StartTask_Buzzer(void *argument)
{
    for (;;)
    {
        if (aimed_flag)
        {
            HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_SET);
            osDelay(200);
            HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_RESET);
            osDelay(800);
        }
        else
        {
            HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_RESET);
            osDelay(100);
        }
    }
}
