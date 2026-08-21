// ============================================================================
// File: tb_pe.sv
// Description: Self-Checking Testbench for AI Processing Element (INT8 MAC)
// ============================================================================

`timescale 1ns / 1ps

module tb_pe;

    logic        clk;
    logic        rst_n;
    logic        load_weight;
    logic signed [7:0]  weight_in;
    logic signed [7:0]  weight_out;
    logic signed [7:0]  act_in;
    logic signed [7:0]  act_out;
    logic signed [31:0] acc_in;
    logic signed [31:0] acc_out;
    logic        enable;
    logic        clear_acc;

    int error_count = 0;

    ai_pe dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .load_weight_i (load_weight),
        .weight_in_i   (weight_in),
        .weight_out_o  (weight_out),
        .act_in_i      (act_in),
        .act_out_o     (act_out),
        .acc_in_i      (acc_in),
        .acc_out_o     (acc_out),
        .enable_i      (enable),
        .clear_acc_i   (clear_acc)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        load_weight = 0;
        weight_in = 8'sd0;
        act_in = 8'sd0;
        acc_in = 32'sd0;
        enable = 0;
        clear_acc = 0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_pe (Self-Checking) ===");

        // 1. Load Weight W = 4
        load_weight = 1; weight_in = 8'sd4; #10;
        load_weight = 0;

        // 2. MAC Step 1: Act = 5, Acc_in = 10 -> Result = 10 + (5 * 4) = 30
        enable = 1; act_in = 8'sd5; acc_in = 32'sd10; #10;
        enable = 0;
        if (acc_out !== 32'sd30 || act_out !== 8'sd5) begin
            $display("[ERROR] PE MAC step 1 failed! Expected 30, Got %0d", acc_out);
            error_count++;
        end

        // 3. MAC Step 2 (Negative): Act = -3, Acc_in = 30 -> Result = 30 + (-3 * 4) = 18
        enable = 1; act_in = -8'sd3; acc_in = 32'sd30; #10;
        enable = 0;
        if (acc_out !== 32'sd18) begin
            $display("[ERROR] PE MAC step 2 failed! Expected 18, Got %0d", acc_out);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_pe PASSED: INT8 MAC PE verified! <<<");
        end else begin
            $display(">>> tb_pe FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
