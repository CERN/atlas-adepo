# LGT, A LWDAQ Tool
# Copyright (C) 2011 Ben Wiener, Brandeis University
# Copyright (C) 2011 Kevan Hashemi, Brandeis University
#

proc LGT_init {} {
	upvar #0 LGT_info info
	upvar #0 LGT_config config
	upvar #0 LWDAQ_config_Voltmeter vconfig
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "LGT" "3.6"
	if {[winfo exists $info(window)]} {return 0}

	set config(daq_ip_addr) "10.0.0.37"
	set config(daq_driver_socket) "1"
	set config(daq_source_driver_socket) "1"
	set config(near_mux_socket) "1"
	set config(far_mux_socket) "8"
	set config(short_element) "1"
	set config(short_flash_s) "0.02"
	set config(long_element) "2"
	set config(long_flash_s) "0.04"
	set config(analysis_enable) "21"
	set config(analysis_orientation_code) "3"
	set config(analysis_pixel_size_um) "7.4"
	set config(analysis_square_size_um) "85"
	set config(daq_image_width) "690"
	set config(daq_image_height) "500"
	set config(daq_image_left) "35"
	set config(daq_image_bottom) "495"
	set config(daq_image_top) "5"
	set config(daq_image_right) "685"
	set config(daq_device_type) "5"
	set config(daq_source_device_type) "5"
	set config(gauge_mux_socket) "6"
	set config(gauge_device_element) "1"
	set config(gauge_auto_calib) "1"
	set config(tension_min_kg) "-10"
	set config(tension_max_kg) "1000"
	set config(tension_V_per_kg) [expr 101.0 * 0.01884 * 2.2 / 2000]
	set config(tension_offset_kg) 23.0
	set config(motor_mux_socket) "7"
	set config(motor_voltage) "24"
	set config(check_tension) "1"

	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 
	
	set info(control) "Idle"
	set info(tension) 0
	set info(previous_direction) 0

	return 1	 
}

proc LGT_Command {command} {
	upvar #0 LGT_info info
	upvar #0 LGT_config config

	if {$info(control) == "Idle"} {
		set info(control) $command
		LWDAQ_post LGT_Do
	} {
		set info(control) $command
	}
}


proc LGT_Tension {} {
	upvar #0 LGT_info info
	upvar #0 LGT_config config
	upvar #0 LWDAQ_config_Voltmeter vconfig
	upvar #0 LWDAQ_info_Voltmeter vinfo

	foreach a {daq_ip_addr daq_driver_socket} {
		set vconfig($a) $config($a)
	}
	set vconfig(daq_mux_socket) $config(gauge_mux_socket)
	set vconfig(daq_device_element) $config(gauge_device_element)
	set vconfig(analysis_auto_calib) $config(gauge_auto_calib)
	
	set result [LWDAQ_acquire Voltmeter]

	if {![LWDAQ_is_error_result $result]} {
	 	set info(tension) [format %.1f \
	 		[expr [lindex $result 1] / $config(tension_V_per_kg) \
	 			- $config(tension_offset_kg)]]
	} {
		set info(tension) "-1"
	}
	
	return $info(tension)
}


proc LGT_Rasnik {side length} {
	upvar #0 LGT_info info
	upvar #0 LGT_config config
	upvar #0 LWDAQ_config_Rasnik rconfig
	upvar #0 LWDAQ_info_Rasnik rinfo

	foreach a {daq_ip_addr daq_driver_socket daq_source_driver_socket \
		analysis_enable analysis_orientation_code analysis_square_size_um \
		daq_device_type daq_source_device_type analysis_pixel_size_um \
		daq_image_width daq_image_height daq_image_left daq_image_top \
		daq_image_right daq_image_bottom} {
		if {[info exists rconfig($a)]} {
			set rconfig($a) $config($a)
		} {
			set rinfo($a) $config($a)
		}
	}
	
	set rconfig(daq_device_element) $config($length\_element)
	set rconfig(daq_source_device_element) $config($length\_element)
	set rconfig(daq_mux_socket) $config($side\_mux_socket)
	set rconfig(daq_source_mux_socket) $config($side\_mux_socket)
	set rconfig(daq_flash_seconds) $config($length\_flash_s)
	
	set result [LWDAQ_acquire Rasnik]
	
	set config($length\_flash_s) $rconfig(daq_flash_seconds)

	if {![LWDAQ_is_error_result $result]} {
		return [lrange $result 1 2]
	} {
		return "-1 -1"
	}
}

