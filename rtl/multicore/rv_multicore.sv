// ============================================================================
// File: rv_multicore.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Dual-Core RISC-V Processing Subsystem (Hart 0 + Hart 1 + Reservation Unit)
// ============================================================================

`timescale 1ns / 1ps
`include "../core/rv_defines.svh"

module rv_multicore (
    input  logic        clk,
    input  logic        rst_n,

    // Core 0 Instruction Bus
    output logic        core0_instr_req_o,
    output logic [31:0] core0_instr_addr_o,
    input  logic [31:0] core0_instr_rdata_i,

    // Core 0 Data Bus
    output logic        core0_data_req_o,
    output logic        core0_data_we_o,
    output logic [3:0]  core0_data_be_o,
    output logic [31:0] core0_data_addr_o,
    output logic [31:0] core0_data_wdata_o,
    input  logic [31:0] core0_data_rdata_i,

    // Core 1 Instruction Bus
    output logic        core1_instr_req_o,
    output logic [31:0] core1_instr_addr_o,
    input  logic [31:0] core1_instr_rdata_i,

    // Core 1 Data Bus
    output logic        core1_data_req_o,
    output logic        core1_data_we_o,
    output logic [3:0]  core1_data_be_o,
    output logic [31:0] core1_data_addr_o,
    output logic [31:0] core1_data_wdata_o,
    input  logic [31:0] core1_data_rdata_i,

    // Custom AI Instruction Interface
    output logic        ai_cmd_valid_o,
    output logic [2:0]  ai_cmd_type_o,
    output logic [31:0] ai_cmd_arg0_o,
    output logic [31:0] ai_cmd_arg1_o,
    input  logic        ai_busy_i,
    input  logic        ai_done_i,

    // External Interrupts
    input  logic        irq_external_core0_i,
    input  logic        irq_external_core1_i,

    // Multicore IPI / CLINT Slave Bus Interface
    input  logic        clint_req_i,
    input  logic        clint_we_i,
    input  logic [3:0]  clint_be_i,
    input  logic [31:0] clint_addr_i,
    input  logic [31:0] clint_wdata_i,
    output logic [31:0] clint_rdata_o
);

    // Internal Interrupt Lines
    logic irq_soft_c0, irq_timer_c0;
    logic irq_soft_c1, irq_timer_c1;

    // Atomic / Reservation Monitor Signals
    logic        c0_atomic_req, c1_atomic_req;
    logic [4:0]  c0_atomic_op, c1_atomic_op;
    logic        c0_sc_success, c1_sc_success;

    // Core AI command wires
    logic        c0_ai_valid, c1_ai_valid;
    logic [2:0]  c0_ai_type, c1_ai_type;
    logic [31:0] c0_ai_arg0, c1_ai_arg0;
    logic [31:0] c0_ai_arg1, c1_ai_arg1;

    assign ai_cmd_valid_o = c0_ai_valid ? c0_ai_valid : c1_ai_valid;
    assign ai_cmd_type_o  = c0_ai_valid ? c0_ai_type  : c1_ai_type;
    assign ai_cmd_arg0_o  = c0_ai_valid ? c0_ai_arg0  : c1_ai_arg0;
    assign ai_cmd_arg1_o  = c0_ai_valid ? c0_ai_arg1  : c1_ai_arg1;

    // ------------------------------------------------------------------------
    // Core 0 (Hart 0) Instance
    // ------------------------------------------------------------------------
    rv_core #(
        .HART_ID   (32'd0),
        .RESET_VEC (32'h0000_0000)
    ) u_core0 (
        .clk                 (clk),
        .rst_n               (rst_n),
        .instr_req_o         (core0_instr_req_o),
        .instr_addr_o        (core0_instr_addr_o),
        .instr_rdata_i       (core0_instr_rdata_i),
        .data_req_o          (core0_data_req_o),
        .data_we_o           (core0_data_we_o),
        .data_be_o           (core0_data_be_o),
        .data_addr_o         (core0_data_addr_o),
        .data_wdata_o        (core0_data_wdata_o),
        .data_rdata_i        (core0_data_rdata_i),
        .atomic_req_o        (c0_atomic_req),
        .atomic_op_o         (c0_atomic_op),
        .atomic_sc_success_i (c0_sc_success),
        .ai_cmd_valid_o      (c0_ai_valid),
        .ai_cmd_type_o       (c0_ai_type),
        .ai_cmd_arg0_o       (c0_ai_arg0),
        .ai_cmd_arg1_o       (c0_ai_arg1),
        .ai_busy_i           (ai_busy_i),
        .ai_done_i           (ai_done_i),
        .irq_software_i      (irq_soft_c0),
        .irq_timer_i         (irq_timer_c0),
        .irq_external_i      (irq_external_core0_i)
    );

    // ------------------------------------------------------------------------
    // Core 1 (Hart 1) Instance
    // ------------------------------------------------------------------------
    rv_core #(
        .HART_ID   (32'd1),
        .RESET_VEC (32'h0000_0000)
    ) u_core1 (
        .clk                 (clk),
        .rst_n               (rst_n),
        .instr_req_o         (core1_instr_req_o),
        .instr_addr_o        (core1_instr_addr_o),
        .instr_rdata_i       (core1_instr_rdata_i),
        .data_req_o          (core1_data_req_o),
        .data_we_o           (core1_data_we_o),
        .data_be_o           (core1_data_be_o),
        .data_addr_o         (core1_data_addr_o),
        .data_wdata_o        (core1_data_wdata_o),
        .data_rdata_i        (core1_data_rdata_i),
        .atomic_req_o        (c1_atomic_req),
        .atomic_op_o         (c1_atomic_op),
        .atomic_sc_success_i (c1_sc_success),
        .ai_cmd_valid_o      (c1_ai_valid),
        .ai_cmd_type_o       (c1_ai_type),
        .ai_cmd_arg0_o       (c1_ai_arg0),
        .ai_cmd_arg1_o       (c1_ai_arg1),
        .ai_busy_i           (ai_busy_i),
        .ai_done_i           (ai_done_i),
        .irq_software_i      (irq_soft_c1),
        .irq_timer_i         (irq_timer_c1),
        .irq_external_i      (irq_external_core1_i)
    );

    // ------------------------------------------------------------------------
    // Multi-Core LR/SC Hardware Reservation Monitor
    // ------------------------------------------------------------------------
    rv_reservation_monitor u_res_monitor (
        .clk             (clk),
        .rst_n           (rst_n),
        .c0_req_i        (core0_data_req_o),
        .c0_we_i         (core0_data_we_o),
        .c0_addr_i       (core0_data_addr_o),
        .c0_atomic_req_i (c0_atomic_req),
        .c0_atomic_op_i  (c0_atomic_op),
        .c0_sc_success_o (c0_sc_success),
        .c1_req_i        (core1_data_req_o),
        .c1_we_i         (core1_data_we_o),
        .c1_addr_i       (core1_data_addr_o),
        .c1_atomic_req_i (c1_atomic_req),
        .c1_atomic_op_i  (c1_atomic_op),
        .c1_sc_success_o (c1_sc_success)
    );

    // ------------------------------------------------------------------------
    // IPI and Multicore Timer Controller
    // ------------------------------------------------------------------------
    rv_ipi_controller u_ipi_ctrl (
        .clk               (clk),
        .rst_n             (rst_n),
        .req_i             (clint_req_i),
        .we_i              (clint_we_i),
        .be_i              (clint_be_i),
        .addr_i            (clint_addr_i),
        .wdata_i           (clint_wdata_i),
        .rdata_o           (clint_rdata_o),
        .irq_soft_core0_o  (irq_soft_c0),
        .irq_timer_core0_o (irq_timer_c0),
        .irq_soft_core1_o  (irq_soft_c1),
        .irq_timer_core1_o (irq_timer_c1)
    );

endmodule
