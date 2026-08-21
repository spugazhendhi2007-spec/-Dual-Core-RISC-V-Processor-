// ============================================================================
// File: tb_atomic_unit.sv
// Description: Self-Checking Testbench for AMO Arithmetic/Logic Unit
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_atomic_unit;

    logic [4:0]  amo_op;
    logic [31:0] mem_val;
    logic [31:0] reg_val;
    logic [31:0] result;

    int error_count = 0;

    rv_atomic_unit dut (
        .amo_op_i  (amo_op),
        .mem_val_i (mem_val),
        .reg_val_i (reg_val),
        .result_o  (result)
    );

    initial begin
        $display("=== Starting tb_atomic_unit (Self-Checking) ===");

        // Test 1: AMOADD (10 + 20 = 30)
        amo_op = 5'b00000; mem_val = 32'd10; reg_val = 32'd20; #10;
        if (result !== 32'd30) begin
            $display("[ERROR] AMOADD failed! Expected 30, Got %0d", result);
            error_count++;
        end

        // Test 2: AMOSWAP (return reg_val = 55)
        amo_op = 5'b00001; mem_val = 32'd10; reg_val = 32'd55; #10;
        if (result !== 32'd55) begin
            $display("[ERROR] AMOSWAP failed! Expected 55, Got %0d", result);
            error_count++;
        end

        // Test 3: AMOMIN Signed (-15 vs 10 -> -15)
        amo_op = 5'b10000; mem_val = -32'd15; reg_val = 32'd10; #10;
        if ($signed(result) !== -15) begin
            $display("[ERROR] AMOMIN failed! Expected -15, Got %0d", $signed(result));
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_atomic_unit PASSED: AMO operations verified! <<<");
        end else begin
            $display(">>> tb_atomic_unit FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
