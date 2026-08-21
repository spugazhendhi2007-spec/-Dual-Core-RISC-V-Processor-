// ============================================================================
// File: tb_forwarding.sv
// Description: Self-Checking Testbench for Data Forwarding Unit
// ============================================================================

`timescale 1ns / 1ps

module tb_forwarding;

    logic [4:0] rs1_ex, rs2_ex, rd_mem, rd_wb;
    logic       reg_write_mem, reg_write_wb;
    logic [1:0] forward_a, forward_b;

    int error_count = 0;

    rv_forwarding dut (
        .rs1_ex_i        (rs1_ex),
        .rs2_ex_i        (rs2_ex),
        .rd_mem_i        (rd_mem),
        .reg_write_mem_i (reg_write_mem),
        .rd_wb_i         (rd_wb),
        .reg_write_wb_i  (reg_write_wb),
        .forward_a_o     (forward_a),
        .forward_b_o     (forward_b)
    );

    initial begin
        $display("=== Starting tb_forwarding (Self-Checking) ===");

        // Test 1: MEM to EX Forwarding
        rs1_ex = 5'd5; rs2_ex = 5'd6; rd_mem = 5'd5; reg_write_mem = 1;
        rd_wb = 5'd0; reg_write_wb = 0; #10;
        if (forward_a !== 2'b01 || forward_b !== 2'b00) begin
            $display("[ERROR] MEM->EX forwarding failed!");
            error_count++;
        end

        // Test 2: WB to EX Forwarding
        rd_mem = 5'd0; reg_write_mem = 0;
        rd_wb = 5'd6; reg_write_wb = 1; #10;
        if (forward_a !== 2'b00 || forward_b !== 2'b10) begin
            $display("[ERROR] WB->EX forwarding failed!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_forwarding PASSED: Data forwarding verified! <<<");
        end else begin
            $display(">>> tb_forwarding FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
