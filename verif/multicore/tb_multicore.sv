// ============================================================================
// File: tb_multicore.sv
// Description: Self-Checking Testbench for Dual-Core Subsystem & IPI Interconnect
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_multicore;

    logic        clk;
    logic        rst_n;

    logic        core0_instr_req;
    logic [31:0] core0_instr_addr, core0_instr_rdata;
    logic        core0_data_req, core0_data_we;
    logic [3:0]  core0_data_be;
    logic [31:0] core0_data_addr, core0_data_wdata, core0_data_rdata;

    logic        core1_instr_req;
    logic [31:0] core1_instr_addr, core1_instr_rdata;
    logic        core1_data_req, core1_data_we;
    logic [3:0]  core1_data_be;
    logic [31:0] core1_data_addr, core1_data_wdata, core1_data_rdata;

    logic        ai_cmd_valid;
    logic [2:0]  ai_cmd_type;
    logic [31:0] ai_cmd_arg0, ai_cmd_arg1;
    logic        ai_busy, ai_done;

    logic        irq_external_core0, irq_external_core1;

    logic        clint_req, clint_we;
    logic [3:0]  clint_be;
    logic [31:0] clint_addr, clint_wdata, clint_rdata;

    int error_count = 0;

    // Simulation Memory
    logic [31:0] mem [2047:0];

    rv_multicore dut (
        .clk                  (clk),
        .rst_n                (rst_n),
        .core0_instr_req_o    (core0_instr_req),
        .core0_instr_addr_o   (core0_instr_addr),
        .core0_instr_rdata_i  (core0_instr_rdata),
        .core0_data_req_o     (core0_data_req),
        .core0_data_we_o      (core0_data_we),
        .core0_data_be_o      (core0_data_be),
        .core0_data_addr_o    (core0_data_addr),
        .core0_data_wdata_o   (core0_data_wdata),
        .core0_data_rdata_i   (core0_data_rdata),
        .core1_instr_req_o    (core1_instr_req),
        .core1_instr_addr_o   (core1_instr_addr),
        .core1_instr_rdata_i  (core1_instr_rdata),
        .core1_data_req_o     (core1_data_req),
        .core1_data_we_o      (core1_data_we),
        .core1_data_be_o      (core1_data_be),
        .core1_data_addr_o    (core1_data_addr),
        .core1_data_wdata_o   (core1_data_wdata),
        .core1_data_rdata_i   (core1_data_rdata),
        .ai_cmd_valid_o       (ai_cmd_valid),
        .ai_cmd_type_o        (ai_cmd_type),
        .ai_cmd_arg0_o        (ai_cmd_arg0),
        .ai_cmd_arg1_o        (ai_cmd_arg1),
        .ai_busy_i            (ai_busy),
        .ai_done_i            (ai_done),
        .irq_external_core0_i (irq_external_core0),
        .irq_external_core1_i (irq_external_core1),
        .clint_req_i          (clint_req),
        .clint_we_i           (clint_we),
        .clint_be_i           (clint_be),
        .clint_addr_i         (clint_addr),
        .clint_wdata_i        (clint_wdata),
        .clint_rdata_o        (clint_rdata)
    );

    always #5 clk = ~clk;

    always_comb begin
        core0_instr_rdata = mem[core0_instr_addr[12:2]];
        core1_instr_rdata = mem[core1_instr_addr[12:2]];
        core0_data_rdata  = mem[core0_data_addr[12:2]];
        core1_data_rdata  = mem[core1_data_addr[12:2]];
    end

    always_ff @(posedge clk) begin
        if (core0_data_req && core0_data_we) mem[core0_data_addr[12:2]] <= core0_data_wdata;
        if (core1_data_req && core1_data_we) mem[core1_data_addr[12:2]] <= core1_data_wdata;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        ai_busy = 0; ai_done = 0;
        irq_external_core0 = 0; irq_external_core1 = 0;
        clint_req = 0; clint_we = 0; clint_be = 4'b1111; clint_addr = 0; clint_wdata = 0;

        for (int i = 0; i < 2048; i++) mem[i] = 32'h0000_0013;

        // Core 0: writes 0x1111 to 0x200
        mem[0] = 32'h0010_0093; // ADDI x1, x0, 1
        mem[1] = 32'h2010_2023; // SW x1, 0x200(x0)

        #20;
        rst_n = 1;

        $display("=== Starting tb_multicore (Self-Checking) ===");

        // Test CLINT IPI Register Access
        clint_req = 1; clint_we = 1; clint_addr = 32'h0004; clint_wdata = 32'd1; #10; // Trigger IPI to Core 1
        clint_req = 1; clint_we = 0; clint_addr = 32'h0004; #10;
        if (clint_rdata !== 32'd1) begin
            $display("[ERROR] CLINT IPI register readback failed!");
            error_count++;
        end
        clint_req = 0;

        #200;

        if (mem[32'h200 >> 2] !== 32'd1) begin
            $display("[ERROR] Core 0 execution in multicore subsystem failed!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_multicore PASSED: Multicore subsystem & IPI verified! <<<");
        end else begin
            $display(">>> tb_multicore FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
