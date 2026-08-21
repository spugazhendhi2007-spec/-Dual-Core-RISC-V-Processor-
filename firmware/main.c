/* ============================================================================
 * File: main.c
 * Project: Dual-Core RISC-V with AI Accelerator
 * Description: Bare-Metal Edge AI Inference Demo Entry Point
 * ============================================================================ */

#include <stdint.h>

extern void main_core0(void);
extern void main_core1(void);

int main(void) {
    // Shared library routines if invoked directly
    return 0;
}
