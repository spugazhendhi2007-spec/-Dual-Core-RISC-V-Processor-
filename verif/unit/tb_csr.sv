// ============================================================================
// File: tb_csr.sv
// Description: Self-Checking Testbench for Machine-Mode CSR Unit
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_csr;

    logic        clk;
    logic        rst_n;
    logic        csr_we;
    logic [2:0]  csr_op;
    logic [11:0] csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;
    logic        trap_entry;
    logic [31:0] trap_cause;
    logic [31:0] trap_pc;
    logic [31:0] trap_val;
    logic        mret;
    logic [31:0] trap_target;
    logic [31:0] mepc;
    logic        mstatus_mie, mie_meie, mie_msie, mie_mtie;
    logic        irq_software, irq_timer, irq_external;

    int error_count = 0;

    rv_csr #(
        .HART_ID (32'd0)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_we_i       (csr_we),
        .csr_op_i       (csr_op),
        .csr_addr_i     (csr_addr),
        .csr_wdata_i    (csr_wdata),
        .csr_rdata_o    (csr_rdata),
        .trap_entry_i   (trap_entry),
        .trap_cause_i   (trap_cause),
        .trap_pc_i      (trap_pc),
        .trap_val_i     (trap_val),
        .mret_i         (mret),
        .trap_target_o  (trap_target),
        .mepc_o         (mepc),
        .mstatus_mie_o  (mstatus_mie),
        .mie_meie_o     (mie_meie),
        .mie_msie_o     (mie_msie),
        .mie_mtie_o     (mie_mtie),
        .irq_software_i (irq_software),
        .irq_timer_i    (irq_timer),
        .irq_external_i (irq_external)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        csr_we = 0;
        csr_op = CSR_RW;
        csr_addr = 12'd0;
        csr_wdata = 0;
        trap_entry = 0;
        trap_cause = 0;
        trap_pc = 0;
        trap_val = 0;
        mret = 0;
        irq_software = 0;
        irq_timer = 0;
        irq_external = 0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_csr (Self-Checking) ===");

        // Test 1: Write and Read MTVEC
        csr_we = 1; csr_op = CSR_RW; csr_addr = CSR_MTVEC; csr_wdata = 32'h0000_0100; #10;
        csr_we = 0; #10;
        if (csr_rdata !== 32'h0000_0100) begin
            $display("[ERROR] MTVEC write/read failed! Expected 0x100, Got 0x%08X", csr_rdata);
            error_count++;
        end

        // Test 2: Trap Entry
        trap_entry = 1; trap_cause = 32'd11; trap_pc = 32'h0000_2000; #10;
        trap_entry = 0; #10;
        if (mepc !== 32'h0000_2000) begin
            $display("[ERROR] MEPC trap update failed! Expected 0x2000, Got 0x%08X", mepc);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_csr PASSED: Machine-mode CSR verified! <<<");
        end else begin
            $display(">>> tb_csr FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
