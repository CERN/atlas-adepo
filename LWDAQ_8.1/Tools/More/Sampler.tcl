# Neruoarchiver.tcl, Interprets, Analyzes, and Archives Data from 
# the LWDAQ Recorder Instrument.
# Copyright (C) 2006-2007 Kevan Hashemi, Open Source Instruments Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

proc Sampler_init {} {
	upvar #0 Sampler_info info
	upvar #0 Sampler_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Sampler" "6"
	if {[winfo exists $info(window)]} {return 0}

	set info(control) "Idle"
	set info(graph_photo) "none"
	set info(image_name) "sampler_image"
	set info(sample_size) 8
	set info(src_codes) "40 0kHz 41 1kHz 42 2kHz 43 5kHz 44 10kHz \
		45 20kHz 46 50kHz 47 100kHz 48 200kHz 49 500kHz"
	set info(nsc_codes) "50 infinite 51 50 52 500 53 5000 54 50000"
	set info(nsc_translation) ""
	set info(src_translation) ""

	set config(graph_width) 400
	set config(graph_height) 300
	set config(reference_voltage) 5.0
	set config(display_range) $config(reference_voltage)
	set config(display_offset) 0
	set config(display_coupling) DC
	set config(download_size) 500
	set config(test_adc) "1"
	set config(ref_adc) "2"
	set config(nsc) "52"
	set config(src) "47"
	set config(startup_skip) 2
	set config(thermometer_elements) "4 3"
	set config(daq_ip_addr) "129.64.37.88"
	set config(A2053_driver_socket) 2
	set config(A2053_mux_socket) 1
	set config(A2100_driver_socket) 5
	set config(A2100_mux_socket) 1
	set config(ref_bottom_temperature) -195.8
	set config(ref_top_temperature) -78.5
	set config(ref_bottom_current) 0
	set config(ref_top_current) 1.493
	set config(gauge_commands) "30A0 31A0 32A0 33A0 34A0 35A0 36A0 37A0"
	set config(gauge_elements) "1 2 3 4 5 6"
	set config(total_current) 1
	set config(zero_currents) "Gauge_0 0.059 0.059 0.059 0.059 0.059 0.059"
	set config(signed_samples) 1
	set config(measure_I_T) 0
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1   
}

proc Sampler_configure {} {
	upvar #0 Sampler_info info
	LWDAQ_tool_configure $info(name)
}

proc Sampler_save {} {
	upvar #0 Sampler_info info
	LWDAQ_tool_save $info(name)
}

proc Sampler_help {} {
	upvar #0 Sampler_info info
	LWDAQ_tool_help $info(name)
}

proc Sampler_command {command} {
	upvar #0 Sampler_info info
	global LWDAQ_Info
	if {$command == $info(control)} {
		return 1
	}
	if {$command == "Stop"} {
		if {$info(control) != "Idle"} {set info(control) "Stop"}
		return 1
	}
	if {$info(control) == "Idle"} {
		set info(control) $command
		LWDAQ_post Sampler_execute
		return 1
	} 
	LWDAQ_print $info(text) "ERROR: Can't $command during $info(control)."
	return 0
}

