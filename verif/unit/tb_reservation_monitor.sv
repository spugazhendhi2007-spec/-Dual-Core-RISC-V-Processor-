// ============================================================================
// File: tb_reservation_monitor.sv
// Description: Self-Checking Testbench for Multicore LR/SC Reservation Monitor
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_reservation_monitor;

    logic        clk;
    logic        rst_n;

    logic        c0_req, c0_we, c0_atomic_req, c0_sc_success;
    logic [31:0] c0_addr;
    logic [4:0]  c0_atomic_op;

    logic        c1_req, c1_we, c1_atomic_req, c1_sc_success;
    logic [31:0] c1_addr;
    logic [4:0]  c1_atomic_op;

    int error_count = 0;

    rv_reservation_monitor dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .c0_req_i        (c0_req),
        .c0_we_i         (c0_we),
        .c0_addr_i       (c0_addr),
        .c0_atomic_req_i (c0_atomic_req),
        .c0_atomic_op_i  (c0_atomic_op),
        .c0_sc_success_o (c0_sc_success),
        .c1_req_i        (c1_req),
        .c1_we_i         (c1_we),
        .c1_addr_i       (c1_addr),
        .c1_atomic_req_i (c1_atomic_req),
        .c1_atomic_op_i  (c1_atomic_op),
        .c1_sc_success_o (c1_sc_success)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        c0_req = 0; c0_we = 0; c0_addr = 0; c0_atomic_req = 0; c0_atomic_op = 0;
        c1_req = 0; c1_we = 0; c1_addr = 0; c1_atomic_req = 0; c1_atomic_op = 0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_reservation_monitor (Self-Checking) ===");

        // Step 1: Core 0 executes LR at 0x1000
        c0_atomic_req = 1; c0_atomic_op = AMO_LR; c0_addr = 32'h0000_1000; #10;
        c0_atomic_req = 0; #10;

        // Step 2: Core 0 checks SC at 0x1000 -> Should Succeed
        c0_addr = 32'h0000_1000; #1;
        if (!c0_sc_success) begin
            $display("[ERROR] Uncontested Core 0 SC failed!");
            error_count++;
        end

        // Step 3: Core 0 registers LR at 0x2000, then Core 1 writes to 0x2000
        c0_atomic_req = 1; c0_atomic_op = AMO_LR; c0_addr = 32'h0000_2000; #10;
        c0_atomic_req = 0; #10;

        c1_req = 1; c1_we = 1; c1_addr = 32'h0000_2000; #10; // Invalidate Core 0 reservation
        c1_req = 0; c1_we = 0; #10;

        // Step 4: Core 0 checks SC at 0x2000 -> Must Fail
        c0_addr = 32'h0000_2000; #1;
        if (c0_sc_success) begin
            $display("[ERROR] Sunk Core 0 SC succeeded after Core 1 store conflict!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_reservation_monitor PASSED: LR/SC coherence verified! <<<");
        end else begin
            $display(">>> tb_reservation_monitor FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
