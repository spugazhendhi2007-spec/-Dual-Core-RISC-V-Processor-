/* ============================================================================
 * File: ai_driver.c
 * Project: Dual-Core RISC-V with AI Accelerator
 * Description: AI Accelerator Hardware Driver & Custom Instruction Interface
 * ============================================================================ */

#include <stdint.h>

#define AI_BASE          0x10000000UL
#define AI_REG_CTRL      (*(volatile uint32_t *)(AI_BASE + 0x00))
#define AI_REG_STATUS    (*(volatile uint32_t *)(AI_BASE + 0x04))
#define AI_REG_ADDR_W    (*(volatile uint32_t *)(AI_BASE + 0x14))
#define AI_REG_ADDR_ACT  (*(volatile uint32_t *)(AI_BASE + 0x18))
#define AI_REG_ADDR_OUT  (*(volatile uint32_t *)(AI_BASE + 0x1C))
#define AI_REG_BIAS      (*(volatile uint32_t *)(AI_BASE + 0x20))
#define AI_REG_SCALE     (*(volatile uint32_t *)(AI_BASE + 0x24))

void ai_accel_run_mmio(uint32_t weight_addr, uint32_t act_addr, uint32_t out_addr, int32_t bias, uint32_t scale) {
    AI_REG_ADDR_W   = weight_addr;
    AI_REG_ADDR_ACT = act_addr;
    AI_REG_ADDR_OUT = out_addr;
    AI_REG_BIAS     = bias;
    AI_REG_SCALE    = scale;
    AI_REG_CTRL     = 0x1; // Start execution

    // Wait until done
    while (AI_REG_STATUS & 0x1);
}

void ai_accel_custom_cfg(uint32_t weight_addr, uint32_t act_addr) {
    __asm__ volatile (
        ".insn r 0x0B, 0x0, 0x0, x0, %0, %1"
        :
        : "r"(weight_addr), "r"(act_addr)
    );
}

void ai_accel_custom_start(void) {
    __asm__ volatile (
        ".insn r 0x0B, 0x1, 0x0, x0, x0, x0"
    );
}

void ai_accel_custom_wait(void) {
    __asm__ volatile (
        ".insn r 0x0B, 0x2, 0x0, x0, x0, x0"
    );
}
