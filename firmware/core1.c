/* ============================================================================
 * File: core1.c
 * Project: Dual-Core RISC-V with AI Accelerator
 * Description: Slave Core 1 Execution Loop (Post-Processing & GPIO Signaling)
 * ============================================================================ */

#include <stdint.h>

#define GPIO_BASE   0x40000000UL
#define GPIO_DIR    (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_OUT    (*(volatile uint32_t *)(GPIO_BASE + 0x04))

void main_core1(void) {
    GPIO_DIR = 0xFFFF; // Configure all GPIOs as outputs
    GPIO_OUT = 0xAA55; // Initial pattern

    while (1) {
        // Wait for interrupt from Core 0
        __asm__ volatile ("wfi");
        GPIO_OUT = ~GPIO_OUT; // Toggle GPIO on completion
    }
}
