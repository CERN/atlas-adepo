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
# Voltmeter.tcl defines the Voltmeter instrument.
#

#
# LWDAQ_init_Voltmeter creates all elements of the Voltmeter instrument's
# config and info arrays.
#
proc LWDAQ_init_Voltmeter {} {
	global LWDAQ_Info
	upvar #0 LWDAQ_info_Voltmeter info
	upvar #0 LWDAQ_config_Voltmeter config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Voltmeter"
	set info(control) "Idle"
	set info(counter) 0 
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(zoom) 1
	set info(daq_extended) 0
	set info(delete_old_images) 1
	set info(file_use_daq_bounds) 0
	set info(daq_device_type) 0
	set info(daq_image_width) 600
	set info(daq_image_height) 300
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) -1
	set info(daq_image_bottom) -1
	set info(daq_password) "no_password"
	set info(daq_redundancy_factor) 2
	set info(daq_sample_size) 2
	set info(daq_firmware_lt12) 0
	set info(daq_source_driver_socket) 0
	set info(daq_source_mux_socket) 1
	set info(daq_source_commands) [list]
	set info(A2057_lo_gain_cmds) "008x 009x 00Ax 018x 028x"
	set info(A2057_hi_gain_cmds) "108x 109x 10Ax 118x 128x"
	set info(A2057_lo_gain) 1
	set info(A2057_hi_gain) 11
	set info(ref_top_V) 5
	set info(ref_top_cmd) "028x"
	set info(ref_bottom_V) 0
	set info(ref_bottom_cmd) "018x"
	set info(ref_ticks) 100
	set info(wake_up_delay_s) 0.010 
	set info(display_s_per_div) 0.001
	set info(display_s_offset) 0
	set info(display_V_per_div) 2.5
	set info(display_V_offset) 0
	set info(display_V_coupling) DC
	set info(display_num_div) 10
	set info(trigger_level) 0
	set info(trigger_slope) "+"
	set info(verbose_description) "{Ave   (V)} {Stdev (V)} {Frequency (Hz)} {Amplitude (V)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 129.64.37.79
	set config(daq_driver_socket) 2
	set config(daq_mux_socket) 1
	set config(daq_device_element) 1
	set config(daq_hi_gain) 0
	set config(daq_logic_outputs) "0011"
	set config(analysis_auto_calib) 0
	set config(analysis_enable) 1
	set config(intensify) none
	set config(verbose_result) 0
	
	return 1
}

#
# LWDAQ_analysis_Voltmeter converts the ADC measurements
# contained in $image_name into voltages, and plots them 
# in the Voltmeter window. It calculates the average value 
# of the voltage, the slope, and the standard deviation,
# and returns these in a string. By default, the routine
# uses image $config(memory_name).
#
proc LWDAQ_analysis_Voltmeter {{image_name ""}} {
	upvar #0 LWDAQ_config_Voltmeter config
	upvar #0 LWDAQ_info_Voltmeter info
	if {$image_name == ""} {set image_name $config(memory_name)}
	set result ""
	if {[catch {
		set v_min [expr $info(display_V_offset) - \
			($info(display_num_div) * $info(display_V_per_div) / 2)]
		set v_max [expr $info(display_V_offset) + \
			($info(display_num_div) * $info(display_V_per_div) / 2)]
		set t_min $info(display_s_offset)
		set t_max [expr $info(display_s_offset) + \
			($info(display_num_div) * $info(display_s_per_div))]
		set result [lwdaq_voltmeter $image_name \
			-v_max $v_max -v_min $v_min -t_min $t_min -t_max $t_max \
			-ac_couple [string match -nocase $info(display_V_coupling) "AC"] \
			-positive_trigger [string match $info(trigger_slope) "+"] \
			-v_trigger $info(trigger_level) \
			-auto_calib $config(analysis_auto_calib)]
	} error_result]} {return "ERROR: $error_result"}
	return $result
}

