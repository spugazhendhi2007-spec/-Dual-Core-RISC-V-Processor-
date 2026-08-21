// ============================================================================
// File: ai_controller.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: AI Sequencing Controller, AXI4-Lite Registers & Custom Instruction Engine
// ============================================================================

`timescale 1ns / 1ps
`include "ai_defines.svh"

module ai_controller (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Slave Register Interface
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

    // DMA Control Interface
    output logic        dma_start_o,
    output logic        dma_dir_o,
    output logic [31:0] dma_src_addr_o,
    output logic [31:0] dma_dst_addr_o,
    output logic [15:0] dma_row_len_o,
    output logic [15:0] dma_row_cnt_o,
    output logic [15:0] dma_src_stride_o,
    output logic [15:0] dma_dst_stride_o,
    input  logic        dma_busy_i,
    input  logic        dma_done_i,

    // Buffer Interfaces
    output logic        w_buf_compute_en_o,
    output logic [8:0]  w_buf_compute_addr_o,
    input  logic [31:0] w_buf_compute_rdata_i,

    output logic        act_buf_compute_en_o,
    output logic [8:0]  act_buf_compute_addr_o,
    input  logic [31:0] act_buf_compute_rdata_i,

    output logic        out_buf_compute_en_o,
    output logic        out_buf_compute_we_o,
    output logic [3:0]  out_buf_compute_be_o,
    output logic [8:0]  out_buf_compute_addr_o,
    output logic [31:0] out_buf_compute_wdata_o,

    // Systolic Array Control (8x8)
    output logic [7:0]         load_weight_o,
    output logic signed [7:0]  weight_data_o [7:0],
    output logic signed [7:0]  act_data_o [7:0],
    output logic signed [31:0] acc_top_o [7:0],
    output logic               mesh_enable_o,
    output logic               mesh_clear_acc_o,
    input  logic signed [31:0] acc_bottom_i [7:0],

    // Post-Processing Signals
    output logic signed [31:0] post_bias_o,
    output logic [1:0]         post_act_mode_o,
    output logic signed [15:0] post_scale_mult_o,
    output logic [4:0]         post_scale_shft_o,

    // Interrupt
    output logic               irq_done_o
);

    // Configuration Registers
    logic [31:0] reg_ctrl;
    logic [31:0] reg_status;
    logic [31:0] reg_dim_m, reg_dim_k, reg_dim_n;
    logic [31:0] reg_addr_w, reg_addr_act, reg_addr_out;
    logic [31:0] reg_bias;
    logic [31:0] reg_scale_mult;
    logic [31:0] reg_scale_shft;
    logic [31:0] reg_act_mode;

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_DMA_LOAD_W,
        ST_DMA_LOAD_ACT,
        ST_LOAD_WEIGHTS,
        ST_COMPUTE,
        ST_DRAIN_POSTPROC,
        ST_DMA_STORE_RES,
        ST_FINISH
    } fsm_state_e;

    fsm_state_e state;
    logic [6:0] step_cnt;
    logic [8:0] out_word_cnt;

    assign post_bias_o       = reg_bias;
    assign post_act_mode_o   = reg_act_mode[1:0];
    assign post_scale_mult_o = reg_scale_mult[15:0];
    assign post_scale_shft_o = reg_scale_shft[4:0];

    // AXI4-Lite Register Read/Write & Custom Instruction Interface
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl       <= 32'd0;
            reg_status     <= 32'd0;
            reg_dim_m      <= 32'd8;
            reg_dim_k      <= 32'd8;
            reg_dim_n      <= 32'd8;
            reg_addr_w     <= 32'h0001_0000;
            reg_addr_act   <= 32'h0001_0100;
            reg_addr_out   <= 32'h0001_0200;
            reg_bias       <= 32'd0;
            reg_scale_mult <= 32'd1;
            reg_scale_shft <= 32'd0;
            reg_act_mode   <= 32'd1; // ReLU
        end else begin
            reg_status[0] <= (state != ST_IDLE);
            if (state == ST_FINISH) begin
                reg_status[1] <= 1'b1;
            end

            // Custom Instruction Dispatch
            if (ai_cmd_valid_i) begin
                if (ai_cmd_type_i == 3'b000) begin // AI_CFG
                    reg_addr_w   <= ai_cmd_arg0_i;
                    reg_addr_act <= ai_cmd_arg1_i;
                end else if (ai_cmd_type_i == 3'b001) begin // AI_START
                    reg_ctrl[0]  <= 1'b1;
                end
            end

            // AXI4-Lite Register Writes
            if (s_axil_req_i && s_axil_we_i) begin
                case (s_axil_addr_i[7:0])
                    AI_REG_CTRL:       reg_ctrl       <= s_axil_wdata_i;
                    AI_REG_STATUS:     reg_status[1]  <= 1'b0;
                    AI_REG_DIM_M:      reg_dim_m      <= s_axil_wdata_i;
                    AI_REG_DIM_K:      reg_dim_k      <= s_axil_wdata_i;
                    AI_REG_DIM_N:      reg_dim_n      <= s_axil_wdata_i;
                    AI_REG_ADDR_W:     reg_addr_w     <= s_axil_wdata_i;
                    AI_REG_ADDR_ACT:   reg_addr_act   <= s_axil_wdata_i;
                    AI_REG_ADDR_OUT:   reg_addr_out   <= s_axil_wdata_i;
                    AI_REG_BIAS:       reg_bias       <= s_axil_wdata_i;
                    AI_REG_SCALE_MULT: reg_scale_mult <= s_axil_wdata_i;
                    AI_REG_SCALE_SHFT: reg_scale_shft <= s_axil_wdata_i;
                    AI_REG_ACT_MODE:   reg_act_mode   <= s_axil_wdata_i;
                    default: ;
                endcase
            end else if (state == ST_FINISH) begin
                reg_ctrl[0] <= 1'b0;
            end
        end
    end

    // AXI4-Lite Register Read
    always_comb begin
        case (s_axil_addr_i[7:0])
            AI_REG_CTRL:       s_axil_rdata_o = reg_ctrl;
            AI_REG_STATUS:     s_axil_rdata_o = reg_status;
            AI_REG_DIM_M:      s_axil_rdata_o = reg_dim_m;
            AI_REG_DIM_K:      s_axil_rdata_o = reg_dim_k;
            AI_REG_DIM_N:      s_axil_rdata_o = reg_dim_n;
            AI_REG_ADDR_W:     s_axil_rdata_o = reg_addr_w;
            AI_REG_ADDR_ACT:   s_axil_rdata_o = reg_addr_act;
            AI_REG_ADDR_OUT:   s_axil_rdata_o = reg_addr_out;
            AI_REG_BIAS:       s_axil_rdata_o = reg_bias;
            AI_REG_SCALE_MULT: s_axil_rdata_o = reg_scale_mult;
            AI_REG_SCALE_SHFT: s_axil_rdata_o = reg_scale_shft;
            AI_REG_ACT_MODE:   s_axil_rdata_o = reg_act_mode;
            default:           s_axil_rdata_o = 32'd0;
        endcase
    end

    // 8x8 Tiling Execution FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_IDLE;
            step_cnt         <= 7'd0;
            out_word_cnt     <= 9'd0;
            irq_done_o       <= 1'b0;
            dma_start_o      <= 1'b0;
            dma_dir_o        <= 1'b0;
            dma_src_addr_o   <= 32'd0;
            dma_dst_addr_o   <= 32'd0;
            dma_row_len_o    <= 16'd0;
            dma_row_cnt_o    <= 16'd0;
            dma_src_stride_o <= 16'd0;
            dma_dst_stride_o <= 16'd0;
            mesh_enable_o    <= 1'b0;
            mesh_clear_acc_o <= 1'b0;
            out_buf_compute_we_o <= 1'b0;
        end else begin
            irq_done_o   <= 1'b0;
            dma_start_o  <= 1'b0;
            out_buf_compute_we_o <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (reg_ctrl[0]) begin
                        step_cnt         <= 7'd0;
                        out_word_cnt     <= 9'd0;
                        // DMA 1: Load Weights (16 words = 64 bytes for 8x8)
                        dma_start_o      <= 1'b1;
                        dma_dir_o        <= 1'b0;
                        dma_src_addr_o   <= reg_addr_w;
                        dma_dst_addr_o   <= 32'd0;
                        dma_row_len_o    <= 16'd16;
                        dma_row_cnt_o    <= 16'd1;
                        dma_src_stride_o <= 16'd0;
                        dma_dst_stride_o <= 16'd0;
                        state            <= ST_DMA_LOAD_W;
                    end
                end

                ST_DMA_LOAD_W: begin
                    if (dma_done_i) begin
                        // DMA 2: Load Activations (16 words = 64 bytes)
                        dma_start_o      <= 1'b1;
                        dma_dir_o        <= 1'b0;
                        dma_src_addr_o   <= reg_addr_act;
                        dma_dst_addr_o   <= 32'd0;
                        dma_row_len_o    <= 16'd16;
                        dma_row_cnt_o    <= 16'd1;
                        dma_src_stride_o <= 16'd0;
                        dma_dst_stride_o <= 16'd0;
                        state            <= ST_DMA_LOAD_ACT;
                    end
                end

                ST_DMA_LOAD_ACT: begin
                    if (dma_done_i) begin
                        step_cnt <= 7'd0;
                        state    <= ST_LOAD_WEIGHTS;
                    end
                end

                ST_LOAD_WEIGHTS: begin
                    step_cnt <= step_cnt + 7'd1;
                    if (step_cnt == 7'd8) begin
                        step_cnt         <= 7'd0;
                        mesh_clear_acc_o <= 1'b1;
                        state            <= ST_COMPUTE;
                    end
                end

                ST_COMPUTE: begin
                    mesh_clear_acc_o <= 1'b0;
                    mesh_enable_o    <= 1'b1;
                    step_cnt         <= step_cnt + 7'd1;
                    if (step_cnt == 7'd16) begin
                        mesh_enable_o <= 1'b0;
                        step_cnt      <= 7'd0;
                        state         <= ST_DRAIN_POSTPROC;
                    end
                end

                ST_DRAIN_POSTPROC: begin
                    out_buf_compute_we_o <= 1'b1;
                    out_word_cnt         <= out_word_cnt + 9'd1;
                    step_cnt             <= step_cnt + 7'd1;
                    if (step_cnt == 7'd15) begin
                        // DMA 3: Write Output Tensor back to Main Memory
                        dma_start_o      <= 1'b1;
                        dma_dir_o        <= 1'b1;
                        dma_src_addr_o   <= 32'd0;
                        dma_dst_addr_o   <= reg_addr_out;
                        dma_row_len_o    <= 16'd16;
                        dma_row_cnt_o    <= 16'd1;
                        dma_src_stride_o <= 16'd0;
                        dma_dst_stride_o <= 16'd0;
                        state            <= ST_DMA_STORE_RES;
                    end
                end

                ST_DMA_STORE_RES: begin
                    if (dma_done_i) begin
                        state <= ST_FINISH;
                    end
                end

                ST_FINISH: begin
                    irq_done_o <= 1'b1;
                    state      <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    // Buffer read/write addressing
    assign w_buf_compute_en_o   = (state == ST_LOAD_WEIGHTS);
    assign w_buf_compute_addr_o = {2'b0, step_cnt};

    assign act_buf_compute_en_o   = (state == ST_COMPUTE);
    assign act_buf_compute_addr_o = {2'b0, step_cnt};

    assign out_buf_compute_en_o    = out_buf_compute_we_o;
    assign out_buf_compute_be_o    = 4'b1111;
    assign out_buf_compute_addr_o  = out_word_cnt;
    assign out_buf_compute_wdata_o = {acc_bottom_i[3][7:0], acc_bottom_i[2][7:0], acc_bottom_i[1][7:0], acc_bottom_i[0][7:0]};

    always_comb begin
        for (int c = 0; c < 8; c++) begin
            load_weight_o[c] = (state == ST_LOAD_WEIGHTS);
            weight_data_o[c] = w_buf_compute_rdata_i[(c*4)%32 +: 8];
            acc_top_o[c]     = 32'sd0;
        end
        for (int r = 0; r < 8; r++) begin
            act_data_o[r] = (state == ST_COMPUTE) ? act_buf_compute_rdata_i[(r*4)%32 +: 8] : 8'sd0;
        end
    end

    assign ai_busy_o = (state != ST_IDLE);
    assign ai_done_o = (state == ST_FINISH);

endmodule
