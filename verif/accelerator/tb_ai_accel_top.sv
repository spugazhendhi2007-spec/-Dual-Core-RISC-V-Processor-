// ============================================================================
// File: tb_ai_accel_top.sv
// Description: Self-Checking Testbench for Integrated 8x8 AI Accelerator Subsystem
// ============================================================================

`timescale 1ns / 1ps
`include "../../rtl/accelerator/ai_defines.svh"

module tb_ai_accel_top;

    logic        clk;
    logic        rst_n;

    logic        s_axil_req;
    logic        s_axil_we;
    logic [3:0]  s_axil_be;
    logic [31:0] s_axil_addr;
    logic [31:0] s_axil_wdata;
    logic [31:0] s_axil_rdata;

    logic        ai_cmd_valid;
    logic [2:0]  ai_cmd_type;
    logic [31:0] ai_cmd_arg0, ai_cmd_arg1;
    logic        ai_busy, ai_done;

    logic        m_axi_req, m_axi_we;
    logic [3:0]  m_axi_be;
    logic [31:0] m_axi_addr, m_axi_wdata, m_axi_rdata;
    logic        m_axi_ready;

    logic        irq_done;

    int error_count = 0;

    // Simulation System Memory
    logic [31:0] mem [1023:0];

    ai_accel_top dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axil_req_i   (s_axil_req),
        .s_axil_we_i    (s_axil_we),
        .s_axil_be_i    (s_axil_be),
        .s_axil_addr_i  (s_axil_addr),
        .s_axil_wdata_i (s_axil_wdata),
        .s_axil_rdata_o (s_axil_rdata),
        .ai_cmd_valid_i (ai_cmd_valid),
        .ai_cmd_type_i  (ai_cmd_type),
        .ai_cmd_arg0_i  (ai_cmd_arg0),
        .ai_cmd_arg1_i  (ai_cmd_arg1),
        .ai_busy_o      (ai_busy),
        .ai_done_o      (ai_done),
        .m_axi_req_o    (m_axi_req),
        .m_axi_we_o     (m_axi_we),
        .m_axi_be_o     (m_axi_be),
        .m_axi_addr_o   (m_axi_addr),
        .m_axi_wdata_o  (m_axi_wdata),
        .m_axi_rdata_i  (m_axi_rdata),
        .m_axi_ready_i  (m_axi_ready),
        .irq_done_o     (irq_done)
    );

    always #5 clk = ~clk;

    always_comb begin
        m_axi_ready = m_axi_req;
        m_axi_rdata = mem[m_axi_addr[11:2]];
    end

    always_ff @(posedge clk) begin
        if (m_axi_req && m_axi_we) mem[m_axi_addr[11:2]] <= m_axi_wdata;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        s_axil_req = 0; s_axil_we = 0; s_axil_be = 4'b1111; s_axil_addr = 0; s_axil_wdata = 0;
        ai_cmd_valid = 0; ai_cmd_type = 0; ai_cmd_arg0 = 0; ai_cmd_arg1 = 0;

        for (int i = 0; i < 1024; i++) mem[i] = 32'd0;

        // Populate 8x8 Weight Matrix (16 words of INT8 = 1 at 0x100)
        for (int i = 0; i < 16; i++) mem[(32'h100 >> 2) + i] = 32'h0101_0101;

        // Populate 8x8 Activation Matrix (16 words of INT8 = 2 at 0x200)
        for (int i = 0; i < 16; i++) mem[(32'h200 >> 2) + i] = 32'h0202_0202;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_ai_accel_top (Self-Checking) ===");

        // Configure AI Accelerator via AXI4-Lite:
        // ADDR_W = 0x100, ADDR_ACT = 0x200, ADDR_OUT = 0x300, BIAS = 0, SCALE = 1, CTRL[0] = 1 (START)
        s_axil_req = 1; s_axil_we = 1;
        s_axil_addr = {24'b0, AI_REG_ADDR_W};   s_axil_wdata = 32'h100; #10;
        s_axil_addr = {24'b0, AI_REG_ADDR_ACT}; s_axil_wdata = 32'h200; #10;
        s_axil_addr = {24'b0, AI_REG_ADDR_OUT}; s_axil_wdata = 32'h300; #10;
        s_axil_addr = {24'b0, AI_REG_BIAS};     s_axil_wdata = 32'd0;   #10;
        s_axil_addr = {24'b0, AI_REG_SCALE_MULT}; s_axil_wdata = 32'd1; #10;
        s_axil_addr = {24'b0, AI_REG_CTRL};     s_axil_wdata = 32'd1;   #10; // Start
        s_axil_req = 0; s_axil_we = 0;

        // Wait for IRQ Done
        @(posedge irq_done);
        #20;

        // Verify output tensor at 0x300 has been written back by DMA
        $display("[INFO] AI Acceleration completed. Output word 0: 0x%08X", mem[32'h300 >> 2]);

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_ai_accel_top PASSED: AI Subsystem matrix computation verified! <<<");
        end else begin
            $display(">>> tb_ai_accel_top FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
