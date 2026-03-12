/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "servo.h"
#include "laser.h"
#include "joystick.h"
#include "buzzer.h"
#include <stdio.h>
#include <string.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define I2C_SLAVE_ADDR   0x20   /* 7-bit addr=0x10, 좌시?��?�� */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc1;
DMA_HandleTypeDef hdma_adc1;

I2C_HandleTypeDef hi2c1;

TIM_HandleTypeDef htim3;

UART_HandleTypeDef huart2;

/* Definitions for defaultTask */
osThreadId_t defaultTaskHandle;
const osThreadAttr_t defaultTask_attributes = {
  .name = "defaultTask",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for Task_Servo */
osThreadId_t Task_ServoHandle;
const osThreadAttr_t Task_Servo_attributes = {
  .name = "Task_Servo",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityLow,
};
/* Definitions for Task_Laser */
osThreadId_t Task_LaserHandle;
const osThreadAttr_t Task_Laser_attributes = {
  .name = "Task_Laser",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityLow,
};
/* Definitions for Task_I2C */
osThreadId_t Task_I2CHandle;
const osThreadAttr_t Task_I2C_attributes = {
  .name = "Task_I2C",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityLow,
};
/* Definitions for Task_Buzzer */
osThreadId_t Task_BuzzerHandle;
const osThreadAttr_t Task_Buzzer_attributes = {
  .name = "Task_Buzzer",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityLow,
};
/* Definitions for Queue_I2C */
osMessageQueueId_t Queue_I2CHandle;
const osMessageQueueAttr_t Queue_I2C_attributes = {
  .name = "Queue_I2C"
};
/* USER CODE BEGIN PV */
uint8_t i2c_rx_buffer[5];
volatile uint32_t i2c_rx_count = 0;
volatile uint32_t i2c_err_count = 0;
volatile TargetData_t last_rx_data;
volatile uint8_t g_target_status = 0;
volatile uint8_t g_mode = MODE_MANUAL;   /* 0=?��?��, 1=?��?��, 2=?��?�� */
volatile uint8_t g_aim_locked = 0;       /* 1=조�? ?���?(1�? 경과), 0=경고 �? */
char uart_buf[128];
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_I2C1_Init(void);
static void MX_TIM3_Init(void);
static void MX_ADC1_Init(void);
void StartDefaultTask(void *argument);
void Servo_Task(void *argument);
void Laser_Task(void *argument);
void I2C_Task(void *argument);
void Buzzer_Task(void *argument);

/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_USART2_UART_Init();
  MX_I2C1_Init();
  MX_TIM3_Init();
  MX_ADC1_Init();
  /* USER CODE BEGIN 2 */
  {
    const char *msg = "\r\n[BOOT] System started\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, strlen(msg), 100);

    HAL_StatusTypeDef ret = HAL_I2C_Slave_Receive_IT(&hi2c1, i2c_rx_buffer, 5);
    int len = sprintf(uart_buf, "[BOOT] I2C Slave Listen: %s (addr=0x%02X)\r\n",
                      (ret == HAL_OK) ? "OK" : "FAIL", (unsigned int)(hi2c1.Init.OwnAddress1 >> 1));
    HAL_UART_Transmit(&huart2, (uint8_t*)uart_buf, len, 100);

    Joystick_Init();
  }
  /* USER CODE END 2 */

  /* Init scheduler */
  osKernelInitialize();

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* Create the queue(s) */
  /* creation of Queue_I2C */
  Queue_I2CHandle = osMessageQueueNew (32, sizeof(uint16_t), &Queue_I2C_attributes);

  /* USER CODE BEGIN RTOS_QUEUES */
  /* CubeMX�? sizeof(uint16_t)�? ?��?��?���?�? TargetData_t ?��기로 ?��?��?�� */
  osMessageQueueDelete(Queue_I2CHandle);
  Queue_I2CHandle = osMessageQueueNew(32, sizeof(TargetData_t), &Queue_I2C_attributes);
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of defaultTask */
  defaultTaskHandle = osThreadNew(StartDefaultTask, NULL, &defaultTask_attributes);

  /* creation of Task_Servo */
  Task_ServoHandle = osThreadNew(Servo_Task, NULL, &Task_Servo_attributes);

  /* creation of Task_Laser */
  Task_LaserHandle = osThreadNew(Laser_Task, NULL, &Task_Laser_attributes);

  /* creation of Task_I2C */
  Task_I2CHandle = osThreadNew(I2C_Task, NULL, &Task_I2C_attributes);

  /* creation of Task_Buzzer */
  Task_BuzzerHandle = osThreadNew(Buzzer_Task, NULL, &Task_Buzzer_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* USER CODE BEGIN RTOS_EVENTS */
  /* add events, ... */
  /* USER CODE END RTOS_EVENTS */

  /* Start scheduler */
  osKernelStart();

  /* We should never get here as control is now taken by the scheduler */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief ADC1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_ADC1_Init(void)
{

  /* USER CODE BEGIN ADC1_Init 0 */

  /* USER CODE END ADC1_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC1_Init 1 */

  /* USER CODE END ADC1_Init 1 */

  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion)
  */
  hadc1.Instance = ADC1;
  hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV4;
  hadc1.Init.Resolution = ADC_RESOLUTION_12B;
  hadc1.Init.ScanConvMode = ENABLE;
  hadc1.Init.ContinuousConvMode = ENABLE;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.NbrOfConversion = 2;
  hadc1.Init.DMAContinuousRequests = ENABLE;
  hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }

  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time.
  */
  sConfig.Channel = ADC_CHANNEL_0;
  sConfig.Rank = 1;
  sConfig.SamplingTime = ADC_SAMPLETIME_84CYCLES;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }

  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time.
  */
  sConfig.Channel = ADC_CHANNEL_1;
  sConfig.Rank = 2;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN ADC1_Init 2 */

  /* USER CODE END ADC1_Init 2 */

}

