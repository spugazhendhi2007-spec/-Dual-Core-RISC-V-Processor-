// ============================================================================
// File: tb_systolic_array.sv
// Description: Self-Checking Testbench for 8x8 Systolic Array (64 PEs)
// ============================================================================

`timescale 1ns / 1ps

module tb_systolic_array;

    logic        clk;
    logic        rst_n;
    logic [7:0]         load_weight;
    logic signed [7:0]  weight_in [7:0];
    logic signed [7:0]  act_in    [7:0];
    logic signed [31:0] acc_in    [7:0];
    logic               enable;
    logic               clear_acc;
    logic signed [31:0] acc_out   [7:0];

    int error_count = 0;

    ai_systolic_array #(
        .ROWS (8),
        .COLS (8)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .load_weight_i (load_weight),
        .weight_in_i   (weight_in),
        .act_in_i      (act_in),
        .acc_in_i      (acc_in),
        .enable_i      (enable),
        .clear_acc_i   (clear_acc),
        .acc_out_o     (acc_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        load_weight = 8'd0;
        enable = 0;
        clear_acc = 0;

        for (int i = 0; i < 8; i++) begin
            weight_in[i] = 8'sd0;
            act_in[i]    = 8'sd0;
            acc_in[i]    = 32'sd0;
        end

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_systolic_array (Self-Checking) ===");

        // 1. Load Weights into Column 0: All PEs in Column 0 get weight = 2
        for (int step = 0; step < 8; step++) begin
            load_weight = 8'b0000_0001;
            weight_in[0] = 8'sd2;
            #10;
        end
        load_weight = 8'd0;

        // 2. Feed Activation = 3 into Row 0, clear accumulator
        clear_acc = 1; #10; clear_acc = 0;

        enable = 1;
        act_in[0] = 8'sd3; #10;
        act_in[0] = 8'sd0;

        // Propagate down the 8 rows
        #100;
        enable = 0;

        // PE[0,0] produced 3 * 2 = 6, which propagated down to acc_out[0]
        if (acc_out[0] !== 32'sd6) begin
            $display("[ERROR] Systolic Array column 0 output mismatch! Expected 6, Got %0d", acc_out[0]);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_systolic_array PASSED: 8x8 (64 PEs) Systolic Array verified! <<<");
        end else begin
            $display(">>> tb_systolic_array FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
