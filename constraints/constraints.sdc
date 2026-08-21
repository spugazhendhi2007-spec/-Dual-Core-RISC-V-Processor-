# ============================================================================
# File: constraints.sdc
# Project: Dual-Core RISC-V with AI Accelerator
# Description: Synopsys Design Constraints (SDC) for SkyWater 130nm ASIC Signoff
# ============================================================================

# Target Operating Frequency: 100 MHz (Period: 10.0 ns)
set CLK_PERIOD 10.0
set CLK_PORT   "clk"
set RST_PORT   "rst_n"

# Clock Definition
create_clock -name sys_clk -period $CLK_PERIOD [get_ports $CLK_PORT]
set_clock_uncertainty -setup 0.5 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.1 [get_clocks sys_clk]
set_clock_transition 0.15 [get_clocks sys_clk]

# Input / Output Delays (30% of Clock Period Budget)
set_input_delay -clock sys_clk -max 3.0 [remove_from_collection [all_inputs] [get_ports "$CLK_PORT $RST_PORT"]]
set_input_delay -clock sys_clk -min 0.5 [remove_from_collection [all_inputs] [get_ports "$CLK_PORT $RST_PORT"]]

set_output_delay -clock sys_clk -max 3.0 [all_outputs]
set_output_delay -clock sys_clk -min 0.5 [all_outputs]

# Driving Cell & Load Modeling (Sky130 standard cells)
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 [remove_from_collection [all_inputs] [get_ports "$CLK_PORT $RST_PORT"]]
set_load 0.05 [all_outputs]

# False Paths on Asynchronous Reset
set_false_path -from [get_ports $RST_PORT]
