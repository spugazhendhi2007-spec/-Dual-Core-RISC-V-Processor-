// ============================================================================
// File: rv_fetch.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Instruction Fetch Unit (PC Generation, Branch/Trap Redirection)
// ============================================================================

`timescale 1ns / 1ps

module rv_fetch #(
    parameter logic [31:0] RESET_VEC = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall_i,
    input  logic        flush_i,

    // Control Flow Redirects
    input  logic        branch_taken_i,
    input  logic [31:0] branch_target_i,
    input  logic        trap_taken_i,
    input  logic [31:0] trap_target_i,
    input  logic        mret_taken_i,
    input  logic [31:0] mepc_i,

    // Instruction Memory Interface
    output logic        instr_req_o,
    output logic [31:0] instr_addr_o,

    // Pipeline Outputs to IF/ID Register
    output logic [31:0] pc_o,
    output logic [31:0] pc_plus4_o
);

    logic [31:0] pc_q, pc_next;

    assign pc_plus4_o = pc_q + 32'd4;

    // Target Selection Priority: Trap > MRET > Branch > Sequential PC+4
    always_comb begin
        if (trap_taken_i) begin
            pc_next = trap_target_i;
        end else if (mret_taken_i) begin
            pc_next = mepc_i;
        end else if (branch_taken_i) begin
            pc_next = branch_target_i;
        end else begin
            pc_next = pc_plus4_o;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_q <= RESET_VEC;
        end else if (!stall_i) begin
            pc_q <= pc_next;
        end
    end

    assign pc_o         = pc_q;
    assign instr_addr_o = pc_q;
    assign instr_req_o  = !stall_i;

endmodule
