// ============================================================================
// File: interrupt_controller.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Platform-Level Interrupt Controller (PLIC) Routing to Core 0 & Core 1
// ============================================================================

`timescale 1ns / 1ps

module interrupt_controller (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Slave Interface
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Peripheral Interrupt Inputs
    input  logic        irq_ai_done_i,
    input  logic        irq_uart_i,
    input  logic        irq_gpio_i,
    input  logic        irq_timer_i,

    // Target Outputs to CPU Cores
    output logic        irq_core0_o,
    output logic        irq_core1_o
);

    logic [3:0] irq_sources;
    logic [3:0] irq_en_core0;
    logic [3:0] irq_en_core1;
    logic [3:0] irq_pending;

    assign irq_sources = {irq_timer_i, irq_gpio_i, irq_uart_i, irq_ai_done_i};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_en_core0 <= 4'd0;
            irq_en_core1 <= 4'd0;
            irq_pending  <= 4'd0;
        end else begin
            irq_pending <= irq_pending | irq_sources;

            if (req_i && we_i) begin
                case (addr_i[7:0])
                    8'h00: irq_en_core0 <= wdata_i[3:0];
                    8'h04: irq_en_core1 <= wdata_i[3:0];
                    8'h08: irq_pending  <= irq_pending & (~wdata_i[3:0]); // W1C
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        case (addr_i[7:0])
            8'h00:   rdata_o = {28'b0, irq_en_core0};
            8'h04:   rdata_o = {28'b0, irq_en_core1};
            8'h08:   rdata_o = {28'b0, irq_pending};
            default: rdata_o = 32'd0;
        endcase
    end

    assign irq_core0_o = (|(irq_pending & irq_en_core0));
    assign irq_core1_o = (|(irq_pending & irq_en_core1));

endmodule
