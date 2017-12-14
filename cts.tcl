##Task 1. Load the Design
set auto_restore_mw_cel_lib_setup true
# Library setup
lappend search_path ../ref/db ../ref/tlup
set target_library "sc_max.db"
set link_library "*"
foreach lib {sc io ram16x128} {
  lappend link_library ${lib}_max.db
  set_min_library $lib\_max.db -min_version $lib\_min.db}
# open design lib
open_mw_lib orca_lib.mw
open_mw_cel place_opt
##Task 2. Examine the Clock Trees
# The following commands should be executed before performing CTS.
check_physical_design -for_cts
check_clock_tree
report_clock
report_clock -skew
report_clock_tree -summary
report_constraint -all
##Task 3. Preparing for Clock Tree Synthesis
remove_routing_rules -all
# Step 1
set_clock_tree_exceptions \
   -stop_pins {I_SDRAM_TOP/I_SDRAM_IF/sd_mux_*/S}
# Step 2
set_clock_tree_options -target_skew 0.1
# Step 3
set_clock_uncertainty 0.1 [all_clocks]
# Step 4
reset_clock_tree_references
set_clock_tree_references -references \
      {bufbd1 bufbd2 bufbd4 bufbd7 bufbdf}
# Step 5
define_routing_rule double_spacing \
   -spacings {METAL2 0.6 METAL3 0.6 METAL4 0.8
          METAL5 1.2 METAL6 1.4}
set_clock_tree_options -routing_rule double_spacing \
        -layer_list {METAL3 METAL4 METAL5 METAL6}
define_routing_rule double_spacing \
	-spacings {METAL2 0.6 METAL3 0.6 METAL4 0.8 METAL5 1.2 METAL6 1.4}
set_clock_tree_options -routing_rule double_spacing \
	-layer_list {METAL3 METAL4 METAL5 METAL6}
report_clock_tree -settings
##Task 4. Perform Clock Tree Synthesis
# If you were to use the core command clock_opt at this stage, this lab would end in about 5 minutes! clock_opt will be able to build the clock tree, fix all setup and hold violations, and route the clock. You can try if you like.
# clock_opt
# Synthesize all clock trees:
compile_clock_tree
#2. Review the global skew after CTS:
report_clock_tree -summary
# 3. Generate a different skew report:
report_clock_timing -type skew -sign 3
# expand the differences in the skews reported
report_timing
##Task 5. Perform Hold Time Optimization
#1. Turn on hold time fixing.
set_fix_hold [all_clocks]
#2. Generate a QoR report:
report_qor
#3. Perform psynopt:
set_max_area 0
set physopt_area_critical_range 0.1
psynopt -area_recovery
# Task 6. Route the Clocks
#1. Remove the max_area constraint so it does not show up in the report_constaint reports as a violation anymore. Execute the following command:
remove_attribute [current_design] max_area
#2. Route the clocks:
route_group -all_clock_nets
#3. report timing final
report_timing
#4.save as cts_routed 
save_mw_cel -as cts_routed
##Task 7. clock_opt
open_mw_cel place_opt -library orca_lib.mw
set_clock_uncertainty 0.1 [all_clocks]
set_clock_tree_options -target_skew 0.1
set_clock_tree_exceptions \
	-stop_pins {I_SDRAM_TOP/I_SDRAM_IF/sd_mux_*/S}
reset_clock_tree_references
set_clock_tree_references -references {bufbd1 bufbd2 bufbd4 bufbd7 bufbdf}
remove_routing_rules -all
define_routing_rule double_spacing \
	-spacings {METAL2 0.6 METAL3 0.6 METAL4 0.8 METAL5 1.2 METAL6 1.4}
set_clock_tree_options -routing_rule double_spacing \
	-layer_list {METAL3 METAL4 METAL5 METAL6}
#3. Perform CTS:
clock_opt -fix_hold_all_clocks
# Clock trees are now built, hold is fixed, and trees are detail-routed.
report_clock_tree -summary
report_clock_timing -type skew
report_constraint -all
report_timing
report_timing -delay min
save_mw_cel -as cts
