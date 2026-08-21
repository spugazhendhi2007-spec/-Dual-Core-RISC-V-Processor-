// ============================================================================
// File: tb_post_process.sv
// Description: Self-Checking Testbench for Post-Processing (Bias + ReLU + Scale + Sat)
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/accelerator/ai_defines.svh"

module tb_post_process;

    logic        clk;
    logic        rst_n;
    logic        valid_in;
    logic signed [31:0] acc_in [7:0];
    logic signed [31:0] bias;
    logic [1:0]  act_mode;
    logic signed [15:0] scale_mult;
    logic [4:0]  scale_shift;
    logic signed [7:0]  data_out [7:0];
    logic        valid_out;

    int error_count = 0;

    ai_post_process #(
        .LANES (8)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_i       (valid_in),
        .acc_in_i      (acc_in),
        .bias_i        (bias),
        .act_mode_i    (act_mode),
        .scale_mult_i  (scale_mult),
        .scale_shift_i (scale_shift),
        .data_out_o    (data_out),
        .valid_o       (valid_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        bias = 32'sd10;
        act_mode = 2'b01; // ReLU
        scale_mult = 16'sd1;
        scale_shift = 5'd0;
        for (int i = 0; i < 8; i++) acc_in[i] = 32'sd0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_post_process (Self-Checking) ===");

        // Test 1: Positive input + Bias: Acc = 20, Bias = 10 -> 30 (ReLU)
        valid_in = 1;
        acc_in[0] = 32'sd20;
        // Test 2: Negative input clamped by ReLU: Acc = -30, Bias = 10 -> -20 -> ReLU gives 0
        acc_in[1] = -32'sd30;
        // Test 3: Large positive clamped by 8-bit saturation: Acc = 500 -> Clamped to 127
        acc_in[2] = 32'sd500;
        #10;
        valid_in = 0;

        #1;
        if (data_out[0] !== 8'sd30) begin
            $display("[ERROR] Lane 0 failed! Expected 30, Got %0d", data_out[0]);
            error_count++;
        end

        if (data_out[1] !== 8'sd0) begin
            $display("[ERROR] Lane 1 ReLU clamp failed! Expected 0, Got %0d", data_out[1]);
            error_count++;
        end

        if (data_out[2] !== 8'sd127) begin
            $display("[ERROR] Lane 2 Saturation failed! Expected 127, Got %0d", data_out[2]);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_post_process PASSED: Quantization pipeline verified! <<<");
        end else begin
            $display(">>> tb_post_process FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
