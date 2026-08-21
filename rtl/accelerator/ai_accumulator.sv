// ============================================================================
// File: ai_accumulator.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 8-Lane Parallel INT32 Output Accumulator & Staging Register
// ============================================================================

`timescale 1ns / 1ps

module ai_accumulator #(
    parameter int LANES = 8
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic                   enable_i,
    input  logic                   clear_i,
    input  logic signed [31:0]     data_in_i [LANES-1:0],

    output logic signed [31:0]     accum_out_o [LANES-1:0],
    output logic                   valid_o
);

    logic signed [31:0] acc_regs [LANES-1:0];
    logic               valid_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < LANES; i++) begin
                acc_regs[i] <= 32'sd0;
            end
            valid_reg <= 1'b0;
        end else begin
            if (clear_i) begin
                for (int i = 0; i < LANES; i++) begin
                    acc_regs[i] <= 32'sd0;
                end
                valid_reg <= 1'b0;
            end else if (enable_i) begin
                for (int i = 0; i < LANES; i++) begin
                    acc_regs[i] <= acc_regs[i] + data_in_i[i];
                end
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

    assign accum_out_o = acc_regs;
    assign valid_o     = valid_reg;

endmodule
