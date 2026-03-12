/* Laser.c
 * aimed_flag 보고 레이저 ON/OFF
 */

#include "main.h"
#include "cmsis_os.h"
#include "Servo.h"
#include "Laser.h"

/* ════════════════════════════════════════════════════
 *  Task_Laser 본체
 * ════════════════════════════════════════════════════ */
void StartTask_Laser(void *argument)
{
    for (;;)
    {
        if (aimed_flag)
            HAL_GPIO_WritePin(Laser_GPIO_Port, Laser_Pin, GPIO_PIN_SET);
        else
            HAL_GPIO_WritePin(Laser_GPIO_Port, Laser_Pin, GPIO_PIN_RESET);

        osDelay(10);
    }
}