proc Sampler_refresh {} {
	upvar #0 Sampler_info info
	upvar #0 Sampler_config config

	set info(nsc_translation) "UNDEFINED"
	foreach {a b} $info(nsc_codes) {
		if {$a == $config(nsc)} {set info(nsc_translation) $b}
	}

	set info(src_translation) "UNDEFINED"
	foreach {a b} $info(src_codes) {
		if {$a == $config(src)} {set info(src_translation) $b}
	}

	if {[lwdaq_image_exists $info(image_name)]==""} {
		return "ERROR: No data to display."
	}
	if {[string match -nocase "AC" $config(display_coupling)]} {
		set config(display_coupling) "AC"
	} {
		set config(display_coupling) "DC"
	}
	if {$config(signed_samples)} {
		if {$config(display_coupling) == "AC"} {
			set display_min \
				[expr $config(display_offset) \
				- 1.0*$config(display_range)]
			set display_max \
				[expr $config(display_offset) \
				+ 1.0*$config(display_range)]
		} {
			set display_min [expr $config(display_offset) - $config(display_range)]
			set display_max [expr $config(display_offset) + $config(display_range)]
		}
	} {
		if {$config(display_coupling) == "AC"} {
			set display_min \
				[expr $config(display_offset) \
				- 1.0*$config(display_range)/2]
			set display_max \
				[expr $config(display_offset) \
				+ 1.0*$config(display_range)/2]
		} {
			set display_min $config(display_offset)
			set display_max [expr $config(display_offset) + $config(display_range)]
		}
	}
	
	set analysis [lwdaq_sampler $info(image_name) \
		"$config(signed_samples) plot $display_min \
		$display_max $config(display_coupling) \
		$config(reference_voltage) \
		$config(test_adc) $config(ref_adc)"]
	if {[LWDAQ_is_error_result $analysis]} {return $analysis}
	lwdaq_draw $info(image_name) $info(graph_photo)
	if {$config(test_adc) == "1"} {
		set result "[lindex $analysis 2] [lindex $analysis 3] "
	} {
		set result "[lindex $analysis 6] [lindex $analysis 7] "	
	}
	set analysis [lwdaq_sampler $info(image_name) \
		"$config(signed_samples) compare \
		$config(reference_voltage) \
		$config(test_adc) $config(ref_adc)"]
	if {[LWDAQ_is_error_result $analysis]} {return $analysis}
	append result "$analysis "
	return $result
}

