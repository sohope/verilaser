///* USER CODE BEGIN Header */
///**
//  ******************************************************************************
//  * @file           : main.c
//  * @brief          : Main program body
//  ******************************************************************************
//  * @attention
//  *
//  * Copyright (c) 2026 STMicroelectronics.
//  * All rights reserved.
//  *
//  * This software is licensed under terms that can be found in the LICENSE file
//  * in the root directory of this software component.
//  * If no LICENSE file comes with this software, it is provided AS-IS.
//  *
//  ******************************************************************************
//  */
///* USER CODE END Header */
///* Includes ------------------------------------------------------------------*/
//#include "main.h"
//
///* Private includes ----------------------------------------------------------*/
///* USER CODE BEGIN Includes */
//
///* USER CODE END Includes */
//
///* Private typedef -----------------------------------------------------------*/
///* USER CODE BEGIN PTD */
//
///* USER CODE END PTD */
//
///* Private define ------------------------------------------------------------*/
///* USER CODE BEGIN PD */
//
///* USER CODE END PD */
//
///* Private macro -------------------------------------------------------------*/
///* USER CODE BEGIN PM */
//
///* USER CODE END PM */
//
///* Private variables ---------------------------------------------------------*/
//TIM_HandleTypeDef htim2;
//TIM_HandleTypeDef htim4;
//
///* USER CODE BEGIN PV */
//uint8_t servo_state = 0;
//uint8_t button_prev = GPIO_PIN_RESET;  // SET ?�� RESET ?���??? �???�???!
///* USER CODE END PV */
//
///* Private function prototypes -----------------------------------------------*/
//void SystemClock_Config(void);
//static void MX_GPIO_Init(void);
//static void MX_TIM2_Init(void);
//static void MX_TIM4_Init(void);
///* USER CODE BEGIN PFP */
//
///* USER CODE END PFP */
//
///* Private user code ---------------------------------------------------------*/
///* USER CODE BEGIN 0 */
//
///* USER CODE END 0 */
//
///**
//  * @brief  The application entry point.
//  * @retval int
//  */
//int main(void)
//{
//
//  /* USER CODE BEGIN 1 */
//
//  /* USER CODE END 1 */
//
//  /* MCU Configuration--------------------------------------------------------*/
//
//  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
//  HAL_Init();
//
//  /* USER CODE BEGIN Init */
//
//  /* USER CODE END Init */
//
//  /* Configure the system clock */
//  SystemClock_Config();
//
//  /* USER CODE BEGIN SysInit */
//
//  /* USER CODE END SysInit */
//
//  /* Initialize all configured peripherals */
//  MX_GPIO_Init();
//  MX_TIM2_Init();
//  MX_TIM4_Init();
//  /* USER CODE BEGIN 2 */
//  HAL_TIM_PWM_Start(&htim4, TIM_CHANNEL_2);
//  __HAL_TIM_SetCompare(&htim4, TIM_CHANNEL_2, 50); // 초기 0?��
//  /* USER CODE END 2 */
//
//  /* Infinite loop */
//  /* USER CODE BEGIN WHILE */
//    while (1)
//    {
//    /* USER CODE END WHILE */
//
//    /* USER CODE BEGIN 3 */
//    	uint8_t button_now = HAL_GPIO_ReadPin(btn_GPIO_Port, btn_Pin);
//
//    	if (button_now == GPIO_PIN_RESET)  // 버튼 ?���? ?��
//    	{
//    	    HAL_GPIO_WritePin(led_GPIO_Port, led_Pin, GPIO_PIN_SET);
//    	    __HAL_TIM_SetCompare(&htim4, TIM_CHANNEL_2, 100); // 180?��
//    	}
//    	else
//    	{
//    	    HAL_GPIO_WritePin(led_GPIO_Port, led_Pin, GPIO_PIN_RESET);
//    	    __HAL_TIM_SetCompare(&htim4, TIM_CHANNEL_2, 50);  // 0?��
//    	}
//
//    	HAL_Delay(10);
//    }
//  /* USER CODE END 3 */
//}
//
///**
//  * @brief System Clock Configuration
//  * @retval None
//  */
//void SystemClock_Config(void)
//{
//  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
//  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
//
//  /** Configure the main internal regulator output voltage
//  */
//  __HAL_RCC_PWR_CLK_ENABLE();
//  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);
//
//  /** Initializes the RCC Oscillators according to the specified parameters
//  * in the RCC_OscInitTypeDef structure.
//  */
//  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
//  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
//  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
//  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
//  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
//  {
//    Error_Handler();
//  }
//
//  /** Initializes the CPU, AHB and APB buses clocks
//  */
//  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
//                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
//  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
//  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
//  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
//  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
//
//  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
//  {
//    Error_Handler();
//  }
//}
//
///**
//  * @brief TIM2 Initialization Function
//  * @param None
//  * @retval None
//  */
//static void MX_TIM2_Init(void)
//{
//
//  /* USER CODE BEGIN TIM2_Init 0 */
//
//  /* USER CODE END TIM2_Init 0 */
//
//  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
//  TIM_MasterConfigTypeDef sMasterConfig = {0};
//
//  /* USER CODE BEGIN TIM2_Init 1 */
//
//  /* USER CODE END TIM2_Init 1 */
//  htim2.Instance = TIM2;
//  htim2.Init.Prescaler = 319;
//  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
//  htim2.Init.Period = 999;
//  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
//  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
//  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
//  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
//  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
//  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  /* USER CODE BEGIN TIM2_Init 2 */
//
//  /* USER CODE END TIM2_Init 2 */
//
//}
//
///**
//  * @brief TIM4 Initialization Function
//  * @param None
//  * @retval None
//  */
//static void MX_TIM4_Init(void)
//{
//
//  /* USER CODE BEGIN TIM4_Init 0 */
//
//  /* USER CODE END TIM4_Init 0 */
//
//  TIM_MasterConfigTypeDef sMasterConfig = {0};
//  TIM_OC_InitTypeDef sConfigOC = {0};
//
//  /* USER CODE BEGIN TIM4_Init 1 */
//
//  /* USER CODE END TIM4_Init 1 */
//  htim4.Instance = TIM4;
//  htim4.Init.Prescaler = 320-1;
//  htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
//  htim4.Init.Period = 1000-1;
//  htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
//  htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
//  if (HAL_TIM_PWM_Init(&htim4) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
//  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
//  if (HAL_TIMEx_MasterConfigSynchronization(&htim4, &sMasterConfig) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  sConfigOC.OCMode = TIM_OCMODE_PWM1;
//  sConfigOC.Pulse = 0;
//  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
//  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
//  if (HAL_TIM_PWM_ConfigChannel(&htim4, &sConfigOC, TIM_CHANNEL_1) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  sConfigOC.Pulse = 500-1;
//  if (HAL_TIM_PWM_ConfigChannel(&htim4, &sConfigOC, TIM_CHANNEL_2) != HAL_OK)
//  {
//    Error_Handler();
//  }
//  /* USER CODE BEGIN TIM4_Init 2 */
//
//  /* USER CODE END TIM4_Init 2 */
//  HAL_TIM_MspPostInit(&htim4);
//
//}
//
///**
//  * @brief GPIO Initialization Function
//  * @param None
//  * @retval None
//  */
//static void MX_GPIO_Init(void)
//{
//  GPIO_InitTypeDef GPIO_InitStruct = {0};
///* USER CODE BEGIN MX_GPIO_Init_1 */
///* USER CODE END MX_GPIO_Init_1 */
//
//  /* GPIO Ports Clock Enable */
//  __HAL_RCC_GPIOC_CLK_ENABLE();
//  __HAL_RCC_GPIOA_CLK_ENABLE();
//  __HAL_RCC_GPIOB_CLK_ENABLE();
//
//  /*Configure GPIO pin Output Level */
//  HAL_GPIO_WritePin(led_GPIO_Port, led_Pin, GPIO_PIN_RESET);


