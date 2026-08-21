// ============================================================================
// File: rv_multiplier.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Pipelined 32x32 Hardware Multiplier (MUL, MULH, MULHSU, MULHU)
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_multiplier (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_i,
    input  rv_md_op_e   op_i,
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,

    output logic [31:0] result_o,
    output logic        valid_o
);

    logic signed [32:0] a_ext, b_ext;
    logic signed [65:0] prod_q;
    rv_md_op_e          op_q;
    logic               valid_q;

    // Operand Sign Extension
    always_comb begin
        case (op_i)
            MD_MUL, MD_MULH: begin
                a_ext = {op_a_i[31], op_a_i};
                b_ext = {op_b_i[31], op_b_i};
            end
            MD_MULHSU: begin
                a_ext = {op_a_i[31], op_a_i};
                b_ext = {1'b0, op_b_i};
            end
            MD_MULHU: begin
                a_ext = {1'b0, op_a_i};
                b_ext = {1'b0, op_b_i};
            end
            default: begin
                a_ext = {op_a_i[31], op_a_i};
                b_ext = {op_b_i[31], op_b_i};
            end
        endcase
    end

    // Pipeline Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod_q  <= 66'sd0;
            op_q    <= MD_MUL;
            valid_q <= 1'b0;
        end else begin
            prod_q  <= a_ext * b_ext;
            op_q    <= op_i;
            valid_q <= enable_i;
        end
    end

    always_comb begin
        case (op_q)
            MD_MUL:  result_o = prod_q[31:0];
            default: result_o = prod_q[63:32]; // MULH, MULHSU, MULHU
        endcase
    end

    assign valid_o = valid_q;

endmodule
