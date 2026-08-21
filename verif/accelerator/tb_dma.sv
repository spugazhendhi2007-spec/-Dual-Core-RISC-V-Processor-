// ============================================================================
// File: tb_dma.sv
// Description: Self-Checking Testbench for 2D Tensor DMA Engine
// ============================================================================

`timescale 1ns / 1ps

module tb_dma;

    logic        clk;
    logic        rst_n;

    logic        start;
    logic        dir;
    logic [31:0] src_addr;
    logic [31:0] dst_addr;
    logic [15:0] row_length;
    logic [15:0] row_count;
    logic [15:0] src_stride;
    logic [15:0] dst_stride;
    logic        busy;
    logic        done;

    logic        m_axi_req;
    logic        m_axi_we;
    logic [3:0]  m_axi_be;
    logic [31:0] m_axi_addr;
    logic [31:0] m_axi_wdata;
    logic [31:0] m_axi_rdata;
    logic        m_axi_ready;

    logic        buf_en;
    logic        buf_we;
    logic [3:0]  buf_be;
    logic [8:0]  buf_addr;
    logic [31:0] buf_wdata;
    logic [31:0] buf_rdata;

    int error_count = 0;

    // Simulation Memory & Local Buffer Model
    logic [31:0] sys_mem [255:0];
    logic [31:0] loc_buf [511:0];

    ai_dma dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start_i       (start),
        .dir_i         (dir),
        .src_addr_i    (src_addr),
        .dst_addr_i    (dst_addr),
        .row_length_i  (row_length),
        .row_count_i   (row_count),
        .src_stride_i  (src_stride),
        .dst_stride_i  (dst_stride),
        .busy_o        (busy),
        .done_o        (done),
        .m_axi_req_o   (m_axi_req),
        .m_axi_we_o    (m_axi_we),
        .m_axi_be_o    (m_axi_be),
        .m_axi_addr_o  (m_axi_addr),
        .m_axi_wdata_o (m_axi_wdata),
        .m_axi_rdata_i (m_axi_rdata),
        .m_axi_ready_i (m_axi_ready),
        .buf_en_o      (buf_en),
        .buf_we_o      (buf_we),
        .buf_be_o      (buf_be),
        .buf_addr_o    (buf_addr),
        .buf_wdata_o   (buf_wdata),
        .buf_rdata_i   (buf_rdata)
    );

    always #5 clk = ~clk;

    // Memory / Buffer Responder
    always_comb begin
        m_axi_ready = m_axi_req;
        m_axi_rdata = sys_mem[m_axi_addr[9:2]];
        buf_rdata   = loc_buf[buf_addr];
    end

    always_ff @(posedge clk) begin
        if (m_axi_req && m_axi_we) sys_mem[m_axi_addr[9:2]] <= m_axi_wdata;
        if (buf_en && buf_we)      loc_buf[buf_addr]        <= buf_wdata;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0; dir = 0;
        src_addr = 0; dst_addr = 0;
        row_length = 0; row_count = 0;
        src_stride = 0; dst_stride = 0;

        for (int i = 0; i < 256; i++) sys_mem[i] = 32'hA000_0000 + i;
        for (int i = 0; i < 512; i++) loc_buf[i] = 32'd0;

        #20;
        rst_n = 1;
        #10;

        $display("=== Starting tb_dma (Self-Checking) ===");

        // Transfer 4 words from sys_mem (addr 0x00) to local buffer
        start = 1; dir = 0;
        src_addr = 32'h00; dst_addr = 32'h00;
        row_length = 16'd4; row_count = 16'd1;
        src_stride = 16'd0; dst_stride = 16'd0;
        #10;
        start = 0;

        @(posedge done);
        #10;

        // Verify local buffer received the 4 words
        for (int i = 0; i < 4; i++) begin
            if (loc_buf[i] !== (32'hA000_0000 + i)) begin
                $display("[ERROR] DMA Buffer[%0d] mismatch! Expected 0x%08X, Got 0x%08X", i, 32'hA000_0000 + i, loc_buf[i]);
                error_count++;
            end
        end

        // Summary
        if (error_count == 0) begin
            $display(">>> tb_dma PASSED: 2D DMA transfer verified! <<<");
        end else begin
            $display(">>> tb_dma FAILED with %0d errors! <<<", error_count);
        end
        $finish;
    end

endmodule
