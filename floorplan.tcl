#source "definitions.tcl"
#Floorplaning 

open_mw_lib $lib_name

copy_mw_cel	\
	-from_library $lib_name \
	-from $cell_name \
	-to_library $lib_name \
	-to "${cell_name}_floorplan"

set ::auto_restore_mw_cel_lib_setup false
open_mw_cel  "${cell_name}_floorplan"
current_mw_cel "${cell_name}_floorplan"


initialize_floorplan 	\
	-core_utilization 0.719852	\
	-core_aspect_ratio 0.976415	\
	-start_first_row		\
	-flip_first_row			\
	-left_io2core 10		\
	-bottom_io2core 10		\
	-right_io2core 10		\
	-top_io2core 10

derive_pg_connection 	\
	-power_net VDD	\
	-power_pin VDD	\
	-ground_net VSS	\
	-ground_pin VSS 


create_rectangular_rings 	\
	 -nets  {VDD}		\
	 -left_offset 0.5	\
	 -left_segment_layer M4	\
	 -left_segment_width 2	\
	 -right_offset 0.5 	\
	 -right_segment_layer M4	\
	 -right_segment_width 2	\
	 -bottom_offset 0.5	\
	 -bottom_segment_layer M4	\
	 -bottom_segment_width 2 	\
	 -top_offset 0.5	\
	 -top_segment_layer M4	\
	 -top_segment_width 2	
	 
create_rectangular_rings  \
		-nets  {VSS}	\
		-left_offset 3	\
		-left_segment_layer M5	\
		-left_segment_width 2	\
		-right_offset 3	\
		-right_segment_layer M5	\
		-right_segment_width 2	\
		-bottom_offset 3		\
		-bottom_segment_layer M5	\
		-bottom_segment_width 2		\
		-top_offset 3			\
		-top_segment_layer M5		\
		-top_segment_width 2

create_power_straps	\
	  -direction vertical	\
	  -start_at 44.92 	\
	  -nets  {VDD} 		\
	  -layer M4		\
	  -width 2
	  
create_power_straps \
	 -direction vertical \
	 -start_at 41.920	\
	 -nets  {VSS}	\
	 -layer M5	\
	 -width 2

save_mw_cel  -design "${cell_name}_floorplan.CEL;1"
close_mw_cel

close_mw_lib
#end of floorplan
