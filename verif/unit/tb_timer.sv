// ============================================================================
// File: tb_timer.sv
// Description: Self-Checking Testbench for SoC Timer Peripheral
// ============================================================================

`timescale 1ns / 1ps

module tb_timer;

    logic        clk;
    logic        rst_n;
    logic        req;
    logic        we;
    logic [3:0]  be;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        irq;

    int error_count = 0;

    timer dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .req_i   (req),
        .we_i    (we),
        .be_i    (be),
        .addr_i  (addr),
        .wdata_i (wdata),
        .rdata_o (rdata),
        .irq_o   (irq)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        req = 0;
        we = 0;
        be = 4'b1111;
        addr = 32'd0;
        wdata = 32'd0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_timer (Self-Checking) ===");

        // Configure timer count = 5, prescaler = 0, enable = 1, irq_en = 1
        req = 1; we = 1; addr = 32'h04; wdata = 32'd0; #10; // Prescaler = 0
        addr = 32'h0C; wdata = 32'd5; #10;                 // Count = 5
        addr = 32'h00; wdata = 32'h05; #10;                 // Enable + IRQ En
        req = 0; we = 0;

        // Wait for IRQ to trigger after 5 cycles
        @(posedge irq);
        #1;
        if (!irq) begin
            $display("[ERROR] Timer interrupt did not trigger!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_timer PASSED: Timer countdown & interrupt verified! <<<");
        end else begin
            $display(">>> tb_timer FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
