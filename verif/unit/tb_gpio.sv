// ============================================================================
// File: tb_gpio.sv
// Description: Self-Checking Testbench for GPIO Peripheral
// ============================================================================

`timescale 1ns / 1ps

module tb_gpio;

    logic        clk;
    logic        rst_n;
    logic        req;
    logic        we;
    logic [3:0]  be;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic [15:0] gpio_in;
    logic [15:0] gpio_out;
    logic [15:0] gpio_oe;
    logic        irq;

    int error_count = 0;

    gpio dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .req_i      (req),
        .we_i       (we),
        .be_i       (be),
        .addr_i     (addr),
        .wdata_i    (wdata),
        .rdata_o    (rdata),
        .gpio_in_i  (gpio_in),
        .gpio_out_o (gpio_out),
        .gpio_oe_o  (gpio_oe),
        .irq_o      (irq)
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
        gpio_in = 16'h0000;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_gpio (Self-Checking) ===");

        // Test 1: Write Output Data & Direction
        req = 1; we = 1; addr = 32'h00; wdata = 32'h0000_FFFF; #10; // DIR = output
        addr = 32'h04; wdata = 32'h0000_55AA; #10; // OUT = 0x55AA
        req = 0; we = 0; #10;
        if (gpio_out !== 16'h55AA || gpio_oe !== 16'hFFFF) begin
            $display("[ERROR] GPIO output register failed!");
            error_count++;
        end

        // Test 2: Input readback
        gpio_in = 16'h1234; #20;
        req = 1; we = 0; addr = 32'h08; #10;
        if (rdata[15:0] !== 16'h1234) begin
            $display("[ERROR] GPIO input sync read failed! Expected 0x1234, Got 0x%04X", rdata[15:0]);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_gpio PASSED: GPIO inputs/outputs verified! <<<");
        end else begin
            $display(">>> tb_gpio FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
