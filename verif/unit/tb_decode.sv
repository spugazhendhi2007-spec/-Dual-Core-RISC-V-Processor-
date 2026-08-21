// ============================================================================
// File: tb_decode.sv
// Description: Self-Checking Testbench for Instruction Decoder (RV32IMA + Custom AI)
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_decode;

    logic [31:0] instr;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] imm;
    rv_alu_op_e  alu_op;
    logic        alu_src_a_sel, alu_src_b_sel;
    logic        mem_read, mem_write;
    logic [1:0]  mem_size;
    logic        mem_unsigned, reg_write;
    logic        is_branch, is_jal, is_jalr;
    logic [2:0]  branch_type;
    logic        is_mul_div;
    rv_md_op_e   md_op;
    logic        is_atomic;
    logic [4:0]  amo_funct5;
    logic        is_csr;
    logic [2:0]  csr_op;
    logic [11:0] csr_addr;
    logic        is_ecall, is_ebreak, is_mret, is_wfi, is_illegal;

    int error_count = 0;

    rv_decode dut (
        .instr_i         (instr),
        .rs1_addr_o      (rs1_addr),
        .rs2_addr_o      (rs2_addr),
        .rd_addr_o       (rd_addr),
        .imm_o           (imm),
        .alu_op_o        (alu_op),
        .alu_src_a_sel_o (alu_src_a_sel),
        .alu_src_b_sel_o (alu_src_b_sel),
        .mem_read_o      (mem_read),
        .mem_write_o     (mem_write),
        .mem_size_o      (mem_size),
        .mem_unsigned_o  (mem_unsigned),
        .reg_write_o     (reg_write),
        .is_branch_o     (is_branch),
        .is_jal_o        (is_jal),
        .is_jalr_o       (is_jalr),
        .branch_type_o   (branch_type),
        .is_mul_div_o    (is_mul_div),
        .md_op_o         (md_op),
        .is_atomic_o     (is_atomic),
        .amo_funct5_o    (amo_funct5),
        .is_csr_o        (is_csr),
        .csr_op_o        (csr_op),
        .csr_addr_o      (csr_addr),
        .is_ecall_o      (is_ecall),
        .is_ebreak_o     (is_ebreak),
        .is_mret_o       (is_mret),
        .is_wfi_o        (is_wfi),
        .is_illegal_o    (is_illegal)
    );

    initial begin
        $display("=== Starting tb_decode (Self-Checking) ===");

        // Test 1: ADDI x1, x2, 10 -> 0x00A10093
        instr = 32'h00A10093; #10;
        if (rd_addr !== 5'd1 || rs1_addr !== 5'd2 || imm !== 32'd10 || !reg_write || alu_op !== ALU_ADD) begin
            $display("[ERROR] ADDI decode failed!");
            error_count++;
        end

        // Test 2: MUL x3, x4, x5 -> 0x025201B3
        instr = 32'h025201B3; #10;
        if (!is_mul_div || md_op !== MD_MUL || rd_addr !== 5'd3) begin
            $display("[ERROR] MUL decode failed!");
            error_count++;
        end

        // Test 3: AMOADD.W x6, x7, (x8) -> 0x0074232F
        instr = 32'h0074232F; #10;
        if (!is_atomic || amo_funct5 !== 5'b00000 || rd_addr !== 5'd6) begin
            $display("[ERROR] AMOADD decode failed!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_decode PASSED: Instruction decoding verified! <<<");
        end else begin
            $display(">>> tb_decode FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
