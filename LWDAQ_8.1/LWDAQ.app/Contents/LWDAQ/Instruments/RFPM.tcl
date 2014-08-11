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
# RFPM.tcl defines the Radio-Frequency Power Meter (RFPM) instrument.
#

#
# LWDAQ_init_RFPM creates all elements of the RFPM instrument's
# config and info arrays.
#
proc LWDAQ_init_RFPM {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_RFPM info
	upvar #0 LWDAQ_config_RFPM config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "RFPM"
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
	set info(daq_image_width) 340
	set info(daq_image_height) 180
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) -1
	set info(daq_image_bottom) -1
	set info(daq_password) "no_password"
	set info(A3008_commands) "\
		0000000010000100 \
		0000000010000101 \
		0000000010000110 \
		0000000010000111"
	set info(A3008_FS_bit) 3
	set info(A3008_DIN_bit) 4
	set info(A3008_SCLK_bit) 5
	set info(A3008_COEN_bit) 8
	set info(A3008_LOEN_bit) 2
	set info(A3008_CFR_bit) 9
	set info(A3008_wake) 0000000010000000
	set info(daq_startup_skip) 10
	set info(display_us_per_div) 0.5
	set info(display_V_per_div) 0.1
	set info(display_V_offset) 0
	set info(display_num_div) 10
	set info(verbose_description) "{Amplitude (V)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 10.0.0.37
	set config(daq_driver_socket) 2
	set config(daq_mux_socket) 3
	set config(daq_num_samples) 5000
	set config(daq_delay_ticks) 0
	set config(daq_dac_value) 0
	set config(analysis_enable) 1
	set config(intensify) none
	set config(verbose_result) 0
	
	return 1
}

#
# LWDAQ_analysis_RFPM converts the ADC measurements
# contained in $image_name into voltages, and plots them 
# in the RFPM window. By default, the routine uses image 
# $config(memory_name). If analysis_enable is set to 1, 
# the analysis returns the peak-to-peak value of the 
# signal on all four RFPM signal paths in units of ADC
# counts. If analysis_enanalysis is 2, the analysis returns 
# the rms values of the signals.
#
proc LWDAQ_analysis_RFPM {{image_name ""}} {
	upvar #0 LWDAQ_config_RFPM config
	upvar #0 LWDAQ_info_RFPM info
	if {$image_name == ""} {set image_name $config(memory_name)}

	set v_min [expr $info(display_V_offset) - \
		($info(display_num_div) * $info(display_V_per_div) / 2)]
	set v_max [expr $info(display_V_offset) + \
		($info(display_num_div) * $info(display_V_per_div) / 2)]
	if {$config(analysis_enable) == 2} {set rms 1} {set rms 0}
	set result [lwdaq_rfpm $image_name -v_max $v_max -v_min $v_min -rms $rms]

	set info(display_us_per_div) [expr \
		$config(daq_num_samples) \
		/ $info(display_num_div) \
		* (0.5 + $config(daq_delay_ticks) * 0.125)]

	return $result
}

#
# LWDAQ_refresh_RFPM refreshes the display of the data, given new
# display settings. RFPM analysis assumes that certain parameters
# are stored in the image's results string. 
#
proc LWDAQ_refresh_RFPM {} {
	upvar #0 LWDAQ_config_RFPM config
	upvar #0 LWDAQ_info_RFPM info
	if {[lwdaq_image_exists $config(memory_name)] != ""} {
		LWDAQ_analysis_RFPM $config(memory_name)
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
}

#
# LWDAQ_controls_RFPM creates secial controls 
# for the RFPM instrument.
#
proc LWDAQ_controls_RFPM {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_RFPM config
	upvar #0 LWDAQ_info_RFPM info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set f $w.scale
	frame $f
	pack $f -side top -fill x

	foreach {label_name element_name} {
			"Offset (V)" {display_V_offset}
			"Scale (V/div)" {display_V_per_div} } {
		label $f.l$element_name -text $label_name \
			-width [string length $label_name]
		entry $f.e$element_name -textvariable LWDAQ_info_RFPM($element_name) \
			-relief sunken -bd 1 -width 6
		pack $f.l$element_name $f.e$element_name -side left -expand 1
		bind $f.e$element_name <Return> LWDAQ_refresh_RFPM
	}
	foreach {label_name element_name} {
			"Scale (us/div)" {display_us_per_div} } {
		label $f.l$element_name -text $label_name \
			-width [string length $label_name]
		label $f.e$element_name -textvariable LWDAQ_info_RFPM($element_name) \
			-width 6
		pack $f.l$element_name $f.e$element_name -side left -expand 1
	}
}

#
# LWDAQ_daq_RFPM reads samples out of an input channel.
#
proc LWDAQ_daq_RFPM {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_RFPM info
	upvar #0 LWDAQ_config_RFPM config

	set repeat [expr $config(daq_num_samples) + $info(daq_startup_skip) - 1]
	set data_size [expr \
		[llength $info(A3008_commands)] * [expr $repeat + 1] \
		+ $info(daq_image_width)]
	set max_data_size [expr $info(daq_image_width) * $info(daq_image_height)]
	if {$data_size > $max_data_size} {
		return "ERROR: Data size exceeds available image area."
	}
	
	if {[catch {
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_data_addr $sock $info(daq_image_width)
		
		#Transmit the eight-bit DAC value.
		set cmd [LWDAQ_set_bit $info(A3008_wake) $info(A3008_FS_bit) 1]
		LWDAQ_transmit_command_binary $sock $cmd
		set cmd [LWDAQ_set_bit $cmd $info(A3008_SCLK_bit) 1]
		LWDAQ_transmit_command_binary $sock $cmd
		LWDAQ_transmit_command_binary $sock $cmd
		LWDAQ_transmit_command_binary $sock $cmd
		LWDAQ_transmit_command_binary $sock $cmd
		for {set i 0} {$i < 8} {incr i} {
			set cmd [LWDAQ_set_bit $cmd $info(A3008_DIN_bit) \
				[string index [LWDAQ_decimal_to_binary $config(daq_dac_value) 8] $i]]
			LWDAQ_transmit_command_binary $sock $cmd		
		}
		set cmd [LWDAQ_set_bit $cmd $info(A3008_DIN_bit) 0]
		LWDAQ_transmit_command_binary $sock $cmd
		LWDAQ_transmit_command_binary $sock $cmd
		LWDAQ_transmit_command_binary $sock $cmd
		LWDAQ_transmit_command_binary $sock $cmd	
		LWDAQ_transmit_command_binary $sock $info(A3008_wake)

		# Acquire traces for each of the four A3008 gain settings.
		LWDAQ_byte_write $sock $LWDAQ_Driver(clen_addr) 0
		foreach cmd $info(A3008_commands) {
			LWDAQ_transmit_command_binary $sock $cmd
			LWDAQ_delay_seconds $sock 0.010
			LWDAQ_set_repeat_counter $sock $repeat
			LWDAQ_set_delay_ticks $sock $config(daq_delay_ticks)
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc8_job)
		}
		LWDAQ_sleep $sock
		LWDAQ_byte_write $sock $LWDAQ_Driver(clen_addr) 1
		
		set image_contents [LWDAQ_ram_read $sock 0 $data_size]
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
		-results "$config(daq_num_samples) \
			$info(daq_startup_skip) \
			[llength $info(A3008_commands)]" \
		-name "$info(name)\_$info(counter)"]
	return $config(memory_name) 
} 

