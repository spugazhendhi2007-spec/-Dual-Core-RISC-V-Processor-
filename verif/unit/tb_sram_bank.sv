// ============================================================================
// File: tb_sram_bank.sv
// Description: Self-Checking Testbench for 16 KB SRAM Bank
// ============================================================================

`timescale 1ns / 1ps

module tb_sram_bank;

    logic        clk;
    logic        en;
    logic        we;
    logic [3:0]  be;
    logic [11:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    int error_count = 0;

    sram_bank #(
        .DEPTH_WORDS (4096),
        .ADDR_WIDTH  (12)
    ) dut (
        .clk     (clk),
        .en_i    (en),
        .we_i    (we),
        .be_i    (be),
        .addr_i  (addr),
        .wdata_i (wdata),
        .rdata_o (rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        en = 0;
        we = 0;
        be = 4'b0000;
        addr = 12'd0;
        wdata = 32'd0;

        #20;
        $display("=== Starting tb_sram_bank (Self-Checking) ===");

        // Test 1: Full word write & read
        en = 1; we = 1; be = 4'b1111; addr = 12'h100; wdata = 32'hA1B2_C3D4; #10;
        we = 0; be = 4'b0000; #10;
        if (rdata !== 32'hA1B2_C3D4) begin
            $display("[ERROR] Full word read failed! Expected 0xA1B2C3D4, Got 0x%08X", rdata);
            error_count++;
        end

        // Test 2: Byte-lane partial write (modify upper byte only)
        we = 1; be = 4'b1000; wdata = 32'hFF00_0000; #10;
        we = 0; be = 4'b0000; #10;
        if (rdata !== 32'hFFB2_C3D4) begin
            $display("[ERROR] Byte lane write failed! Expected 0xFFB2C3D4, Got 0x%08X", rdata);
            error_count++;
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_sram_bank PASSED: SRAM banking & byte-lanes verified! <<<");
        end else begin
            $display(">>> tb_sram_bank FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
