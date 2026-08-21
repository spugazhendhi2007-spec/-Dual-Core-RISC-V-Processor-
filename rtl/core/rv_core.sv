// ============================================================================
// File: rv_core.sv
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Integrated 5-Stage In-Order RV32IMA Core with Custom AI Interface
// ============================================================================

`timescale 1ns / 1ps
`include "rv_defines.svh"

module rv_core #(
    parameter logic [31:0] HART_ID   = 32'd0,
    parameter logic [31:0] RESET_VEC = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction Bus
    output logic        instr_req_o,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,

    // Data Bus
    output logic        data_req_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,

    // Atomic Operation Interface
    output logic        atomic_req_o,
    output logic [4:0]  atomic_op_o,
    input  logic        atomic_sc_success_i,

    // Custom AI Instruction Interface
    output logic        ai_cmd_valid_o,
    output logic [2:0]  ai_cmd_type_o,
    output logic [31:0] ai_cmd_arg0_o,
    output logic [31:0] ai_cmd_arg1_o,
    input  logic        ai_busy_i,
    input  logic        ai_done_i,

    // Interrupt Lines
    input  logic        irq_software_i,
    input  logic        irq_timer_i,
    input  logic        irq_external_i
);

    // Pipeline Signals
    logic [31:0] if_pc, if_pc_plus4;
    logic [31:0] id_pc, id_pc_plus4, id_instr;
    logic        id_valid;

    // Decode Signals
    logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic [31:0] id_imm, id_rs1_data, id_rs2_data;
    rv_alu_op_e  id_alu_op;
    logic        id_alu_src_a_sel, id_alu_src_b_sel;
    logic        id_mem_read, id_mem_write, id_mem_unsigned;
    logic [1:0]  id_mem_size;
    logic        id_reg_write, id_is_branch, id_is_jal, id_is_jalr;
    logic [2:0]  id_branch_type;
    logic        id_is_mul_div;
    rv_md_op_e   id_md_op;
    logic        id_is_atomic;
    logic [4:0]  id_amo_funct5;
    logic        id_is_csr, id_is_ecall, id_is_ebreak, id_is_mret, id_is_wfi, id_is_illegal;
    logic [2:0]  id_csr_op;
    logic [11:0] id_csr_addr;

    // ID/EX Register Signals
    logic [31:0] ex_pc, ex_pc_plus4, ex_imm, ex_rs1_data, ex_rs2_data;
    logic [4:0]  ex_rs1_addr, ex_rs2_addr, ex_rd_addr;
    rv_alu_op_e  ex_alu_op;
    logic        ex_alu_src_a_sel, ex_alu_src_b_sel;
    logic        ex_mem_read, ex_mem_write, ex_mem_unsigned;
    logic [1:0]  ex_mem_size;
    logic        ex_reg_write, ex_is_branch, ex_is_jal, ex_is_jalr;
    logic [2:0]  ex_branch_type;
    logic        ex_is_mul_div;
    rv_md_op_e   ex_md_op;
    logic        ex_is_atomic;
    logic [4:0]  ex_amo_funct5;
    logic        ex_is_csr, ex_is_ecall, ex_is_ebreak, ex_is_mret, ex_is_illegal;
    logic [2:0]  ex_csr_op;
    logic [11:0] ex_csr_addr;
    logic        ex_valid;

    // EX Stage Execution Signals
    logic [31:0] ex_op_a_forwarded, ex_op_b_forwarded;
    logic [31:0] ex_alu_op_a, ex_alu_op_b, ex_alu_result;
    logic        ex_alu_zero, ex_alu_lt, ex_alu_ltu;
    logic        ex_branch_taken;
    logic [31:0] ex_branch_target;
    logic [31:0] ex_mul_result, ex_div_result, ex_md_result;
    logic        ex_mul_valid, ex_div_busy, ex_div_done, ex_md_busy;

    // EX/MEM Register Signals
    logic [31:0] mem_pc, mem_pc_plus4, mem_alu_result, mem_write_data;
    logic [4:0]  mem_rd_addr;
    logic        mem_mem_read, mem_mem_write, mem_mem_unsigned;
    logic [1:0]  mem_mem_size;
    logic        mem_reg_write, mem_is_jal, mem_is_jalr;
    logic        mem_is_atomic;
    logic [4:0]  mem_amo_funct5;
    logic        mem_is_csr, mem_is_ecall, mem_is_ebreak, mem_is_mret, mem_is_illegal;
    logic [2:0]  mem_csr_op;
    logic [11:0] mem_csr_addr;
    logic [31:0] mem_csr_wdata;
    logic        mem_valid;

    // MEM Stage Data Formatting & CSRs
    logic [31:0] mem_load_data_formatted;
    logic [31:0] mem_csr_rdata, mem_trap_target, mem_mepc;
    logic        mem_trap_taken;
    logic [31:0] mem_trap_cause;
    logic        csr_mstatus_mie, csr_mie_meie, csr_mie_msie, csr_mie_mtie;

    // MEM/WB Register Signals
    logic [31:0] wb_alu_result, wb_load_data, wb_pc_plus4, wb_csr_rdata;
    logic [4:0]  wb_rd_addr;
    logic        wb_reg_write, wb_mem_read, wb_is_jal_or_jalr, wb_is_csr, wb_is_atomic;
    logic        wb_atomic_sc_success;
    logic        wb_valid;
    logic [31:0] wb_final_data;

    // Hazard Controls
    logic [1:0]  forward_a, forward_b;
    logic        stall_if, stall_id, stall_ex;
    logic        flush_if, flush_id, flush_ex;
    logic        ai_core_stall;

    // ------------------------------------------------------------------------
    // Stage 1: Instruction Fetch (IF)
    // ------------------------------------------------------------------------
    rv_fetch #(
        .RESET_VEC(RESET_VEC)
    ) u_fetch (
        .clk             (clk),
        .rst_n           (rst_n),
        .stall_i         (stall_if || ai_core_stall),
        .flush_i         (flush_if),
        .branch_taken_i  (ex_branch_taken),
        .branch_target_i (ex_branch_target),
        .trap_taken_i    (mem_trap_taken),
        .trap_target_i   (mem_trap_target),
        .mret_taken_i    (mem_is_mret && mem_valid),
        .mepc_i          (mem_mepc),
        .instr_req_o     (instr_req_o),
        .instr_addr_o    (instr_addr_o),
        .pc_o            (if_pc),
        .pc_plus4_o      (if_pc_plus4)
    );

    rv_reg_if_id u_if_id_reg (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall_i       (stall_id || ai_core_stall),
        .flush_i       (flush_id),
        .if_pc_i       (if_pc),
        .if_pc_plus4_i (if_pc_plus4),
        .if_instr_i    (instr_rdata_i),
        .id_pc_o       (id_pc),
        .id_pc_plus4_o (id_pc_plus4),
        .id_instr_o    (id_instr),
        .id_valid_o    (id_valid)
    );

    // ------------------------------------------------------------------------
    // Stage 2: Instruction Decode (ID)
    // ------------------------------------------------------------------------
    rv_decode u_decode (
        .instr_i         (id_instr),
        .rs1_addr_o      (id_rs1_addr),
        .rs2_addr_o      (id_rs2_addr),
        .rd_addr_o       (id_rd_addr),
        .imm_o           (id_imm),
        .alu_op_o        (id_alu_op),
        .alu_src_a_sel_o (id_alu_src_a_sel),
        .alu_src_b_sel_o (id_alu_src_b_sel),
        .mem_read_o      (id_mem_read),
        .mem_write_o     (id_mem_write),
        .mem_size_o      (id_mem_size),
        .mem_unsigned_o  (id_mem_unsigned),
        .reg_write_o     (id_reg_write),
        .is_branch_o     (id_is_branch),
        .is_jal_o        (id_is_jal),
        .is_jalr_o       (id_is_jalr),
        .branch_type_o   (id_branch_type),
        .is_mul_div_o    (id_is_mul_div),
        .md_op_o         (id_md_op),
        .is_atomic_o     (id_is_atomic),
        .amo_funct5_o    (id_amo_funct5),
        .is_csr_o        (id_is_csr),
        .csr_op_o        (id_csr_op),
        .csr_addr_o      (id_csr_addr),
        .is_ecall_o      (id_is_ecall),
        .is_ebreak_o     (id_is_ebreak),
        .is_mret_o       (id_is_mret),
        .is_wfi_o        (id_is_wfi),
        .is_illegal_o    (id_is_illegal)
    );

    rv_regfile u_regfile (
        .clk      (clk),
        .rst_n    (rst_n),
        .raddr1_i (id_rs1_addr),
        .rdata1_o (id_rs1_data),
        .raddr2_i (id_rs2_addr),
        .rdata2_o (id_rs2_data),
        .we_i     (wb_reg_write && wb_valid),
        .waddr_i  (wb_rd_addr),
        .wdata_i  (wb_final_data)
    );

    rv_ai_interface u_ai_interface (
        .clk              (clk),
        .rst_n            (rst_n),
        .is_custom_ai_i   (id_valid && (id_instr[6:0] == 7'b0001011)),
        .ai_funct3_i      (id_instr[14:12]),
        .rs1_data_i       (id_rs1_data),
        .rs2_data_i       (id_rs2_data),
        .ai_cmd_valid_o   (ai_cmd_valid_o),
        .ai_cmd_type_o    (ai_cmd_type_o),
        .ai_cmd_arg0_o    (ai_cmd_arg0_o),
        .ai_cmd_arg1_o    (ai_cmd_arg1_o),
        .ai_busy_i        (ai_busy_i),
        .ai_done_i        (ai_done_i),
        .core_stall_req_o (ai_core_stall)
    );

    // ID/EX Pipeline Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_pc            <= 32'd0;
            ex_pc_plus4      <= 32'd0;
            ex_imm           <= 32'd0;
            ex_rs1_data      <= 32'd0;
            ex_rs2_data      <= 32'd0;
            ex_rs1_addr      <= 5'd0;
            ex_rs2_addr      <= 5'd0;
            ex_rd_addr       <= 5'd0;
            ex_alu_op        <= ALU_ADD;
            ex_alu_src_a_sel <= 1'b0;
            ex_alu_src_b_sel <= 1'b0;
            ex_mem_read      <= 1'b0;
            ex_mem_write     <= 1'b0;
            ex_mem_size      <= 2'b10;
            ex_mem_unsigned  <= 1'b0;
            ex_reg_write     <= 1'b0;
            ex_is_branch     <= 1'b0;
            ex_is_jal        <= 1'b0;
            ex_is_jalr       <= 1'b0;
            ex_branch_type   <= 3'b000;
            ex_is_mul_div    <= 1'b0;
            ex_md_op         <= MD_MUL;
            ex_is_atomic     <= 1'b0;
            ex_amo_funct5    <= 5'd0;
            ex_is_csr        <= 1'b0;
            ex_csr_op        <= 3'b000;
            ex_csr_addr      <= 12'd0;
            ex_is_ecall      <= 1'b0;
            ex_is_ebreak     <= 1'b0;
            ex_is_mret       <= 1'b0;
            ex_is_illegal    <= 1'b0;
            ex_valid         <= 1'b0;
        end else if (flush_ex) begin
            ex_reg_write     <= 1'b0;
            ex_mem_read      <= 1'b0;
            ex_mem_write     <= 1'b0;
            ex_is_branch     <= 1'b0;
            ex_is_jal        <= 1'b0;
            ex_is_jalr       <= 1'b0;
            ex_is_mul_div    <= 1'b0;
            ex_is_atomic     <= 1'b0;
            ex_is_csr        <= 1'b0;
            ex_valid         <= 1'b0;
        end else if (!stall_ex && !ai_core_stall) begin
            ex_pc            <= id_pc;
            ex_pc_plus4      <= id_pc_plus4;
            ex_imm           <= id_imm;
            ex_rs1_data      <= id_rs1_data;
            ex_rs2_data      <= id_rs2_data;
            ex_rs1_addr      <= id_rs1_addr;
            ex_rs2_addr      <= id_rs2_addr;
            ex_rd_addr       <= id_rd_addr;
            ex_alu_op        <= id_alu_op;
            ex_alu_src_a_sel <= id_alu_src_a_sel;
            ex_alu_src_b_sel <= id_alu_src_b_sel;
            ex_mem_read      <= id_mem_read;
            ex_mem_write     <= id_mem_write;
            ex_mem_size      <= id_mem_size;
            ex_mem_unsigned  <= id_mem_unsigned;
            ex_reg_write     <= id_reg_write;
            ex_is_branch     <= id_is_branch;
            ex_is_jal        <= id_is_jal;
            ex_is_jalr       <= id_is_jalr;
            ex_branch_type   <= id_branch_type;
            ex_is_mul_div    <= id_is_mul_div;
            ex_md_op         <= id_md_op;
            ex_is_atomic     <= id_is_atomic;
            ex_amo_funct5    <= id_amo_funct5;
            ex_is_csr        <= id_is_csr;
            ex_csr_op        <= id_csr_op;
            ex_csr_addr      <= id_csr_addr;
            ex_is_ecall      <= id_is_ecall;
            ex_is_ebreak     <= id_is_ebreak;
            ex_is_mret       <= id_is_mret;
            ex_is_illegal    <= id_is_illegal;
            ex_valid         <= id_valid;
        end
    end

    // ------------------------------------------------------------------------
    // Stage 3: Execution (EX)
    // ------------------------------------------------------------------------
    rv_forwarding u_forwarding (
        .rs1_ex_i        (ex_rs1_addr),
        .rs2_ex_i        (ex_rs2_addr),
        .rd_mem_i        (mem_rd_addr),
        .reg_write_mem_i (mem_reg_write && mem_valid),
        .rd_wb_i         (wb_rd_addr),
        .reg_write_wb_i  (wb_reg_write && wb_valid),
        .forward_a_o     (forward_a),
        .forward_b_o     (forward_b)
    );

    always_comb begin
        case (forward_a)
            2'b01:   ex_op_a_forwarded = mem_alu_result;
            2'b10:   ex_op_a_forwarded = wb_final_data;
            default: ex_op_a_forwarded = ex_rs1_data;
        endcase

        case (forward_b)
            2'b01:   ex_op_b_forwarded = mem_alu_result;
            2'b10:   ex_op_b_forwarded = wb_final_data;
            default: ex_op_b_forwarded = ex_rs2_data;
        endcase

        ex_alu_op_a = (ex_alu_src_a_sel) ? ex_pc  : ex_op_a_forwarded;
        ex_alu_op_b = (ex_alu_src_b_sel) ? ex_imm : ex_op_b_forwarded;
    end

    rv_alu u_alu (
        .op_a_i        (ex_alu_op_a),
        .op_b_i        (ex_alu_op_b),
        .alu_op_i      (ex_alu_op),
        .result_o      (ex_alu_result),
        .zero_o        (ex_alu_zero),
        .less_than_o   (ex_alu_lt),
        .less_than_u_o (ex_alu_ltu)
    );

    rv_multiplier u_multiplier (
        .clk      (clk),
        .rst_n    (rst_n),
        .enable_i (ex_is_mul_div && (ex_md_op[2] == 1'b0) && ex_valid),
        .op_i     (ex_md_op),
        .op_a_i   (ex_op_a_forwarded),
        .op_b_i   (ex_op_b_forwarded),
        .result_o (ex_mul_result),
        .valid_o  (ex_mul_valid)
    );

    rv_divider u_divider (
        .clk      (clk),
        .rst_n    (rst_n),
        .start_i  (ex_is_mul_div && (ex_md_op[2] == 1'b1) && ex_valid && !ex_div_busy),
        .op_i     (ex_md_op),
        .op_a_i   (ex_op_a_forwarded),
        .op_b_i   (ex_op_b_forwarded),
        .result_o (ex_div_result),
        .busy_o   (ex_div_busy),
        .done_o   (ex_div_done)
    );

    assign ex_md_busy   = ex_is_mul_div && (ex_md_op[2] ? ex_div_busy : !ex_mul_valid);
    assign ex_md_result = ex_md_op[2] ? ex_div_result : ex_mul_result;

    rv_branch u_branch (
        .branch_type_i   (ex_branch_type),
        .is_branch_i     (ex_is_branch && ex_valid),
        .is_jal_i        (ex_is_jal && ex_valid),
        .is_jalr_i       (ex_is_jalr && ex_valid),
        .op_a_i          (ex_op_a_forwarded),
        .op_b_i          (ex_op_b_forwarded),
        .pc_i            (ex_pc),
        .imm_i           (ex_imm),
        .branch_taken_o  (ex_branch_taken),
        .branch_target_o (ex_branch_target)
    );

    // EX/MEM Pipeline Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_pc          <= 32'd0;
            mem_pc_plus4    <= 32'd0;
            mem_alu_result  <= 32'd0;
            mem_write_data  <= 32'd0;
            mem_rd_addr     <= 5'd0;
            mem_mem_read    <= 1'b0;
            mem_mem_write   <= 1'b0;
            mem_mem_size    <= 2'b10;
            mem_mem_unsigned<= 1'b0;
            mem_reg_write   <= 1'b0;
            mem_is_jal      <= 1'b0;
            mem_is_jalr     <= 1'b0;
            mem_is_atomic   <= 1'b0;
            mem_amo_funct5  <= 5'd0;
            mem_is_csr      <= 1'b0;
            mem_csr_op      <= 3'b000;
            mem_csr_addr    <= 12'd0;
            mem_csr_wdata   <= 32'd0;
            mem_is_ecall    <= 1'b0;
            mem_is_ebreak   <= 1'b0;
            mem_is_mret     <= 1'b0;
            mem_is_illegal  <= 1'b0;
            mem_valid       <= 1'b0;
        end else begin
            mem_pc          <= ex_pc;
            mem_pc_plus4    <= ex_pc_plus4;
            mem_alu_result  <= ex_is_mul_div ? ex_md_result : ex_alu_result;
            mem_write_data  <= ex_op_b_forwarded;
            mem_rd_addr     <= ex_rd_addr;
            mem_mem_read    <= ex_mem_read;
            mem_mem_write   <= ex_mem_write;
            mem_mem_size    <= ex_mem_size;
            mem_mem_unsigned<= ex_mem_unsigned;
            mem_reg_write   <= ex_reg_write;
            mem_is_jal      <= ex_is_jal;
            mem_is_jalr     <= ex_is_jalr;
            mem_is_atomic   <= ex_is_atomic;
            mem_amo_funct5  <= ex_amo_funct5;
            mem_is_csr      <= ex_is_csr;
            mem_csr_op      <= ex_csr_op;
            mem_csr_addr    <= ex_csr_addr;
            mem_csr_wdata   <= (ex_csr_op[2]) ? {27'b0, ex_rs1_addr} : ex_op_a_forwarded;
            mem_is_ecall    <= ex_is_ecall;
            mem_is_ebreak   <= ex_is_ebreak;
            mem_is_mret     <= ex_is_mret;
            mem_is_illegal  <= ex_is_illegal;
            mem_valid       <= ex_valid;
        end
    end

    // ------------------------------------------------------------------------
    // Stage 4: Memory Access & CSR (MEM)
    // ------------------------------------------------------------------------
    always_comb begin
        data_be_o    = 4'b0000;
        data_wdata_o = 32'd0;
        case (mem_mem_size)
            2'b00: begin // Byte
                case (mem_alu_result[1:0])
                    2'b00: begin data_be_o = 4'b0001; data_wdata_o = {24'b0, mem_write_data[7:0]}; end
                    2'b01: begin data_be_o = 4'b0010; data_wdata_o = {16'b0, mem_write_data[7:0], 8'b0}; end
                    2'b10: begin data_be_o = 4'b0100; data_wdata_o = {8'b0, mem_write_data[7:0], 16'b0}; end
                    2'b11: begin data_be_o = 4'b1000; data_wdata_o = {mem_write_data[7:0], 24'b0}; end
                endcase
            end
            2'b01: begin // Halfword
                if (mem_alu_result[1]) begin
                    data_be_o    = 4'b1100;
                    data_wdata_o = {mem_write_data[15:0], 16'b0};
                end else begin
                    data_be_o    = 4'b0011;
                    data_wdata_o = {16'b0, mem_write_data[15:0]};
                end
            end
            default: begin // Word
                data_be_o    = 4'b1111;
                data_wdata_o = mem_write_data;
            end
        endcase
    end

    assign data_req_o   = (mem_mem_read || mem_mem_write) && mem_valid;
    assign data_we_o    = mem_mem_write && mem_valid;
    assign data_addr_o  = mem_alu_result;
    assign atomic_req_o = mem_is_atomic && mem_valid;
    assign atomic_op_o  = mem_amo_funct5;

    always_comb begin
        case (mem_mem_size)
            2'b00: begin
                case (mem_alu_result[1:0])
                    2'b00: mem_load_data_formatted = mem_mem_unsigned ? {24'b0, data_rdata_i[7:0]}   : {{24{data_rdata_i[7]}}, data_rdata_i[7:0]};
                    2'b01: mem_load_data_formatted = mem_mem_unsigned ? {24'b0, data_rdata_i[15:8]}  : {{24{data_rdata_i[15]}}, data_rdata_i[15:8]};
                    2'b10: mem_load_data_formatted = mem_mem_unsigned ? {24'b0, data_rdata_i[23:16]} : {{24{data_rdata_i[23]}}, data_rdata_i[23:16]};
                    2'b11: mem_load_data_formatted = mem_mem_unsigned ? {24'b0, data_rdata_i[31:24]} : {{24{data_rdata_i[31]}}, data_rdata_i[31:24]};
                endcase
            end
            2'b01: begin
                if (mem_alu_result[1]) begin
                    mem_load_data_formatted = mem_mem_unsigned ? {16'b0, data_rdata_i[31:16]} : {{16{data_rdata_i[31]}}, data_rdata_i[31:16]};
                end else begin
                    mem_load_data_formatted = mem_mem_unsigned ? {16'b0, data_rdata_i[15:0]}  : {{16{data_rdata_i[15]}}, data_rdata_i[15:0]};
                end
            end
            default: begin
                mem_load_data_formatted = data_rdata_i;
            end
        endcase
    end

    rv_exception u_exception (
        .valid_i        (mem_valid),
        .is_ecall_i     (mem_is_ecall),
        .is_ebreak_i    (mem_is_ebreak),
        .is_illegal_i   (mem_is_illegal),
        .irq_external_i (irq_external_i),
        .irq_software_i (irq_software_i),
        .irq_timer_i    (irq_timer_i),
        .mstatus_mie_i  (csr_mstatus_mie),
        .mie_meie_i     (csr_mie_meie),
        .mie_msie_i     (csr_mie_msie),
        .mie_mtie_i     (csr_mie_mtie),
        .trap_taken_o   (mem_trap_taken),
        .trap_cause_o   (mem_trap_cause)
    );

    rv_csr #(
        .HART_ID(HART_ID)
    ) u_csr (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_we_i       (mem_is_csr && mem_valid),
        .csr_op_i       (mem_csr_op),
        .csr_addr_i     (mem_csr_addr),
        .csr_wdata_i    (mem_csr_wdata),
        .csr_rdata_o    (mem_csr_rdata),
        .trap_entry_i   (mem_trap_taken),
        .trap_cause_i   (mem_trap_cause),
        .trap_pc_i      (mem_pc),
        .trap_val_i     (32'd0),
        .mret_i         (mem_is_mret && mem_valid),
        .trap_target_o  (mem_trap_target),
        .mepc_o         (mem_mepc),
        .mstatus_mie_o  (csr_mstatus_mie),
        .mie_meie_o     (csr_mie_meie),
        .mie_msie_o     (csr_mie_msie),
        .mie_mtie_o     (csr_mie_mtie),
        .irq_software_i (irq_software_i),
        .irq_timer_i    (irq_timer_i),
        .irq_external_i (irq_external_i)
    );

    // MEM/WB Pipeline Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_alu_result        <= 32'd0;
            wb_load_data         <= 32'd0;
            wb_pc_plus4          <= 32'd0;
            wb_csr_rdata         <= 32'd0;
            wb_rd_addr           <= 5'd0;
            wb_reg_write         <= 1'b0;
            wb_mem_read          <= 1'b0;
            wb_is_jal_or_jalr    <= 1'b0;
            wb_is_csr            <= 1'b0;
            wb_is_atomic         <= 1'b0;
            wb_atomic_sc_success <= 1'b0;
            wb_valid             <= 1'b0;
        end else begin
            wb_alu_result        <= mem_alu_result;
            wb_load_data         <= mem_load_data_formatted;
            wb_pc_plus4          <= mem_pc_plus4;
            wb_csr_rdata         <= mem_csr_rdata;
            wb_rd_addr           <= mem_rd_addr;
            wb_reg_write         <= mem_reg_write;
            wb_mem_read          <= mem_mem_read;
            wb_is_jal_or_jalr    <= mem_is_jal || mem_is_jalr;
            wb_is_csr            <= mem_is_csr;
            wb_is_atomic         <= mem_is_atomic;
            wb_atomic_sc_success <= atomic_sc_success_i;
            wb_valid             <= mem_valid;
        end
    end

    // ------------------------------------------------------------------------
    // Stage 5: Writeback (WB)
    // ------------------------------------------------------------------------
    always_comb begin
        if (wb_is_atomic && (wb_rd_addr != 5'd0)) begin
            wb_final_data = wb_mem_read ? wb_load_data : {31'b0, !wb_atomic_sc_success};
        end else if (wb_mem_read) begin
            wb_final_data = wb_load_data;
        end else if (wb_is_jal_or_jalr) begin
            wb_final_data = wb_pc_plus4;
        end else if (wb_is_csr) begin
            wb_final_data = wb_csr_rdata;
        end else begin
            wb_final_data = wb_alu_result;
        end
    end

    // ------------------------------------------------------------------------
    // Hazard Unit Instance
    // ------------------------------------------------------------------------
    rv_hazard u_hazard (
        .rs1_id_i           (id_rs1_addr),
        .rs2_id_i           (id_rs2_addr),
        .rd_ex_i            (ex_rd_addr),
        .mem_read_ex_i      (ex_mem_read),
        .multi_cycle_busy_i (ex_md_busy),
        .branch_taken_i     (ex_branch_taken),
        .trap_taken_i       (mem_trap_taken),
        .mret_taken_i       (mem_is_mret && mem_valid),
        .stall_if_o         (stall_if),
        .stall_id_o         (stall_id),
        .stall_ex_o         (stall_ex),
        .flush_if_o         (flush_if),
        .flush_id_o         (flush_id),
        .flush_ex_o         (flush_ex)
    );

endmodule
