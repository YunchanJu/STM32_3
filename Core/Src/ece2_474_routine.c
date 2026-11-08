/*
 * 초기화·폴링·인터럽트 실습 템플릿입니다. CubeMX 자동 생성 파일이 아닙니다.
 * 학생은 아래 함수의 '실습 코드 작성' 부분을 채웁니다.
 * 아래쪽 HAL 콜백은 자동 생성된 인터럽트 처리 코드와 실습 함수를 연결합니다.
 * 인터럽트에서는 처리할 일을 기록하고 빠르게 돌아옵니다.
 * 인터럽트 함수 안에서는 HAL_Delay, scanf, getchar, printf를 사용하지 않습니다.
 */
#include "ece2_474.h"
#include "main.h"
#include "stm32_3_config.h"

volatile uint32_t spi_transfer_count;
volatile uint32_t spi_error_count;
volatile uint8_t spi_last_byte;
static uint32_t spi_last_ms;
#if !STM32_SPI_SLAVE
static uint8_t spi_pattern_index;
#endif
/* 주변장치 변수의 extern 선언은 ece2_474.h에 있습니다. */

/* UART 인터럽트 수신 실습 때 필요한 버퍼의 주석을 해제합니다.
 * 파일 범위에 두면 수신 완료 함수에서도 같은 버퍼를 사용할 수 있습니다.
 */
// static uint8_t uart2_rx_ece2;
// static uint8_t uart3_rx_ece2;

/* 주변장치 초기화가 끝난 뒤, 메인 루프에 들어가기 전에 한 번 호출됩니다. */
void ece2_474_init(void)
{
    HAL_GPIO_WritePin(SPI_CS_ece2_GPIO_Port, SPI_CS_ece2_Pin, GPIO_PIN_SET);
    spi_last_ms = HAL_GetTick();
#if STM32_SPI_SLAVE
    if (HAL_SPI_DeInit(&hspi1) != HAL_OK) Error_Handler();
    hspi1.Init.Mode = SPI_MODE_SLAVE;
    hspi1.Init.NSS = SPI_NSS_HARD_INPUT;
    if (HAL_SPI_Init(&hspi1) != HAL_OK) Error_Handler();
    GPIO_InitTypeDef gpio = {0};
    gpio.Pin = GPIO_PIN_4;
    gpio.Mode = GPIO_MODE_AF_PP;
    gpio.Pull = GPIO_PULLUP;
    gpio.Speed = GPIO_SPEED_FREQ_LOW;
    gpio.Alternate = GPIO_AF5_SPI1;
    HAL_GPIO_Init(GPIOA, &gpio);
    printf("SPI1 slave RX: NSS=PA4, Mode0, 8-bit MSB, VCP=9600 8N1\r\n");
#else
    printf("SPI1 master TX: CS=PB6, Mode0, 781250Hz, VCP=9600 8N1\r\n");
#endif
}

/* 메인 루프에서 반복해서 호출됩니다. */
void polling_routine(void)
{
#if STM32_SPI_SLAVE
    uint8_t rx = 0U;
    HAL_StatusTypeDef result = HAL_SPI_Receive(&hspi1, &rx, 1U, 2000U);
    if (result == HAL_OK) {
        spi_last_byte = rx;
        ++spi_transfer_count;
        printf("RX=%02X\r\n", (unsigned int)rx);
    } else if (result == HAL_TIMEOUT) {
        printf("RX timeout: check sender, SCK, MOSI, CS and GND\r\n");
    } else {
        ++spi_error_count;
        printf("RX error=%d\r\n", (int)result);
    }
#else
    static const uint8_t patterns[4] = {0x55U, 0xA5U, 0x00U, 0xFFU};
    uint32_t now_ms = HAL_GetTick();
    if ((uint32_t)(now_ms - spi_last_ms) < 1000U) return;
    spi_last_ms = now_ms;
    uint8_t tx = patterns[spi_pattern_index];
    HAL_GPIO_WritePin(SPI_CS_ece2_GPIO_Port, SPI_CS_ece2_Pin, GPIO_PIN_RESET);
    HAL_StatusTypeDef result = HAL_SPI_Transmit(&hspi1, &tx, 1U, 100U);
    HAL_GPIO_WritePin(SPI_CS_ece2_GPIO_Port, SPI_CS_ece2_Pin, GPIO_PIN_SET);
    spi_last_byte = tx;
    if (result == HAL_OK) ++spi_transfer_count;
    else ++spi_error_count;
    printf("TX=%02X, result=%d\r\n", (unsigned int)tx, (int)result);
    spi_pattern_index = (uint8_t)((spi_pattern_index + 1U) & 3U);
#endif
}

