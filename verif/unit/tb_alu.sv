// ============================================================================
// File: tb_alu.sv
// Description: Self-Checking Testbench for 32-bit ALU
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_alu;

    logic [31:0] op_a;
    logic [31:0] op_b;
    rv_alu_op_e  alu_op;
    logic [31:0] result;
    logic        zero;
    logic        less_than;
    logic        less_than_u;

    int error_count = 0;

    rv_alu dut (
        .op_a_i        (op_a),
        .op_b_i        (op_b),
        .alu_op_i      (alu_op),
        .result_o      (result),
        .zero_o        (zero),
        .less_than_o   (less_than),
        .less_than_u_o (less_than_u)
    );

    initial begin
        $display("=== Starting tb_alu (Self-Checking) ===");

        // Test 1: ADD
        op_a = 32'd15; op_b = 32'd25; alu_op = ALU_ADD; #10;
        if (result !== 32'd40) begin
            $display("[ERROR] ADD: Expected 40, Got %0d", result);
            error_count++;
        end

        // Test 2: SUB
        op_a = 32'd100; op_b = 32'd35; alu_op = ALU_SUB; #10;
        if (result !== 32'd65) begin
            $display("[ERROR] SUB: Expected 65, Got %0d", result);
            error_count++;
        end

        // Test 3: SLL
        op_a = 32'h0000_0001; op_b = 32'd4; alu_op = ALU_SLL; #10;
        if (result !== 32'h0000_0010) begin
            $display("[ERROR] SLL: Expected 0x10, Got 0x%08X", result);
            error_count++;
        end

        // Test 4: SLT Signed
        op_a = -32'd10; op_b = 32'd5; alu_op = ALU_SLT; #10;
        if (result !== 32'd1 || !less_than) begin
            $display("[ERROR] SLT: Expected 1, Got %0d", result);
            error_count++;
        end

        // Test 5: SLTU Unsigned
        op_a = 32'hFFFF_FFFF; op_b = 32'd5; alu_op = ALU_SLTU; #10;
        if (result !== 32'd0 || less_than_u) begin
            $display("[ERROR] SLTU: Expected 0, Got %0d", result);
            error_count++;
        end

        // Test 6: XOR, OR, AND
        op_a = 32'hAA55_AA55; op_b = 32'hFF00_FF00; alu_op = ALU_XOR; #10;
        if (result !== (32'hAA55_AA55 ^ 32'hFF00_FF00)) error_count++;

        alu_op = ALU_OR; #10;
        if (result !== (32'hAA55_AA55 | 32'hFF00_FF00)) error_count++;

        alu_op = ALU_AND; #10;
        if (result !== (32'hAA55_AA55 & 32'hFF00_FF00)) error_count++;

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_alu PASSED: All ALU operations verified successfully! <<<");
        end else begin
            $display(">>> tb_alu FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
