/*
 * I2C.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_I2C_H_
#define INC_I2C_H_

#include <stdint.h>

/* ── 태스크 간 공유 구조체 ──────────────────────────── */
typedef struct {
    uint8_t  mode;        /* 0=수동, 1=격자, 2=추적 */
    uint8_t  blob_valid;  /* 0=객체없음, 1=객체있음  */
    uint16_t center_x;    /* 0 ~ 319                 */
    uint8_t  center_y;    /* 0 ~ 239                 */
} Coord_t;

void StartTask_I2C(void *argument);

#endif /* I2C_H */










































