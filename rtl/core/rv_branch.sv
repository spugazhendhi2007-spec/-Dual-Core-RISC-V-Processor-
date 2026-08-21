// ============================================================================
// File: rv_branch.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Branch Condition Comparator & Target Address Calculation Unit
// ============================================================================

`timescale 1ns / 1ps

module rv_branch (
    input  logic [2:0]  branch_type_i,
    input  logic        is_branch_i,
    input  logic        is_jal_i,
    input  logic        is_jalr_i,
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] imm_i,

    output logic        branch_taken_o,
    output logic [31:0] branch_target_o
);

    logic eq, lt, ltu;

    assign eq  = (op_a_i == op_b_i);
    assign lt  = ($signed(op_a_i) < $signed(op_b_i));
    assign ltu = (op_a_i < op_b_i);

    always_comb begin
        branch_taken_o = 1'b0;
        if (is_jal_i || is_jalr_i) begin
            branch_taken_o = 1'b1;
        end else if (is_branch_i) begin
            case (branch_type_i)
                3'b000: branch_taken_o = eq;        // BEQ
                3'b001: branch_taken_o = !eq;       // BNE
                3'b100: branch_taken_o = lt;        // BLT
                3'b101: branch_taken_o = !lt;       // BGE
                3'b110: branch_taken_o = ltu;       // BLTU
                3'b111: branch_taken_o = !ltu;      // BGEU
                default: branch_taken_o = 1'b0;
            endcase
        end
    end

    always_comb begin
        if (is_jalr_i) begin
            branch_target_o = (op_a_i + imm_i) & ~32'd1;
        end else begin
            branch_target_o = pc_i + imm_i;
        end
    end

endmodule
