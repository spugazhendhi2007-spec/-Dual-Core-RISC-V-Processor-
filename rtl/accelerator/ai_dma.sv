// ============================================================================
// File: ai_dma.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Programmable 2D Burst Direct Memory Access (DMA) Engine for Tensors
// ============================================================================

`timescale 1ns / 1ps

module ai_dma (
    input  logic        clk,
    input  logic        rst_n,

    // Command Interface
    input  logic        start_i,
    input  logic        dir_i, // 0: Mem -> Accel Buffer, 1: Accel Buffer -> Mem
    input  logic [31:0] src_addr_i,
    input  logic [31:0] dst_addr_i,
    input  logic [15:0] row_length_i, // in words
    input  logic [15:0] row_count_i,
    input  logic [15:0] src_stride_i,
    input  logic [15:0] dst_stride_i,
    output logic        busy_o,
    output logic        done_o,

    // AXI4 Master Interface
    output logic        m_axi_req_o,
    output logic        m_axi_we_o,
    output logic [3:0]  m_axi_be_o,
    output logic [31:0] m_axi_addr_o,
    output logic [31:0] m_axi_wdata_o,
    input  logic [31:0] m_axi_rdata_i,
    input  logic        m_axi_ready_i,

    // Local Accelerator Buffer Interface
    output logic        buf_en_o,
    output logic        buf_we_o,
    output logic [3:0]  buf_be_o,
    output logic [8:0]  buf_addr_o,
    output logic [31:0] buf_wdata_o,
    input  logic [31:0] buf_rdata_i
);

    typedef enum logic [2:0] {
        DMA_IDLE,
        DMA_READ_EXT_REQ,
        DMA_READ_EXT_WAIT,
        DMA_WRITE_BUF,
        DMA_READ_BUF_REQ,
        DMA_WRITE_EXT_REQ,
        DMA_DONE
    } dma_state_e;

    dma_state_e state;
    logic [31:0] curr_src_addr;
    logic [31:0] curr_dst_addr;
    logic [15:0] words_in_row_left;
    logic [15:0] rows_left;
    logic [8:0]  curr_buf_addr;
    logic [31:0] data_latch;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= DMA_IDLE;
            curr_src_addr      <= 32'd0;
            curr_dst_addr      <= 32'd0;
            words_in_row_left  <= 16'd0;
            rows_left          <= 16'd0;
            curr_buf_addr      <= 9'd0;
            data_latch         <= 32'd0;
            done_o             <= 1'b0;
        end else begin
            done_o <= 1'b0;

            case (state)
                DMA_IDLE: begin
                    if (start_i && (row_length_i != 16'd0) && (row_count_i != 16'd0)) begin
                        curr_src_addr     <= src_addr_i;
                        curr_dst_addr     <= dst_addr_i;
                        words_in_row_left <= row_length_i;
                        rows_left         <= row_count_i;
                        curr_buf_addr     <= 9'd0;
                        if (!dir_i) begin
                            state <= DMA_READ_EXT_REQ;
                        end else begin
                            state <= DMA_READ_BUF_REQ;
                        end
                    end
                end

                DMA_READ_EXT_REQ: begin
                    if (m_axi_ready_i) begin
                        state <= DMA_READ_EXT_WAIT;
                    end
                end

                DMA_READ_EXT_WAIT: begin
                    data_latch <= m_axi_rdata_i;
                    state      <= DMA_WRITE_BUF;
                end

                DMA_WRITE_BUF: begin
                    curr_buf_addr <= curr_buf_addr + 9'd1;
                    curr_src_addr <= curr_src_addr + 32'd4;
                    words_in_row_left <= words_in_row_left - 16'd1;

                    if (words_in_row_left == 16'd1) begin
                        rows_left <= rows_left - 16'd1;
                        if (rows_left == 16'd1) begin
                            state <= DMA_DONE;
                        end else begin
                            words_in_row_left <= row_length_i;
                            curr_src_addr     <= curr_src_addr + {16'b0, src_stride_i};
                            state             <= DMA_READ_EXT_REQ;
                        end
                    end else begin
                        state <= DMA_READ_EXT_REQ;
                    end
                end

                DMA_READ_BUF_REQ: begin
                    state <= DMA_WRITE_EXT_REQ;
                end

                DMA_WRITE_EXT_REQ: begin
                    if (m_axi_ready_i) begin
                        curr_buf_addr <= curr_buf_addr + 9'd1;
                        curr_dst_addr <= curr_dst_addr + 32'd4;
                        words_in_row_left <= words_in_row_left - 16'd1;

                        if (words_in_row_left == 16'd1) begin
                            rows_left <= rows_left - 16'd1;
                            if (rows_left == 16'd1) begin
                                state <= DMA_DONE;
                            end else begin
                                words_in_row_left <= row_length_i;
                                curr_dst_addr     <= curr_dst_addr + {16'b0, dst_stride_i};
                                state             <= DMA_READ_BUF_REQ;
                            end
                        end else begin
                            state <= DMA_READ_BUF_REQ;
                        end
                    end
                end

                DMA_DONE: begin
                    done_o <= 1'b1;
                    state  <= DMA_IDLE;
                end

                default: state <= DMA_IDLE;
            endcase
        end
    end

    // Master Bus Drive
    always_comb begin
        m_axi_req_o   = 1'b0;
        m_axi_we_o    = 1'b0;
        m_axi_be_o    = 4'b1111;
        m_axi_addr_o  = dir_i ? curr_dst_addr : curr_src_addr;
        m_axi_wdata_o = buf_rdata_i;

        if (state == DMA_READ_EXT_REQ) begin
            m_axi_req_o = 1'b1;
            m_axi_we_o  = 1'b0;
        end else if (state == DMA_WRITE_EXT_REQ) begin
            m_axi_req_o = 1'b1;
            m_axi_we_o  = 1'b1;
        end
    end

    // Buffer Drive
    always_comb begin
        buf_en_o    = 1'b0;
        buf_we_o    = 1'b0;
        buf_be_o    = 4'b1111;
        buf_addr_o  = curr_buf_addr;
        buf_wdata_o = data_latch;

        if (state == DMA_WRITE_BUF) begin
            buf_en_o = 1'b1;
            buf_we_o = 1'b1;
        end else if (state == DMA_READ_BUF_REQ) begin
            buf_en_o = 1'b1;
            buf_we_o = 1'b0;
        end
    end

    assign busy_o = (state != DMA_IDLE);

endmodule
