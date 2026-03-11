/* Servo.c
 * Queue에서 조이스틱/카메라 좌표를 받아 서보 각도를 누적 제어
 */

#include "main.h"
#include "cmsis_os.h"
#include "I2C.h"
#include "Servo.h"
#include <stdlib.h> // abs() 사용을 위해 필요
#include <math.h>   /* fabsf() */

/* ── 외부 참조 ─────────────────────────────────────── */
extern TIM_HandleTypeDef  htim3;
extern osMessageQueueId_t Queue_I2CHandle;
extern osMessageQueueId_t Queue_JoyHandle;
extern volatile uint8_t g_mode;   /* ← 추가 */
/* ── 조준완료 플래그 ────── */
volatile uint8_t aimed_flag = 0;

/* ── 내부 전역 변수 (현재 각도 유지) ────────────────── */
static float current_pan  = 90.0f;   /* 초기값: 중립 */
static float current_tilt = 90.0f;

/* ── 상수 설정 ─────────────────────────────────────── */
#define TEST_X  329    /* ← 원하는 좌표로 바꾸세요 */
#define TEST_Y  239

#define SCREEN_CX    160
#define SCREEN_CY    120
#define DEADZONE_JOY 15      /* 조이스틱 중앙부 불감대 (떨림 방지) */
#define JOY_GAIN     0.05f   /* 조이스틱 이동 속도 (숫자가 커질수록 빨라짐) */
#define AUTO_GAIN    0.5f   /* 자동 추적 속도 ← 원하는 값으로 조절 */
#define CCR_MIN      500
#define CCR_MAX      2500

/* ── 내부 함수 선언 ─────────────────────────────────── */
static void Servo_SetAngle(float pan, float tilt);
static void Servo_Control_Logic(uint16_t cx, uint16_t cy, float gain);

/* ════════════════════════════════════════════════════
 * Task_Servo 본체
 * ════════════════════════════════════════════════════ */
void StartTask_Servo(void *argument)
{
    Coord_t coord;

    /* PWM 채널 시작 */
    HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);  /* Pan  : PA6 */
    HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);  /* Tilt : PA7 */

    /* 초기 중립 위치 설정 */
    Servo_SetAngle(current_pan, current_tilt);

    for (;;)
    {
        if (g_mode == 1)
        {
            /* ── 수동 모드: 조이스틱 Queue ── */
            if (osMessageQueueGet(Queue_JoyHandle, &coord, NULL, 20) == osOK)
            {
//                if (coord.blob_valid)
                	Servo_Control_Logic(coord.center_x, coord.center_y, JOY_GAIN);
//                else
//                    aimed_flag = 0;
            }
        }
        else
        {
            /* ── 자동 모드: 목표 각도로 직접 수렴 ── */
            float target_pan  = (TEST_X / 319.0f) * 180.0f;
            float target_tilt = (TEST_Y / 239.0f) * 180.0f;

            float diff_pan  = target_pan  - current_pan;
            float diff_tilt = target_tilt - current_tilt;

            if (fabsf(diff_pan) > 1.0f || fabsf(diff_tilt) > 1.0f)
            {
                current_pan  -= diff_pan  * AUTO_GAIN;
                current_tilt += diff_tilt * AUTO_GAIN;

                Servo_SetAngle(current_pan, current_tilt);
                aimed_flag = 0;
            }
            else
            {
                aimed_flag = 1;
            }
            osDelay(33);
        }
    }
}

/* ════════════════════════════════════════════════════
 * 조이스틱 입력 → 각도 누적 계산 (Incremental Control)
 * ════════════════════════════════════════════════════ */
static void Servo_Control_Logic(uint16_t cx, uint16_t cy, float gain)
{
    /* [1] 중앙(160, 120)으로부터의 오차 계산 */
    int16_t err_x = (int16_t)cx - SCREEN_CX;
    int16_t err_y = (int16_t)cy - SCREEN_CY;

    /* [2] 데드존 확인 (가만히 있을 때 떨림 방지) */
    if (abs(err_x) < DEADZONE_JOY && abs(err_y) < DEADZONE_JOY)
    {
        aimed_flag = 1; // 중앙에 위치함
        return;
    }
    aimed_flag = 0;

    /* [3] 각도 누적 (조이스틱을 밀고 있는 동안 각도가 계속 변함) */
    /* 방향이 반대라면 -JOY_GAIN으로 수정하세요 */
    current_pan  += (float)err_x * gain; // a = a + b
    current_tilt += (float)err_y * gain;

    // a = -b

    /* [4] 각도 제한 (0~180도) */
    if (current_pan < 0.0f)    current_pan = 0.0f;
    if (current_pan > 180.0f)  current_pan = 180.0f;
    if (current_tilt < 0.0f)   current_tilt = 0.0f;
    if (current_tilt > 180.0f) current_tilt = 180.0f;

    /* [5] 최종 PWM 출력 */
    Servo_SetAngle(current_pan, current_tilt);
}

/* ════════════════════════════════════════════════════
 * 각도 → CCR 변환 후 TIM3 출력
 * ════════════════════════════════════════════════════ */
static void Servo_SetAngle(float pan, float tilt)
{
    // 각도(0~180)를 CCR(1000~2000)으로 변환
//    uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * 1000.0f);
//    uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * 1000.0f);
	uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * (CCR_MAX - CCR_MIN));
	uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * (CCR_MAX - CCR_MIN));

    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, ccr_pan);
    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, ccr_tilt);
}
