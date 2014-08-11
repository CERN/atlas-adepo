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
# Flowmeter.tcl defines the Flowmeter instrument.
#

#
# LWDAQ_init_Flowmeter creates all elements of the Flowmeter instrument's
# config and info arrays.
#
proc LWDAQ_init_Flowmeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Flowmeter info
	upvar #0 LWDAQ_config_Flowmeter config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Flowmeter"
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
	set info(daq_image_height) 220
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) -1
	set info(daq_image_bottom) -1
	set info(daq_password) "no_password"
	set info(ref_top_C) 25.69
	set info(ref_bottom_C) 15.38
	set info(daq_select_commands) \
		"8080 00A0 0880 1080 2080 4080 0081 0082 0084 0088 0090 0180 0480"
	set info(daq_heat_commands) \
		"8280 02A0 0A80 1280 2280 4280 0281 0282 0284 0288 0290 0380 0680"
	set info(display_s_per_div) 1
	set info(display_C_per_div) 5
	set info(display_C_offset) 19.9
	set info(display_num_div) 10
	set info(mains_frequency) 60
	set info(ambient) 0
	set info(heat) 0
	set info(cool) 0
	set info(transfer) 0
	set infot(analyze) 0
	set info(verbose_description) " {Inverse Time Constant (1/s)} \
		{RMS Residual (C)} \
		{Ambient Temperature (C)} \
		{Peak Temperature Above Ambient (C)} \
		{Start Temperature Above Ambient (C)} \
		{End Temperature Above Ambient (C)} "
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 129.64.37.79
	set config(daq_driver_socket) 4
	set config(daq_mux_socket) 1
	set config(daq_device_element) 11
	set config(daq_heating_seconds) 2
	set config(analysis_enable) 1
	set config(intensify) none
	set config(verbose_result) 0
	
	return 1
}

#
# LWDAQ_analysis_Flowmeter takes the flowmeter RTD sensor resistance
# measurements in $image_name and plots a graph of sensor temperature
# versus time in the Flowmeter window. It returns a string containing
# the inverse time-constant of the cool-down phase. By default, the
# routine uses image $config(memory_name).
#
proc LWDAQ_analysis_Flowmeter {{image_name ""}} {
	upvar #0 LWDAQ_config_Flowmeter config
	upvar #0 LWDAQ_info_Flowmeter info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[catch {
		set c_min [expr $info(display_C_offset) - \
			($info(display_num_div) * $info(display_C_per_div) / 2)]
		set c_max [expr $info(display_C_offset) + \
			($info(display_num_div) * $info(display_C_per_div) / 2)]
		set t_min 0
		set t_max [expr $info(display_num_div) * $info(display_s_per_div)]
		set result [lwdaq_flowmeter $image_name \
			-c_max $c_max -c_min $c_min -t_min $t_min -t_max $t_max \
			-ref_top $info(ref_top_C) -ref_bottom $info(ref_bottom_C)  ]
	} error_result]} {return "ERROR: $error_result"}
	set info(analyze) 1
	return $result
}

#
# LWDAQ_refresh_Flowmeter refreshes the display of the data, 
# given new display settings. It calls the Flowmeter analysis
# procedure. 
#
proc LWDAQ_refresh_Flowmeter {} {
	upvar #0 LWDAQ_config_Flowmeter config
	upvar #0 LWDAQ_info_Flowmeter info
	if {[lwdaq_image_exists $config(memory_name)] != ""} {
		LWDAQ_analysis_Flowmeter $config(memory_name)
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
}

#
# LWDAQ_controls_Flowmeter creates secial controls 
# for the Flowmeter instrument.
#
proc LWDAQ_controls_Flowmeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_Flowmeter config
	upvar #0 LWDAQ_info_Flowmeter info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set g $w.display
	frame $g
	pack $g -side top -fill x

	foreach {label_name element_name} {
			"Offset (C)" {display_C_offset}
			"Scale (C/div)" {display_C_per_div}
			"Scale (s/div)" {display_s_per_div} } {
		label $g.l$element_name -text $label_name \
			-width [string length $label_name]
		entry $g.e$element_name -textvariable LWDAQ_info_Flowmeter($element_name) \
			-relief sunken -bd 1 -width 6
		pack $g.l$element_name $g.e$element_name -side left -expand 1
		bind $g.e$element_name <Return> LWDAQ_refresh_Flowmeter
	}

	set g $w.state
	frame $g
	pack $g -side top -fill x

	foreach {label_name var_name} {
			"Ambient" {ambient}
			"Heat" {heat}
			"Cool" {cool}
			"Transfer" {transfer}
			"Analyze" {analyze} } {
		label $g.l$var_name -text $label_name \
			-width [string length $label_name]
		checkbutton $g.c$var_name -variable LWDAQ_info_Flowmeter($var_name)
		pack $g.l$var_name $g.l$var_name  $g.c$var_name -side left -expand 1
	}
}

