/* ============================================================================
 * File: core0.c
 * Project: Dual-Core RISC-V with AI Accelerator
 * Description: Master Core 0 Execution Loop (AI Scheduling & IPI Synchronization)
 * ============================================================================ */

#include <stdint.h>

#define CLINT_BASE    0x20000000UL
#define CLINT_MSIP1   (*(volatile uint32_t *)(CLINT_BASE + 0x04))

extern void ai_accel_run_mmio(uint32_t w, uint32_t a, uint32_t o, int32_t b, uint32_t s);

void main_core0(void) {
    uint32_t w_addr   = 0x00001000;
    uint32_t act_addr = 0x00001100;
    uint32_t out_addr = 0x00001200;

    // Launch AI Acceleration task
    ai_accel_run_mmio(w_addr, act_addr, out_addr, 0, 1);

    // Notify Core 1 via Inter-Processor Interrupt (IPI)
    CLINT_MSIP1 = 1;

    while (1) {
        __asm__ volatile ("wfi");
    }
}
