/* ============================================================================
 * File: startup.S
 * Project: Dual-Core RISC-V with AI Accelerator
 * Description: Multicore Reset Initialization, Stack Setup & Core Dispatch
 * ============================================================================ */

    .section .text.init
    .global _start

_start:
    /* Read Hart ID from CSR mhartid */
    csrr a0, mhartid

    /* Core 0 Stack: 0x00008000, Core 1 Stack: 0x0000A000 */
    bnez a0, _core1_start

_core0_start:
    la sp, _stack_top_core0
    la t0, _trap_handler
    csrw mtvec, t0
    jal main_core0
    j _halt

_core1_start:
    la sp, _stack_top_core1
    la t0, _trap_handler
    csrw mtvec, t0
    jal main_core1
    j _halt

_trap_handler:
    mret

_halt:
    wfi
    j _halt