#
# LWDAQ_daq_Flowmeter reads configuration parameters from the LWDAQ
# hardware, and records them in a result string, which it returns.
#
proc LWDAQ_daq_Flowmeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Flowmeter info
	upvar #0 LWDAQ_config_Flowmeter config

	foreach a {ambient heat cool transfer analyze} {set info($a) 0}
	set image_size [expr $info(daq_image_width) * $info(daq_image_height)]
	set ambient_samples [expr round($info(daq_image_width)/$info(display_num_div))]
	set cooling_samples [expr $info(daq_image_width) - $ambient_samples]
	set period [expr 1.0 * $info(display_s_per_div) \
		* $info(display_num_div) / $info(daq_image_width)]
	set cooling_seconds [expr $cooling_samples * $period]
	set ambient_seconds [expr $ambient_samples * $period]
	set delay [expr $period - $LWDAQ_Driver(min_adc16_sample_period)]
	if {$delay < 0} {
		set delay 0
		set period $LWDAQ_Driver(min_adc16_sample_period)
	}
	set ref_period [expr 10 / $info(mains_frequency) / $info(daq_image_width)]
	if {[catch {
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_wake $sock
		LWDAQ_set_data_addr $sock $info(daq_image_width)

		set c [lindex $config(daq_device_element) 0]
		set sel_cmd "" 
		set ht_cmd ""
		if {$c == "B"} {
			set sel_cmd [lindex $info(daq_select_commands) 0]
			set ht_cmd [lindex $info(daq_heat_commands) 0]
		}
		if {$c == "T"} {
			set sel_cmd [lindex $info(daq_select_commands) 1]
			set ht_cmd [lindex $info(daq_heat_commands) 1]
		}
		if {[string is integer $c]} {
			set sel_cmd [lindex $info(daq_select_commands) [expr $c + 1]]
			set ht_cmd [lindex $info(daq_heat_commands) [expr $c + 1]]
		}
		if {$sel_cmd != ""} {
			LWDAQ_transmit_command_hex $sock [lindex $info(daq_select_commands) 0]
			LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
			LWDAQ_set_repeat_counter $sock [expr $info(daq_image_width) - 1]
			LWDAQ_set_delay_seconds $sock $ref_period
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
			LWDAQ_wait_for_driver $sock

			LWDAQ_transmit_command_hex $sock $sel_cmd
			LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
			LWDAQ_set_repeat_counter $sock [expr $ambient_samples - 1]
			LWDAQ_set_delay_seconds $sock $delay
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
			LWDAQ_wait_for_driver $sock $ambient_seconds
			
			set info(ambient) 1
			if {$info(control) == "Stop"} {error "acquisition aborted"}
			
			LWDAQ_transmit_command_hex $sock $ht_cmd
			LWDAQ_delay_seconds $sock $config(daq_heating_seconds)
			LWDAQ_wait_for_driver $sock $config(daq_heating_seconds)

			set info(heat) 1
			if {$info(control) == "Stop"} {error "acquisition aborted"}
			
			LWDAQ_transmit_command_hex $sock $sel_cmd
			LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
			LWDAQ_set_repeat_counter $sock [expr $cooling_samples - 1]
			LWDAQ_set_delay_seconds $sock $delay
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
			LWDAQ_wait_for_driver $sock $cooling_seconds
			
			LWDAQ_transmit_command_hex $sock [lindex $info(daq_select_commands) 1]
			LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
			LWDAQ_set_repeat_counter $sock [expr $info(daq_image_width) - 1]
			LWDAQ_set_delay_seconds $sock $ref_period
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
			LWDAQ_wait_for_driver $sock

			set info(cool) 1
		}
		LWDAQ_sleep $sock
		set image_contents [LWDAQ_ram_read $sock 0 $image_size]
		LWDAQ_socket_close $sock
		set info(transfer) 1
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
		-data $image_contents \
		-results "[format %1.5e $period]" \
		-name "$info(name)\_$info(counter)"]
		
	return $config(memory_name) 
} 

