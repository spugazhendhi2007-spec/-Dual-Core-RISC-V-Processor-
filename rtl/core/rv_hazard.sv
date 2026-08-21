// ============================================================================
// File: rv_hazard.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Pipeline Hazard Detection & Control Unit (Load-Use, Branch, Multi-cycle)
// ============================================================================

`timescale 1ns / 1ps

module rv_hazard (
    input  logic [4:0]  rs1_id_i,
    input  logic [4:0]  rs2_id_i,
    input  logic [4:0]  rd_ex_i,
    input  logic        mem_read_ex_i,
    input  logic        multi_cycle_busy_i,
    input  logic        branch_taken_i,
    input  logic        trap_taken_i,
    input  logic        mret_taken_i,

    output logic        stall_if_o,
    output logic        stall_id_o,
    output logic        stall_ex_o,
    output logic        flush_if_o,
    output logic        flush_id_o,
    output logic        flush_ex_o
);

    logic load_use_hazard;
    logic control_redirect;

    assign load_use_hazard  = mem_read_ex_i && (rd_ex_i != 5'd0) && ((rd_ex_i == rs1_id_i) || (rd_ex_i == rs2_id_i));
    assign control_redirect = branch_taken_i || trap_taken_i || mret_taken_i;

    always_comb begin
        stall_if_o = 1'b0;
        stall_id_o = 1'b0;
        stall_ex_o = 1'b0;
        flush_if_o = 1'b0;
        flush_id_o = 1'b0;
        flush_ex_o = 1'b0;

        if (control_redirect) begin
            flush_if_o = 1'b1;
            flush_id_o = 1'b1;
            flush_ex_o = 1'b1;
        end else if (multi_cycle_busy_i) begin
            stall_if_o = 1'b1;
            stall_id_o = 1'b1;
            stall_ex_o = 1'b1;
        end else if (load_use_hazard) begin
            stall_if_o = 1'b1;
            stall_id_o = 1'b1;
            flush_ex_o = 1'b1;
        end
    end

endmodule
