# ============================================================================
# File: genus.tcl
# Project: Dual-Core RISC-V with AI Accelerator
# Description: Cadence Genus Synthesis & PPA Optimization Script (SkyWater 130nm)
# ============================================================================

set_db / .source_verbose true
set_db information_level 7

# 1. Target Library Setup (SkyWater 130nm)
set_db target_library "sky130_fd_sc_hd__tt_025C_1v80.lib"
set_db link_library "* sky130_fd_sc_hd__tt_025C_1v80.lib"
set_db lef_library "sky130_fd_sc_hd.tlef sky130_fd_sc_hd.lef"

# 2. Read RTL Sources
set_db init_hdl_search_path [list "rtl/core" "rtl/multicore" "rtl/accelerator" "rtl/memory" "rtl/bus" "rtl/peripherals" "rtl/soc"]

read_hdl -language sv [list \
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
]

# 3. Elaborate Top Design
elaborate soc_top
check_design -unresolved

# 4. Apply Timing Constraints
read_sdc constraints/constraints.sdc

# 5. Synthesis & Optimization (Generic -> Mapping -> Spatial)
syn_generic
syn_map
syn_opt

# 6. Generate Reports
report_area > reports/area/genus_area.rpt
report_timing > reports/timing/genus_timing.rpt
report_power > reports/power/genus_power.rpt
report_qor > reports/genus_qor.rpt

# 7. Export Gate-Level Netlist & SDC for PnR
write_hdl > netlist/soc_top_synth.v
write_sdc > netlist/soc_top_synth.sdc

puts "=== Cadence Genus Synthesis Complete ==="
