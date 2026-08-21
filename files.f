// ============================================================================
// File: files.f
// Description: Cadence Incisive (irun) / Xcelium (xrun) Filelist
// ============================================================================

-sv
-incdir rtl/core
-incdir rtl/accelerator
-access +rwc
-nowarn SPDUSD
-nowarn DSEMEL
-nowarn DLCPTH
-nowarn LIBNOU

// Core Subsystem
rtl/core/rv_defines.svh
rtl/core/rv_fetch.sv
rtl/core/rv_decode.sv
rtl/core/rv_regfile.sv
rtl/core/rv_alu.sv
rtl/core/rv_multiplier.sv
rtl/core/rv_divider.sv
rtl/core/rv_hazard.sv
rtl/core/rv_forwarding.sv
rtl/core/rv_branch.sv
rtl/core/rv_csr.sv
rtl/core/rv_exception.sv
rtl/core/rv_pipeline_regs.sv
rtl/core/rv_ai_interface.sv
rtl/core/rv_core.sv

// Multicore Subsystem
rtl/multicore/rv_reservation_monitor.sv
rtl/multicore/rv_atomic_unit.sv
rtl/multicore/rv_ipi_controller.sv
rtl/multicore/rv_multicore.sv

// AI Accelerator Subsystem
rtl/accelerator/ai_defines.svh
rtl/accelerator/ai_pe.sv
rtl/accelerator/ai_systolic_array.sv
rtl/accelerator/ai_input_buffer.sv
rtl/accelerator/ai_weight_buffer.sv
rtl/accelerator/ai_output_buffer.sv
rtl/accelerator/ai_accumulator.sv
rtl/accelerator/ai_post_process.sv
rtl/accelerator/ai_dma.sv
rtl/accelerator/ai_controller.sv
rtl/accelerator/ai_accel_top.sv

// Memory, Bus & Peripherals
rtl/memory/sram_bank.sv
rtl/memory/memory_arbiter.sv
rtl/memory/sram_controller.sv
rtl/bus/axi4_interconnect.sv
rtl/bus/axi4lite_interconnect.sv
rtl/peripherals/uart.sv
rtl/peripherals/gpio.sv
rtl/peripherals/timer.sv
rtl/peripherals/interrupt_controller.sv
rtl/soc/soc_top.sv

// Testbench Top
verif/soc/tb_soc_top.sv
