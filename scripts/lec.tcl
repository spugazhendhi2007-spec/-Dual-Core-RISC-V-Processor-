# ============================================================================
# File: lec.tcl
# Project: Dual-Core RISC-V with AI Accelerator
# Description: Cadence Conformal Logic Equivalence Checking (LEC) Script
# ============================================================================

set log file reports/lec/conformal_lec.log -replace

# Set Golden Design (RTL)
read design -golden -sv09 [list \
    "rtl/core/rv_defines.svh" \
    "rtl/core/rv_fetch.sv" \
    "rtl/core/rv_decode.sv" \
    "rtl/core/rv_regfile.sv" \
    "rtl/core/rv_alu.sv" \
    "rtl/core/rv_branch.sv" \
    "rtl/core/rv_multiplier.sv" \
    "rtl/core/rv_divider.sv" \
    "rtl/core/rv_hazard.sv" \
    "rtl/core/rv_forwarding.sv" \
    "rtl/core/rv_csr.sv" \
    "rtl/core/rv_exception.sv" \
    "rtl/core/rv_pipeline_regs.sv" \
    "rtl/core/rv_ai_interface.sv" \
    "rtl/core/rv_core.sv" \
    "rtl/multicore/rv_reservation_monitor.sv" \
    "rtl/multicore/rv_atomic_unit.sv" \
    "rtl/multicore/rv_ipi_controller.sv" \
    "rtl/multicore/rv_multicore.sv" \
    "rtl/accelerator/ai_defines.svh" \
    "rtl/accelerator/ai_pe.sv" \
    "rtl/accelerator/ai_systolic_array.sv" \
    "rtl/accelerator/ai_input_buffer.sv" \
    "rtl/accelerator/ai_weight_buffer.sv" \
    "rtl/accelerator/ai_output_buffer.sv" \
    "rtl/accelerator/ai_accumulator.sv" \
    "rtl/accelerator/ai_post_process.sv" \
    "rtl/accelerator/ai_dma.sv" \
    "rtl/accelerator/ai_controller.sv" \
    "rtl/accelerator/ai_accel_top.sv" \
    "rtl/memory/sram_bank.sv" \
    "rtl/memory/memory_arbiter.sv" \
    "rtl/memory/sram_controller.sv" \
    "rtl/bus/axi4_interconnect.sv" \
    "rtl/bus/axi4lite_interconnect.sv" \
    "rtl/peripherals/uart.sv" \
    "rtl/peripherals/gpio.sv" \
    "rtl/peripherals/timer.sv" \
    "rtl/peripherals/interrupt_controller.sv" \
    "rtl/soc/soc_top.sv" \
] -root soc_top

# Set Revised Design (Synthesized Netlist)
read library -statename sky130 sky130_fd_sc_hd__tt_025C_1v80.lib
read design -revised -verilog netlist/soc_top_synth.v -root soc_top

# Map key points and verify equivalence
set system mode lec
map key points
add compare points -all
compare

# Report Differences
report compare data -noneq > reports/lec/non_equivalent_points.rpt
report compare data -abort > reports/lec/aborted_points.rpt

puts "=== Cadence Conformal LEC Verification Complete ==="