/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : 완전추적 테스트 — 좌표 직접 입력
  *
  * ★ 테스트 방법:
  *   TEST_X, TEST_Y 값만 바꾸고 빌드 → 플래시
  *
  * TIM4 CCR 범위 (PSC=319, ARR=999, 클럭=16MHz):
  *   CCR 50  = 1000μs = 0°
  *   CCR 75  = 1500μs = 90°  (중립)
  *   CCR 100 = 2000μs = 180°
  *
  * 핀:
  *   TIM4_CH1 (PB6) → Pan  서보
  *   TIM4_CH2 (PB7) → Tilt 서보
  ******************************************************************************
  */
/* USER CODE END Header */

#include "main.h"

/* ── 하드웨어 핸들 ─────────────────────────────────── */
TIM_HandleTypeDef htim2;
TIM_HandleTypeDef htim4;

/* ════════════════════════════════════════════════════
 * ★ 여기 좌표만 바꾸고 빌드하면 됩니다 ★
 *   x: 0 ~ 319  (화면 중심 = 160)
 *   y: 0 ~ 239  (화면 중심 = 120)
 *
 * ════════════════════════════════════════════════════ */
#define TEST_X    160
#define TEST_Y	  120

/* ── 제어 파라미터 ─────────────────────────────────── */
#define SCREEN_CX    160
#define SCREEN_CY    120
#define GAIN         0.5f
#define DEADZONE_PX  10
#define CCR_MIN      50      /* 0°   = 1000μs */
#define CCR_MID      75      /* 90°  = 1500μs */
#define CCR_MAX      100     /* 180° = 2000μs */

