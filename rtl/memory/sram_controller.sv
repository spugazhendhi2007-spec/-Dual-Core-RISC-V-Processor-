// ============================================================================
// File: sram_controller.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 64 KB Banked SRAM Controller (4 x 16 KB Banks, Interleaved Addressing)
// ============================================================================

`timescale 1ns / 1ps

module sram_controller (
    input  logic        clk,
    input  logic        rst_n,

    // Bus Slave Interface (64 KB addressable space: 0x0000_0000 to 0x0000_FFFF)
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    output logic        ready_o
);

    // 4 Banks x 16 KB each = 64 KB total
    // Bank Select = addr[3:2], Bank Word Index = addr[15:4] (12 bits -> 4096 words)
    logic [1:0]  bank_sel;
    logic [11:0] bank_addr;

    assign bank_sel  = addr_i[3:2];
    assign bank_addr = addr_i[15:4];

    logic [3:0]  bank_en;
    logic [3:0]  bank_we;
    logic [31:0] bank_rdata [3:0];

    always_comb begin
        for (int b = 0; b < 4; b++) begin
            bank_en[b] = req_i && (bank_sel == b);
            bank_we[b] = we_i  && (bank_sel == b);
        end
    end

    // Bank Instances
    genvar b;
    generate
        for (b = 0; b < 4; b++) begin : gen_sram_banks
            sram_bank #(
                .DEPTH_WORDS (4096),
                .ADDR_WIDTH  (12)
            ) u_bank (
                .clk     (clk),
                .en_i    (bank_en[b]),
                .we_i    (bank_we[b]),
                .be_i    (be_i),
                .addr_i  (bank_addr),
                .wdata_i (wdata_i),
                .rdata_o (bank_rdata[b])
            );
        end
    endgenerate

    // Pipelined Read Mux
    logic [1:0] bank_sel_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bank_sel_q <= 2'd0;
            ready_o    <= 1'b0;
        end else begin
            bank_sel_q <= bank_sel;
            ready_o    <= req_i;
        end
    end

    assign rdata_o = bank_rdata[bank_sel_q];

endmodule