#
# LWDAQ_refresh_Voltmeter refreshes the display of the data, given new
# display settings. Voltmeter analysis assumes that certain parameters
# are stored in the image's results string. 
#
proc LWDAQ_refresh_Voltmeter {} {
	upvar #0 LWDAQ_config_Voltmeter config
	upvar #0 LWDAQ_info_Voltmeter info
	if {[lwdaq_image_exists $config(memory_name)] != ""} {
		LWDAQ_analysis_Voltmeter $config(memory_name)
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
}

#
# LWDAQ_controls_Voltmeter creates secial controls 
# for the Voltmeter instrument.
#
proc LWDAQ_controls_Voltmeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_Voltmeter config
	upvar #0 LWDAQ_info_Voltmeter info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set g $w.scale
	frame $g
	pack $g -side top -fill x

	foreach {label_name element_name} {
			"Offset (V)" {display_V_offset}
			"Scale (V/div)" {display_V_per_div}
			"Offset (s)" {display_s_offset}
			"Scale (s/div)" {display_s_per_div} } {
		label $g.l$element_name -text $label_name \
			-width [string length $label_name]
		entry $g.e$element_name -textvariable LWDAQ_info_Voltmeter($element_name) \
			-relief sunken -bd 1 -width 6
		pack $g.l$element_name $g.e$element_name -side left -expand 1
		bind $g.e$element_name <Return> LWDAQ_refresh_Voltmeter
	}

	set g $w.trigger
	frame $g
	pack $g -side top -fill x

	foreach {label_name element_name} {
			"Coupling (AC/DC)" {display_V_coupling} 
			"Trigger Level (V)" {trigger_level}
			"Trigger Slope (+-)" {trigger_slope} } {
		label $g.l$element_name -text $label_name \
			-width [string length $label_name]
		pack $g.l$element_name -side left -expand 1
		entry $g.e$element_name -textvariable LWDAQ_info_Voltmeter($element_name) \
			-relief sunken -bd 1 -width 6
		pack $g.l$element_name $g.e$element_name -side left -expand 1
		bind $g.e$element_name <Return> LWDAQ_refresh_Voltmeter
	}
}

#
# LWDAQ_cmd_Voltmeter takes the top three nibbles of a sixteen
# bit command word and adds the correct nibble at the end to set the
# logic outputs.
#
proc LWDAQ_cmd_Voltmeter {cmd} {
	upvar #0 LWDAQ_info_Voltmeter info
	upvar #0 LWDAQ_config_Voltmeter config

	binary scan [binary format B4 $config(daq_logic_outputs)] H1 dlo_hex
	set cmd [string replace $cmd end end $dlo_hex]
	return $cmd
}

