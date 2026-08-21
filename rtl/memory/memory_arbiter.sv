// ============================================================================
// File: memory_arbiter.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Multi-Port Round-Robin Memory Access Arbiter
// ============================================================================

`timescale 1ns / 1ps

module memory_arbiter #(
    parameter int NUM_MASTERS = 3
) (
    input  logic        clk,
    input  logic        rst_n,

    // Master Request Lines
    input  logic [NUM_MASTERS-1:0]        req_i,
    input  logic [NUM_MASTERS-1:0]        we_i,
    input  logic [NUM_MASTERS-1:0][3:0]   be_i,
    input  logic [NUM_MASTERS-1:0][31:0]  addr_i,
    input  logic [NUM_MASTERS-1:0][31:0]  wdata_i,
    output logic [NUM_MASTERS-1:0][31:0]  rdata_o,
    output logic [NUM_MASTERS-1:0]        gnt_o,

    // Unified Slave Port (to Memory Bank Controller)
    output logic        slave_req_o,
    output logic        slave_we_o,
    output logic [3:0]  slave_be_o,
    output logic [31:0] slave_addr_o,
    output logic [31:0] slave_wdata_o,
    input  logic [31:0] slave_rdata_i
);

    logic [1:0] grant_idx;
    logic [1:0] last_grant;

    // Round-Robin Priority Encoder
    always_comb begin
        grant_idx   = 2'd0;
        slave_req_o = 1'b0;

        if (last_grant == 2'd0) begin
            if (req_i[1])      begin grant_idx = 2'd1; slave_req_o = 1'b1; end
            else if (req_i[2]) begin grant_idx = 2'd2; slave_req_o = 1'b1; end
            else if (req_i[0]) begin grant_idx = 2'd0; slave_req_o = 1'b1; end
        end else if (last_grant == 2'd1) begin
            if (req_i[2])      begin grant_idx = 2'd2; slave_req_o = 1'b1; end
            else if (req_i[0]) begin grant_idx = 2'd0; slave_req_o = 1'b1; end
            else if (req_i[1]) begin grant_idx = 2'd1; slave_req_o = 1'b1; end
        end else begin
            if (req_i[0])      begin grant_idx = 2'd0; slave_req_o = 1'b1; end
            else if (req_i[1]) begin grant_idx = 2'd1; slave_req_o = 1'b1; end
            else if (req_i[2]) begin grant_idx = 2'd2; slave_req_o = 1'b1; end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_grant <= 2'd0;
        end else if (slave_req_o) begin
            last_grant <= grant_idx;
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MASTERS; m++) begin
            gnt_o[m]   = (grant_idx == m) && slave_req_o;
            rdata_o[m] = slave_rdata_i;
        end
        slave_we_o    = we_i[grant_idx];
        slave_be_o    = be_i[grant_idx];
        slave_addr_o  = addr_i[grant_idx];
        slave_wdata_o = wdata_i[grant_idx];
    end

endmodule
