# lab 6 run script

set auto_restore_mw_cel_lib_setup true

# gui_start

open_mw_lib orca_lib.mw
copy_mw_cel -from cts -to route_opt
open_mw_cel route_opt
# definitions
set my_mw_lib    orca_lib.mw
set mw_path      "../ref/mw_lib"
set tech_file    "../ref/tech/cb13_6m.tf"
set tlup_map     "cb13_6m.map"
set tlup_max     "cb13_6m_max.tluplus"
set tlup_min     "cb13_6m_min.tluplus"
set top_design   "ORCA"
set verilog_file "./design_data/ORCA.v"
set scandef_file "./design_data/ORCA.scandef"
set sdc_file     "./design_data/ORCA.sdc"
set tdf_file     "./design_data/ORCA.tdf"
set libs         {sc io special ram4x32 ram8x64 ram32x64 ram16x128}
# setup library
lappend search_path "../ref/db ../ref/tlup"
set target_library "sc_max.db"
set link_library "*"
set mw_ref_libs ""
foreach lib $libs {
	lappend link_library ${lib}_max.db
	lappend mw_ref_libs $mw_path/$lib
}
##lib_min.tcl
foreach lib {sc io ram8x64 ram16x128} {
        set_min_library $lib\_max.db -min_version $lib\_min.db
}
set_operating_conditions \
        -max cb13fs120_tsmc_max \
        -max_library cb13fs120_tsmc_max \
        -min cb13fs120_tsmc_min \
        -min_library cb13fs120_tsmc_min
## end lib_min.tcl
#Task 2. Check the Design
report_constraint -all
##Task 3. Routing & Optimization
report_route_opt_strategy
#1. you will route the design, making sure that the router doesn’t spend too much time on the design. Execute the following commands:
# Limit the number of loops, for the purpose of
# this lab only!
set_route_opt_strategy -search_repair_loops 1 -eco_route_search_repair_loops 1
#
route_opt
#2. Save the current cell
save_mw_cel
#Task 4. DRC Error Checking and Fixing
#1. Use the LayoutWindow menu: Verification Error Browser … to open the “Error Browser”. 
#2. Select which error to view. Select a category as shown below. Highlight one of the errors using the mouse. The layout view zooms to the error. Browse afew other errors and/or error types. Close the browser when you are satisfied.(The screenshot shown below may not match what you see!)
#3. Make sure the current design was saved (save_mw_cel). This is required since Hercules runs on the cell saved in the design Milkyway library.
save_mw_cel
# 4. Run the Hercules Detailed DRC checker using Verification DRC or using the command verify_drc.
verify_drc
# 5. Bring up the Route Routing Setup Set Route Options… In the Miscellaneous tab, select “Check and fix” under the two options “Check Same Net Notch”, as well as “Wire / Contact end of line rule”. Confirm with OK.
#set_route_options  -default
set_route_options \
	-same_net_notch check_and_fix \
	-wire_contact_eol_rule check_and_fix
#6. Recalculate the number of DRC violations as seen by the router using Route Verify Route… or use the command verify_route.
verify_route
set_route_opt_strategy -default
#8. Run a search & repair operation with 5 loops to repair the new DRC violation (use the lecture for help).
route_search_repair -loop 5
#9. Save the CEL one more time, then run the Hercules DRC checker once again.You should see that the number of violations has gone down quite a bit. If youlike and you are not running out of time, observe the errors in the error browser one last time.
verify_drc
#Task 6. Signal Integrity
#1. Enable SI analysis by bringing up the menu Timing Set SI Options, or by entering the following command:
set_si_options \
	-route_xtalk_prevention true \
	-route_xtalk_prevention_threshold 0.35 \
	-delta_delay true \
	-static_noise true \
	-static_noise_threshold_above_low 0.30 \
	-static_noise_threshold_below_high 0.30
#2. Analyze the design for constraint violations.
report_constraint -all
#3. You can perform further analysis to see what exactly is causing the violation:
report_timing -crosstalk_delta
#4. Experiment with the following command until the design meets timing underSI. You may also use the lecture and try some of the other options shown there.
route_opt -incremental -xtalk_reduction
report_constraint -all
# save
save_mw_cel -overwrite
verify_drc
# Print diagnostics summary
print_message_info
