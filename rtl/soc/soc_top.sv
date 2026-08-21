// ============================================================================
// File: soc_top.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Top-Level ASIC System-on-Chip (Dual RV32IMA + 8x8 Systolic INT8 AI Accel + SRAM + Periphs)
// ============================================================================

`timescale 1ns / 1ps
`include "../core/rv_defines.svh"
`include "../accelerator/ai_defines.svh"

module soc_top (
    input  logic        clk,
    input  logic        rst_n,

    // UART Interface
    input  logic        uart_rx_i,
    output logic        uart_tx_o,

    // GPIO Interface
    input  logic [15:0] gpio_in_i,
    output logic [15:0] gpio_out_o,
    output logic [15:0] gpio_oe_o
);

    // Multicore Instruction & Data Bus Signals
    logic        c0_instr_req;
    logic [31:0] c0_instr_addr, c0_instr_rdata;
    logic        c0_data_req, c0_data_we;
    logic [3:0]  c0_data_be;
    logic [31:0] c0_data_addr, c0_data_wdata, c0_data_rdata;

    logic        c1_instr_req;
    logic [31:0] c1_instr_addr, c1_instr_rdata;
    logic        c1_data_req, c1_data_we;
    logic [3:0]  c1_data_be;
    logic [31:0] c1_data_addr, c1_data_wdata, c1_data_rdata;

    // Custom AI Instruction Interface
    logic        ai_cmd_valid;
    logic [2:0]  ai_cmd_type;
    logic [31:0] ai_cmd_arg0, ai_cmd_arg1;
    logic        ai_busy, ai_done;

    // AI DMA Master Bus
    logic        ai_dma_req, ai_dma_we;
    logic [3:0]  ai_dma_be;
    logic [31:0] ai_dma_addr, ai_dma_wdata, ai_dma_rdata;
    logic        ai_dma_ready;

    // AXI4 Interconnect Internal Slaves
    logic        sram_req, sram_we;
    logic [3:0]  sram_be;
    logic [31:0] sram_addr, sram_wdata, sram_rdata;
    logic        sram_ready;

    logic        axil_bridge_req, axil_bridge_we;
    logic [3:0]  axil_bridge_be;
    logic [31:0] axil_bridge_addr, axil_bridge_wdata, axil_bridge_rdata;
    logic        axil_bridge_ready;

    // AXI4-Lite Peripherals
    logic        ai_s_req, ai_s_we;
    logic [3:0]  ai_s_be;
    logic [31:0] ai_s_addr, ai_s_wdata, ai_s_rdata;

    logic        clint_req, clint_we;
    logic [3:0]  clint_be;
    logic [31:0] clint_addr, clint_wdata, clint_rdata;

    logic        uart_req, uart_we;
    logic [3:0]  uart_be;
    logic [31:0] uart_addr, uart_wdata, uart_rdata;

    logic        gpio_req, gpio_we;
    logic [3:0]  gpio_be;
    logic [31:0] gpio_addr, gpio_wdata, gpio_rdata;

    logic        plic_req, plic_we;
    logic [3:0]  plic_be;
    logic [31:0] plic_addr, plic_wdata, plic_rdata;

    // Interrupt Lines
    logic        irq_ai_done, irq_uart, irq_gpio, irq_timer;
    logic        irq_core0, irq_core1;

    // ------------------------------------------------------------------------
    // Dual-Core RV32IMA Subsystem
    // ------------------------------------------------------------------------
    rv_multicore u_multicore (
        .clk                  (clk),
        .rst_n                (rst_n),
        .core0_instr_req_o    (c0_instr_req),
        .core0_instr_addr_o   (c0_instr_addr),
        .core0_instr_rdata_i  (c0_instr_rdata),
        .core0_data_req_o     (c0_data_req),
        .core0_data_we_o      (c0_data_we),
        .core0_data_be_o      (c0_data_be),
        .core0_data_addr_o    (c0_data_addr),
        .core0_data_wdata_o   (c0_data_wdata),
        .core0_data_rdata_i   (c0_data_rdata),
        .core1_instr_req_o    (c1_instr_req),
        .core1_instr_addr_o   (c1_instr_addr),
        .core1_instr_rdata_i  (c1_instr_rdata),
        .core1_data_req_o     (c1_data_req),
        .core1_data_we_o      (c1_data_we),
        .core1_data_be_o      (c1_data_be),
        .core1_data_addr_o    (c1_data_addr),
        .core1_data_wdata_o   (c1_data_wdata),
        .core1_data_rdata_i   (c1_data_rdata),
        .ai_cmd_valid_o       (ai_cmd_valid),
        .ai_cmd_type_o        (ai_cmd_type),
        .ai_cmd_arg0_o        (ai_cmd_arg0),
        .ai_cmd_arg1_o        (ai_cmd_arg1),
        .ai_busy_i            (ai_busy),
        .ai_done_i            (ai_done),
        .irq_external_core0_i (irq_core0),
        .irq_external_core1_i (irq_core1),
        .clint_req_i          (clint_req),
        .clint_we_i           (clint_we),
        .clint_be_i           (clint_be),
        .clint_addr_i         (clint_addr),
        .clint_wdata_i        (clint_wdata),
        .clint_rdata_o        (clint_rdata)
    );

    // ------------------------------------------------------------------------
    // 8x8 INT8 AI Accelerator Subsystem (64 PEs, 2D DMA, Post-Processor)
    // ------------------------------------------------------------------------
    ai_accel_top u_ai_accel (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axil_req_i   (ai_s_req),
        .s_axil_we_i    (ai_s_we),
        .s_axil_be_i    (ai_s_be),
        .s_axil_addr_i  (ai_s_addr),
        .s_axil_wdata_i (ai_s_wdata),
        .s_axil_rdata_o (ai_s_rdata),
        .ai_cmd_valid_i (ai_cmd_valid),
        .ai_cmd_type_i  (ai_cmd_type),
        .ai_cmd_arg0_i  (ai_cmd_arg0),
        .ai_cmd_arg1_i  (ai_cmd_arg1),
        .ai_busy_o      (ai_busy),
        .ai_done_o      (ai_done),
        .m_axi_req_o    (ai_dma_req),
        .m_axi_we_o     (ai_dma_we),
        .m_axi_be_o     (ai_dma_be),
        .m_axi_addr_o   (ai_dma_addr),
        .m_axi_wdata_o  (ai_dma_wdata),
        .m_axi_rdata_i  (ai_dma_rdata),
        .m_axi_ready_i  (ai_dma_ready),
        .irq_done_o     (irq_ai_done)
    );

    // ------------------------------------------------------------------------
    // AXI4 High-Bandwidth Crossbar Interconnect
    // ------------------------------------------------------------------------
    axi4_interconnect #(
        .NUM_MASTERS (3)
    ) u_axi4_ic (
        .clk             (clk),
        .rst_n           (rst_n),
        .m0_req_i        (c0_data_req),
        .m0_we_i         (c0_data_we),
        .m0_be_i         (c0_data_be),
        .m0_addr_i       (c0_data_addr),
        .m0_wdata_i      (c0_data_wdata),
        .m0_rdata_o      (c0_data_rdata),
        .m0_ready_o      (),
        .m1_req_i        (c1_data_req),
        .m1_we_i         (c1_data_we),
        .m1_be_i         (c1_data_be),
        .m1_addr_i       (c1_data_addr),
        .m1_wdata_i      (c1_data_wdata),
        .m1_rdata_o      (c1_data_rdata),
        .m1_ready_o      (),
        .m2_req_i        (ai_dma_req),
        .m2_we_i         (ai_dma_we),
        .m2_be_i         (ai_dma_be),
        .m2_addr_i       (ai_dma_addr),
        .m2_wdata_i      (ai_dma_wdata),
        .m2_rdata_o      (ai_dma_rdata),
        .m2_ready_o      (ai_dma_ready),
        .s0_sram_req_o   (sram_req),
        .s0_sram_we_o    (sram_we),
        .s0_sram_be_o    (sram_be),
        .s0_sram_addr_o  (sram_addr),
        .s0_sram_wdata_o (sram_wdata),
        .s0_sram_rdata_i (sram_rdata),
        .s0_sram_ready_i (sram_ready),
        .s1_axil_req_o   (axil_bridge_req),
        .s1_axil_we_o    (axil_bridge_we),
        .s1_axil_be_o    (axil_bridge_be),
        .s1_axil_addr_o  (axil_bridge_addr),
        .s1_axil_wdata_o (axil_bridge_wdata),
        .s1_axil_rdata_i (axil_bridge_rdata),
        .s1_axil_ready_i (axil_bridge_ready)
    );

    // ------------------------------------------------------------------------
    // 64 KB Banked SRAM Memory Controller
    // ------------------------------------------------------------------------
    sram_controller u_sram_ctrl (
        .clk     (clk),
        .rst_n   (rst_n),
        .req_i   (sram_req || c0_instr_req || c1_instr_req),
        .we_i    (sram_we),
        .be_i    (sram_be),
        .addr_i  (sram_req ? sram_addr : (c0_instr_req ? c0_instr_addr : c1_instr_addr)),
        .wdata_i (sram_wdata),
        .rdata_o (sram_rdata),
        .ready_o (sram_ready)
    );

    assign c0_instr_rdata = sram_rdata;
    assign c1_instr_rdata = sram_rdata;

    // ------------------------------------------------------------------------
    // AXI4-Lite Peripheral Interconnect
    // ------------------------------------------------------------------------
    axi4lite_interconnect u_axil_ic (
        .clk             (clk),
        .rst_n           (rst_n),
        .s_req_i         (axil_bridge_req),
        .s_we_i          (axil_bridge_we),
        .s_be_i          (axil_bridge_be),
        .s_addr_i        (axil_bridge_addr),
        .s_wdata_i       (axil_bridge_wdata),
        .s_rdata_o       (axil_bridge_rdata),
        .s_ready_o       (axil_bridge_ready),
        .m0_ai_req_o     (ai_s_req),
        .m0_ai_we_o      (ai_s_we),
        .m0_ai_be_o      (ai_s_be),
        .m0_ai_addr_o    (ai_s_addr),
        .m0_ai_wdata_o   (ai_s_wdata),
        .m0_ai_rdata_i   (ai_s_rdata),
        .m1_clint_req_o   (clint_req),
        .m1_clint_we_o    (clint_we),
        .m1_clint_be_o    (clint_be),
        .m1_clint_addr_o  (clint_addr),
        .m1_clint_wdata_o (clint_wdata),
        .m1_clint_rdata_i (clint_rdata),
        .m2_uart_req_o   (uart_req),
        .m2_uart_we_o    (uart_we),
        .m2_uart_be_o    (uart_be),
        .m2_uart_addr_o  (uart_addr),
        .m2_uart_wdata_o (uart_wdata),
        .m2_uart_rdata_i (uart_rdata),
        .m3_gpio_req_o   (gpio_req),
        .m3_gpio_we_o    (gpio_we),
        .m3_gpio_be_o    (gpio_be),
        .m3_gpio_addr_o  (gpio_addr),
        .m3_gpio_wdata_o (gpio_wdata),
        .m3_gpio_rdata_i (gpio_rdata),
        .m4_plic_req_o   (plic_req),
        .m4_plic_we_o    (plic_we),
        .m4_plic_be_o    (plic_be),
        .m4_plic_addr_o  (plic_addr),
        .m4_plic_wdata_o (plic_wdata),
        .m4_plic_rdata_i (plic_rdata)
    );

    // ------------------------------------------------------------------------
    // Peripherals
    // ------------------------------------------------------------------------
    uart u_uart (
        .clk     (clk),
        .rst_n   (rst_n),
        .req_i   (uart_req),
        .we_i    (uart_we),
        .be_i    (uart_be),
        .addr_i  (uart_addr),
        .wdata_i (uart_wdata),
        .rdata_o (uart_rdata),
        .rx_i    (uart_rx_i),
        .tx_o    (uart_tx_o),
        .irq_o   (irq_uart)
    );

    gpio u_gpio (
        .clk        (clk),
        .rst_n      (rst_n),
        .req_i      (gpio_req),
        .we_i       (gpio_we),
        .be_i       (gpio_be),
        .addr_i     (gpio_addr),
        .wdata_i    (gpio_wdata),
        .rdata_o    (gpio_rdata),
        .gpio_in_i  (gpio_in_i),
        .gpio_out_o (gpio_out_o),
        .gpio_oe_o  (gpio_oe_o),
        .irq_o      (irq_gpio)
    );

    timer u_timer (
        .clk     (clk),
        .rst_n   (rst_n),
        .req_i   (1'b0),
        .we_i    (1'b0),
        .be_i    (4'b0000),
        .addr_i  (32'd0),
        .wdata_i (32'd0),
        .rdata_o (),
        .irq_o   (irq_timer)
    );

    interrupt_controller u_plic (
        .clk           (clk),
        .rst_n         (rst_n),
        .req_i         (plic_req),
        .we_i          (plic_we),
        .be_i          (plic_be),
        .addr_i        (plic_addr),
        .wdata_i       (plic_wdata),
        .rdata_o       (plic_rdata),
        .irq_ai_done_i (irq_ai_done),
        .irq_uart_i    (irq_uart),
        .irq_gpio_i    (irq_gpio),
        .irq_timer_i   (irq_timer),
        .irq_core0_o   (irq_core0),
        .irq_core1_o   (irq_core1)
    );

endmodule
