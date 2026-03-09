/* Servo.c
 * Queue에서 좌표 꺼내서 Pan + Tilt 동시 계산 + PWM 출력
 *
 * 카메라 고정 방식 (직접 매핑):
 *   center_x (0~319) → pan  (0~180°)
 *   center_y (0~239) → tilt (0~180°)
 *
 * TIM3 CCR 범위 (PSC=83, ARR=19999, 84MHz):
 *   CCR 1000 = 1000μs = 0°
 *   CCR 1500 = 1500μs = 90°  (중립)
 *   CCR 2000 = 2000μs = 180°
 */

#include "main.h"
#include "cmsis_os.h"
#include "I2C.h"
#include "Servo.h"

/* ── 외부 참조 ─────────────────────────────────────── */
extern TIM_HandleTypeDef  htim3;
extern osMessageQueueId_t Queue_I2CHandle;

/* ── 조준완료 플래그 (Laser, Buzzer Task가 읽음) ────── */
volatile uint8_t aimed_flag = 0;

/* ── 상수 ──────────────────────────────────────────── */
#define SCREEN_CX    160
#define SCREEN_CY    120
#define DEADZONE_PX  10
#define CCR_MIN      1000
#define CCR_MAX      2000

/* ── 내부 함수 선언 ─────────────────────────────────── */
static void Servo_SetAngle(float pan, float tilt);
static void Servo_Track(uint16_t cx, uint8_t cy);

/* ════════════════════════════════════════════════════
 *  Task_Servo 본체
 * ════════════════════════════════════════════════════ */
void StartTask_Servo(void *argument)
{
    Coord_t coord;

    /* PWM 채널 시작 */
    HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);  /* Pan  */
    HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);  /* Tilt */

    /* 중립 위치로 이동 */
    Servo_SetAngle(90.0f, 90.0f);

    for (;;)
    {
        /* [1] Queue 대기 (블로킹) */
        if (osMessageQueueGet(Queue_I2CHandle, &coord, NULL, osWaitForever) != osOK)
            continue;

        /* [2] blob_valid 확인 */
        if (!coord.blob_valid)
        {
            aimed_flag = 0;
            continue;
        }

        /* [3] mode 분기 */
        switch (coord.mode)
        {
            case 0:  /* 수동 — 버튼으로 처리 */
                break;

            case 1:  /* 격자 — 추후 구현 */
                break;

            case 2:  /* 완전추적 */
                Servo_Track(coord.center_x, coord.center_y);
                break;

            default:
                break;
        }
    }
}

/* ════════════════════════════════════════════════════
 *  완전추적 (카메라 고정 → 직접 매핑)
 * ════════════════════════════════════════════════════ */
static void Servo_Track(uint16_t cx, uint8_t cy)
{
    /* [1] 데드존 확인 */
    int16_t err_x = (int16_t)cx - SCREEN_CX;
    int16_t err_y = (int16_t)cy - SCREEN_CY;

    if (abs(err_x) < DEADZONE_PX && abs(err_y) < DEADZONE_PX)
    {
        aimed_flag = 1;
        return;
    }
    aimed_flag = 0;

    /* [2] 좌표 → 각도 직접 매핑 */
    float pan_angle  = (float)cx / 319.0f * 180.0f;
    float tilt_angle = (float)cy / 239.0f * 180.0f;

    /* [3] PWM 출력 */
    Servo_SetAngle(pan_angle, tilt_angle);
}

/* ════════════════════════════════════════════════════
 *  각도 → CCR 변환 후 TIM3 동시 출력
 *  CCR = 1000 + (angle / 180.0) * 1000
 * ════════════════════════════════════════════════════ */
static void Servo_SetAngle(float pan, float tilt)
{
    uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * 1000.0f);
    uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * 1000.0f);

    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, ccr_pan);
    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, ccr_tilt);
}