/* ── 서보 현재 각도 ────────────────────────────────── */
static float pan_angle  = 90.0f;
static float tilt_angle = 90.0f;

/* ── 함수 선언 ─────────────────────────────────────── */
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_TIM2_Init(void);
static void MX_TIM4_Init(void);
static void Servo_SetAngle(float pan, float tilt);
static void Servo_Track(uint16_t cx, uint8_t cy);

/* ════════════════════════════════════════════════════
 *  main
 * ════════════════════════════════════════════════════ */
int main(void)
{
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_TIM2_Init();
    MX_TIM4_Init();

    /* PWM 채널 시작 */
    HAL_TIM_PWM_Start(&htim4, TIM_CHANNEL_1);   /* Pan  */
    HAL_TIM_PWM_Start(&htim4, TIM_CHANNEL_2);   /* Tilt */

    /* 중립 위치 (90°) 로 이동 후 대기 */
    Servo_SetAngle(90.0f, 90.0f);
    HAL_Delay(500);

    /* ★ 좌표 입력 → 추적 1회 실행 */
    Servo_Track(TEST_X, TEST_Y);

    while (1)
    {
        /* 매 33ms마다 반복 추적 */
        Servo_Track(TEST_X, TEST_Y);

        /* LED로 결과 표시 */
        int16_t ex = (int16_t)TEST_X - SCREEN_CX;
        int16_t ey = (int16_t)TEST_Y - SCREEN_CY;

        if (abs(ex) < DEADZONE_PX && abs(ey) < DEADZONE_PX)
        {
            HAL_GPIO_WritePin(led_GPIO_Port, led_Pin, GPIO_PIN_SET);
        }
        else
        {
            HAL_GPIO_TogglePin(led_GPIO_Port, led_Pin);
        }

        HAL_Delay(33);   /* 30fps */
    }


//    **바뀐 것 두 가지:**
//    ```
//    1. Servo_Track() → while(1) 안으로 이동
//       매 33ms마다 Pan/Tilt 동시 업데이트
//
//    2. HAL_Delay(200) 제거
//       → LED 깜빡임 안에 있던 딜레이가
//         서보 업데이트도 막고 있었음
//       → 33ms로 통일
}

