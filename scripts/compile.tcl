# ============================================================================
# File: compile.tcl
# Project: Dual-Core RISC-V with AI Accelerator
# Description: Cadence Xcelium / Incisive RTL Simulation Script
# ============================================================================

set_db / .source_verbose true

# Include paths
set INC_DIRS [list "rtl/core" "rtl/accelerator"]

# Core RTL files
set CORE_FILES [list \
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
]

# Multicore RTL files
set MULTICORE_FILES [list \
    "rtl/multicore/rv_reservation_monitor.sv" \
    "rtl/multicore/rv_atomic_unit.sv" \
    "rtl/multicore/rv_ipi_controller.sv" \
    "rtl/multicore/rv_multicore.sv" \
]

# Accelerator RTL files
set ACCEL_FILES [list \
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
]

# Memory, Bus & Peripheral Files
set SOC_FILES [list \
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

puts "=== Compiling RTL Files with Cadence Xcelium ==="
# xrun -sv -incdir $INC_DIRS $CORE_FILES $MULTICORE_FILES $ACCEL_FILES $SOC_FILES verif/soc/tb_soc_top.sv
