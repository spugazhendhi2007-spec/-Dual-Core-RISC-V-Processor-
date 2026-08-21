// ============================================================================
// File: tb_regfile.sv
// Description: Self-Checking Testbench for 32x32 Register File (x0 hardwired zero, 2R/1W)
// ============================================================================

`timescale 1ns / 1ps

module tb_regfile;

    logic        clk;
    logic        rst_n;
    logic [4:0]  raddr1;
    logic [31:0] rdata1;
    logic [4:0]  raddr2;
    logic [31:0] rdata2;
    logic        we;
    logic [4:0]  waddr;
    logic [31:0] wdata;

    int error_count = 0;

    rv_regfile dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .raddr1_i (raddr1),
        .rdata1_o (rdata1),
        .raddr2_i (raddr2),
        .rdata2_o (rdata2),
        .we_i     (we),
        .waddr_i  (waddr),
        .wdata_i  (wdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        raddr1 = 0;
        raddr2 = 0;
        we = 0;
        waddr = 0;
        wdata = 0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_regfile (Self-Checking) ===");

        // Test 1: Verify x0 is strictly 0 and cannot be overwritten
        we = 1; waddr = 5'd0; wdata = 32'hDEAD_BEEF; #10;
        we = 0; raddr1 = 5'd0; #10;
        if (rdata1 !== 32'd0) begin
            $display("[ERROR] x0 was modified to 0x%08X! Must be 0.", rdata1);
            error_count++;
        end

        // Test 2: Write all registers x1..x31 and read back
        for (int i = 1; i < 32; i++) begin
            we = 1; waddr = i[4:0]; wdata = 32'h1000_0000 + i; #10;
        end
        we = 0;

        for (int i = 1; i < 32; i++) begin
            raddr1 = i[4:0];
            raddr2 = 32 - i;
            #10;
            if (rdata1 !== (32'h1000_0000 + i)) begin
                $display("[ERROR] Reg x%0d mismatch! Expected 0x%08X, Got 0x%08X", i, 32'h1000_0000 + i, rdata1);
                error_count++;
            end
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_regfile PASSED: All 32 registers verified successfully! <<<");
        end else begin
            $display(">>> tb_regfile FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
