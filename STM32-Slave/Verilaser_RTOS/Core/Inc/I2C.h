/*
 * I2C.h
 *
 *  Created on: Mar 9, 2026
 *      Author: kccistc
 */

#ifndef INC_I2C_H_
#define INC_I2C_H_

#include <stdint.h>
#include "cmsis_os.h"   /* ← 추가 */

typedef struct {
    uint8_t  mode;
    uint8_t  blob_valid;
    uint16_t center_x;
    uint8_t  center_y;
} Coord_t;

extern osMessageQueueId_t Queue_I2CHandle;   /* ← 추가 */
extern osMessageQueueId_t Queue_JoyHandle;   /* ← 추가 */

void StartTask_I2C(void *argument);

#endif /* INC_I2C_H_ */




