/* ════════════════════════════════════════════════════
 *  완전추적 핵심 로직
 *
 *  [1] err 계산  : err_x = cx - 160
 *  [2] 데드존    : |err| < 10px → 유지, 리턴
 *  [3] 각도 누적 : pan  += err_x * gain
 *                  tilt += err_y * gain
 *  [4] 클리핑    : 0 ~ 180° 강제 제한
 *  [5] PWM 출력
 * ════════════════════════════════════════════════════ */
static void Servo_Track(uint16_t cx, uint8_t cy)
{
    /* [1] 오차 계산 */
    int16_t err_x = (int16_t)cx - SCREEN_CX;
    int16_t err_y = (int16_t)cy - SCREEN_CY;

    /* [2] 데드존 → 조준 이미 완료 */
    if (abs(err_x) < DEADZONE_PX && abs(err_y) < DEADZONE_PX)
        return;

    /* [3] 각도 누적
     *     서보 방향이 반대면 GAIN 앞에 - 붙이면 됩니다
     *     pan_angle  += (float)err_x * (-GAIN);  */
    pan_angle  += (float)err_x * -GAIN;
    tilt_angle += (float)err_y * GAIN;

    /* [4] 클리핑 */
    if (pan_angle  < 0.0f)   pan_angle  = 0.0f;
    if (pan_angle  > 180.0f) pan_angle  = 180.0f;
    if (tilt_angle < 0.0f)   tilt_angle = 0.0f;
    if (tilt_angle > 180.0f) tilt_angle = 180.0f;

    /* [5] PWM 출력 */
    Servo_SetAngle(pan_angle, tilt_angle);
}

/* ════════════════════════════════════════════════════
 *  각도 → CCR 변환 후 TIM4 출력
 *  CCR = 50 + (angle / 180.0) * 50
 * ════════════════════════════════════════════════════ */
static void Servo_SetAngle(float pan, float tilt)
{
    uint32_t ccr_pan  = (uint32_t)(CCR_MIN + (pan  / 180.0f) * 50.0f);
    uint32_t ccr_tilt = (uint32_t)(CCR_MIN + (tilt / 180.0f) * 50.0f);

    __HAL_TIM_SET_COMPARE(&htim4, TIM_CHANNEL_1, ccr_pan);
    __HAL_TIM_SET_COMPARE(&htim4, TIM_CHANNEL_2, ccr_tilt);
}

/* ════════════════════════════════════════════════════
 *  주변장치 초기화 (기존 코드 동일)
 * ════════════════════════════════════════════════════ */
void SystemClock_Config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    __HAL_RCC_PWR_CLK_ENABLE();
    __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

    RCC_OscInitStruct.OscillatorType      = RCC_OSCILLATORTYPE_HSI;
    RCC_OscInitStruct.HSIState            = RCC_HSI_ON;
    RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
    RCC_OscInitStruct.PLL.PLLState        = RCC_PLL_NONE;
    HAL_RCC_OscConfig(&RCC_OscInitStruct);

    RCC_ClkInitStruct.ClockType      = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK
                                     | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource   = RCC_SYSCLKSOURCE_HSI;
    RCC_ClkInitStruct.AHBCLKDivider  = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
    HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0);
}

static void MX_TIM2_Init(void)
{
    TIM_ClockConfigTypeDef  sClockSourceConfig = {0};
    TIM_MasterConfigTypeDef sMasterConfig      = {0};

    htim2.Instance               = TIM2;
    htim2.Init.Prescaler         = 319;
    htim2.Init.CounterMode       = TIM_COUNTERMODE_UP;
    htim2.Init.Period            = 999;
    htim2.Init.ClockDivision     = TIM_CLOCKDIVISION_DIV1;
    htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
    HAL_TIM_Base_Init(&htim2);

    sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
    HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig);

    sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
    sMasterConfig.MasterSlaveMode     = TIM_MASTERSLAVEMODE_DISABLE;
    HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig);
}

