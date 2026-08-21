# ASIC PROJECT REQUIREMENTS

```text
DOCUMENT: PROJECT_REQUIREMENTS.md
PROJECT: Dual-Core RISC-V Processor with Integrated INT8 AI Accelerator
TARGET PROCESS: SkyWater 130nm (sky130_fd_sc_hd)
FLOW: Cadence Genus / Innovus / Tempus / Voltus / Conformal
```

---

## 1. Subsystem Requirements

1. **Dual RV32IMA Cores**:
   - RV32I base instructions + RV32M multiplier/divider + RV32A atomic instructions.
   - 5-stage in-order pipeline (IF-ID-EX-MEM-WB) with branch resolution in EX.
   - Machine-mode CSRs, exception handling, data forwarding, and hazard management.
2. **8x8 Systolic AI Accelerator**:
   - 64 Processing Elements (PEs) with INT8 signed $\times$ INT8 signed $\to$ INT32 accumulation.
   - Weight-stationary dataflow.
   - Multi-lane post-processing (Bias, ReLU/ReLU6, Fixed-Point Scale, Rounding, Shift, INT8 Saturation $[-128, +127]$).
   - Autonomous 2D DMA engine.
   - Custom RISC-V instruction coprocessor interface (`AI_CFG`, `AI_START`, `AI_WAIT`).
3. **Memory & Interconnect**:
   - 64 KB Banked SRAM (4 x 16 KB interleaved).
   - High-throughput AXI4 multi-master crossbar + AXI4-Lite peripheral bus.
4. **Peripherals**:
   - UART, GPIO (16-bit), Timer, Centralized Interrupt Controller.
5. **Physical & Signoff Specifications**:
   - Target Frequency: 100 MHz (Clock Period = 10.0 ns) on SKY130 HD library.
   - LEC: 100% equivalence between RTL and synthesized gate netlist.
