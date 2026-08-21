// ============================================================================
// File: rv_forwarding.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Data Forwarding Unit (EX-to-EX, MEM-to-EX Bypassing Paths)
// ============================================================================

`timescale 1ns / 1ps

module rv_forwarding (
    input  logic [4:0]  rs1_ex_i,
    input  logic [4:0]  rs2_ex_i,
    input  logic [4:0]  rd_mem_i,
    input  logic        reg_write_mem_i,
    input  logic [4:0]  rd_wb_i,
    input  logic        reg_write_wb_i,

    output logic [1:0]  forward_a_o,
    output logic [1:0]  forward_b_o
);

    always_comb begin
        // Forwarding for Operand A
        if (reg_write_mem_i && (rd_mem_i != 5'd0) && (rd_mem_i == rs1_ex_i)) begin
            forward_a_o = 2'b01; // Forward from MEM stage
        end else if (reg_write_wb_i && (rd_wb_i != 5'd0) && (rd_wb_i == rs1_ex_i)) begin
            forward_a_o = 2'b10; // Forward from WB stage
        end else begin
            forward_a_o = 2'b00; // No forwarding
        end

        // Forwarding for Operand B
        if (reg_write_mem_i && (rd_mem_i != 5'd0) && (rd_mem_i == rs2_ex_i)) begin
            forward_b_o = 2'b01; // Forward from MEM stage
        end else if (reg_write_wb_i && (rd_wb_i != 5'd0) && (rd_wb_i == rs2_ex_i)) begin
            forward_b_o = 2'b10; // Forward from WB stage
        end else begin
            forward_b_o = 2'b00; // No forwarding
        end
    end

endmodule
