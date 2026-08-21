# ENGINEERING DECISION LOG

```text
DOCUMENT: DECISION_LOG.md
PROJECT: Dual-Core RISC-V Processor with Integrated INT8 AI Accelerator
```

---

## Decision Record

* **DEC-001: Systolic Array Dimension Specification**: 8x8 Grid = 64 Processing Elements with INT8 signed inputs and INT32 accumulation.
* **DEC-002: Dual-Core Coherence & Synchronization**: 64 KB Banked SRAM with Hardware Reservation Monitor for `LR.W`/`SC.W` and atomic ALU operations (`AMO`).
* **DEC-003: AI Coprocessor Interface**: Dual support for memory-mapped AXI4-Lite control registers (0x1000_0000) and custom RISC-V instructions (`AI_CFG`, `AI_START`, `AI_WAIT`).
* **DEC-004: Target Technology & ASIC EDA Flow**: SkyWater 130nm (`sky130_fd_sc_hd`) standard cell library, synthesized via Cadence Genus, verified via Conformal LEC, physical P&R via Innovus, and STA via Tempus.
