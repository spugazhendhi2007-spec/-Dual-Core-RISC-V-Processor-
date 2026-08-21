// ============================================================================
// File: tb_divider.sv
// Description: Self-Checking Testbench for 32-Cycle Iterative Divider
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_divider;

    logic        clk;
    logic        rst_n;
    logic        start;
    rv_md_op_e   op;
    logic [31:0] op_a;
    logic [31:0] op_b;
    logic [31:0] result;
    logic        busy;
    logic        done;

    int error_count = 0;

    rv_divider dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .start_i  (start),
        .op_i     (op),
        .op_a_i   (op_a),
        .op_b_i   (op_b),
        .result_o (result),
        .busy_o   (busy),
        .done_o   (done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        op = MD_DIV;
        op_a = 0;
        op_b = 0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_divider (Self-Checking) ===");

        // Test 1: 100 / 7 = 14
        start = 1; op = MD_DIV; op_a = 32'd100; op_b = 32'd7; #10;
        start = 0;
        @(posedge done);
        #1;
        if (result !== 32'd14) begin
            $display("[ERROR] DIV: Expected 14, Got %0d", result);
            error_count++;
        end

        // Test 2: 100 % 7 = 2
        start = 1; op = MD_REM; op_a = 32'd100; op_b = 32'd7; #10;
        start = 0;
        @(posedge done);
        #1;
        if (result !== 32'd2) begin
            $display("[ERROR] REM: Expected 2, Got %0d", result);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_divider PASSED: Iterative division verified! <<<");
        end else begin
            $display(">>> tb_divider FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
