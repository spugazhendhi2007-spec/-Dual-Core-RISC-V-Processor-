// ============================================================================
// File: rv_regfile.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 32 x 32-bit Integer Register File (2 Read Ports, 1 Write Port, x0=0)
// ============================================================================

`timescale 1ns / 1ps

module rv_regfile (
    input  logic        clk,
    input  logic        rst_n,

    // Read Port 1
    input  logic [4:0]  raddr1_i,
    output logic [31:0] rdata1_o,

    // Read Port 2
    input  logic [4:0]  raddr2_i,
    output logic [31:0] rdata2_o,

    // Write Port
    input  logic        we_i,
    input  logic [4:0]  waddr_i,
    input  logic [31:0] wdata_i
);

    logic [31:0] regs [31:1];

    // Asynchronous Read with Write-Through & x0 Hardwired Zero
    always_comb begin
        if (raddr1_i == 5'd0) begin
            rdata1_o = 32'd0;
        end else if (we_i && (waddr_i == raddr1_i)) begin
            rdata1_o = wdata_i; // Forward from WB to ID
        end else begin
            rdata1_o = regs[raddr1_i];
        end

        if (raddr2_i == 5'd0) begin
            rdata2_o = 32'd0;
        end else if (we_i && (waddr_i == raddr2_i)) begin
            rdata2_o = wdata_i; // Forward from WB to ID
        end else begin
            rdata2_o = regs[raddr2_i];
        end
    end

    // Synchronous Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 1; i < 32; i++) begin
                regs[i] <= 32'd0;
            end
        end else if (we_i && (waddr_i != 5'd0)) begin
            regs[waddr_i] <= wdata_i;
        end
    end

endmodule
