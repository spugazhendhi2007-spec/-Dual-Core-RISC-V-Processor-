// ============================================================================
// File: timer.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: General Purpose 32-Bit SoC Hardware Timer with Prescaler & Periodic IRQ
// ============================================================================

`timescale 1ns / 1ps

module timer (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Slave Interface
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Interrupt Output
    output logic        irq_o
);

    logic [31:0] ctrl_reg;     // [0] enable, [1] auto-reload, [2] irq_en
    logic [31:0] prescaler_reg;
    logic [31:0] reload_reg;
    logic [31:0] count_reg;
    logic [31:0] prescale_cnt;
    logic        irq_pending;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg      <= 32'd0;
            prescaler_reg <= 32'd0;
            reload_reg    <= 32'd0;
            count_reg     <= 32'd0;
            prescale_cnt  <= 32'd0;
            irq_pending   <= 1'b0;
        end else begin
            if (ctrl_reg[0]) begin // Timer enabled
                if (prescale_cnt >= prescaler_reg) begin
                    prescale_cnt <= 32'd0;
                    if (count_reg == 32'd0) begin
                        if (ctrl_reg[1]) begin // Auto-reload
                            count_reg <= reload_reg;
                        end else begin
                            ctrl_reg[0] <= 1'b0; // Stop
                        end
                        irq_pending <= 1'b1;
                    end else begin
                        count_reg <= count_reg - 32'd1;
                    end
                end else begin
                    prescale_cnt <= prescale_cnt + 32'd1;
                end
            end

            if (req_i && we_i) begin
                case (addr_i[7:0])
                    8'h00: ctrl_reg      <= wdata_i;
                    8'h04: prescaler_reg <= wdata_i;
                    8'h08: reload_reg    <= wdata_i;
                    8'h0C: count_reg     <= wdata_i;
                    8'h10: irq_pending   <= irq_pending & (~wdata_i[0]); // W1C
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        case (addr_i[7:0])
            8'h00:   rdata_o = ctrl_reg;
            8'h04:   rdata_o = prescaler_reg;
            8'h08:   rdata_o = reload_reg;
            8'h0C:   rdata_o = count_reg;
            8'h10:   rdata_o = {31'b0, irq_pending};
            default: rdata_o = 32'd0;
        endcase
    end

    assign irq_o = irq_pending && ctrl_reg[2];

endmodule
