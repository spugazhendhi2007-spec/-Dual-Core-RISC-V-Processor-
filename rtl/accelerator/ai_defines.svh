// ============================================================================
// File: ai_defines.svh
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Global Constants & Register Addresses for 8x8 INT8 AI Accelerator
// ============================================================================

`ifndef AI_DEFINES_SVH
`define AI_DEFINES_SVH

// AXI4-Lite Control Registers (Offset from 0x1000_0000)
localparam logic [7:0] AI_REG_CTRL       = 8'h00;
localparam logic [7:0] AI_REG_STATUS     = 8'h04;
localparam logic [7:0] AI_REG_DIM_M      = 8'h08;
localparam logic [7:0] AI_REG_DIM_K      = 8'h0C;
localparam logic [7:0] AI_REG_DIM_N      = 8'h10;
localparam logic [7:0] AI_REG_ADDR_W     = 8'h14;
localparam logic [7:0] AI_REG_ADDR_ACT   = 8'h18;
localparam logic [7:0] AI_REG_ADDR_OUT   = 8'h1C;
localparam logic [7:0] AI_REG_BIAS       = 8'h20;
localparam logic [7:0] AI_REG_SCALE_MULT = 8'h24;
localparam logic [7:0] AI_REG_SCALE_SHFT = 8'h28;
localparam logic [7:0] AI_REG_ACT_MODE   = 8'h2C;

localparam int AI_ARRAY_ROWS = 8;
localparam int AI_ARRAY_COLS = 8;
localparam int AI_TOTAL_PES  = 64;

`endif
