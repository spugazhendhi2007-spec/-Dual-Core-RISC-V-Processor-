// ============================================================================
// File: tb_core.sv
// Description: Self-Checking Testbench for Integrated RV32IMA Core
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/core/rv_defines.svh"

module tb_core;

    logic        clk;
    logic        rst_n;

    logic        instr_req;
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    logic        data_req;
    logic        data_we;
    logic [3:0]  data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;

    logic        atomic_req;
    logic [4:0]  atomic_op;
    logic        atomic_sc_success;

    logic        ai_cmd_valid;
    logic [2:0]  ai_cmd_type;
    logic [31:0] ai_cmd_arg0;
    logic [31:0] ai_cmd_arg1;
    logic        ai_busy;
    logic        ai_done;

    logic        irq_software, irq_timer, irq_external;

    int error_count = 0;

    // Simulation Memory
    logic [31:0] mem [1023:0];

    rv_core #(
        .HART_ID   (32'd0),
        .RESET_VEC (32'h0000_0000)
    ) dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .instr_req_o         (instr_req),
        .instr_addr_o        (instr_addr),
        .instr_rdata_i       (instr_rdata),
        .data_req_o          (data_req),
        .data_we_o           (data_we),
        .data_be_o           (data_be),
        .data_addr_o         (data_addr),
        .data_wdata_o        (data_wdata),
        .data_rdata_i        (data_rdata),
        .atomic_req_o        (atomic_req),
        .atomic_op_o         (atomic_op),
        .atomic_sc_success_i (atomic_sc_success),
        .ai_cmd_valid_o      (ai_cmd_valid),
        .ai_cmd_type_o       (ai_cmd_type),
        .ai_cmd_arg0_o       (ai_cmd_arg0),
        .ai_cmd_arg1_o       (ai_cmd_arg1),
        .ai_busy_i           (ai_busy),
        .ai_done_i           (ai_done),
        .irq_software_i      (irq_software),
        .irq_timer_i         (irq_timer),
        .irq_external_i      (irq_external)
    );

    always #5 clk = ~clk;

    // Simple Memory Model
    always_comb begin
        instr_rdata = mem[instr_addr[11:2]];
        data_rdata  = mem[data_addr[11:2]];
    end

    always_ff @(posedge clk) begin
        if (data_req && data_we) begin
            mem[data_addr[11:2]] <= data_wdata;
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        atomic_sc_success = 1;
        ai_busy = 0;
        ai_done = 0;
        irq_software = 0;
        irq_timer = 0;
        irq_external = 0;

        for (int i = 0; i < 1024; i++) mem[i] = 32'h0000_0013; // NOPs

        // Program to test RV32IMA:
        // 0x00: ADDI x1, x0, 15        (0x00F00093)
        // 0x04: ADDI x2, x0, 25        (0x01900113)
        // 0x08: ADD  x3, x1, x2        (0x002081B3) -> x3 = 40
        // 0x0C: SW   x3, 0x100(x0)     (0x10302023) -> Store 40 at 0x100
        // 0x10: MUL  x4, x1, x2        (0x02208233) -> x4 = 375
        // 0x14: SW   x4, 0x104(x0)     (0x10402223) -> Store 375 at 0x104
        mem[0] = 32'h00F0_0093;
        mem[1] = 32'h0190_0113;
        mem[2] = 32'h0020_81B3;
        mem[3] = 32'h1030_2023;
        mem[4] = 32'h0220_8233;
        mem[5] = 32'h1040_2223;

        #20;
        rst_n = 1;

        $display("=== Starting tb_core (Self-Checking) ===");

        // Run for 30 cycles
        #300;

        // Check if memory received the results
        if (mem[32'h100 >> 2] !== 32'd40) begin
            $display("[ERROR] Core ADD result at 0x100 failed! Expected 40, Got %0d", mem[32'h100 >> 2]);
            error_count++;
        end

        if (mem[32'h104 >> 2] !== 32'd375) begin
            $display("[ERROR] Core MUL result at 0x104 failed! Expected 375, Got %0d", mem[32'h104 >> 2]);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_core PASSED: RV32IMA Core execution verified! <<<");
        end else begin
            $display(">>> tb_core FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
