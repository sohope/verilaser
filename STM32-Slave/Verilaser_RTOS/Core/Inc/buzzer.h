#ifndef INC_BUZZER_H_
#define INC_BUZZER_H_

#include "main.h"

void Buzzer_Init(void);
void Buzzer_On(void);
void Buzzer_Off(void);
void Buzzer_Beep(uint32_t on_ms, uint32_t off_ms);

#endif /* INC_BUZZER_H_ */
