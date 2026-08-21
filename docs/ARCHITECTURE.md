# ASIC ARCHITECTURE SPECIFICATION

```text
DOCUMENT: ARCHITECTURE.md
PROJECT: Dual-Core RISC-V Processor with Integrated INT8 AI Accelerator
TARGET PROCESS: SkyWater 130nm (sky130_fd_sc_hd)
FLOW: Cadence Genus / Innovus / Tempus / Voltus / Conformal
```

---

## 1. System Overview

The SoC integrates:
1. **Dual RV32IMA Cores**: Hart 0 and Hart 1 with identical 5-stage in-order pipelines, hardware M-extension (multiplier/iterative divider), A-extension (atomic operations + reservation monitor), and machine-mode CSRs.
2. **8x8 Systolic AI Accelerator**: 64 PEs, weight-stationary dataflow, INT8 signed multiply, INT32 accumulation, post-processing (Bias + ReLU + Scale + Round + Shift + Saturation), autonomous 2D DMA, and custom RISC-V instruction interface.
3. **64 KB Banked SRAM**: 4 interleaved banks (16 KB each) with synchronous access and byte enables.
4. **Interconnect**: AXI4 multi-master high-bandwidth crossbar + AXI4-Lite peripheral bus.
5. **Peripherals**: UART, GPIO, Timer, Interrupt Controller.

---

## 2. Memory Map

| Address Range | Size | Component | Protocol | Function |
| :--- | :--- | :--- | :--- | :--- |
| `0x0000_0000 - 0x0000_FFFF` | 64 KB | Shared Banked SRAM | AXI4 | Code, Data, Tensor Buffers |
| `0x1000_0000 - 0x1000_00FF` | 256 B | AI Accelerator Registers | AXI4-Lite | Matrix/Conv Config & Control |
| `0x2000_0000 - 0x2000_00FF` | 256 B | Multicore CLINT & IPI | AXI4-Lite | Software Interrupts & Mutex |
| `0x3000_0000 - 0x3000_00FF` | 256 B | UART Controller | AXI4-Lite | Console IO & Printf |
| `0x4000_0000 - 0x4000_00FF` | 256 B | GPIO Controller | AXI4-Lite | 16-bit IO & Interrupts |
| `0x5000_0000 - 0x5000_00FF` | 256 B | Interrupt Controller | AXI4-Lite | Routing & Priority Aggregation |
