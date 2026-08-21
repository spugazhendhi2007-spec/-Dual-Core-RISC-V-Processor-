// ============================================================================
// File: rv_pipeline_regs.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Pipeline Inter-Stage Registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_reg_if_id (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall_i,
    input  logic        flush_i,

    input  logic [31:0] if_pc_i,
    input  logic [31:0] if_pc_plus4_i,
    input  logic [31:0] if_instr_i,

    output logic [31:0] id_pc_o,
    output logic [31:0] id_pc_plus4_o,
    output logic [31:0] id_instr_o,
    output logic        id_valid_o
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_pc_o       <= 32'd0;
            id_pc_plus4_o <= 32'd0;
            id_instr_o    <= 32'h0000_0013; // NOP
            id_valid_o    <= 1'b0;
        end else if (flush_i) begin
            id_pc_o       <= 32'd0;
            id_pc_plus4_o <= 32'd0;
            id_instr_o    <= 32'h0000_0013;
            id_valid_o    <= 1'b0;
        end else if (!stall_i) begin
            id_pc_o       <= if_pc_i;
            id_pc_plus4_o <= if_pc_plus4_i;
            id_instr_o    <= if_instr_i;
            id_valid_o    <= 1'b1;
        end
    end

endmodule
