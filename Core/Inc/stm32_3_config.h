#ifndef STM32_3_CONFIG_H
#define STM32_3_CONFIG_H
#ifndef STM32_SPI_SLAVE
#define STM32_SPI_SLAVE 0
#endif
#if STM32_SPI_SLAVE != 0 && STM32_SPI_SLAVE != 1
#error "STM32_SPI_SLAVE must be 0 (master) or 1 (slave)"
#endif
#endif
