/* ============================================================================
 * File: linker.ld
 * Project: Dual-Core RISC-V with AI Accelerator
 * Description: Linker Script for 64 KB SRAM Address Space
 * ============================================================================ */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    .text.init : {
        *(.text.init)
    } > RAM

    .text : {
        *(.text*)
        *(.rodata*)
    } > RAM

    .data : {
        *(.data*)
        *(.sdata*)
    } > RAM

    .bss : {
        *(.bss*)
        *(.sbss*)
        *(COMMON)
    } > RAM

    _stack_top_core0 = 0x00008000;
    _stack_top_core1 = 0x0000A000;
}
