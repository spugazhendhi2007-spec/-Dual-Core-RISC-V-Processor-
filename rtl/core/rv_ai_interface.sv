// ============================================================================
// File: rv_ai_interface.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Custom RISC-V Instruction Coprocessor Interface (AI_CFG, AI_START, AI_WAIT)
// ============================================================================

`timescale 1ns / 1ps

module rv_ai_interface (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction Decode Signals
    input  logic        is_custom_ai_i,
    input  logic [2:0]  ai_funct3_i,
    input  logic [31:0] rs1_data_i,
    input  logic [31:0] rs2_data_i,

    // Interface to AI Accelerator Controller
    output logic        ai_cmd_valid_o,
    output logic [2:0]  ai_cmd_type_o,
    output logic [31:0] ai_cmd_arg0_o,
    output logic [31:0] ai_cmd_arg1_o,
    input  logic        ai_busy_i,
    input  logic        ai_done_i,

    // Core Pipeline Stall Request (for AI_WAIT)
    output logic        core_stall_req_o
);

    localparam logic [2:0] AI_CMD_CFG   = 3'b000;
    localparam logic [2:0] AI_CMD_START = 3'b001;
    localparam logic [2:0] AI_CMD_WAIT  = 3'b010;

    assign ai_cmd_valid_o   = is_custom_ai_i;
    assign ai_cmd_type_o    = ai_funct3_i;
    assign ai_cmd_arg0_o    = rs1_data_i;
    assign ai_cmd_arg1_o    = rs2_data_i;

    // AI_WAIT instruction stalls until AI accelerator finishes
    assign core_stall_req_o = is_custom_ai_i && (ai_funct3_i == AI_CMD_WAIT) && ai_busy_i;

endmodule
