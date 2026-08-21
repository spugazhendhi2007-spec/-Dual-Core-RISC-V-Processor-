// ============================================================================
// File: rv_decode.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Full RV32IMA Instruction Decoder + Custom AI Coprocessor Instructions
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_decode (
    input  logic [31:0]        instr_i,

    // Register File Indices
    output logic [4:0]         rs1_addr_o,
    output logic [4:0]         rs2_addr_o,
    output logic [4:0]         rd_addr_o,
    output logic [31:0]        imm_o,

    // ALU & Datapath Controls
    output rv_alu_op_e         alu_op_o,
    output logic               alu_src_a_sel_o, // 0: rs1, 1: pc
    output logic               alu_src_b_sel_o, // 0: rs2, 1: imm

    // Memory Controls
    output logic               mem_read_o,
    output logic               mem_write_o,
    output logic [1:0]         mem_size_o,      // 2'b00: byte, 2'b01: half, 2'b10: word
    output logic               mem_unsigned_o,
    output logic               reg_write_o,

    // Control Flow Controls
    output logic               is_branch_o,
    output logic               is_jal_o,
    output logic               is_jalr_o,
    output logic [2:0]         branch_type_o,

    // M-Extension Controls
    output logic               is_mul_div_o,
    output rv_md_op_e          md_op_o,

    // A-Extension Controls (Atomic)
    output logic               is_atomic_o,
    output logic [4:0]         amo_funct5_o,

    // CSR & System Exception Controls
    output logic               is_csr_o,
    output logic [2:0]         csr_op_o,
    output logic [11:0]        csr_addr_o,
    output logic               is_ecall_o,
    output logic               is_ebreak_o,
    output logic               is_mret_o,
    output logic               is_wfi_o,
    output logic               is_illegal_o
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];
    assign funct7 = instr_i[31:25];

    assign rs1_addr_o = instr_i[19:15];
    assign rs2_addr_o = instr_i[24:20];
    assign rd_addr_o  = instr_i[11:7];

    // Immediate Decoder
    always_comb begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: // I-type, Load, JALR
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
            7'b0100011: // S-type (Store)
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            7'b1100011: // B-type (Branch)
                imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
            7'b0110111, 7'b0010111: // U-type (LUI, AUIPC)
                imm_o = {instr_i[31:12], 12'b0};
            7'b1101111: // J-type (JAL)
                imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
            default:
                imm_o = 32'd0;
        endcase
    end

    // Instruction Decode Logic
    always_comb begin
        alu_op_o        = ALU_ADD;
        alu_src_a_sel_o = 1'b0;
        alu_src_b_sel_o = 1'b0;
        mem_read_o      = 1'b0;
        mem_write_o     = 1'b0;
        mem_size_o      = 2'b10;
        mem_unsigned_o  = 1'b0;
        reg_write_o     = 1'b0;
        is_branch_o     = 1'b0;
        is_jal_o        = 1'b0;
        is_jalr_o       = 1'b0;
        branch_type_o   = funct3;
        is_mul_div_o    = 1'b0;
        md_op_o         = MD_MUL;
        is_atomic_o     = 1'b0;
        amo_funct5_o    = funct7[6:2];
        is_csr_o        = 1'b0;
        csr_op_o        = funct3;
        csr_addr_o      = instr_i[31:20];
        is_ecall_o      = 1'b0;
        is_ebreak_o     = 1'b0;
        is_mret_o       = 1'b0;
        is_wfi_o        = 1'b0;
        is_illegal_o    = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type: RV32I / RV32M
                reg_write_o = 1'b1;
                if (funct7 == 7'b0000001) begin // M-Extension
                    is_mul_div_o = 1'b1;
                    case (funct3)
                        3'b000: md_op_o = MD_MUL;
                        3'b001: md_op_o = MD_MULH;
                        3'b010: md_op_o = MD_MULHSU;
                        3'b011: md_op_o = MD_MULHU;
                        3'b100: md_op_o = MD_DIV;
                        3'b101: md_op_o = MD_DIVU;
                        3'b110: md_op_o = MD_REM;
                        3'b111: md_op_o = MD_REMU;
                    endcase
                end else begin // RV32I Base ALU
                    case (funct3)
                        3'b000: alu_op_o = (funct7[5]) ? ALU_SUB : ALU_ADD;
                        3'b001: alu_op_o = ALU_SLL;
                        3'b010: alu_op_o = ALU_SLT;
                        3'b011: alu_op_o = ALU_SLTU;
                        3'b100: alu_op_o = ALU_XOR;
                        3'b101: alu_op_o = (funct7[5]) ? ALU_SRA : ALU_SRL;
                        3'b110: alu_op_o = ALU_OR;
                        3'b111: alu_op_o = ALU_AND;
                    endcase
                end
            end

            7'b0010011: begin // I-type ALU
                reg_write_o     = 1'b1;
                alu_src_b_sel_o = 1'b1;
                case (funct3)
                    3'b000: alu_op_o = ALU_ADD;
                    3'b001: alu_op_o = ALU_SLL;
                    3'b010: alu_op_o = ALU_SLT;
                    3'b011: alu_op_o = ALU_SLTU;
                    3'b100: alu_op_o = ALU_XOR;
                    3'b101: alu_op_o = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110: alu_op_o = ALU_OR;
                    3'b111: alu_op_o = ALU_AND;
                endcase
            end

            7'b0000011: begin // Load Instructions
                reg_write_o     = 1'b1;
                mem_read_o      = 1'b1;
                alu_src_b_sel_o = 1'b1;
                alu_op_o        = ALU_ADD;
                case (funct3)
                    3'b000: begin mem_size_o = 2'b00; mem_unsigned_o = 1'b0; end // LB
                    3'b001: begin mem_size_o = 2'b01; mem_unsigned_o = 1'b0; end // LH
                    3'b010: begin mem_size_o = 2'b10; mem_unsigned_o = 1'b0; end // LW
                    3'b100: begin mem_size_o = 2'b00; mem_unsigned_o = 1'b1; end // LBU
                    3'b101: begin mem_size_o = 2'b01; mem_unsigned_o = 1'b1; end // LHU
                    default: is_illegal_o = 1'b1;
                endcase
            end

            7'b0100011: begin // Store Instructions
                mem_write_o     = 1'b1;
                alu_src_b_sel_o = 1'b1;
                alu_op_o        = ALU_ADD;
                case (funct3)
                    3'b000: mem_size_o = 2'b00; // SB
                    3'b001: mem_size_o = 2'b01; // SH
                    3'b010: mem_size_o = 2'b10; // SW
                    default: is_illegal_o = 1'b1;
                endcase
            end

            7'b1100011: begin // Branch Instructions
                is_branch_o = 1'b1;
            end

            7'b1101111: begin // JAL
                is_jal_o    = 1'b1;
                reg_write_o = 1'b1;
            end

            7'b1100111: begin // JALR
                is_jalr_o       = 1'b1;
                reg_write_o     = 1'b1;
                alu_src_b_sel_o = 1'b1;
            end

            7'b0110111: begin // LUI
                reg_write_o     = 1'b1;
                alu_src_b_sel_o = 1'b1;
                alu_op_o        = ALU_ADD;
            end

            7'b0010111: begin // AUIPC
                reg_write_o     = 1'b1;
                alu_src_a_sel_o = 1'b1; // PC
                alu_src_b_sel_o = 1'b1; // Imm
                alu_op_o        = ALU_ADD;
            end

            7'b0101111: begin // RV32A Atomic Instructions
                is_atomic_o = 1'b1;
                reg_write_o = 1'b1;
                if (amo_funct5_o == AMO_LR) begin
                    mem_read_o = 1'b1;
                end else if (amo_funct5_o == AMO_SC) begin
                    mem_write_o = 1'b1;
                end else begin
                    mem_read_o  = 1'b1;
                    mem_write_o = 1'b1;
                end
            end

            7'b1110011: begin // System Instructions / CSR
                if (funct3 == 3'b000) begin
                    case (instr_i[31:20])
                        12'h000: is_ecall_o  = 1'b1;
                        12'h001: is_ebreak_o = 1'b1;
                        12'h302: is_mret_o   = 1'b1;
                        12'h105: is_wfi_o    = 1'b1;
                        default: is_illegal_o = 1'b1;
                    endcase
                end else begin
                    is_csr_o    = 1'b1;
                    reg_write_o = (rd_addr_o != 5'd0);
                end
            end

            7'b0001011: begin // Custom AI Coprocessor Instructions (AI_CFG, AI_START, AI_WAIT)
                reg_write_o = 1'b0;
            end

            default: begin
                is_illegal_o = 1'b1;
            end
        endcase
    end

endmodule