proc LGT_Go {direction} {
	upvar #0 LGT_config config
	upvar #0 LGT_info info
	
	set v $config(motor_voltage)
	if {![string is double -strict $v]} {set v 0.0}
	
	if {$info(previous_direction) != $direction} {
		set v 0.0
		set info(previous_direction) $direction
	}
	
	set speed [expr round($v * 127.0 / 24.0)]
	switch $direction {
		"Tighten" {set command [expr 128 + $speed]}
		"Loosen" {set command [expr $speed]}
		default {set command 0}
	}

	if {[catch {
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(motor_mux_socket)
		LWDAQ_transmit_command $sock $command
		LWDAQ_wait_for_driver $sock
		LWDAQ_socket_close $sock 
	} error_result]} {
		if {[info exists sock]} {LWDAQ_socket_close $sock}
		return "ERROR: $error_result"
	}

	return "$command"
}


proc LGT_Do {} {
	upvar #0 LGT_config config
	upvar #0 LGT_info info
	global LWDAQ_Info
	
	if {$info(control) == "Stop"} {
		LGT_Go "Stop"
		set info(control) "Idle"
		return 1
	}
	
	if {$info(control) == "Tension"} {
		LGT_Tension
		if {[winfo exists $info(window)]} {LWDAQ_post LGT_Do}
		return 1
	}
	
	if {$info(control) == "Acquire"} {
		set result "[clock seconds] "
		foreach s {near far} {
			foreach l {short long} {
				append result "[LGT_Rasnik $s $l] "
				LWDAQ_support
				if {$info(control) == "Stop"} {
					LWDAQ_print $info(text) "WARNING: Acquire aborted."
					set info(control) "Idle"
					return 0
				}
			}
		}
		append result "[LGT_Tension] "
		LWDAQ_print $info(text) $result green
		LWDAQ_print [file join $LWDAQ_Info(tools_dir) Data LGT_Results.txt] $result
		set info(control) "Idle"
		return 1
	}
	
	if {($info(control) == "Tighten") || ($info(control) == "Loosen")} {

		if {$config(check_tension)} {	
			set tension [LGT_Tension]
			if {($info(control) == "Loosen") \
				&& ($tension < $config(tension_min_kg))} {	
				LWDAQ_print $info(text) "ERROR: Tension \"$tension\" too low."
				set info(control) "Idle"
				LGT_Go "Stop"
				return 0
			}
			if {($info(control) == "Tighten") \
				&& ($tension > $config(tension_max_kg))} {
				LWDAQ_print $info(text) "ERROR: Tension \"$tension\" too high."
				set info(control) "Idle"
				LGT_Go "Stop"
				return 0
			}
		}
		
		set command [LGT_Go $info(control)]
		if {[LWDAQ_is_error_result $command]} {
			LWDAQ_print $info(text) $command
		}
				
		if {[winfo exists $info(window)]} {LWDAQ_post LGT_Do}
		return 1
	}
	
	return 0
}

proc LGT_open {} {
	upvar #0 LGT_config config
	upvar #0 LGT_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
	
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	foreach a {Acquire Tighten Loosen Stop Tension} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LGT_Command $a"
		pack $f.$b -side left -expand 1
	}

	set f $w.tension
	frame $f
	pack $f -side top -fill x
	
	label $f.control -textvariable LGT_info(control) -fg blue
	pack $f.control -side left -expand 1
	
	foreach a {Help Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b $info(name)"
		pack $f.$b -side left -expand 1
	}
	label $f.sl -text "Tension (kg)"
	label $f.sv -textvariable LGT_info(tension)
	pack $f.sl $f.sv -side left -expand 1

	set info(text) [LWDAQ_text_widget $w 80 15]

	LWDAQ_print $info(text) "$info(name) Version $info(version)\n" purple
	
	return 1
}



LGT_init
LGT_open
	
return 1

----------Begin Help----------

Long Guide Tube Control Program

To establish communication with the LWDAQ Driver, open the Configuration Panel
with the Config button. Set the daq_ip_addr parameter to match the IP address
of the driver. You will see other daq parameters that select a driver socket
for the LGT multiplexer, and specify the multiplexer sockets into which the 
remaining LGT devices are plugged.

The Acquire button starts a data aqcuisition from all four internal Rasnik 
monitors. It measures the rod tension also, and records all four Rasnik x-y
measurements, with the tension to a single line in the LGT text window. If you
want to see the Rasnik images, open the Rasnik instrument before you press
Acquire. The program also writes these values to a file in the LWDAQ software
Tools/Data directory. 

The Tighten and Loosen buttons direct the motor to turn the tension rod. At
the same time, the LGT program checks the rod tension by reading out the strain
gauge. If the rod tension exceeds tension_max_kg, LGT turns the motor off. You
can loosen the motor after that, but not tighten it. The same check happens
when the tension dropps below tension_min_kg.

If you press the Tension button, the LGT program simply reads out the tension
continuously, without moving the motor.

Kevan Hashemi hashemi@brandeis.edu

----------End Help----------

----------Begin Data----------

----------End Data----------


