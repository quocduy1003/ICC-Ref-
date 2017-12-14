###########Task 1. Checking Logical Design Setup
# Library setup
lappend search_path ../ref/db ../ref/tlup
set target_library "sc_max.db"
set link_library "*"
foreach lib {sc io ram16x128} {
  lappend link_library ${lib}_max.db
  set_min_library $lib\_max.db -min_version $lib\_min.db}
##Open the design library, and then make a copy for a working design cell.
# Open the copied design cell to perform the placement exploration.
open_mw_lib orca_lib.mw
copy_mw_cel -from ORCA_TOP -to explore
open_mw_cel explore
#     Note: Making a copy of a cell is optional. However, it is a good practice to work on a copy of a design cell to avoid accidentally overwriting the starting design cell.
# Verify that the clock definitions are complete:
report_clock
report_clock -skew
report_port -v *clk
# Perform a timing sanity check using zero-interconnect delay mode:
set_zero_interconnect_delay_mode true
report_timing
# Turn off timing for the scan enable net, since it will be handled later by place_opt:
set_ideal_network [get_ports scan_en]
report_timing
# Check all constraint violations:
report_constraint -all
view
report_constraint -all_violators -nosplit
## You should find that there are a number of hold violations, which we don’t care about now. Also, there are max transition and max capacitance violations on the reset networks, which high fanout synthesis will take care of during place_opt.
##Don’t forget to turn off ZIC:
set_zero_interconnect_delay_mode false
############Task 2. Placement Exploration
#Open the graphical user interface (GUI).
start_gui
#Check for potential floorplan issues:
check_physical_design -for_placement
check_physical_constraints
# So how is it possible that utilization is so high even before starting? Use the following command to get a quick picture of what is going on:
create_placement -quick
report_pnet_options
set_pnet_options -none {METAL2 METAL3 METAL4}
set_pnet_options -partial {METAL2 METAL3 METAL4}
report_pnet_options
check_physical_constraints
# Apply soft and hard keepouts to the floorplan as learned in lecture:
set physopt_hard_keepout_distance 5
set physopt_soft_keepout_distance 15
# Perform placement, so you can see how the settings applied so far affect the design:
create_placement
legalize_placement
report_placement_utilization
# Generate and Analyze a placement congestion map :draw placement congestion map
# Have a look at a cell density map, to see whether the cell distribution may be problematic. :Select “Pin Density” from the already open dialog that is used to display the congestion, or choose Placement Pin Density Map. Set the Grid Dimension to 2 std cell heights and apply.
# Run placement with congestion options to see if congestion in the bottom areas of the design improves:
create_placement -congestion
legalize_placement
# Follow up with a high effort congestion placement:
create_placement -congestion -congestion_effort high
legalize_placement
# NHAN XET VE DENSITY CELL, PIN, PLACEMENT CONGRESTION MAP, GLOBAL ROUTE MAP CUA 3 KIEU CHAY PLACEMENT TREN
#############        Task 3. Timing
# Before going any further, analyze the timing of the placed design.
report_timing
#To see whether the timing can be improved by better placement, run the following command. This will enable the timing-driven placement:
create_placement -timing_driven -congestion \
    -congestion_effort high
legalize_placement
report_timing
###########Task 4. Perform Placement and Optimization
close_mw_cel
# Copy and open a working design cell to perform the placement and optimization.
copy_mw_cel -from ORCA_TOP -to place_opt
open_mw_cel place_opt
#### Apply the provided script to add the physical design constraints you found during the previous tasks:
# These are OFF by default!
set enable_recovery_removal_arcs true
set physopt_enable_via_res_support true
# Hard keepout alway creates the margin around the macros
set physopt_hard_keepout_distance 5
# Soft keepout only affects between the macros or the macro and the core boundary
set physopt_soft_keepout_distance 15
set_pnet_options -none {METAL2 METAL3 METAL4}
set_pnet_options -partial {METAL2 METAL3 METAL4}
# Before running place_opt, you need to make sure that scan information has been annotated on the design. Execute the following command:
report_scan_chain
# If you don’t see anything, this means that no scan chain information was loaded.
# Load the SCANDEF file:
read_def ../ref/design_data/ORCA_TOP.scandef
v report_scan_chain
# You should see scan chains now! This information will be used during place_opt to optimize the scan chain wiring.
# Report the settings for high fanout synthesis:
report_ahfs_options
# Based on the above, and knowing the defaults (see man-page) have a look at which nets are candidates for high fanout synthesis:
all_high_fanout -nets -threshold 100
# Based on your observations earlier, perform a placement and optimization run while optimizing :
place_opt -optimize_dft -congestion
# Save the current design as “placed”.
save_mw_cel -as placed
report_placement_utilization
# Run the following command to have a look at your high fanout nets
report_buffer_tree_qor -from [all_high_fanout -nets \
   -threshold 100 -through_buf_inv]
# You can see that the reset nets and scan_en have been buffered.
# Perform an incremental area recovery:
set_max_area 0
set physopt_area_critical_range 0.1
psynopt -area_recovery
#     Note:  Any area recovery will lower the utilization of the standard cells and may help lower the congestion.
#### Task 5. Incremental Dynamic Power Optimization
# 1. Enable dynamic power optimization (disabled by default):
report_power_options
set_power_options -dynamic true
report_power_options
# 2. Set the toggle rates for the design:
set_switching_activity -toggle_rate 0.25  -static_probability 0.5 [get_ports  pad_in[*]]
set_switching_activity -toggle_rate 0.30  -static_probability 0.5 [get_ports  pc_be_in[*]]
set_switching_activity -toggle_rate 0.70  -static_probability 0.5 [get_ports  sd_DQ_in[*]]
set_switching_activity -toggle_rate 0.00  -static_probability 0.0 [get_ports "scan_en test_mode *rst_n pidsel pgnt_n pm66en"]
set_switching_activity -toggle_rate 0.03 -static_probability 0.5 [get_ports  "ppar_in pframe_n_in ptrdy_n_in pirdy_n_in pdevsel_n_in pstop_n_in pperr_n_in pserr_n_in"]
# 3. Report and record the current dynamic power dissipation:
report_power
# or You can also see the power using “report_constraint”.
# Perform incremental power optimization and generate a power report for comparison:
psynopt -power
report_power
# Enabling power optimization during placement and optimization (place_opt) would show a bigger reduction.
# If you wish though, you can start a power optimization using the full place_opt flow, and look at the results in the morning! Start with a clean design, and make sure you set the following options:
set_power_options -dynamic true \
   -low_power_placement true
place_opt -congestion -optimize_dft -power
report_power
