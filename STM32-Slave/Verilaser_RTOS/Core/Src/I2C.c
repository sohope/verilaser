/* I2C.c
 * Basys3로부터 I2C Slave로 좌표 수신 → Queue에 전달
 *
 * 패킷 구조 (7바이트):
 *   [0] STX       = 0xAA
 *   [1] mode      = 0/1/2
 *   [2] blob_valid= 0/1
 *   [3] cx_h      = center_x >> 8
 *   [4] cx_l      = center_x & 0xFF
 *   [5] cy        = center_y (0~239)
 *   [6] CHECKSUM  = XOR([0]~[5])
 */

#include "main.h"
#include "cmsis_os.h"
#include "I2C.h"

/* ── 외부 참조 ─────────────────────────────────────── */
extern I2C_HandleTypeDef  hi2c1;
extern osMessageQueueId_t Queue_I2CHandle;

/* ── 상수 ──────────────────────────────────────────── */
#define PKT_LEN  7
#define PKT_STX  0xAA

/* ════════════════════════════════════════════════════
 *  Task_I2C 본체
 * ════════════════════════════════════════════════════ */
void StartTask_I2C(void *argument)
{
    uint8_t buf[PKT_LEN];
    Coord_t coord;

    for (;;)
    {
        /* [1] 7바이트 수신 (블로킹) */
        if (HAL_I2C_Slave_Receive(&hi2c1, buf, PKT_LEN, osWaitForever) != HAL_OK)
        {
            osDelay(10);
            continue;
        }

        /* [2] STX 확인 */
        if (buf[0] != PKT_STX)
        {
            osDelay(1);
            continue;
        }

        /* [3] CHECKSUM 검증 */
        uint8_t chk = buf[0] ^ buf[1] ^ buf[2] ^ buf[3] ^ buf[4] ^ buf[5];
        if (chk != buf[6])
        {
            osDelay(1);
            continue;
        }

        /* [4] 파싱 */
        coord.mode       = buf[1];
        coord.blob_valid = buf[2];
        coord.center_x   = ((uint16_t)buf[3] << 8) | buf[4];
        coord.center_y   = buf[5];

        /* [5] Queue에 전달 */
        osMessageQueuePut(Queue_I2CHandle, &coord, 0, 0);
    }
}