#
# LWDAQ_daq_Voltmeter reads samples out of an input channel.
#
proc LWDAQ_daq_Voltmeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Voltmeter info
	upvar #0 LWDAQ_config_Voltmeter config

	# Determine the number of samples and the length of the resulting block of
	# data.
	set num_samples [expr $info(daq_redundancy_factor) * $info(daq_image_width)]
	set block_length [expr \
		($info(daq_redundancy_factor) * [llength $config(daq_device_element)] + 2)  \
		* $info(daq_image_width) \
		* $info(daq_sample_size) \
		+ $info(daq_image_width)]
		
	# Configure the voltmeter head for high gain or low gain.
	if {$config(daq_hi_gain)} {
		set gain $info(A2057_hi_gain)
		set cmds $info(A2057_hi_gain_cmds)
	} {
		set gain $info(A2057_lo_gain)
		set cmds $info(A2057_lo_gain_cmds)
	} 
	
	# Determine the sample period.
	set period [expr $info(display_s_per_div) \
		* $info(display_num_div) \
		/ $info(daq_image_width)]
	if {$period < $LWDAQ_Driver(min_adc16_sample_period)} {
		set period $LWDAQ_Driver(min_adc16_sample_period)
	}
	
	# Convert sample period into delay timer ticks, depending upon the firmware
	# version of the driver.
	if $info(daq_firmware_lt12) {
		set delay_ticks [expr round(($period - $LWDAQ_Driver(min_adc16_sample_period)) \
			* $LWDAQ_Driver(delay_timer_frequency))]
	} {
		set delay_ticks [expr round($period * $LWDAQ_Driver(delay_timer_frequency)) \
			- $LWDAQ_Driver(adc16_startup_ticks)]
	}

	if {[catch {
		# Connect to the driver.
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		
		# If we have source commands to transmit, do so now. We assume these will provoke
		# whatever electrical activity we wish to monitor.
		if {$info(daq_source_commands) != ""} {
			LWDAQ_set_driver_mux $sock \
				$info(daq_source_driver_socket) $info(daq_source_mux_socket)
			foreach cmd $info(daq_source_commands) {
				LWDAQ_transmit_command_hex $sock $cmd
			}
		}

		
		# Select the voltmeter device.
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_data_addr $sock $info(daq_image_width)
		
		# We wake up the board by sending it a command to read its bottom
		# reference voltage.
		LWDAQ_transmit_command_hex $sock [LWDAQ_cmd_Voltmeter $info(ref_bottom_cmd)]
		LWDAQ_delay_seconds $sock $info(wake_up_delay_s)
		
		# We enable the pre-conversion count-down in the driver by clearing the CLEN
		# bit. The CLEN bit performs this function in A2037E firmware 12 and up.
		LWDAQ_byte_write $sock $LWDAQ_Driver(clen_addr) 0

		# Acquire bottom reference voltage. We don't apply the redundancy factor to 
		# the reference voltages because we want to allow high redundancy factor for
		# single-channel acquisition without the over-head of waiting for the reference
		# voltages. We use a short sample period also, because we want to be able to
		# capture one second of the signal without waiting one second to obtain the
		# reference voltages.
		LWDAQ_set_repeat_counter $sock [expr $info(daq_image_width) - 1]
		LWDAQ_set_delay_ticks $sock $info(ref_ticks)
		LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)

		# Select each channel specified in daq_device_element and sample
		# the returned voltage.
		foreach e $config(daq_device_element) {
			if {![string is integer $e]} {continue}
			set cmd [lindex $cmds $e]
			if {$cmd == ""} {set cmd [lindex $cmds 0]} 
			LWDAQ_transmit_command_hex $sock [LWDAQ_cmd_Voltmeter $cmd]
			LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
			LWDAQ_set_repeat_counter $sock [expr $num_samples - 1]
			LWDAQ_set_delay_ticks $sock $delay_ticks
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
		}
		
		# Acquire top reference voltage. We do this after the signal
		# acquisition so that we can compensate for some of the drift
		# that may have occured in our voltmeter when we acquire a 
		# signal over the course of several seconds.
		LWDAQ_transmit_command_hex $sock [LWDAQ_cmd_Voltmeter $info(ref_top_cmd)]
		LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
		LWDAQ_set_repeat_counter $sock [expr $info(daq_image_width) - 1]
		LWDAQ_set_delay_ticks $sock $info(ref_ticks)
		LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)

		# Send the device to sleep.
		LWDAQ_sleep $sock

		# We set the CLEN bit again so as to leave it in its power-up reset state.
		LWDAQ_byte_write $sock $LWDAQ_Driver(clen_addr) 1

		# Read the data out of the relay RAM.
		set image_contents [LWDAQ_ram_read $sock 0 $block_length]

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
		-data $image_contents \
		-results "[format %1.5e $period] \
			$info(ref_bottom_V) \
			$info(ref_top_V) \
			$gain \
			$info(daq_redundancy_factor) \
			[llength $config(daq_device_element)]" \
		-name "$info(name)\_$info(counter)"]
		
	return $config(memory_name) 
} 

