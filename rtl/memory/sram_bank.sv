// ============================================================================
// File: sram_bank.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 16 KB Synchronous SRAM Bank (4096 Words x 32 Bits, Byte-Addressable)
// ============================================================================

`timescale 1ns / 1ps

module sram_bank #(
    parameter int DEPTH_WORDS = 4096, // 4096 x 4 Bytes = 16 KB
    parameter int ADDR_WIDTH  = 12
) (
    input  logic                  clk,
    input  logic                  en_i,
    input  logic                  we_i,
    input  logic [3:0]            be_i,
    input  logic [ADDR_WIDTH-1:0] addr_i,
    input  logic [31:0]           wdata_i,
    output logic [31:0]           rdata_o
);

    logic [31:0] mem [DEPTH_WORDS-1:0];

    always_ff @(posedge clk) begin
        if (en_i) begin
            if (we_i) begin
                if (be_i[0]) mem[addr_i][7:0]   <= wdata_i[7:0];
                if (be_i[1]) mem[addr_i][15:8]  <= wdata_i[15:8];
                if (be_i[2]) mem[addr_i][23:16] <= wdata_i[23:16];
                if (be_i[3]) mem[addr_i][31:24] <= wdata_i[31:24];
            end
            rdata_o <= mem[addr_i];
        end
    end

endmodule
