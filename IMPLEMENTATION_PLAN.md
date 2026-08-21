# IMPLEMENTATION_PLAN.md

# Dual-Core RISC-V Processor with Integrated INT8 AI Accelerator
## Complete RTL-to-GDSII ASIC Implementation

---

## 1. PROJECT TITLE

Design, PPA Optimization and RTL-to-GDSII Implementation of a Dual-Core
RISC-V Processor with Integrated INT8 AI Accelerator for Edge AI Applications.

---

## 2. PROJECT OBJECTIVE

Design and implement a complete dual-core 32-bit RISC-V processor with an
integrated INT8 AI accelerator and take the design through the complete ASIC
RTL-to-GDSII flow.

The project shall include:

1. Dual RV32IMA processor cores.
2. Five-stage in-order pipelines.
3. Hardware multiplication and iterative division.
4. Atomic instructions for multicore synchronization.
5. Shared banked SRAM.
6. AXI4 system interconnect.
7. AXI4-Lite peripheral/control interface.
8. INT8 8x8 systolic AI accelerator.
9. INT32 accumulation.
10. Programmable AI DMA.
11. Custom RISC-V AI instruction interface.
12. UART/GPIO/timer/interrupt peripherals.
13. Bare-metal firmware.
14. Comprehensive RTL verification.
15. Functional and code coverage.
16. Logic synthesis.
17. Static timing analysis.
18. Logical equivalence checking.
19. Physical implementation.
20. Power analysis.
21. DRC/LVS verification.
22. Final GDSII generation.

---

# 3. FIXED ARCHITECTURAL SPECIFICATION

The following parameters are frozen for the baseline implementation.

| Parameter | Specification |
|-----------|---------------|
| Number of CPU cores | 2 |
| ISA | RV32IMA |
| Data width | 32 bit |
| Pipeline | 5-stage in-order |
| Pipeline stages | IF-ID-EX-MEM-WB |
| Branch resolution | EX stage |
| Register file | 32 x 32 bit |
| Register ports | 2 read + 1 write |
| x0 | Hardwired zero |
| M extension | MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU |
| Divider | Iterative |
| A extension | LR.W/SC.W + required AMO instructions |
| AI precision | INT8 |
| AI accumulator | INT32 |
| AI architecture | 8 x 8 systolic array |
| Number of AI PEs | 64 |
| AI operations | GEMM and tiled Conv2D |
| Activation | INT8 signed |
| Weight | INT8 signed |
| Post processing | Bias + ReLU + Requantization |
| DMA | Programmable 2D DMA |
| Shared SRAM | 64 KB |
| SRAM organization | Banked |
| Interconnect | AXI4 |
| Control bus | AXI4-Lite |
| AI interface | Custom RISC-V instruction interface |
| Synchronization | LR/SC + AMO + software interrupts |
| Technology | SKY130 |
| Standard cell library | sky130_fd_sc_hd |
| RTL | SystemVerilog |
| Simulation | Cadence Xcelium/irun |
| Synthesis | Cadence Genus |
| LEC | Cadence Conformal |
| P&R | Cadence Innovus |
| STA | Cadence Tempus |
| Power | Cadence Voltus |
| Final output | GDSII |

Do not silently change these parameters.

Any architectural change must be recorded in DECISION_LOG.md.