/* 1. 사용자 버튼 PC13을 눌렀을 때 호출됩니다. 우선순위: 7.
 * 버튼의 접점 때문에 한 번 눌러도 여러 번 호출될 수 있습니다.
 */
static void button_isr_p7(void)
{
    /* 실습 코드 작성: 버튼 이벤트를 기록하거나 LED 상태를 변경합니다. */
}

/* 2. TIM6를 인터럽트 방식으로 시작하면 100 ms마다 호출됩니다. 우선순위: 4.
 * 시작 호출: HAL_TIM_Base_Start_IT(&htim6);
 */
static void tim6_isr_p4(void)
{
    /* 실습 코드 작성: 횟수를 세거나 메인 루프에서 처리할 표시를 남깁니다. */
}

/* 3. PC 통신 UART2의 요청한 수신이 완료되면 호출됩니다. 우선순위: 6.
 * 먼저 수신 버퍼를 준비하고 HAL_UART_Receive_IT로 수신을 요청해야 합니다.
 * 다음 입력도 받으려면 처리 후 수신을 다시 요청합니다.
 * 현재 표준 입력은 기다리는 방식입니다. 같은 UART의 인터럽트 수신과 함께 쓰지 않습니다.
 */
static void uart2_isr_p6(void)
{
    /* 실습 코드 작성: PC 수신 버퍼를 처리하고 다음 수신을 요청합니다. */
}

/* 4. FPGA 통신 UART3의 요청한 수신이 완료되면 호출됩니다. 우선순위: 5.
 * 먼저 수신 버퍼를 준비하고 HAL_UART_Receive_IT로 수신을 요청해야 합니다.
 * 다음 입력도 받으려면 처리 후 수신을 다시 요청합니다.
 */
static void uart3_isr_p5(void)
{
    /* 실습 코드 작성: FPGA 수신 버퍼를 처리하고 다음 수신을 요청합니다. */
}

/* PA0: 풀업 입력의 HIGH -> LOW 변화. 우선순위: 8. */
static void gpio_in_pullup_isr_p8_ece2(void)
{
    /* 실습 코드 작성 */
}

/* PA1: 풀다운 입력의 LOW -> HIGH 변화. 우선순위: 9. */
static void gpio_in_pulldown_isr_p9_ece2(void)
{
    /* 실습 코드 작성 */
}

/* 아래는 HAL 콜백과 실습 함수를 연결하는 코드입니다. */

/* CubeMX의 EXTI 처리 코드에서 버튼 실습 함수로 연결합니다. */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    if (GPIO_Pin == BUTTON_ece2_Pin)
    {
        button_isr_p7();
    }
    else if (GPIO_Pin == GPIO_IN_PULLUP_ece2_Pin)
    {
        gpio_in_pullup_isr_p8_ece2();
    }
    else if (GPIO_Pin == GPIO_IN_PULLDOWN_ece2_Pin)
    {
        gpio_in_pulldown_isr_p9_ece2();
    }
}

/* CubeMX의 타이머 처리 코드에서 TIM6 실습 함수로 연결합니다. */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if (htim->Instance == TIM6)
    {
        tim6_isr_p4();
    }
}

/* UART 수신 완료 시 PC 통신과 FPGA 통신을 구분합니다. */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART2)
    {
        uart2_isr_p6();
    }
    else if (huart->Instance == USART3)
    {
        uart3_isr_p5();
    }
}