static void MX_TIM4_Init(void)
{
    TIM_MasterConfigTypeDef sMasterConfig = {0};
    TIM_OC_InitTypeDef      sConfigOC     = {0};

    htim4.Instance               = TIM4;
    htim4.Init.Prescaler         = 320 - 1;
    htim4.Init.CounterMode       = TIM_COUNTERMODE_UP;
    htim4.Init.Period            = 1000 - 1;
    htim4.Init.ClockDivision     = TIM_CLOCKDIVISION_DIV1;
    htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
    HAL_TIM_PWM_Init(&htim4);

    sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
    sMasterConfig.MasterSlaveMode     = TIM_MASTERSLAVEMODE_DISABLE;
    HAL_TIMEx_MasterConfigSynchronization(&htim4, &sMasterConfig);

    sConfigOC.OCMode     = TIM_OCMODE_PWM1;
    sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;

    sConfigOC.Pulse = CCR_MID;
    HAL_TIM_PWM_ConfigChannel(&htim4, &sConfigOC, TIM_CHANNEL_1);

    sConfigOC.Pulse = CCR_MID;
    HAL_TIM_PWM_ConfigChannel(&htim4, &sConfigOC, TIM_CHANNEL_2);

    HAL_TIM_MspPostInit(&htim4);
}

static void MX_GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_GPIOC_CLK_ENABLE();
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();

    HAL_GPIO_WritePin(led_GPIO_Port, led_Pin, GPIO_PIN_RESET);

    GPIO_InitStruct.Pin  = btn_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(btn_GPIO_Port, &GPIO_InitStruct);

    GPIO_InitStruct.Pin   = led_Pin;
    GPIO_InitStruct.Mode  = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull  = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(led_GPIO_Port, &GPIO_InitStruct);
}

void Error_Handler(void)
{
    __disable_irq();
    while (1) {}
}

//ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ

//  /*Configure GPIO pin : btn_Pin */
//  GPIO_InitStruct.Pin = btn_Pin;
//  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
//  GPIO_InitStruct.Pull = GPIO_NOPULL;
//  HAL_GPIO_Init(btn_GPIO_Port, &GPIO_InitStruct);
//
//  /*Configure GPIO pin : led_Pin */
//  GPIO_InitStruct.Pin = led_Pin;
//  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
//  GPIO_InitStruct.Pull = GPIO_NOPULL;
//  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
//  HAL_GPIO_Init(led_GPIO_Port, &GPIO_InitStruct);
//
///* USER CODE BEGIN MX_GPIO_Init_2 */
///* USER CODE END MX_GPIO_Init_2 */
//}
//
///* USER CODE BEGIN 4 */
//
///* USER CODE END 4 */
//
///**
//  * @brief  This function is executed in case of error occurrence.
//  * @retval None
//  */
//void Error_Handler(void)
//{
//  /* USER CODE BEGIN Error_Handler_Debug */
//  /* User can add his own implementation to report the HAL error return state */
//  __disable_irq();
//  while (1)
//  {
//  }
//  /* USER CODE END Error_Handler_Debug */
//}
//
//#ifdef  USE_FULL_ASSERT
///**
//  * @brief  Reports the name of the source file and the source line number
//  *         where the assert_param error has occurred.
//  * @param  file: pointer to the source file name
//  * @param  line: assert_param error line source number
//  * @retval None
//  */
//void assert_failed(uint8_t *file, uint32_t line)
//{
//  /* USER CODE BEGIN 6 */
//  /* User can add his own implementation to report the file name and line number,
//     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
//  /* USER CODE END 6 */
//}
//#endif /* USE_FULL_ASSERT */
