// ============================================================================
// File: ai_post_process.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Multi-Lane Tensor Post-Processor (Bias + ReLU + Scale + Round + Shift + Saturation)
// ============================================================================

`timescale 1ns / 1ps
`include "ai_defines.svh"

module ai_post_process #(
    parameter int LANES = 8
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic                   valid_i,
    input  logic signed [31:0]     acc_in_i [LANES-1:0],

    // Quantization Configuration
    input  logic signed [31:0]     bias_i,
    input  logic [1:0]             act_mode_i, // 0: None, 1: ReLU, 2: ReLU6
    input  logic signed [15:0]     scale_mult_i,
    input  logic [4:0]             scale_shift_i,

    output logic signed [7:0]      data_out_o [LANES-1:0],
    output logic                   valid_o
);

    genvar lane;
    generate
        for (lane = 0; lane < LANES; lane++) begin : gen_lane_proc
            logic signed [31:0] biased;
            logic signed [31:0] activated;
            logic signed [47:0] multiplied;
            logic signed [31:0] rounded;
            logic signed [7:0]  saturated;

            // 1. Bias Addition
            assign biased = acc_in_i[lane] + bias_i;

            // 2. Activation (ReLU / ReLU6 / None)
            always_comb begin
                case (act_mode_i)
                    2'b01: activated = (biased < 32'sd0) ? 32'sd0 : biased; // ReLU
                    2'b10: begin // ReLU6
                        logic signed [31:0] max_val;
                        max_val = 32'sd6 << scale_shift_i;
                        if (biased < 32'sd0) activated = 32'sd0;
                        else if (biased > max_val) activated = max_val;
                        else activated = biased;
                    end
                    default: activated = biased; // None
                endcase
            end

            // 3. Scale & Rounding
            assign multiplied = activated * scale_mult_i;
            assign rounded    = (scale_shift_i > 0) ? (multiplied + (48'sd1 << (scale_shift_i - 1))) >>> scale_shift_i : multiplied[31:0];

            // 4. Signed 8-bit Saturation Clamping [-128, +127]
            always_comb begin
                if (rounded > 32'sd127) begin
                    saturated = 8'sd127;
                end else if (rounded < -32'sd128) begin
                    saturated = -8'sd128;
                end else begin
                    saturated = rounded[7:0];
                end
            end

            // Pipelined Stage Output
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    data_out_o[lane] <= 8'sd0;
                end else begin
                    data_out_o[lane] <= saturated;
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
        end else begin
            valid_o <= valid_i;
        end
    end

endmodule