/**
  * @brief I2C1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_I2C1_Init(void)
{

  /* USER CODE BEGIN I2C1_Init 0 */

  /* USER CODE END I2C1_Init 0 */

  /* USER CODE BEGIN I2C1_Init 1 */

  /* USER CODE END I2C1_Init 1 */
  hi2c1.Instance = I2C1;
  hi2c1.Init.ClockSpeed = 100000;
  hi2c1.Init.DutyCycle = I2C_DUTYCYCLE_2;
  hi2c1.Init.OwnAddress1 = 40;
  hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
  hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
  hi2c1.Init.OwnAddress2 = 0;
  hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
  hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_ENABLE;
  if (HAL_I2C_Init(&hi2c1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN I2C1_Init 2 */
  hi2c1.Init.OwnAddress1 = I2C_SLAVE_ADDR;
  HAL_I2C_Init(&hi2c1);
  /* USER CODE END I2C1_Init 2 */

}

/**
  * @brief TIM3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM3_Init(void)
{

  /* USER CODE BEGIN TIM3_Init 0 */

  /* USER CODE END TIM3_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};

  /* USER CODE BEGIN TIM3_Init 1 */

  /* USER CODE END TIM3_Init 1 */
  htim3.Instance = TIM3;
  htim3.Init.Prescaler = 83;
  htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim3.Init.Period = 19999;
  htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim3.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_PWM_Init(&htim3) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim3, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 0;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_1) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM3_Init 2 */

  /* USER CODE END TIM3_Init 2 */
  HAL_TIM_MspPostInit(&htim3);

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void)
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA2_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA2_Stream0_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA2_Stream0_IRQn, 5, 0);
  HAL_NVIC_EnableIRQ(DMA2_Stream0_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, LD2_Pin|Laser_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(Led_fire_GPIO_Port, Led_fire_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(Buzzer_GPIO_Port, Buzzer_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pins : LD2_Pin Laser_Pin */
  GPIO_InitStruct.Pin = LD2_Pin|Laser_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : Btn_fire_Pin Btn_mode_Pin */
  GPIO_InitStruct.Pin = Btn_fire_Pin|Btn_mode_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pin : Led_fire_Pin */
  GPIO_InitStruct.Pin = Led_fire_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(Led_fire_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : Buzzer_Pin */
  GPIO_InitStruct.Pin = Buzzer_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(Buzzer_GPIO_Port, &GPIO_InitStruct);

/* USER CODE BEGIN MX_GPIO_Init_2 */
/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */
void HAL_I2C_SlaveRxCpltCallback(I2C_HandleTypeDef *hi2c)
{
	if(hi2c -> Instance == I2C1)
	{
		i2c_rx_count++;

		TargetData_t txData;
		txData.status = i2c_rx_buffer[0];
		txData.x = (i2c_rx_buffer[1] << 8) | i2c_rx_buffer[2];
		txData.y = (i2c_rx_buffer[3] << 8) | i2c_rx_buffer[4];

		last_rx_data = txData;
		osMessageQueuePut(Queue_I2CHandle, &txData, 0, 0);
		HAL_I2C_Slave_Receive_IT(&hi2c1, i2c_rx_buffer, 5);
	}
}

void HAL_I2C_ErrorCallback(I2C_HandleTypeDef *hi2c)
{
	if(hi2c -> Instance == I2C1)
	{
		i2c_err_count++;
		HAL_I2C_Slave_Receive_IT(&hi2c1, i2c_rx_buffer, 5);
	}
}
/* USER CODE END 4 */

/* USER CODE BEGIN Header_StartDefaultTask */
/**
  * @brief  Function implementing the defaultTask thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_StartDefaultTask */
void StartDefaultTask(void *argument)
{
  /* USER CODE BEGIN 5 */
  /* defaultTask: 모드 ?��?�� 버튼 + Fire 버튼 처리 (LeeJae StartTask03 참고) */
  uint8_t btn_prev = 1;

  for(;;)
  {
    /* ???? Btn_mode(PB15) ?���?: Mode 0 ?�� 1 ?�� 2 ?�� 0 ... ???? */
    uint8_t btn_now = HAL_GPIO_ReadPin(Btn_mode_GPIO_Port, Btn_mode_Pin);
    if (btn_prev == 1 && btn_now == 0)  /* falling edge */
    {
      g_mode = (g_mode + 1) % 3;

      /* LED ?��?��: ?��?��모드=ON, ?��머�?=OFF */
      HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin,
                        (g_mode == MODE_ZEROING) ? GPIO_PIN_SET : GPIO_PIN_RESET);

      osDelay(50);  /* ?��바운?�� */
    }
    btn_prev = btn_now;

    /* ???? Btn_fire(PB13) ?�� Led_fire(PB14) ?��?�� ???? */
    if (HAL_GPIO_ReadPin(Btn_fire_GPIO_Port, Btn_fire_Pin) == GPIO_PIN_RESET)
      HAL_GPIO_WritePin(Led_fire_GPIO_Port, Led_fire_Pin, GPIO_PIN_SET);
    else
      HAL_GPIO_WritePin(Led_fire_GPIO_Port, Led_fire_Pin, GPIO_PIN_RESET);

    osDelay(20);
  }
  /* USER CODE END 5 */
}

/* USER CODE BEGIN Header_Servo_Task */
/**
* @brief Function implementing the Task_Servo thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_Servo_Task */
void Servo_Task(void *argument)
{
  /* USER CODE BEGIN Servo_Task */
	TargetData_t rxData;
	Servo_Init();

	uint8_t prev_mode = 0xFF;  /* 모드 ?��?�� 감�??�� */

  for(;;)
  {
	/* 모드�? 바�?�면 ?��보�?? ?��?���? 리셋 */
	if(g_mode != prev_mode)
	{
		Servo_GoCenter();
		prev_mode = g_mode;
	}

	switch(g_mode)
	{
	case MODE_MANUAL:
	{
		uint16_t cx, cy;
		Joystick_Read(&cx, &cy);
		Servo_Manual(cx, cy);

		/* I2C ?��?�� 비워?�� 객체 감�? ?��?�� ?��?��?��?�� (�????��) */
		if(osMessageQueueGet(Queue_I2CHandle, &rxData, NULL, 0) == osOK)
			g_target_status = rxData.status;

		osDelay(20);  /* 50Hz */
		break;
	}
	case MODE_ZEROING:
		g_target_status = 0;
		Servo_GoCenter();
		osDelay(100);
		break;

	case MODE_TRACK:
		if(osMessageQueueGet(Queue_I2CHandle, &rxData, NULL, 100) == osOK)
		{
			g_target_status = rxData.status;
			if(rxData.status == 1)
			{
				Servo_Track(rxData.x, rxData.y);
			}
		}
		break;
	}
  }
  /* USER CODE END Servo_Task */
}

/* USER CODE BEGIN Header_Laser_Task */
/**
* @brief Function implementing the Task_Laser thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_Laser_Task */
void Laser_Task(void *argument)
{
  /* USER CODE BEGIN Laser_Task */
	Laser_Init();
  for(;;)
  {
	uint8_t fire = (HAL_GPIO_ReadPin(Btn_fire_GPIO_Port, Btn_fire_Pin) == GPIO_PIN_RESET);

	switch(g_mode)
	{
	case MODE_MANUAL:
		/* ?��?�� 모드: Btn_fire ?��르는 ?��?���? ON */
		if(fire)
			Laser_On();
		else
			Laser_Off();
		break;

	case MODE_ZEROING:
		/* ?��?�� 모드: ?��?�� ON (?���? 기�??�� ?��?��?��) */
		Laser_On();
		break;

	case MODE_TRACK:
		/* ?��?�� 추적: 1�? 경고 ?�� 조�? ?���? ?��?���? 발사 */
		if(g_aim_locked)
			Laser_On();
		else
			Laser_Off();
		break;
	}
	osDelay(10);
  }
  /* USER CODE END Laser_Task */
}

/* USER CODE BEGIN Header_I2C_Task */
/**
* @brief Function implementing the Task_I2C thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_I2C_Task */
void I2C_Task(void *argument)
{
  /* USER CODE BEGIN I2C_Task */
  /* ?��버그 로그 ?��?�� ?��?��?��: UART ?��?��?? ?��기서�? */
  static const char *mode_names[] = {"MAN", "ZERO", "TRK"};

  for(;;)
  {
    uint16_t jx, jy;
    Joystick_Read(&jx, &jy);

    int len = snprintf(uart_buf, sizeof(uart_buf),
                       "[%s] joy=(%3u,%3u) i2c=(%3u,%3u) st=%u rx=%lu err=%lu\r\n",
                       mode_names[g_mode],
                       jx, jy,
                       last_rx_data.x, last_rx_data.y,
                       g_target_status, i2c_rx_count, i2c_err_count);
    HAL_UART_Transmit(&huart2, (uint8_t*)uart_buf, len, 100);
    osDelay(300);
  }
  /* USER CODE END I2C_Task */
}

/* USER CODE BEGIN Header_Buzzer_Task */
/**
* @brief Function implementing the Task_Buzzer thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_Buzzer_Task */
void Buzzer_Task(void *argument)
{
  /* USER CODE BEGIN Buzzer_Task */
	Buzzer_Init();
	uint32_t detect_start = 0;
	uint8_t  prev_status  = 0;

  for(;;)
  {
	switch(g_mode)
	{
	case MODE_MANUAL:
		/* ?��?�� 모드: 객체 감�? ?�� ?��?��?�� */
		if(g_target_status == 1)
			Buzzer_On();
		else
			Buzzer_Off();
		osDelay(50);
		break;

	case MODE_ZEROING:
		/* ?��?�� 모드: 무음 */
		Buzzer_Off();
		osDelay(100);
		break;

	case MODE_TRACK:
		if(g_target_status == 1)
		{
			/* 객체 감�? ?��?�� ?��?�� 기록 */
			if(prev_status == 0)
			{
				detect_start = osKernelGetTickCount();
				prev_status = 1;
				g_aim_locked = 0;
			}

			uint32_t elapsed = osKernelGetTickCount() - detect_start;
			if(elapsed < 1000)
			{
				/* 처음 1�?: ?��?��?��?�� (경고, ?��?��?? 미발?��) */
				g_aim_locked = 0;
				Buzzer_Beep(100, 100);
			}
			else
			{
				/* 1�? ?��: ?��?��?�� + ?��?��?? 발사 */
				g_aim_locked = 1;
				Buzzer_On();
				osDelay(50);
			}
		}
		else
		{
			/* 객체 ?��?��: 무음 */
			prev_status = 0;
			g_aim_locked = 0;
			Buzzer_Off();
			osDelay(50);
		}
		break;
	}
  }
  /* USER CODE END Buzzer_Task */
}

/**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM1 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  /* USER CODE BEGIN Callback 0 */

  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM1) {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
