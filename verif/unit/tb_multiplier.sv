// ============================================================================
// File: tb_multiplier.sv
// Description: Self-Checking Testbench for 32x32 Hardware Multiplier
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_multiplier;

    logic        clk;
    logic        rst_n;
    logic        enable;
    rv_md_op_e   op;
    logic [31:0] op_a;
    logic [31:0] op_b;
    logic [31:0] result;
    logic        valid;

    int error_count = 0;

    rv_multiplier dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .enable_i (enable),
        .op_i     (op),
        .op_a_i   (op_a),
        .op_b_i   (op_b),
        .result_o (result),
        .valid_o  (valid)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        enable = 0;
        op = MD_MUL;
        op_a = 0;
        op_b = 0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_multiplier (Self-Checking) ===");

        // Test 1: 125 * 400 = 50000
        enable = 1; op = MD_MUL; op_a = 32'd125; op_b = 32'd400; #10;
        enable = 0;
        if (result !== 32'd50000 || !valid) begin
            $display("[ERROR] MUL: Expected 50000, Got %0d", result);
            error_count++;
        end

        // Test 2: Signed negative product (-10) * 20 = -200
        enable = 1; op = MD_MUL; op_a = -32'd10; op_b = 32'd20; #10;
        enable = 0;
        if ($signed(result) !== -200) begin
            $display("[ERROR] MUL: Expected -200, Got %0d", $signed(result));
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_multiplier PASSED: Hardware multiplication verified! <<<");
        end else begin
            $display(">>> tb_multiplier FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
