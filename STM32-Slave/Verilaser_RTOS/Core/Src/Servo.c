/* Servo.c
 * Queue에서 조이스틱/카메라 좌표를 받아 서보 각도를 누적 제어
 */

#include "main.h"
#include "cmsis_os.h"
#include "I2C.h"
#include "Servo.h"
#include <stdlib.h> // abs() 사용을 위해 필요

/* ── 외부 참조 ─────────────────────────────────────── */
extern TIM_HandleTypeDef  htim3;
extern osMessageQueueId_t Queue_I2CHandle;

/* ── 조준완료 플래그 ────── */
volatile uint8_t aimed_flag = 0;

/* ── 내부 전역 변수 (현재 각도 유지) ────────────────── */
static float current_pan  = 90.0f;   /* 초기값: 중립 */
static float current_tilt = 90.0f;

/* ── 상수 설정 ─────────────────────────────────────── */
#define SCREEN_CX    160
#define SCREEN_CY    120
#define DEADZONE_JOY 15      /* 조이스틱 중앙부 불감대 (떨림 방지) */
#define JOY_GAIN     0.05f   /* 조이스틱 이동 속도 (숫자가 커질수록 빨라짐) */
#define CCR_MIN      1000
#define CCR_MAX      2000

/* ── 내부 함수 선언 ─────────────────────────────────── */
static void Servo_SetAngle(float pan, float tilt);
static void Servo_Control_Logic(uint16_t cx, uint16_t cy);

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
        /* [1] Queue에서 데이터 대기 */
        if (osMessageQueueGet(Queue_I2CHandle, &coord, NULL, osWaitForever) != osOK)
            continue;

        /* [2] 데이터 유효성 검사 */
        if (!coord.blob_valid)
        {
            aimed_flag = 0;
            continue;
        }

        /* [3] 모드별 처리 */
        switch (coord.mode)
        {
            case 0:  /* 수동(조이스틱) 모드 */
                Servo_Control_Logic(coord.center_x, coord.center_y);
                break;

            case 2:  /* 완전추적(카메라) 모드 - 현재는 조이스틱으로 테스트 중 */
                Servo_Control_Logic(coord.center_x, coord.center_y);
                break;

            default:
                break;
        }
    }
}

/* ════════════════════════════════════════════════════
 * 조이스틱 입력 → 각도 누적 계산 (Incremental Control)
 * ════════════════════════════════════════════════════ */
static void Servo_Control_Logic(uint16_t cx, uint16_t cy)
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
    current_pan  += (float)err_x * JOY_GAIN;
    current_tilt += (float)err_y * JOY_GAIN;

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
    uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * 1000.0f);
    uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * 1000.0f);

    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, ccr_pan);
    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, ccr_tilt);
}
