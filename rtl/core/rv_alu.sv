// ============================================================================
// File: rv_alu.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Single-Cycle 32-bit Arithmetic Logic Unit
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_alu (
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,
    input  rv_alu_op_e  alu_op_i,

    output logic [31:0] result_o,
    output logic        zero_o,
    output logic        less_than_o,
    output logic        less_than_u_o
);

    logic [31:0] shift_val;

    always_comb begin
        case (alu_op_i)
            ALU_ADD:  result_o = op_a_i + op_b_i;
            ALU_SUB:  result_o = op_a_i - op_b_i;
            ALU_SLL:  result_o = op_a_i << op_b_i[4:0];
            ALU_SLT:  result_o = ($signed(op_a_i) < $signed(op_b_i)) ? 32'd1 : 32'd0;
            ALU_SLTU: result_o = (op_a_i < op_b_i) ? 32'd1 : 32'd0;
            ALU_XOR:  result_o = op_a_i ^ op_b_i;
            ALU_SRL:  result_o = op_a_i >> op_b_i[4:0];
            ALU_SRA:  result_o = $signed(op_a_i) >>> op_b_i[4:0];
            ALU_OR:   result_o = op_a_i | op_b_i;
            ALU_AND:  result_o = op_a_i & op_b_i;
            default:  result_o = 32'd0;
        endcase
    end

    assign zero_o        = (result_o == 32'd0);
    assign less_than_o   = ($signed(op_a_i) < $signed(op_b_i));
    assign less_than_u_o = (op_a_i < op_b_i);

endmodule
