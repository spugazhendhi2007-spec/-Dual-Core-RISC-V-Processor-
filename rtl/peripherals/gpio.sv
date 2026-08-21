// ============================================================================
// File: gpio.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: 16-Bit General Purpose Input / Output (GPIO) Controller with Edge IRQs
// ============================================================================

`timescale 1ns / 1ps

module gpio (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Slave Interface
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // External Physical Pins
    input  logic [15:0] gpio_in_i,
    output logic [15:0] gpio_out_o,
    output logic [15:0] gpio_oe_o,

    // Interrupt
    output logic        irq_o
);

    logic [15:0] dir_reg;
    logic [15:0] out_reg;
    logic [15:0] in_sync_0, in_sync_1, in_prev;
    logic [15:0] irq_en_reg;
    logic [15:0] irq_stat_reg;

    assign gpio_out_o = out_reg;
    assign gpio_oe_o  = dir_reg;

    // Synchronize external inputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_sync_0 <= 16'd0;
            in_sync_1 <= 16'd0;
            in_prev   <= 16'd0;
        end else begin
            in_sync_0 <= gpio_in_i;
            in_sync_1 <= in_sync_0;
            in_prev   <= in_sync_1;
        end
    end

    // Register Writes & IRQ Edge Detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dir_reg      <= 16'd0;
            out_reg      <= 16'd0;
            irq_en_reg   <= 16'd0;
            irq_stat_reg <= 16'd0;
        end else begin
            for (int i = 0; i < 16; i++) begin
                if (irq_en_reg[i] && (in_sync_1[i] != in_prev[i])) begin
                    irq_stat_reg[i] <= 1'b1;
                end
            end

            if (req_i && we_i) begin
                case (addr_i[7:0])
                    8'h00: dir_reg      <= wdata_i[15:0];
                    8'h04: out_reg      <= wdata_i[15:0];
                    8'h0C: irq_en_reg   <= wdata_i[15:0];
                    8'h10: irq_stat_reg <= irq_stat_reg & (~wdata_i[15:0]); // W1C
                    default: ;
                endcase
            end
        end
    end

    // Register Read
    always_comb begin
        case (addr_i[7:0])
            8'h00:   rdata_o = {16'b0, dir_reg};
            8'h04:   rdata_o = {16'b0, out_reg};
            8'h08:   rdata_o = {16'b0, in_sync_1};
            8'h0C:   rdata_o = {16'b0, irq_en_reg};
            8'h10:   rdata_o = {16'b0, irq_stat_reg};
            default: rdata_o = 32'd0;
        endcase
    end

    assign irq_o = (|(irq_stat_reg & irq_en_reg));

endmodule
