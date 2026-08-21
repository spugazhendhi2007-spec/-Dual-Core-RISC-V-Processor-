// ============================================================================
// File: ai_systolic_array.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 8x8 Systolic Array Mesh (64 Processing Elements, INT8 MAC, INT32 Acc)
// ============================================================================

`timescale 1ns / 1ps

module ai_systolic_array #(
    parameter int ROWS = 8,
    parameter int COLS = 8
) (
    input  logic        clk,
    input  logic        rst_n,

    // Weight Loading Port (Top Edge)
    input  logic [COLS-1:0]        load_weight_i,
    input  logic signed [7:0]      weight_in_i [COLS-1:0],

    // Activation Input Port (Left Edge)
    input  logic signed [7:0]      act_in_i [ROWS-1:0],

    // Top Partial Sum Inputs (Top Edge)
    input  logic signed [31:0]     acc_in_i [COLS-1:0],

    // Execution Controls
    input  logic                   enable_i,
    input  logic                   clear_acc_i,

    // Bottom Partial Sum Outputs (Bottom Edge)
    output logic signed [31:0]     acc_out_o [COLS-1:0]
);

    // Internal Mesh Routing Matrix
    logic signed [7:0]  act_horiz    [ROWS-1:0][COLS:0];
    logic signed [31:0] acc_vert     [ROWS:0][COLS-1:0];
    logic signed [7:0]  weight_chain [ROWS:0][COLS-1:0];

    // Left Boundary Activation Connections
    genvar r, c;
    generate
        for (r = 0; r < ROWS; r++) begin : gen_left_acts
            assign act_horiz[r][0] = act_in_i[r];
        end
    endgenerate

    // Top Boundary Connections
    generate
        for (c = 0; c < COLS; c++) begin : gen_top_inputs
            assign acc_vert[0][c]     = acc_in_i[c];
            assign weight_chain[0][c] = weight_in_i[c];
        end
    endgenerate

    // 8x8 Grid of 64 Processing Elements
    generate
        for (r = 0; r < ROWS; r++) begin : gen_rows
            for (c = 0; c < COLS; c++) begin : gen_cols
                ai_pe u_pe (
                    .clk           (clk),
                    .rst_n         (rst_n),
                    .load_weight_i (load_weight_i[c]),
                    .weight_in_i   (weight_chain[r][c]),
                    .weight_out_o  (weight_chain[r+1][c]),
                    .act_in_i      (act_horiz[r][c]),
                    .acc_in_i      (acc_vert[r][c]),
                    .enable_i      (enable_i),
                    .clear_acc_i   (clear_acc_i),
                    .act_out_o     (act_horiz[r][c+1]),
                    .acc_out_o     (acc_vert[r+1][c])
                );
            end
        end
    endgenerate

    // Bottom Boundary Outputs
    generate
        for (c = 0; c < COLS; c++) begin : gen_bottom_outputs
            assign acc_out_o[c] = acc_vert[ROWS][c];
        end
    endgenerate

endmodule
