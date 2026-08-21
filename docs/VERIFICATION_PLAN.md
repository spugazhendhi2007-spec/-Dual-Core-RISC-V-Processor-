# ASIC VERIFICATION PLAN

```text
DOCUMENT: VERIFICATION_PLAN.md
PROJECT: Dual-Core RISC-V with Integrated INT8 AI Accelerator
TARGET METRIC: >= 90% Functional & Code Coverage, 0 RTL-vs-Model Mismatches
```

---

## 1. Modular Self-Checking Verification Architecture

Each RTL module is accompanied by an isolated, deterministic, self-checking SystemVerilog testbench in `verif/`:

* **Unit Testbenches (`verif/unit/`)**:
  - `tb_alu.sv`: Exhaustive tests for all ALU operations (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND).
  - `tb_regfile.sv`: 2-read/1-write port access, write-through/hazard check, x0 zero verification.
  - `tb_decode.sv`: RV32I, RV32M, RV32A and Custom AI instruction decode validation.
  - `tb_multiplier.sv`: 32x32 signed/unsigned multiplications (`MUL`, `MULH`, `MULHSU`, `MULHU`).
  - `tb_divider.sv`: 32-cycle iterative division/remainder (`DIV`, `DIVU`, `REM`, `REMU`), divide-by-zero, overflow.
  - `tb_branch.sv`: Branch conditions (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`) and target calculation.
  - `tb_csr.sv`: Machine-mode CSR read/write/set/clear and trap vector jumps.
  - `tb_hazard.sv`: Load-use stall assertion and branch/trap pipeline flushes.
  - `tb_forwarding.sv`: EX-to-EX and MEM-to-EX operand bypassing paths.
  - `tb_atomic_unit.sv`: Atomic ALU operations (`AMOSWAP`, `AMOADD`, `AMOXOR`, `AMOAND`, `AMOOR`, `AMOMIN`, `AMOMAX`).
  - `tb_reservation_monitor.sv`: `LR.W` reservation registration and external conflicting store invalidation.
  - `tb_pe.sv`: Processing Element INT8 multiply, INT32 accumulation, enable/clear controls.
  - `tb_post_process.sv`: Bias addition, ReLU activation, scaling, rounding, arithmetic shift, INT8 saturation.
  - `tb_sram_bank.sv`: 16 KB SRAM synchronous read/write with byte enables.
  - `tb_uart.sv`: TX FIFO serialization and RX framing.
  - `tb_gpio.sv`: Pin IO and edge-triggered interrupt detection.
  - `tb_timer.sv`: Prescaler and periodic interrupt firing.

* **Subsystem Testbenches**:
  - `verif/core/tb_core.sv`: Single RV32IMA core instruction execution.
  - `verif/multicore/tb_multicore.sv`: Dual-core concurrency, IPI, and spinlock synchronization.
  - `verif/accelerator/tb_systolic_array.sv`: 8x8 matrix multiplication mesh.
  - `verif/accelerator/tb_dma.sv`: 2D stride burst transfers.
  - `verif/accelerator/tb_ai_accel_top.sv`: Complete AI accelerator subsystem.
  - `verif/soc/tb_soc_top.sv`: Full SoC end-to-end simulation.

* **Golden Reference Model (`verif/model/ai_ref_model.py`)**:
  - Pure Python reference model executing 1,000+ randomized GEMM and Conv2D stress tests.
