// ============================================================================
// File: rv_ipi_controller.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Inter-Processor Interrupt (IPI) & Multi-Core Real-Time Timer Controller
// ============================================================================

`timescale 1ns / 1ps

module rv_ipi_controller (
    input  logic        clk,
    input  logic        rst_n,

    // Bus Slave Interface
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Core Interrupt Lines
    output logic        irq_soft_core0_o,
    output logic        irq_timer_core0_o,
    output logic        irq_soft_core1_o,
    output logic        irq_timer_core1_o
);

    localparam logic [15:0] ADDR_MSIP0      = 16'h0000;
    localparam logic [15:0] ADDR_MSIP1      = 16'h0004;
    localparam logic [15:0] ADDR_MUTEX      = 16'h0010;
    localparam logic [15:0] ADDR_MTIMECMP0  = 16'h4000;
    localparam logic [15:0] ADDR_MTIMECMP0_H= 16'h4004;
    localparam logic [15:0] ADDR_MTIMECMP1  = 16'h4008;
    localparam logic [15:0] ADDR_MTIMECMP1_H= 16'h400C;
    localparam logic [15:0] ADDR_MTIME      = 16'hBFF8;
    localparam logic [15:0] ADDR_MTIME_H    = 16'hBFFC;

    logic        msip0_reg;
    logic        msip1_reg;
    logic [63:0] mtimecmp0_reg;
    logic [63:0] mtimecmp1_reg;
    logic [63:0] mtime_reg;
    logic [31:0] mutex_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime_reg <= 64'd0;
        end else begin
            mtime_reg <= mtime_reg + 64'd1;
        end
    end

    assign irq_timer_core0_o = (mtime_reg >= mtimecmp0_reg) && (mtimecmp0_reg != 64'd0);
    assign irq_timer_core1_o = (mtime_reg >= mtimecmp1_reg) && (mtimecmp1_reg != 64'd0);
    assign irq_soft_core0_o  = msip0_reg;
    assign irq_soft_core1_o  = msip1_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            msip0_reg      <= 1'b0;
            msip1_reg      <= 1'b0;
            mtimecmp0_reg  <= 64'hFFFF_FFFF_FFFF_FFFF;
            mtimecmp1_reg  <= 64'hFFFF_FFFF_FFFF_FFFF;
            mutex_reg      <= 32'd0;
        end else if (req_i && we_i) begin
            case (addr_i[15:0])
                ADDR_MSIP0:        msip0_reg <= wdata_i[0];
                ADDR_MSIP1:        msip1_reg <= wdata_i[0];
                ADDR_MUTEX:        mutex_reg <= wdata_i;
                ADDR_MTIMECMP0:    mtimecmp0_reg[31:0]  <= wdata_i;
                ADDR_MTIMECMP0_H:  mtimecmp0_reg[63:32] <= wdata_i;
                ADDR_MTIMECMP1:    mtimecmp1_reg[31:0]  <= wdata_i;
                ADDR_MTIMECMP1_H:  mtimecmp1_reg[63:32] <= wdata_i;
                default: ;
            endcase
        end
    end

    always_comb begin
        case (addr_i[15:0])
            ADDR_MSIP0:        rdata_o = {31'b0, msip0_reg};
            ADDR_MSIP1:        rdata_o = {31'b0, msip1_reg};
            ADDR_MUTEX:        rdata_o = mutex_reg;
            ADDR_MTIMECMP0:    rdata_o = mtimecmp0_reg[31:0];
            ADDR_MTIMECMP0_H:  rdata_o = mtimecmp0_reg[63:32];
            ADDR_MTIMECMP1:    rdata_o = mtimecmp1_reg[31:0];
            ADDR_MTIMECMP1_H:  rdata_o = mtimecmp1_reg[63:32];
            ADDR_MTIME:        rdata_o = mtime_reg[31:0];
            ADDR_MTIME_H:      rdata_o = mtime_reg[63:32];
            default:           rdata_o = 32'd0;
        endcase
    end

endmodule
