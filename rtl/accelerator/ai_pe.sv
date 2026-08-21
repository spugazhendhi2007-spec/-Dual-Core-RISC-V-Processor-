// ============================================================================
// File: ai_pe.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Processing Element (PE) with INT8 Multiply & INT32 Accumulation
// ============================================================================

`timescale 1ns / 1ps

module ai_pe (
    input  logic        clk,
    input  logic        rst_n,

    // Weight Stationary Loading
    input  logic        load_weight_i,
    input  logic signed [7:0]  weight_in_i,
    output logic signed [7:0]  weight_out_o,

    // Activation Flow (Horizontal)
    input  logic signed [7:0]  act_in_i,
    output logic signed [7:0]  act_out_o,

    // Partial Sum Accumulation Flow (Vertical)
    input  logic signed [31:0] acc_in_i,
    output logic signed [31:0] acc_out_o,

    // Control Signals
    input  logic        enable_i,
    input  logic        clear_acc_i
);

    logic signed [7:0]  weight_q;
    logic signed [7:0]  act_q;
    logic signed [31:0] acc_q;

    // Weight Register (Weight Stationary)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_q <= 8'sd0;
        end else if (load_weight_i) begin
            weight_q <= weight_in_i;
        end
    end

    // Activation & Partial Sum Pipelining
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_q <= 8'sd0;
            acc_q <= 32'sd0;
        end else if (clear_acc_i) begin
            act_q <= 8'sd0;
            acc_q <= 32'sd0;
        end else if (enable_i) begin
            act_q <= act_in_i;
            acc_q <= acc_in_i + (act_in_i * weight_q);
        end
    end

    assign weight_out_o = weight_q;
    assign act_out_o    = act_q;
    assign acc_out_o    = acc_q;

endmodule
