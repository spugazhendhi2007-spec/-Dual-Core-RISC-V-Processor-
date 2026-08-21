// ============================================================================
// File: tb_hazard.sv
// Description: Self-Checking Testbench for Pipeline Hazard Unit
// ============================================================================

`timescale 1ns / 1ps

module tb_hazard;

    logic [4:0] rs1_id, rs2_id, rd_ex;
    logic       mem_read_ex, multi_cycle_busy;
    logic       branch_taken, trap_taken, mret_taken;
    logic       stall_if, stall_id, stall_ex;
    logic       flush_if, flush_id, flush_ex;

    int error_count = 0;

    rv_hazard dut (
        .rs1_id_i           (rs1_id),
        .rs2_id_i           (rs2_id),
        .rd_ex_i            (rd_ex),
        .mem_read_ex_i      (mem_read_ex),
        .multi_cycle_busy_i (multi_cycle_busy),
        .branch_taken_i     (branch_taken),
        .trap_taken_i       (trap_taken),
        .mret_taken_i       (mret_taken),
        .stall_if_o         (stall_if),
        .stall_id_o         (stall_id),
        .stall_ex_o         (stall_ex),
        .flush_if_o         (flush_if),
        .flush_id_o         (flush_id),
        .flush_ex_o         (flush_ex)
    );

    initial begin
        $display("=== Starting tb_hazard (Self-Checking) ===");

        // Test 1: Load-Use Data Hazard -> Stall IF/ID, Flush EX
        rs1_id = 5'd3; rs2_id = 5'd4; rd_ex = 5'd3; mem_read_ex = 1;
        multi_cycle_busy = 0; branch_taken = 0; trap_taken = 0; mret_taken = 0; #10;
        if (!stall_if || !stall_id || !flush_ex) begin
            $display("[ERROR] Load-use hazard detection failed!");
            error_count++;
        end

        // Test 2: Branch Taken -> Flush IF, ID, EX
        mem_read_ex = 0; branch_taken = 1; #10;
        if (!flush_if || !flush_id || !flush_ex) begin
            $display("[ERROR] Branch flush failed!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_hazard PASSED: Hazard detection verified! <<<");
        end else begin
            $display(">>> tb_hazard FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
