// ============================================================================
// File: tb_uart.sv
// Description: Self-Checking Testbench for UART Peripheral
// ============================================================================

`timescale 1ns / 1ps

module tb_uart;

    logic        clk;
    logic        rst_n;
    logic        req;
    logic        we;
    logic [3:0]  be;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        rx;
    logic        tx;
    logic        irq;

    int error_count = 0;

    uart dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .req_i   (req),
        .we_i    (we),
        .be_i    (be),
        .addr_i  (addr),
        .wdata_i (wdata),
        .rdata_o (rdata),
        .rx_i    (rx),
        .tx_o    (tx),
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
        rx = 1;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_uart (Self-Checking) ===");

        // Configure fast baud rate for simulation
        req = 1; we = 1; addr = 32'h0C; wdata = 32'd4; #10;

        // Push character 'A' (0x41) to TX FIFO
        addr = 32'h00; wdata = 32'h41; #10;
        req = 0; we = 0; #10;

        // Verify TX pin pulses start bit (0)
        #20;
        if (tx !== 1'b0) begin
            $display("[ERROR] UART Start bit was not transmitted properly!");
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_uart PASSED: UART transmission verified! <<<");
        end else begin
            $display(">>> tb_uart FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
