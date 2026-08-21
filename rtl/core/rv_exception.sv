// ============================================================================
// File: rv_exception.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Exception Detection, Prioritization & Trap Generation Unit
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_exception (
    input  logic        valid_i,
    input  logic        is_ecall_i,
    input  logic        is_ebreak_i,
    input  logic        is_illegal_i,
    input  logic        irq_external_i,
    input  logic        irq_software_i,
    input  logic        irq_timer_i,
    input  logic        mstatus_mie_i,
    input  logic        mie_meie_i,
    input  logic        mie_msie_i,
    input  logic        mie_mtie_i,

    output logic        trap_taken_o,
    output logic [31:0] trap_cause_o
);

    always_comb begin
        trap_taken_o = 1'b0;
        trap_cause_o = 32'd0;

        // Asynchronous Interrupts
        if (mstatus_mie_i) begin
            if (irq_external_i && mie_meie_i) begin
                trap_taken_o = 1'b1;
                trap_cause_o = TRAP_IRQ_EXT;
            end else if (irq_software_i && mie_msie_i) begin
                trap_taken_o = 1'b1;
                trap_cause_o = TRAP_IRQ_SFT;
            end else if (irq_timer_i && mie_mtie_i) begin
                trap_taken_o = 1'b1;
                trap_cause_o = TRAP_IRQ_TMR;
            end
        end

        // Synchronous Exceptions
        if (!trap_taken_o && valid_i) begin
            if (is_illegal_i) begin
                trap_taken_o = 1'b1;
                trap_cause_o = TRAP_ILLEGAL;
            end else if (is_ecall_i) begin
                trap_taken_o = 1'b1;
                trap_cause_o = TRAP_ECALL_M;
            end else if (is_ebreak_i) begin
                trap_taken_o = 1'b1;
                trap_cause_o = 32'd3;
            end
        end
    end

endmodule
