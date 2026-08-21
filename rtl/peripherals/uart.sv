// ============================================================================
// File: uart.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: AXI4-Lite Memory-Mapped Universal Asynchronous Receiver Transmitter
// ============================================================================

`timescale 1ns / 1ps

module uart (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Slave Interface
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Serial Line Pins
    input  logic        rx_i,
    output logic        tx_o,

    // Interrupt
    output logic        irq_o
);

    localparam logic [7:0] REG_DATA   = 8'h00;
    localparam logic [7:0] REG_STATUS = 8'h04;
    localparam logic [7:0] REG_CTRL   = 8'h08;
    localparam logic [7:0] REG_BAUD   = 8'h0C;

    logic [7:0]  tx_fifo [15:0];
    logic [3:0]  tx_wr_ptr, tx_rd_ptr;
    logic [4:0]  tx_count;

    logic [7:0]  rx_fifo [15:0];
    logic [3:0]  rx_wr_ptr, rx_rd_ptr;
    logic [4:0]  rx_count;

    logic [15:0] baud_div;
    logic [15:0] baud_cnt;
    logic        tx_busy;
    logic [9:0]  tx_shift;
    logic [3:0]  tx_bit_cnt;

    logic [31:0] ctrl_reg;

    assign tx_busy = (tx_bit_cnt != 4'd0);

    // TX Baud Generation & Serializer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt   <= 16'd0;
            tx_bit_cnt <= 4'd0;
            tx_shift   <= 10'h3FF;
            tx_o       <= 1'b1;
            tx_rd_ptr  <= 4'd0;
        end else begin
            if (tx_bit_cnt == 4'd0) begin
                if (tx_count != 5'd0) begin
                    tx_shift   <= {1'b1, tx_fifo[tx_rd_ptr], 1'b0};
                    tx_rd_ptr  <= tx_rd_ptr + 4'd1;
                    tx_bit_cnt <= 4'd10;
                    baud_cnt   <= (baud_div != 16'd0) ? baud_div : 16'd16;
                end
            end else begin
                if (baud_cnt == 16'd0) begin
                    baud_cnt   <= (baud_div != 16'd0) ? baud_div : 16'd16;
                    tx_o       <= tx_shift[0];
                    tx_shift   <= {1'b1, tx_shift[9:1]};
                    tx_bit_cnt <= tx_bit_cnt - 4'd1;
                end else begin
                    baud_cnt <= baud_cnt - 16'd1;
                end
            end
        end
    end

    // FIFO Counters & Register Read/Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_wr_ptr <= 4'd0;
            tx_count  <= 5'd0;
            rx_wr_ptr <= 4'd0;
            rx_rd_ptr <= 4'd0;
            rx_count  <= 5'd0;
            baud_div  <= 16'd868; // 100MHz / 115200 ≈ 868
            ctrl_reg  <= 32'd0;
        end else begin
            if ((tx_bit_cnt == 4'd0) && (tx_count != 5'd0) && !(req_i && we_i && (addr_i[7:0] == REG_DATA))) begin
                tx_count <= tx_count - 5'd1;
            end

            if (req_i && we_i) begin
                case (addr_i[7:0])
                    REG_DATA: begin
                        if (tx_count < 5'd16) begin
                            tx_fifo[tx_wr_ptr] <= wdata_i[7:0];
                            tx_wr_ptr          <= tx_wr_ptr + 4'd1;
                            if (!((tx_bit_cnt == 4'd0) && (tx_count != 5'd0))) begin
                                tx_count <= tx_count + 5'd1;
                            end
                        end
                    end
                    REG_CTRL: ctrl_reg <= wdata_i;
                    REG_BAUD: baud_div <= wdata_i[15:0];
                    default: ;
                endcase
            end
        end
    end

    // Register Read
    always_comb begin
        case (addr_i[7:0])
            REG_DATA:   rdata_o = (rx_count > 0) ? {24'b0, rx_fifo[rx_rd_ptr]} : 32'd0;
            REG_STATUS: rdata_o = {16'b0, rx_count, 3'b0, (rx_count > 0), 2'b0, tx_busy, (tx_count < 16)};
            REG_CTRL:   rdata_o = ctrl_reg;
            REG_BAUD:   rdata_o = {16'b0, baud_div};
            default:    rdata_o = 32'd0;
        endcase
    end

    assign irq_o = (rx_count > 0) && ctrl_reg[0];

endmodule
