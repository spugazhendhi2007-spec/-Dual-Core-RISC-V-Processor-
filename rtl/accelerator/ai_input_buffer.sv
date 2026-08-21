// ============================================================================
// File: ai_input_buffer.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Dual-Port Double-Buffered Activation Scratchpad (2 KB)
// ============================================================================

`timescale 1ns / 1ps

module ai_input_buffer #(
    parameter int DEPTH_WORDS = 512, // 512 x 32-bit = 2048 Bytes
    parameter int ADDR_WIDTH  = 9
) (
    input  logic        clk,

    // Port A: DMA / System Interface
    input  logic                  en_a_i,
    input  logic                  we_a_i,
    input  logic [3:0]            be_a_i,
    input  logic [ADDR_WIDTH-1:0] addr_a_i,
    input  logic [31:0]           wdata_a_i,
    output logic [31:0]           rdata_a_o,

    // Port B: Systolic Array Compute Interface
    input  logic                  en_b_i,
    input  logic                  we_b_i,
    input  logic [3:0]            be_b_i,
    input  logic [ADDR_WIDTH-1:0] addr_b_i,
    input  logic [31:0]           wdata_b_i,
    output logic [31:0]           rdata_b_o
);

    logic [31:0] mem [DEPTH_WORDS-1:0];

    always_ff @(posedge clk) begin
        if (en_a_i) begin
            if (we_a_i) begin
                if (be_a_i[0]) mem[addr_a_i][7:0]   <= wdata_a_i[7:0];
                if (be_a_i[1]) mem[addr_a_i][15:8]  <= wdata_a_i[15:8];
                if (be_a_i[2]) mem[addr_a_i][23:16] <= wdata_a_i[23:16];
                if (be_a_i[3]) mem[addr_a_i][31:24] <= wdata_a_i[31:24];
            end
            rdata_a_o <= mem[addr_a_i];
        end
    end

    always_ff @(posedge clk) begin
        if (en_b_i) begin
            if (we_b_i) begin
                if (be_b_i[0]) mem[addr_b_i][7:0]   <= wdata_b_i[7:0];
                if (be_b_i[1]) mem[addr_b_i][15:8]  <= wdata_b_i[15:8];
                if (be_b_i[2]) mem[addr_b_i][23:16] <= wdata_b_i[23:16];
                if (be_b_i[3]) mem[addr_b_i][31:24] <= wdata_b_i[31:24];
            end
            rdata_b_o <= mem[addr_b_i];
        end
    end

endmodule
