// ============================================================================
// File: axi4lite_interconnect.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: AXI4-Lite Peripheral Address Decoder & Bus Router
// ============================================================================

`timescale 1ns / 1ps

module axi4lite_interconnect (
    input  logic        clk,
    input  logic        rst_n,

    // Upstream AXI4-Lite Slave Port (from AXI4 Interconnect Bridge)
    input  logic        s_req_i,
    input  logic        s_we_i,
    input  logic [3:0]  s_be_i,
    input  logic [31:0] s_addr_i,
    input  logic [31:0] s_wdata_i,
    output logic [31:0] s_rdata_o,
    output logic        s_ready_o,

    // Slave 0: AI Accelerator (0x1000_0000 - 0x1000_00FF)
    output logic        m0_ai_req_o,
    output logic        m0_ai_we_o,
    output logic [3:0]  m0_ai_be_o,
    output logic [31:0] m0_ai_addr_o,
    output logic [31:0] m0_ai_wdata_o,
    input  logic [31:0] m0_ai_rdata_i,

    // Slave 1: Multicore CLINT / Mutex (0x2000_0000 - 0x2000_00FF)
    output logic        m1_clint_req_o,
    output logic        m1_clint_we_o,
    output logic [3:0]  m1_clint_be_o,
    output logic [31:0] m1_clint_addr_o,
    output logic [31:0] m1_clint_wdata_o,
    input  logic [31:0] m1_clint_rdata_i,

    // Slave 2: UART Controller (0x3000_0000 - 0x3000_00FF)
    output logic        m2_uart_req_o,
    output logic        m2_uart_we_o,
    output logic [3:0]  m2_uart_be_o,
    output logic [31:0] m2_uart_addr_o,
    output logic [31:0] m2_uart_wdata_o,
    input  logic [31:0] m2_uart_rdata_i,

    // Slave 3: GPIO Controller (0x4000_0000 - 0x4000_00FF)
    output logic        m3_gpio_req_o,
    output logic        m3_gpio_we_o,
    output logic [3:0]  m3_gpio_be_o,
    output logic [31:0] m3_gpio_addr_o,
    output logic [31:0] m3_gpio_wdata_o,
    input  logic [31:0] m3_gpio_rdata_i,

    // Slave 4: Interrupt Controller (0x5000_0000 - 0x5000_00FF)
    output logic        m4_plic_req_o,
    output logic        m4_plic_we_o,
    output logic [3:0]  m4_plic_be_o,
    output logic [31:0] m4_plic_addr_o,
    output logic [31:0] m4_plic_wdata_o,
    input  logic [31:0] m4_plic_rdata_i
);

    // Decode Target Peripheral from s_addr_i[31:28]
    // 0x1: AI Accel, 0x2: CLINT, 0x3: UART, 0x4: GPIO, 0x5: PLIC
    logic [2:0] slave_sel;
    always_comb begin
        case (s_addr_i[31:28])
            4'h1: slave_sel = 3'd0;
            4'h2: slave_sel = 3'd1;
            4'h3: slave_sel = 3'd2;
            4'h4: slave_sel = 3'd3;
            4'h5: slave_sel = 3'd4;
            default: slave_sel = 3'd7;
        endcase
    end

    assign m0_ai_req_o    = s_req_i && (slave_sel == 3'd0);
    assign m0_ai_we_o     = s_we_i;
    assign m0_ai_be_o     = s_be_i;
    assign m0_ai_addr_o   = s_addr_i;
    assign m0_ai_wdata_o  = s_wdata_i;

    assign m1_clint_req_o   = s_req_i && (slave_sel == 3'd1);
    assign m1_clint_we_o    = s_we_i;
    assign m1_clint_be_o    = s_be_i;
    assign m1_clint_addr_o  = s_addr_i;
    assign m1_clint_wdata_o = s_wdata_i;

    assign m2_uart_req_o   = s_req_i && (slave_sel == 3'd2);
    assign m2_uart_we_o    = s_we_i;
    assign m2_uart_be_o    = s_be_i;
    assign m2_uart_addr_o  = s_addr_i;
    assign m2_uart_wdata_o = s_wdata_i;

    assign m3_gpio_req_o   = s_req_i && (slave_sel == 3'd3);
    assign m3_gpio_we_o    = s_we_i;
    assign m3_gpio_be_o    = s_be_i;
    assign m3_gpio_addr_o  = s_addr_i;
    assign m3_gpio_wdata_o = s_wdata_i;

    assign m4_plic_req_o   = s_req_i && (slave_sel == 3'd4);
    assign m4_plic_we_o    = s_we_i;
    assign m4_plic_be_o    = s_be_i;
    assign m4_plic_addr_o  = s_addr_i;
    assign m4_plic_wdata_o = s_wdata_i;

    always_comb begin
        case (slave_sel)
            3'd0: s_rdata_o = m0_ai_rdata_i;
            3'd1: s_rdata_o = m1_clint_rdata_i;
            3'd2: s_rdata_o = m2_uart_rdata_i;
            3'd3: s_rdata_o = m3_gpio_rdata_i;
            3'd4: s_rdata_o = m4_plic_rdata_i;
            default: s_rdata_o = 32'd0;
        endcase
    end

    assign s_ready_o = s_req_i;

endmodule
