# Long-Wire Data Acquisition Software (LWDAQ)
# Copyright (C) 2004-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

#
# Inclinometer.tcl defines the Inclinometer instrument.
#

#
# LWDAQ_init_Inclinometer creates all elements of the Inclinometer instrument's
# config and info arrays.
#
proc LWDAQ_init_Inclinometer {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Inclinometer info
	upvar #0 LWDAQ_config_Inclinometer config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Inclinometer"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(daq_extended) 0
	set info(delete_old_images) 1
	set info(file_use_daq_bounds) 0
	set info(daq_device_type) 0
	set info(daq_image_width) 340
	set info(daq_image_height) 240
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) -1
	set info(daq_image_bottom) -1
	set info(daq_password) "no_password"
	set info(analysis_trigger) "automatic"
	set info(display_num_div) 10
	set info(display_us_per_div) 0
	set info(display_V_per_div) 2
	set info(A2065_commands) "0094 0093 008E 008B"
	set info(A2065_settling_delay) 0.05
	set info(verbose_description) "\
		{X+	   (V)} {XCNTR (V)} \
		{Y+	   (V)} {YCNTR (V)} \
		{X} {Y}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 129.64.37.88
	set config(daq_driver_socket) 1
	set config(daq_mux_socket) 1
	set config(analysis_enable) 1
	set config(analysis_harmonic) 11
	set config(daq_num_samples) 557
	set config(daq_delay_ticks) 132
	set config(intensify) none
	set config(verbose_result) 0
	
	return 1
}

#
# LWDAQ_analysis_Inclinometer converts the ADC measurements
# contained in $image_name into voltages, and plots them 
# in the Inclinometer window. It calculates the average value 
# of the voltage, the slope, and the standard deviation,
# and returns these in a string. By default, the routine uses
# image $config(memory_name).
#
proc LWDAQ_analysis_Inclinometer {{image_name ""}} {
	upvar #0 LWDAQ_config_Inclinometer config
	upvar #0 LWDAQ_info_Inclinometer info
	
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[string match -nocase "auto*" $info(analysis_trigger)]} {
		set result [lwdaq_inclinometer $image_name \
			-v_max 1 -v_min -1 -v_trigger 0 -harmonic 0]
		if {[LWDAQ_is_error_result $result]} {return $result}
		if {[lindex $result 2] != ""} {
			set v [expr [lindex $result 2]]
		} {
			set v 0
		}
	} {
		if {[string is integer -strict $info(analysis_trigger)]} {
			set v $info(analysis_trigger) 
		} {
			LWDAQ_print $info(text) \
				"WARNING: invalid analysis_trigger \"$info(analysis_trigger)\"."
			set v 0
		}
	}
	
	set result [lwdaq_inclinometer $image_name \
			-v_max [expr $info(display_V_per_div) * $info(display_num_div) / 2.0] \
			-v_min [expr -$info(display_V_per_div) * $info(display_num_div) / 2.0] \
			-v_trigger $v \
			-harmonic $config(analysis_harmonic)]
	if {[LWDAQ_is_error_result $result]} {return $result}
	
	set info(display_us_per_div) [expr \
		$config(daq_num_samples) \
		/ $info(display_num_div)  \
		* (0.375 + $config(daq_delay_ticks) * 0.125)]
	if {[catch {
		set xp [lindex $result 0]
		set xc [lindex $result 1]
		lappend result [format {%.6f} [expr  $xc / $xp]]
		set yp [lindex $result 2]
		set yc [lindex $result 3]
		lappend result [format {%.6f} [expr  $yc / $yp]]
	} error_result]} {
		set result "$result -1 -1"
	}
	
	return $result
}

#
# LWDAQ_controls_Inclinometer creates secial controls 
# for the Inclinometer instrument.
#
proc LWDAQ_controls_Inclinometer {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_Inclinometer config
	upvar #0 LWDAQ_info_Inclinometer info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set f $w.scale
	frame $f
	pack $f -side top -fill x

	foreach {label_name element_name} {
			"Scale (us/div)" {display_us_per_div} 
			"Scale (V/div)" {display_V_per_div} } {
		label $f.l$element_name -text $label_name \
			-width [string length $label_name]
		label $f.e$element_name -textvariable LWDAQ_info_Inclinometer($element_name) \
			-width 6
		pack $f.l$element_name $f.e$element_name -side left -expand 1
	}
}


#
# LWDAQ_daq_Inclinometer reads samples out of an input channel.
#
proc LWDAQ_daq_Inclinometer {} {
	global LWDAQ_Info LWDAQ_Driver
	upvar #0 LWDAQ_info_Inclinometer info
	upvar #0 LWDAQ_config_Inclinometer config

	set redundancy_factor 2
	set pixels_per_sample 2
	set block_length [expr $pixels_per_sample \
		* [llength $info(A2065_commands)] \
		* $config(daq_num_samples) \
		* $redundancy_factor]
	set repeat [expr $config(daq_num_samples) * $redundancy_factor - 1]
	
	if {[catch {
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_data_addr $sock 0

		# We enable the pre-conversion count-down in the driver by clearing the CLEN
		# bit. The CLEN bit performs this function in A2037E firmware 12 and up.
		LWDAQ_byte_write $sock $LWDAQ_Driver(clen_addr) 0
		
		# Go through each of the inclinometer commands and acquire waveforms.
 		foreach cmd $info(A2065_commands) {
			LWDAQ_transmit_command_hex $sock $cmd
			LWDAQ_delay_seconds $sock $info(A2065_settling_delay)
			LWDAQ_set_repeat_counter $sock $repeat
			LWDAQ_set_delay_ticks $sock $config(daq_delay_ticks)
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
		}
		LWDAQ_sleep $sock
		
		# We set the CLEN bit again so as to leave it in its power-up reset state.
		LWDAQ_byte_write $sock $LWDAQ_Driver(clen_addr) 1
		
		# Read the data out of the relay RAM.
		set data [LWDAQ_ram_read $sock 0 $block_length]

		# Close the socket to the relay.
		LWDAQ_socket_close $sock
	} error_result]} { 
		if {[info exists sock]} {LWDAQ_socket_close $sock}
		return "ERROR: $error_result"
	}

	set config(memory_name) [lwdaq_image_create \
		-width $info(daq_image_width) \
		-height $info(daq_image_height) \
		-left $info(daq_image_left) \
		-right $info(daq_image_right) \
		-top $info(daq_image_top) \
		-bottom $info(daq_image_bottom) \
		-results "$config(daq_num_samples) \
			$redundancy_factor \
			[llength $info(A2065_commands)] \
			$config(daq_delay_ticks)" \
		-name "$info(name)\_$info(counter)"]
	lwdaq_data_manipulate $config(memory_name) write 0 $data

	return $config(memory_name) 
} 

