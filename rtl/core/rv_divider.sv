// ============================================================================
// File: rv_divider.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 32-Cycle Iterative Non-Restoring Hardware Divider (DIV, DIVU, REM, REMU)
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_divider (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_i,
    rv_md_op_e          op_i,
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,

    output logic [31:0] result_o,
    output logic        busy_o,
    output logic        done_o
);

    typedef enum logic [1:0] {
        DIV_IDLE,
        DIV_CALC,
        DIV_FINISH
    } div_state_e;

    div_state_e state;
    logic [5:0]  count;
    logic [63:0] dividend_rem;
    logic [31:0] divisor;
    logic        is_signed;
    logic        neg_quotient;
    logic        neg_remainder;
    rv_md_op_e   op_reg;

    assign is_signed = (op_i == MD_DIV) || (op_i == MD_REM);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= DIV_IDLE;
            count         <= 6'd0;
            dividend_rem  <= 64'd0;
            divisor       <= 32'd0;
            op_reg        <= MD_DIV;
            neg_quotient  <= 1'b0;
            neg_remainder <= 1'b0;
            done_o        <= 1'b0;
        end else begin
            done_o <= 1'b0;

            case (state)
                DIV_IDLE: begin
                    if (start_i) begin
                        op_reg        <= op_i;
                        count         <= 6'd32;
                        neg_quotient  <= is_signed && (op_a_i[31] ^ op_b_i[31]) && (op_b_i != 32'd0);
                        neg_remainder <= is_signed && op_a_i[31];

                        // Absolute values
                        dividend_rem <= {32'd0, (is_signed && op_a_i[31]) ? -op_a_i : op_a_i};
                        divisor      <= (is_signed && op_b_i[31]) ? -op_b_i : op_b_i;

                        // Division by Zero Corner Case
                        if (op_b_i == 32'd0) begin
                            state  <= DIV_FINISH;
                        end else begin
                            state  <= DIV_CALC;
                        end
                    end
                end

                DIV_CALC: begin
                    logic [63:0] shifted;
                    shifted = dividend_rem << 1;
                    if (shifted[63:32] >= divisor) begin
                        dividend_rem <= {shifted[63:32] - divisor, shifted[31:1], 1'b1};
                    end else begin
                        dividend_rem <= shifted;
                    end

                    count <= count - 6'd1;
                    if (count == 6'd1) begin
                        state <= DIV_FINISH;
                    end
                end

                DIV_FINISH: begin
                    done_o <= 1'b1;
                    state  <= DIV_IDLE;
                end
            endcase
        end
    end

    // Result Adjustment
    always_comb begin
        logic [31:0] quot_final, rem_final;

        if (divisor == 32'd0) begin
            quot_final = 32'hFFFF_FFFF;
            rem_final  = (op_reg == MD_DIV || op_reg == MD_REM) ? op_a_i : op_a_i;
        end else begin
            quot_final = neg_quotient ? -dividend_rem[31:0] : dividend_rem[31:0];
            rem_final  = neg_remainder ? -dividend_rem[63:32] : dividend_rem[63:32];
        end

        case (op_reg)
            MD_DIV, MD_DIVU: result_o = quot_final;
            MD_REM, MD_REMU: result_o = rem_final;
            default:         result_o = quot_final;
        endcase
    end

    assign busy_o = (state != DIV_IDLE);

endmodule
