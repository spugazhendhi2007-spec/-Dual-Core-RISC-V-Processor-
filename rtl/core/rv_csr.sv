// ============================================================================
// File: rv_csr.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Complete Machine-Mode CSR Register File (RV32 Privileged Spec)
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_csr #(
    parameter logic [31:0] HART_ID = 32'd0
) (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction Pipeline Interface
    input  logic        csr_we_i,
    input  logic [2:0]  csr_op_i,
    input  logic [11:0] csr_addr_i,
    input  logic [31:0] csr_wdata_i,
    output logic [31:0] csr_rdata_o,

    // Trap & Exception Handling
    input  logic        trap_entry_i,
    input  logic [31:0] trap_cause_i,
    input  logic [31:0] trap_pc_i,
    input  logic [31:0] trap_val_i,

    input  logic        mret_i,
    output logic [31:0] trap_target_o,
    output logic [31:0] mepc_o,

    // Status bits exposed to exception logic
    output logic        mstatus_mie_o,
    output logic        mie_meie_o,
    output logic        mie_msie_o,
    output logic        mie_mtie_o,

    // External Interrupt Inputs
    input  logic        irq_software_i,
    input  logic        irq_timer_i,
    input  logic        irq_external_i
);

    logic [31:0] mstatus_reg;
    logic [31:0] mie_reg;
    logic [31:0] mtvec_reg;
    logic [31:0] mscratch_reg;
    logic [31:0] mepc_reg;
    logic [31:0] mcause_reg;
    logic [31:0] mtval_reg;
    logic [63:0] mcycle_reg;
    logic [63:0] minstret_reg;

    logic [31:0] mip_wire;
    assign mip_wire = {20'b0, irq_external_i, 3'b0, irq_timer_i, 3'b0, irq_software_i, 3'b0};

    assign mstatus_mie_o = mstatus_reg[3];
    assign mie_meie_o    = mie_reg[11];
    assign mie_mtie_o    = mie_reg[7];
    assign mie_msie_o    = mie_reg[3];

    // CSR Read
    always_comb begin
        case (csr_addr_i)
            CSR_MSTATUS:  csr_rdata_o = mstatus_reg;
            CSR_MISA:     csr_rdata_o = 32'h4000_1101; // RV32IMA
            CSR_MIE:      csr_rdata_o = mie_reg;
            CSR_MTVEC:    csr_rdata_o = mtvec_reg;
            CSR_MSCRATCH: csr_rdata_o = mscratch_reg;
            CSR_MEPC:     csr_rdata_o = mepc_reg;
            CSR_MCAUSE:   csr_rdata_o = mcause_reg;
            CSR_MTVAL:    csr_rdata_o = mtval_reg;
            CSR_MIP:      csr_rdata_o = mip_wire;
            CSR_MCYCLE:   csr_rdata_o = mcycle_reg[31:0];
            CSR_MINSTRET: csr_rdata_o = minstret_reg[31:0];
            CSR_MHARTID:  csr_rdata_o = HART_ID;
            default:      csr_rdata_o = 32'd0;
        endcase
    end

    // Compute updated write value
    logic [31:0] csr_wval;
    always_comb begin
        case (csr_op_i)
            CSR_RW, CSR_RWI: csr_wval = csr_wdata_i;
            CSR_RS, CSR_RSI: csr_wval = csr_rdata_o | csr_wdata_i;
            CSR_RC, CSR_RCI: csr_wval = csr_rdata_o & (~csr_wdata_i);
            default:         csr_wval = csr_wdata_i;
        endcase
    end

    // Sequential CSR update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus_reg  <= 32'h0000_1800; // MPP = 2'b11 (M-mode)
            mie_reg      <= 32'd0;
            mtvec_reg    <= 32'h0000_0040;
            mscratch_reg <= 32'd0;
            mepc_reg     <= 32'd0;
            mcause_reg   <= 32'd0;
            mtval_reg    <= 32'd0;
            mcycle_reg   <= 64'd0;
            minstret_reg <= 64'd0;
        end else begin
            mcycle_reg <= mcycle_reg + 64'd1;

            if (trap_entry_i) begin
                mepc_reg       <= trap_pc_i;
                mcause_reg     <= trap_cause_i;
                mtval_reg      <= trap_val_i;
                mstatus_reg[7] <= mstatus_reg[3]; // MPIE <= MIE
                mstatus_reg[3] <= 1'b0;           // Disable MIE
            end else if (mret_i) begin
                mstatus_reg[3] <= mstatus_reg[7]; // MIE <= MPIE
                mstatus_reg[7] <= 1'b1;           // MPIE <= 1
            end else if (csr_we_i) begin
                minstret_reg <= minstret_reg + 64'd1;
                case (csr_addr_i)
                    CSR_MSTATUS:  mstatus_reg  <= {csr_wval[31:8], csr_wval[7], 3'b0, csr_wval[3], 3'b0};
                    CSR_MIE:      mie_reg      <= csr_wval;
                    CSR_MTVEC:    mtvec_reg    <= {csr_wval[31:2], 2'b00};
                    CSR_MSCRATCH: mscratch_reg <= csr_wval;
                    CSR_MEPC:     mepc_reg     <= {csr_wval[31:2], 2'b00};
                    CSR_MCAUSE:   mcause_reg   <= csr_wval;
                    CSR_MTVAL:    mtval_reg    <= csr_wval;
                    default: ;
                endcase
            end
        end
    end

    assign trap_target_o = mtvec_reg;
    assign mepc_o        = mepc_reg;

endmodule
