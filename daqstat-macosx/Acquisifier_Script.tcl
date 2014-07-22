acquisifier: 
config: 
	 cycle_period_seconds 0 
end. 

default: 
name: BCAM_Default 
instrument: BCAM 
default_post_processing: { 
if {![LWDAQ_is_error_result $result]} { 
append config(run_result) "[lrange $result 1 2]" ; 
 } { 
append config(run_result) " -1 -1 " ; # append joue le meme role que 'set' 
 } 
  set f [open $config(run_results) a] 
 puts $f $result 
 close $f 
 LWDAQ_print $info(text) "Appended modified result to [file tail $config(run_results)]." blue ;  
 set fn [file join [file dirname $config(run_results)] $name.lwdaq] 
 # LWDAQ_write_image_file $iconfig(memory_name) $fn 
 LWDAQ_print $info(text) "Saved raw image to [file tail $fn]" blue ; 
 } 

config: 
	 image_source daq 
	 analysis_enable 1 
	 daq_flash_seconds 0.0000033 
	 daq_adjust_flash 1 
	 daq_ip_addr 10.145.44.16:4090
	 daq_source_ip_addr * 
	 ambient_exposure_seconds 0 
	 intensify exact 
end. 

acquire: 
name: 20MABNDL000077_PR002_PR003_1_PR024
instrument: BCAM 
result: None 
time: 0 
config: 
	 analysis_num_spots 6 
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_device_element 20
	 daq_driver_socket 2
	 daq_source_driver_socket 2
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
	 daq_source_device_element "1 2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR013_PR014_2_PR035
instrument: BCAM 
result: None 
time: 0 
config: 
	 analysis_num_spots 6 
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_device_element 20
	 daq_driver_socket 1
	 daq_source_driver_socket 1
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
	 daq_source_device_element "1 2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

