#ifndef INC_JOYSTICK_H_
#define INC_JOYSTICK_H_

#include "main.h"

void Joystick_Init(void);
void Joystick_Read(uint16_t *cx, uint16_t *cy);

#endif /* INC_JOYSTICK_H_ */