proc Sampler_execute {{command ""}} {
	upvar #0 Sampler_info info
	upvar #0 Sampler_config config
	upvar #0 LWDAQ_config_Terminal s_config
	upvar #0 LWDAQ_config_Gauge c_config
	upvar #0 LWDAQ_config_Thermometer t_config
	upvar #0 LWDAQ_info_Terminal s_info
	upvar #0 LWDAQ_info_Gauge c_info
	upvar #0 LWDAQ_info_Thermometer t_info

	if {$command != ""} {set info(control) $command}
	
	if {![array exists info]} {return 0}

	if {$info(window) != ""} {
		if {![winfo exists $info(window)]} {return 0}
	}
	
	if {$info(control) == "Stop"} {
		set info(control) "Idle"
		return 1
	}
	 
	if {($info(control) == "Run") || ($info(control) == "Step")} {	
		LWDAQ_print -nonewline $info(text) "[clock seconds] "
		set saved_lwdaq_config [lwdaq_config]
		lwdaq_config -text_name $info(text) 
		
		if {[catch {
		
			# Acquire ADC data from Terminal Instrument and display.
			set s_config(tx_hex) "F0 $config(src) $config(nsc) 10"
			set s_config(rx_size) [expr $config(download_size) * $info(sample_size)]
			set s_config(analysis_enable) 0
			set s_config(tx_ascii) ""
			set s_config(tx_decimal) ""
			set s_config(tx_file_name) ""
			set s_config(daq_ip_addr) $config(daq_ip_addr)
			set s_config(daq_driver_socket) $config(A2100_driver_socket)
			set s_config(daq_mux_socket) $config(A2100_mux_socket)
			set s_info(daq_image_width) $config(graph_width)
			set s_info(daq_image_height) $config(graph_height)
			set result [LWDAQ_acquire Terminal]
			if {[LWDAQ_is_error_result $result]} {error $result}
			lwdaq_image_manipulate $s_config(memory_name) copy -name $info(image_name)
			lwdaq_data_manipulate $info(image_name) shift \
				[expr $info(sample_size) * $config(startup_skip)]
			set result [Sampler_refresh]
			if {[LWDAQ_is_error_result $result]} {error $result}
			LWDAQ_print -nonewline $info(text) "$result " blue
			
			# Don't to additional data acquisition unless requested by user.
			if {$config(measure_I_T)} {
			
				# Acquire temperature from Thermometer Instrument.
				set t_info(ref_bottom_C) $config(ref_bottom_temperature)
				set t_info(ref_top_C) $config(ref_top_temperature)
				set t_config(daq_device_element) $config(thermometer_elements)
				set t_config(daq_ip_addr) $config(daq_ip_addr)
				set t_config(daq_driver_socket) $config(A2053_driver_socket)
				set t_config(daq_mux_socket) $config(A2053_mux_socket)
				set result [LWDAQ_acquire Thermometer]
				if {[LWDAQ_is_error_result $result]} {error $result}
				foreach a {1 2} {
					LWDAQ_print -nonewline $info(text) \
						"[format %.1f [lindex $result $a]] " green
				}
	
				# Set the A2100 to sampling at the specified rate.
				set s_config(tx_hex) "F0 $config(src) 50 10"
				set s_config(rx_size) 0
				set result [LWDAQ_acquire Terminal]
				if {[LWDAQ_is_error_result $result]} {error $result}
	
				# Acquire currents from Gauge Instrument.
				set c_config(ref_bottom_y) $config(ref_bottom_current)
				set c_config(ref_top_y) $config(ref_top_current)
				set c_info(gauge_commands) $config(gauge_commands)
				set c_config(daq_device_element) $config(gauge_elements)
				set c_config(daq_ip_addr) $config(daq_ip_addr)
				set c_config(daq_driver_socket) $config(A2100_driver_socket)
				set c_config(daq_mux_socket) $config(A2100_mux_socket)
				set result [LWDAQ_acquire Gauge]
				if {[LWDAQ_is_error_result $result]} {error $result}
	
				# Calculate net currents.
				set nc [list]
				foreach a {1 2 3 4 5 6} {
					lappend nc [expr \
						[lindex $result $a] \
						- [lindex $config(zero_currents) $a] ]
				}
	
				# Either print the individual currents or the combined
				# currents for each ADC.
				if {$config(total_current)} {
					LWDAQ_print -nonewline $info(text)	"\
						[format %.3f [expr [lindex $nc 0] + [lindex $nc 1] + [lindex $nc 2]]] \
						[format %.3f [expr [lindex $nc 3] + [lindex $nc 4] + [lindex $nc 5]]]" \
						purple
	
				} {
					foreach a {0 1 2 3 4 5} {
						LWDAQ_print -nonewline $info(text) \
							"[format %.3f [lindex $nc $a]] " orange
					}
				}
				
				# Reset the A2100.
				set s_config(tx_hex) "F0"
				set s_config(rx_size) 0
				set result [LWDAQ_acquire Terminal]
				if {[LWDAQ_is_error_result $result]} {error $result}
				
				# Restore the Terminal so it's settings are the ones that get
				# new data, instead of just reset the A2100.
				set s_config(tx_hex) "F0 $config(src) $config(nsc) 10"
				set s_config(rx_size) [expr $config(download_size) * $info(sample_size)]
			}
		} error_result]} {
			LWDAQ_print $info(text)
			LWDAQ_print $info(text) $error_result
			set info(control) "Idle"
			return 0
		}
		
		LWDAQ_print $info(text)
		eval "lwdaq_config $saved_lwdaq_config"
		if {$info(control) == "Run"} {	
			LWDAQ_post Sampler_execute
		} {
			set info(control) "Idle"
		}
		return 1
	}
	
	if {$info(control) == "SZC"} {	
		LWDAQ_print -nonewline $info(text) "[clock seconds] "
		set saved_lwdaq_config [lwdaq_config]
		lwdaq_config -text_name $info(text) 
		
		if {[catch {
			# Acquire zero currents from Gauge Instrument.
			set c_config(ref_bottom_y) $config(ref_bottom_current)
			set c_config(ref_top_y) $config(ref_top_current)
			set c_info(gauge_commands) $config(gauge_commands)
			set c_config(daq_device_element) $config(gauge_elements)
			set s_config(daq_ip_addr) $config(daq_ip_addr)
			set c_config(daq_driver_socket) $config(A2100_driver_socket)
			set c_config(daq_mux_socket) $config(A2100_mux_socket)
			set result [LWDAQ_acquire Gauge]
			if {[LWDAQ_is_error_result $result]} {error $result}
			
			# Set zero currents and display them.
			set config(zero_currents) $result
			foreach a {1 2 3 4 5 6} {
				LWDAQ_print -nonewline $info(text) \
					"[format %.3f [lindex $result $a]] " orange
			}

		} error_result]} {
			LWDAQ_print $info(text)
			LWDAQ_print $info(text) $error_result
			set info(control) "Idle"
			return 0
		}

		LWDAQ_print $info(text)
		eval "lwdaq_config $saved_lwdaq_config"
		set info(control) "Idle"
		return 1
	}

	set info(control) "Idle"
	return 1
}


