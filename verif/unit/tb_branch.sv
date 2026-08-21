// ============================================================================
// File: tb_branch.sv
// Description: Self-Checking Testbench for Branch Resolution & Target Calculator
// ============================================================================

`timescale 1ns / 1ps

module tb_branch;

    logic [2:0]  branch_type;
    logic        is_branch;
    logic        is_jal;
    logic        is_jalr;
    logic [31:0] op_a;
    logic [31:0] op_b;
    logic [31:0] pc;
    logic [31:0] imm;
    logic        branch_taken;
    logic [31:0] branch_target;

    int error_count = 0;

    rv_branch dut (
        .branch_type_i   (branch_type),
        .is_branch_i     (is_branch),
        .is_jal_i        (is_jal),
        .is_jalr_i       (is_jalr),
        .op_a_i          (op_a),
        .op_b_i          (op_b),
        .pc_i            (pc),
        .imm_i           (imm),
        .branch_taken_o  (branch_taken),
        .branch_target_o (branch_target)
    );

    initial begin
        $display("=== Starting tb_branch (Self-Checking) ===");

        // Test 1: BEQ Taken
        is_branch = 1; is_jal = 0; is_jalr = 0; branch_type = 3'b000;
        op_a = 32'd50; op_b = 32'd50; pc = 32'h0000_1000; imm = 32'd16; #10;
        if (!branch_taken || branch_target !== 32'h0000_1010) begin
            $display("[ERROR] BEQ taken failed!");
            error_count++;
        end

        // Test 2: BNE Not Taken
        branch_type = 3'b001; op_a = 32'd50; op_b = 32'd50; #10;
        if (branch_taken) begin
            $display("[ERROR] BNE not taken failed!");
            error_count++;
        end

        // Test 3: JALR target alignment check
        is_branch = 0; is_jalr = 1; op_a = 32'h0000_2001; imm = 32'd4; #10;
        if (!branch_taken || branch_target !== 32'h0000_2004) begin
            $display("[ERROR] JALR alignment failed!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_branch PASSED: Branch evaluation verified! <<<");
        end else begin
            $display(">>> tb_branch FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
