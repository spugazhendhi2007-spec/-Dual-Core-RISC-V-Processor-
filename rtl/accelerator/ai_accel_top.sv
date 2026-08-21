// ============================================================================
// File: ai_accel_top.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Complete 8x8 INT8 AI Accelerator ASIC Subsystem (64 PEs, 2D DMA, Post-Proc)
// ============================================================================

`timescale 1ns / 1ps
`include "ai_defines.svh"

module ai_accel_top (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Slave Register Interface (from CPU via Interconnect)
    input  logic        s_axil_req_i,
    input  logic        s_axil_we_i,
    input  logic [3:0]  s_axil_be_i,
    input  logic [31:0] s_axil_addr_i,
    input  logic [31:0] s_axil_wdata_i,
    output logic [31:0] s_axil_rdata_o,

    // Custom RISC-V Instruction Coprocessor Interface
    input  logic        ai_cmd_valid_i,
    input  logic [2:0]  ai_cmd_type_i,
    input  logic [31:0] ai_cmd_arg0_i,
    input  logic [31:0] ai_cmd_arg1_i,
    output logic        ai_busy_o,
    output logic        ai_done_o,

    // AXI4 Master DMA Bus Interface (to System Crossbar)
    output logic        m_axi_req_o,
    output logic        m_axi_we_o,
    output logic [3:0]  m_axi_be_o,
    output logic [31:0] m_axi_addr_o,
    output logic [31:0] m_axi_wdata_o,
    input  logic [31:0] m_axi_rdata_i,
    input  logic        m_axi_ready_i,

    // Interrupt Output
    output logic        irq_done_o
);

    // Internal Controller - Buffer - Systolic Array Wires
    logic        dma_start, dma_dir, dma_busy, dma_done;
    logic [31:0] dma_src_addr, dma_dst_addr;
    logic [15:0] dma_row_len, dma_row_cnt, dma_src_stride, dma_dst_stride;

    logic        dma_buf_en, dma_buf_we;
    logic [3:0]  dma_buf_be;
    logic [8:0]  dma_buf_addr;
    logic [31:0] dma_buf_wdata, dma_buf_rdata;

    // Buffer Compute Signals
    logic        w_buf_compute_en;
    logic [8:0]  w_buf_compute_addr;
    logic [31:0] w_buf_compute_rdata;

    logic        act_buf_compute_en;
    logic [8:0]  act_buf_compute_addr;
    logic [31:0] act_buf_compute_rdata;

    logic        out_buf_compute_en, out_buf_compute_we;
    logic [3:0]  out_buf_compute_be;
    logic [8:0]  out_buf_compute_addr;
    logic [31:0] out_buf_compute_wdata;

    // 8x8 Systolic Signals
    logic [7:0]         load_weight;
    logic signed [7:0]  weight_data [7:0];
    logic signed [7:0]  act_data    [7:0];
    logic signed [31:0] acc_top     [7:0];
    logic               mesh_enable, mesh_clear_acc;
    logic signed [31:0] acc_bottom  [7:0];

    // Post-Processing Signals
    logic signed [31:0] post_bias;
    logic [1:0]         post_act_mode;
    logic signed [15:0] post_scale_mult;
    logic [4:0]         post_scale_shft;
    logic signed [7:0]  post_quant_out [7:0];
    logic               post_valid_out;

    // Controller Instance
    ai_controller u_ctrl (
        .clk                  (clk),
        .rst_n                (rst_n),
        .s_axil_req_i         (s_axil_req_i),
        .s_axil_we_i          (s_axil_we_i),
        .s_axil_be_i          (s_axil_be_i),
        .s_axil_addr_i        (s_axil_addr_i),
        .s_axil_wdata_i       (s_axil_wdata_i),
        .s_axil_rdata_o       (s_axil_rdata_o),
        .ai_cmd_valid_i       (ai_cmd_valid_i),
        .ai_cmd_type_i        (ai_cmd_type_i),
        .ai_cmd_arg0_i        (ai_cmd_arg0_i),
        .ai_cmd_arg1_i        (ai_cmd_arg1_i),
        .ai_busy_o            (ai_busy_o),
        .ai_done_o            (ai_done_o),
        .dma_start_o          (dma_start),
        .dma_dir_o            (dma_dir),
        .dma_src_addr_o       (dma_src_addr),
        .dma_dst_addr_o       (dma_dst_addr),
        .dma_row_len_o        (dma_row_len),
        .dma_row_cnt_o        (dma_row_cnt),
        .dma_src_stride_o     (dma_src_stride),
        .dma_dst_stride_o     (dma_dst_stride),
        .dma_busy_i           (dma_busy),
        .dma_done_i           (dma_done),
        .w_buf_compute_en_o   (w_buf_compute_en),
        .w_buf_compute_addr_o (w_buf_compute_addr),
        .w_buf_compute_rdata_i(w_buf_compute_rdata),
        .act_buf_compute_en_o (act_buf_compute_en),
        .act_buf_compute_addr_o(act_buf_compute_addr),
        .act_buf_compute_rdata_i(act_buf_compute_rdata),
        .out_buf_compute_en_o (out_buf_compute_en),
        .out_buf_compute_we_o (out_buf_compute_we),
        .out_buf_compute_be_o (out_buf_compute_be),
        .out_buf_compute_addr_o(out_buf_compute_addr),
        .out_buf_compute_wdata_o(out_buf_compute_wdata),
        .load_weight_o        (load_weight),
        .weight_data_o        (weight_data),
        .act_data_o           (act_data),
        .acc_top_o            (acc_top),
        .mesh_enable_o        (mesh_enable),
        .mesh_clear_acc_o     (mesh_clear_acc),
        .acc_bottom_i         (acc_bottom),
        .post_bias_o          (post_bias),
        .post_act_mode_o      (post_act_mode),
        .post_scale_mult_o    (post_scale_mult),
        .post_scale_shft_o    (post_scale_shft),
        .irq_done_o           (irq_done_o)
    );

    // Buffers (2 KB each)
    logic [31:0] sp_w_dma_rdata, sp_act_dma_rdata, sp_out_dma_rdata;

    ai_weight_buffer u_weight_buf (
        .clk       (clk),
        .en_a_i    (dma_buf_en && !dma_dir),
        .we_a_i    (dma_buf_we && !dma_dir),
        .be_a_i    (dma_buf_be),
        .addr_a_i  (dma_buf_addr),
        .wdata_a_i (dma_buf_wdata),
        .rdata_a_o (sp_w_dma_rdata),
        .en_b_i    (w_buf_compute_en),
        .we_b_i    (1'b0),
        .be_b_i    (4'b0000),
        .addr_b_i  (w_buf_compute_addr),
        .wdata_b_i (32'd0),
        .rdata_b_o (w_buf_compute_rdata)
    );

    ai_input_buffer u_act_buf (
        .clk       (clk),
        .en_a_i    (dma_buf_en && !dma_dir),
        .we_a_i    (dma_buf_we && !dma_dir),
        .be_a_i    (dma_buf_be),
        .addr_a_i  (dma_buf_addr),
        .wdata_a_i (dma_buf_wdata),
        .rdata_a_o (sp_act_dma_rdata),
        .en_b_i    (act_buf_compute_en),
        .we_b_i    (1'b0),
        .be_b_i    (4'b0000),
        .addr_b_i  (act_buf_compute_addr),
        .wdata_b_i (32'd0),
        .rdata_b_o (act_buf_compute_rdata)
    );

    ai_output_buffer u_out_buf (
        .clk       (clk),
        .en_a_i    (dma_buf_en && dma_dir),
        .we_a_i    (1'b0),
        .be_a_i    (4'b0000),
        .addr_a_i  (dma_buf_addr),
        .wdata_a_i (32'd0),
        .rdata_a_o (sp_out_dma_rdata),
        .en_b_i    (out_buf_compute_en),
        .we_b_i    (out_buf_compute_we),
        .be_b_i    (out_buf_compute_be),
        .addr_b_i  (out_buf_compute_addr),
        .wdata_b_i (out_buf_compute_wdata),
        .rdata_b_o ()
    );

    assign dma_buf_rdata = dma_dir ? sp_out_dma_rdata : 32'd0;

    // 8x8 Systolic Array Instance (64 PEs)
    ai_systolic_array #(
        .ROWS (8),
        .COLS (8)
    ) u_systolic_array (
        .clk           (clk),
        .rst_n         (rst_n),
        .load_weight_i (load_weight),
        .weight_in_i   (weight_data),
        .act_in_i      (act_data),
        .acc_in_i      (acc_top),
        .enable_i      (mesh_enable),
        .clear_acc_i   (mesh_clear_acc),
        .acc_out_o     (acc_bottom)
    );

    // Multi-Lane Post-Processor Instance
    ai_post_process #(
        .LANES (8)
    ) u_post_proc (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_i       (mesh_enable),
        .acc_in_i      (acc_bottom),
        .bias_i        (post_bias),
        .act_mode_i    (post_act_mode),
        .scale_mult_i  (post_scale_mult),
        .scale_shift_i (post_scale_shft),
        .data_out_o    (post_quant_out),
        .valid_o       (post_valid_out)
    );

    // 2D DMA Engine Instance
    ai_dma u_dma (
        .clk           (clk),
        .rst_n         (rst_n),
        .start_i       (dma_start),
        .dir_i         (dma_dir),
        .src_addr_i    (dma_src_addr),
        .dst_addr_i    (dma_dst_addr),
        .row_length_i  (dma_row_len),
        .row_count_i   (dma_row_cnt),
        .src_stride_i  (dma_src_stride),
        .dst_stride_i  (dma_dst_stride),
        .busy_o        (dma_busy),
        .done_o        (dma_done),
        .m_axi_req_o   (m_axi_req_o),
        .m_axi_we_o    (m_axi_we_o),
        .m_axi_be_o    (m_axi_be_o),
        .m_axi_addr_o  (m_axi_addr_o),
        .m_axi_wdata_o (m_axi_wdata_o),
        .m_axi_rdata_i (m_axi_rdata_i),
        .m_axi_ready_i (m_axi_ready_i),
        .buf_en_o      (dma_buf_en),
        .buf_we_o      (dma_buf_we),
        .buf_be_o      (dma_buf_be),
        .buf_addr_o    (dma_buf_addr),
        .buf_wdata_o   (dma_buf_wdata),
        .buf_rdata_i   (dma_buf_rdata)
    );

endmodule
