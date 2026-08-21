# ============================================================================
# File: innovus.tcl
# Project: Dual-Core RISC-V with AI Accelerator
# Description: Cadence Innovus Place & Route (PnR) to GDSII Script (SkyWater 130nm)
# ============================================================================

set_db / .source_verbose true

# 1. Design & Library Initialization
set_db init_netlist_files "netlist/soc_top_synth.v"
set_db init_top_cell "soc_top"
set_db init_lef_files [list "sky130_fd_sc_hd.tlef" "sky130_fd_sc_hd.lef"]
set_db init_power_nets "VDD"
set_db init_ground_nets "VSS"

init_design

# 2. Floorplanning (Target 70% Core Utilization)
create_floorplan -core_util 0.70 -core_margins_by die -core_margin_top 15.0 -core_margin_bottom 15.0 -core_margin_left 15.0 -core_margin_right 15.0

# 3. Power Distribution Network (PDN Rings & Stripes)
add_rings -nets {VDD VSS} -type core_rings -width 4.0 -spacing 1.5 -layer {top met4 bottom met4 left met5 right met5}
add_stripes -nets {VDD VSS} -layer met4 -direction horizontal -width 2.0 -spacing 1.0 -set_to_set_distance 20.0
add_stripes -nets {VDD VSS} -layer met5 -direction vertical -width 2.0 -spacing 1.0 -set_to_set_distance 20.0
sroute -connect {blockPin corePin padPin}

# 4. Standard Cell Placement & Pre-CTS Optimization
set_db place_opt_run_cloning true
place_opt_design

# 5. Clock Tree Synthesis (CTS - CCOpt Engine)
create_clock_tree_spec
ccopt_design

# 6. Detailed Routing (NanoRoute)
set_db route_design_detail_post_route_spread_wire true
route_design

# 7. Post-Route Timing & Physical Optimization
opt_design -post_route

# 8. Physical Signoff Verification (DRC / LVS / Antenna)
check_drc -out_file reports/physical/innovus_drc.rpt
check_connectivity -out_file reports/physical/innovus_lvs.rpt
check_process_antenna -out_file reports/physical/innovus_antenna.rpt

# 9. GDSII & Signoff Netlist Export
write_stream physical/soc_top.gds -map_file sky130.gds.map
write_netlist physical/soc_top_final.v
write_def physical/soc_top.def
write_spef physical/soc_top.spef

puts "=== Cadence Innovus RTL-to-GDSII Implementation Complete ==="
