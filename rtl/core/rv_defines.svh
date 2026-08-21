// ============================================================================
// File: rv_defines.svh
// Project: Dual-Core RISC-V with AI Accelerator
// Description: Global RISC-V Constants, Opcodes, Enums & CSR Addresses
// ============================================================================

`ifndef RV_DEFINES_SVH
`define RV_DEFINES_SVH

// ALU Operations
typedef enum logic [3:0] {
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_SLL  = 4'd2,
    ALU_SLT  = 4'd3,
    ALU_SLTU = 4'd4,
    ALU_XOR  = 4'd5,
    ALU_SRL  = 4'd6,
    ALU_SRA  = 4'd7,
    ALU_OR   = 4'd8,
    ALU_AND  = 4'd9
} rv_alu_op_e;

// Multiplier & Divider Operations
typedef enum logic [2:0] {
    MD_MUL    = 3'b000,
    MD_MULH   = 3'b001,
    MD_MULHSU = 3'b010,
    MD_MULHU  = 3'b011,
    MD_DIV    = 3'b100,
    MD_DIVU   = 3'b101,
    MD_REM    = 3'b110,
    MD_REMU   = 3'b111
} rv_md_op_e;

// Atomic Funct5 Encodings
localparam logic [4:0] AMO_LR   = 5'b00010;
localparam logic [4:0] AMO_SC   = 5'b00011;
localparam logic [4:0] AMO_SWAP = 5'b00001;
localparam logic [4:0] AMO_ADD  = 5'b00000;
localparam logic [4:0] AMO_XOR  = 5'b00100;
localparam logic [4:0] AMO_AND  = 5'b01100;
localparam logic [4:0] AMO_OR   = 5'b01000;
localparam logic [4:0] AMO_MIN  = 5'b10000;
localparam logic [4:0] AMO_MAX  = 5'b10100;
localparam logic [4:0] AMO_MINU = 5'b11000;
localparam logic [4:0] AMO_MAXU = 5'b11100;

// CSR Operations
localparam logic [2:0] CSR_RW  = 3'b001;
localparam logic [2:0] CSR_RS  = 3'b010;
localparam logic [2:0] CSR_RC  = 3'b011;
localparam logic [2:0] CSR_RWI = 3'b101;
localparam logic [2:0] CSR_RSI = 3'b110;
localparam logic [2:0] CSR_RCI = 3'b111;

// CSR Addresses
localparam logic [11:0] CSR_MSTATUS  = 12'h300;
localparam logic [11:0] CSR_MISA     = 12'h301;
localparam logic [11:0] CSR_MIE      = 12'h304;
localparam logic [11:0] CSR_MTVEC    = 12'h305;
localparam logic [11:0] CSR_MSCRATCH = 12'h340;
localparam logic [11:0] CSR_MEPC     = 12'h341;
localparam logic [11:0] CSR_MCAUSE   = 12'h342;
localparam logic [11:0] CSR_MTVAL    = 12'h343;
localparam logic [11:0] CSR_MIP      = 12'h344;
localparam logic [11:0] CSR_MCYCLE   = 12'hB00;
localparam logic [11:0] CSR_MINSTRET = 12'hB02;
localparam logic [11:0] CSR_MHARTID  = 12'hF14;

// Trap Causes
localparam logic [31:0] TRAP_ILLEGAL = 32'd2;
localparam logic [31:0] TRAP_ECALL_M = 32'd11;
localparam logic [31:0] TRAP_IRQ_SFT = 32'h8000_0003;
localparam logic [31:0] TRAP_IRQ_TMR = 32'h8000_0007;
localparam logic [31:0] TRAP_IRQ_EXT = 32'h8000_000B;

`endif
