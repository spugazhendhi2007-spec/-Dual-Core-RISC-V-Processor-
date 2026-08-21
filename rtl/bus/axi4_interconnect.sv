// ============================================================================
// File: axi4_interconnect.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Multi-Master Multi-Slave AXI4 High-Bandwidth Crossbar Switch
// ============================================================================

`timescale 1ns / 1ps

module axi4_interconnect #(
    parameter int NUM_MASTERS = 3 // M0: Core0, M1: Core1, M2: AI DMA
) (
    input  logic        clk,
    input  logic        rst_n,

    // Master 0 (Core 0 Data Bus)
    input  logic        m0_req_i,
    input  logic        m0_we_i,
    input  logic [3:0]  m0_be_i,
    input  logic [31:0] m0_addr_i,
    input  logic [31:0] m0_wdata_i,
    output logic [31:0] m0_rdata_o,
    output logic        m0_ready_o,

    // Master 1 (Core 1 Data Bus)
    input  logic        m1_req_i,
    input  logic        m1_we_i,
    input  logic [3:0]  m1_be_i,
    input  logic [31:0] m1_addr_i,
    input  logic [31:0] m1_wdata_i,
    output logic [31:0] m1_rdata_o,
    output logic        m1_ready_o,

    // Master 2 (AI DMA Engine)
    input  logic        m2_req_i,
    input  logic        m2_we_i,
    input  logic [3:0]  m2_be_i,
    input  logic [31:0] m2_addr_i,
    input  logic [31:0] m2_wdata_i,
    output logic [31:0] m2_rdata_o,
    output logic        m2_ready_o,

    // Slave 0 (64 KB Banked SRAM: 0x0000_0000 - 0x0000_FFFF)
    output logic        s0_sram_req_o,
    output logic        s0_sram_we_o,
    output logic [3:0]  s0_sram_be_o,
    output logic [31:0] s0_sram_addr_o,
    output logic [31:0] s0_sram_wdata_o,
    input  logic [31:0] s0_sram_rdata_i,
    input  logic        s0_sram_ready_i,

    // Slave 1 (AXI4-Lite Bridge for Peripherals: 0x1000_0000 - 0x5FFF_FFFF)
    output logic        s1_axil_req_o,
    output logic        s1_axil_we_o,
    output logic [3:0]  s1_axil_be_o,
    output logic [31:0] s1_axil_addr_o,
    output logic [31:0] s1_axil_wdata_o,
    input  logic [31:0] s1_axil_rdata_i,
    input  logic        s1_axil_ready_i
);

    // Arbiter among 3 Masters
    logic [1:0] gnt_master;
    logic [1:0] last_gnt;
    logic       any_req;

    always_comb begin
        gnt_master = 2'd0;
        any_req    = 1'b0;

        if (last_gnt == 2'd0) begin
            if (m1_req_i)      begin gnt_master = 2'd1; any_req = 1'b1; end
            else if (m2_req_i) begin gnt_master = 2'd2; any_req = 1'b1; end
            else if (m0_req_i) begin gnt_master = 2'd0; any_req = 1'b1; end
        end else if (last_gnt == 2'd1) begin
            if (m2_req_i)      begin gnt_master = 2'd2; any_req = 1'b1; end
            else if (m0_req_i) begin gnt_master = 2'd0; any_req = 1'b1; end
            else if (m1_req_i) begin gnt_master = 2'd1; any_req = 1'b1; end
        end else begin
            if (m0_req_i)      begin gnt_master = 2'd0; any_req = 1'b1; end
            else if (m1_req_i) begin gnt_master = 2'd1; any_req = 1'b1; end
            else if (m2_req_i) begin gnt_master = 2'd2; any_req = 1'b1; end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_gnt <= 2'd0;
        end else if (any_req) begin
            last_gnt <= gnt_master;
        end
    end

    // Selected Master Bus Signals
    logic        sel_req, sel_we;
    logic [3:0]  sel_be;
    logic [31:0] sel_addr, sel_wdata;

    always_comb begin
        case (gnt_master)
            2'd0: begin
                sel_req   = m0_req_i;
                sel_we    = m0_we_i;
                sel_be    = m0_be_i;
                sel_addr  = m0_addr_i;
                sel_wdata = m0_wdata_i;
            end
            2'd1: begin
                sel_req   = m1_req_i;
                sel_we    = m1_we_i;
                sel_be    = m1_be_i;
                sel_addr  = m1_addr_i;
                sel_wdata = m1_wdata_i;
            end
            default: begin
                sel_req   = m2_req_i;
                sel_we    = m2_we_i;
                sel_be    = m2_be_i;
                sel_addr  = m2_addr_i;
                sel_wdata = m2_wdata_i;
            end
        endcase
    end

    // Route Request to Target Slave
    logic is_sram, is_axil;
    assign is_sram = (sel_addr[31:16] == 16'h0000); // 0x0000_0000 - 0x0000_FFFF
    assign is_axil = !is_sram;

    assign s0_sram_req_o   = sel_req && is_sram;
    assign s0_sram_we_o    = sel_we;
    assign s0_sram_be_o    = sel_be;
    assign s0_sram_addr_o  = sel_addr;
    assign s0_sram_wdata_o = sel_wdata;

    assign s1_axil_req_o   = sel_req && is_axil;
    assign s1_axil_we_o    = sel_we;
    assign s1_axil_be_o    = sel_be;
    assign s1_axil_addr_o  = sel_addr;
    assign s1_axil_wdata_o = sel_wdata;

    // Response Routing
    logic [31:0] active_rdata;
    logic        active_ready;

    assign active_rdata = is_sram ? s0_sram_rdata_i : s1_axil_rdata_i;
    assign active_ready = is_sram ? s0_sram_ready_i : s1_axil_ready_i;

    assign m0_rdata_o = active_rdata;
    assign m1_rdata_o = active_rdata;
    assign m2_rdata_o = active_rdata;

    assign m0_ready_o = (gnt_master == 2'd0) ? active_ready : 1'b0;
    assign m1_ready_o = (gnt_master == 2'd1) ? active_ready : 1'b0;
    assign m2_ready_o = (gnt_master == 2'd2) ? active_ready : 1'b0;

endmodule
