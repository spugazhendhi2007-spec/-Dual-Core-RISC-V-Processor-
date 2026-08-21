// ============================================================================
// File: rv_atomic_unit.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: RV32A Atomic Memory Operation (AMO) Arithmetic / Logic Unit
// ============================================================================

`timescale 1ns / 1ps
`include "../core/rv_defines.svh"

module rv_atomic_unit (
    input  logic [4:0]  amo_op_i,
    input  logic [31:0] mem_val_i,
    input  logic [31:0] reg_val_i,
    output logic [31:0] result_o
);

    localparam logic [4:0] AMO_OP_SWAP  = 5'b00001;
    localparam logic [4:0] AMO_OP_ADD   = 5'b00000;
    localparam logic [4:0] AMO_OP_XOR   = 5'b00100;
    localparam logic [4:0] AMO_OP_AND   = 5'b01100;
    localparam logic [4:0] AMO_OP_OR    = 5'b01000;
    localparam logic [4:0] AMO_OP_MIN   = 5'b10000;
    localparam logic [4:0] AMO_OP_MAX   = 5'b10100;
    localparam logic [4:0] AMO_OP_MINU  = 5'b11000;
    localparam logic [4:0] AMO_OP_MAXU  = 5'b11100;

    always_comb begin
        case (amo_op_i)
            AMO_OP_SWAP: result_o = reg_val_i;
            AMO_OP_ADD:  result_o = mem_val_i + reg_val_i;
            AMO_OP_XOR:  result_o = mem_val_i ^ reg_val_i;
            AMO_OP_AND:  result_o = mem_val_i & reg_val_i;
            AMO_OP_OR:   result_o = mem_val_i | reg_val_i;
            AMO_OP_MIN:  result_o = ($signed(mem_val_i) < $signed(reg_val_i)) ? mem_val_i : reg_val_i;
            AMO_OP_MAX:  result_o = ($signed(mem_val_i) > $signed(reg_val_i)) ? mem_val_i : reg_val_i;
            AMO_OP_MINU: result_o = (mem_val_i < reg_val_i) ? mem_val_i : reg_val_i;
            AMO_OP_MAXU: result_o = (mem_val_i > reg_val_i) ? mem_val_i : reg_val_i;
            default:     result_o = reg_val_i;
        endcase
    end

endmodule
