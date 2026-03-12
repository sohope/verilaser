/* Joystick.c
 * 조이스틱 ADC 값을 읽어 Queue_I2C로 전달
 *
 * 수정사항:
 *   - adc_val을 uint32_t로 변경 (DMA는 32비트 단위로 전송)
 *   - Queue 타입이 Coord_t와 맞게 main.c도 수정 필요
 */

#include "main.h"
#include "cmsis_os.h"
#include "I2C.h"
#include "Joystick.h"

/* 외부 참조 */
extern ADC_HandleTypeDef  hadc1;
extern osMessageQueueId_t Queue_JoyHandle;

/* ── ADC DMA 버퍼: uint32_t 사용 ─────────────────────
 *   HAL_ADC_Start_DMA() 세 번째 인자가 uint32_t* 이므로
 *   버퍼도 uint32_t로 선언해야 값이 안 깨짐
 * ──────────────────────────────────────────────────── */
static volatile uint32_t adc_val[2];   /* [0]=X축, [1]=Y축 */

void StartTask_Joystick(void *argument)
{
    Coord_t joy_coord;
    joy_coord.mode       = 0;   /* 수동(조이스틱) 모드 */
    joy_coord.blob_valid = 1;   /* 데이터 유효 */

    /* ADC DMA 시작 */
    HAL_ADC_Start_DMA(&hadc1, (uint32_t*)adc_val, 2);

    for (;;)
    {
        /* ── ADC(0~4095) → 화면 좌표(0~319, 0~239) 매핑 ──
         * 조이스틱을 위로 밀었을 때 tilt가 줄어야 하면
         * center_y 줄에 (239.0f - ...) 로 반전하면 됩니다.
         * ──────────────────────────────────────────────── */
        joy_coord.center_x = (uint16_t)((adc_val[0] / 4095.0f) * 319.0f);
        joy_coord.center_y = (uint16_t)((adc_val[1] / 4095.0f) * 239.0f);

        /* Queue에 전송 (Task_Servo가 꺼내 씀) */
        osMessageQueuePut(Queue_JoyHandle, &joy_coord, 0, 10);

        osDelay(20);   /* 50Hz */
    }
}