proc Sampler_open {} {
	upvar #0 Sampler_config config
	upvar #0 Sampler_info info
	
	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	label $f.lstate -textvariable $info(name)_info(control) -width 12 -fg blue
	pack $f.lstate -side left -expand 1
	foreach a {Stop Step Run} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Sampler_command $a"
		pack $f.$b -side left -expand 1
	}
	foreach a {Help Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Sampler"
		pack $f.$b -side left -expand 1
	}

	set f $w.display
	frame $f -border 2
	pack $f -side top -fill x
	
   	set info(graph_photo) [image create photo \
   		-width $config(graph_width) -height $config(graph_height)]
	label $f.graph -image $info(graph_photo) 
	pack $f.graph -side left -fill y
	
	set g $f.contols
	frame $g -border 2 
	pack $g -side right -fill y

	foreach {a b} { \
			nsc "Number of Samples Code" \
			src "Sample Rate Code"} {
		label $g.l$a -text $b -width 14 -anchor w
		entry $g.e$a -textvariable Sampler_config($a) -relief sunken -bd 1 -width 6
		bind $g.e$a <Return> Sampler_refresh
		label $g.t$a -textvariable Sampler_info($a\_translation) -width 8
		grid $g.l$a $g.e$a $g.t$a -sticky news
	}

	foreach {a b c} { \
			reference_voltage "Reference Voltage" "V"\
			download_size "Download Size" "Samples"\
			startup_skip "Start-Up Skip" "Samples"\
			test_adc "Test Channel" "ID" \
			ref_adc "Reference Channel" "ID" \
			display_range "Display Range" "V"\
			display_offset "Display Offset" "V"\
			display_coupling "Display Coupling" "AC/DC"} {
		label $g.l$a -text $b -anchor w
		entry $g.e$a -textvariable Sampler_config($a) -relief sunken -bd 1 -width 6
		bind $g.e$a <Return> Sampler_refresh
		label $g.u$a -text $c
		grid $g.l$a $g.e$a $g.u$a -sticky news
	}

	
	foreach {a b} { \
			measure_I_T "Measure I and T" \
			signed_samples "Signed Samples"} {
		label $g.l$a -text $b -width 22 -anchor w
		checkbutton $g.c$a -variable Sampler_config($a)
		grid $g.l$a $g.c$a -sticky news
	}

	button $g.zc -text "Set Zero Currents" -command "Sampler_command SZC"
	grid $g.zc -sticky w

	

	set info(text) [LWDAQ_text_widget $w 80 15]
	return 1
}

Sampler_init
Sampler_open
Sampler_refresh

	
return 1

----------Begin Help----------

For a description of the Sampler Tool, see the Sampler Tool section of the ADC Tester Manual:

http://alignment.hep.brandeis.edu/Electronics/A2100/M2100.html

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
