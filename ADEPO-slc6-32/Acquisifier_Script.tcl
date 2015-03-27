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
 set suffix $iconfig(daq_source_device_element) 
 regsub -all " " $suffix "-" suffix 
 set fn [file join [file dirname $config(run_results)] $name-$suffix.gif] 
 LWDAQ_write_image_file $iconfig(memory_name) $fn 
 LWDAQ_print $info(text) "Saved raw image to $fn" blue ; 
 } 

config: 
	 image_source daq 
	 analysis_enable 1 
	 daq_flash_seconds 0.0000033 
	 daq_ip_addr 10.145.44.16:4090
	 daq_source_ip_addr * 
	 ambient_exposure_seconds 0 
	 intensify exact 
end. 

acquire: 
name: 20MABNDA000318_PR004
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 1
	 daq_source_mux_socket 1
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000334_PR005
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 2
	 daq_source_mux_socket 2
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000317_PR015
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 1
	 daq_mux_socket 1
	 daq_source_mux_socket 1
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000146_PR016
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 1
	 daq_mux_socket 2
	 daq_source_mux_socket 2
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000077_PR002
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 125 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000077_PR003
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 125 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000077_20MABNDM000168
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 4
	 daq_device_element 1 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000077_PR024
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 2
	 daq_device_element 1 
	 daq_source_device_element "1 2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR013
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 1 
	 daq_source_device_element "1" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 200 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR013
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 1 
	 daq_source_device_element "2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 200 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR014
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 1 
	 daq_source_device_element "1" 
	 daq_image_left 200 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR014
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 1 
	 daq_source_device_element "2" 
	 daq_image_left 200 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_20MABNDL000196
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "1" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_20MABNDL000196
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR035
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000020_PR035
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000168_PR025
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 4
	 daq_device_element 1 
	 daq_source_device_element "1 2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 181 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000168_PR026
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 4
	 daq_device_element 1 
	 daq_source_device_element "1 2" 
	 daq_image_left 181 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000168_20MABNDL000077
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "1 2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDM000168_PR001
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000196_PR036
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 181 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000196_PR037
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 181 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000196_20MABNDM000020
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 1
	 daq_device_element 1 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDL000196_PR012
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 7
	 daq_source_mux_socket 7
	 daq_source_driver_socket 3
	 daq_device_element 1 
	 daq_source_device_element "1 2" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000135_PR027
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 1
	 daq_source_mux_socket 1
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000126_PR028
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 2
	 daq_source_mux_socket 2
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000272_PR038
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 1
	 daq_source_mux_socket 1
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000003_PR039
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 2
	 daq_source_mux_socket 2
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000196_PR006
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 3
	 daq_source_mux_socket 3
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000324_PR007
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 2
	 daq_mux_socket 4
	 daq_source_mux_socket 4
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000001_PR017
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 1
	 daq_mux_socket 3
	 daq_source_mux_socket 3
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000260_PR019
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 1
	 daq_mux_socket 4
	 daq_source_mux_socket 4
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000212_PR029
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 3
	 daq_source_mux_socket 3
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000128_PR030
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 4
	 daq_mux_socket 4
	 daq_source_mux_socket 4
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000444_PR040
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 3
	 daq_source_mux_socket 3
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000053_PR041
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 2 
	 daq_driver_socket 3
	 daq_mux_socket 4
	 daq_source_mux_socket 4
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3 4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000188_PR008
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 260 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000188_PR008
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 260 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000188_PR010
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 260 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000188_PR010
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 260 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000039_PR009
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 100 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000039_PR009
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 100 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000039_PR011
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 100 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000039_PR011
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 2
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 2
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 100 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000155_PR020
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 100 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000155_PR020
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 100 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000155_PR022
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 100 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000155_PR022
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 100 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000010_PR021
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 260 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000010_PR021
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 260 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000010_PR023
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 260 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000010_PR023
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 1
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 1
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 260 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000069_PR031
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 60 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000069_PR031
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 60 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000069_PR033
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 60 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000069_PR033
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 60 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000131_PR032
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 250 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000131_PR032
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 250 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000131_PR034
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 250 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDB000131_PR034
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 4
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 4
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 250 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000208_PR042
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 260 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000208_PR042
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 260 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000208_PR046
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 260 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000208_PR046
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 5
	 daq_source_mux_socket 5
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 260 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000035_PR044
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 100 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000035_PR044
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 20 
	 daq_image_top 1 
	 daq_image_right 100 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000035_PR047
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "3" 
	 daq_image_left 100 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

acquire: 
name: 20MABNDA000035_PR047
instrument: BCAM 
result: None 
time: 0 
config: 

	 daq_adjust_flash 1 
	 analysis_num_spots 1 
	 daq_driver_socket 3
	 daq_mux_socket 6
	 daq_source_mux_socket 6
	 daq_source_driver_socket 3
	 daq_device_element 2 
	 daq_source_device_element "4" 
	 daq_image_left 100 
	 daq_image_top 1 
	 daq_image_right 343 
	 daq_image_bottom 243 
end. 

