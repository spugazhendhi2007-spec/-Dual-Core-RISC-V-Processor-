// ============================================================================
// File: rv_reservation_monitor.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Multi-Core LR/SC Hardware Reservation Monitor & Conflict Snooper
// ============================================================================

`timescale 1ns / 1ps
`include "../core/rv_defines.svh"

module rv_reservation_monitor (
    input  logic        clk,
    input  logic        rst_n,

    // Core 0 Interface
    input  logic        c0_req_i,
    input  logic        c0_we_i,
    input  logic [31:0] c0_addr_i,
    input  logic        c0_atomic_req_i,
    input  logic [4:0]  c0_atomic_op_i,
    output logic        c0_sc_success_o,

    // Core 1 Interface
    input  logic        c1_req_i,
    input  logic        c1_we_i,
    input  logic [31:0] c1_addr_i,
    input  logic        c1_atomic_req_i,
    input  logic [4:0]  c1_atomic_op_i,
    output logic        c1_sc_success_o
);

    logic [31:0] c0_res_addr;
    logic        c0_res_valid;

    logic [31:0] c1_res_addr;
    logic        c1_res_valid;

    assign c0_sc_success_o = c0_res_valid && (c0_addr_i == c0_res_addr);
    assign c1_sc_success_o = c1_res_valid && (c1_addr_i == c1_res_addr);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c0_res_valid <= 1'b0;
            c0_res_addr  <= 32'd0;
            c1_res_valid <= 1'b0;
            c1_res_addr  <= 32'd0;
        end else begin
            // Core 0 Reservation Updates
            if (c0_atomic_req_i && (c0_atomic_op_i == AMO_LR)) begin
                c0_res_valid <= 1'b1;
                c0_res_addr  <= c0_addr_i;
            end else if ((c0_atomic_req_i && (c0_atomic_op_i == AMO_SC)) ||
                         (c1_req_i && c1_we_i && (c1_addr_i == c0_res_addr))) begin
                c0_res_valid <= 1'b0; // Invalidate on SC or external conflicting store
            end

            // Core 1 Reservation Updates
            if (c1_atomic_req_i && (c1_atomic_op_i == AMO_LR)) begin
                c1_res_valid <= 1'b1;
                c1_res_addr  <= c1_addr_i;
            end else if ((c1_atomic_req_i && (c1_atomic_op_i == AMO_SC)) ||
                         (c0_req_i && c0_we_i && (c0_addr_i == c1_res_addr))) begin
                c1_res_valid <= 1'b0; // Invalidate on SC or external conflicting store
            end
        end
    end

endmodule
