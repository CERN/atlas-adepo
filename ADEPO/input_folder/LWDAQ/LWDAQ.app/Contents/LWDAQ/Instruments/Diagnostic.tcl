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
# Diagnostic.tcl defines the Diagnostic instrument.
#

#
# LWDAQ_init_Diagnostic creates all elements of the Diagnostic instrument's
# config and info arrays.
#
proc LWDAQ_init_Diagnostic {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Diagnostic info
	upvar #0 LWDAQ_config_Diagnostic config
	array unset config

	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Diagnostic"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(daq_extended) 0
	set info(daq_device_type) 0
	set info(delete_old_images) 1
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 340
	set info(daq_image_height) 240
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) -1
	set info(daq_image_bottom) -1
	set info(daq_password) "no_password"
	set info(psc_num_tries) 0
	set info(psc_counter) 0
	set info(psc_max_tries) 4
	set info(display_s_per_div) 0.001
	set info(display_V_per_div) 5
	set info(display_V_offset) 0
	set info(display_V_coupling) DC
	set info(display_num_div) 10
	set info(min_p15) 14
	set info(max_p15) 16
	set info(min_p5) 4.5
	set info(max_p5) 5.5
	set info(min_n15) -16
	set info(max_n15) -14
	set info(max_p15_mA) 200
	set info(max_p5_mA) 200
	set info(max_n15_mA) 200
	set info(commands) "0000"
	set info(repeat) 0
	set info(sleepall_params) "8 10"
	set info(verbose_description) " \
		{Software Version} {Hardware Type} \
		{Hardware Version} {Firmware Version} \
		{Most Recent Loop Time (ns)} {Data transfer speed (kBytes/s)} \
		{+15V Supply Voltage (V)} {+15V Supply Current (mA)} \
		{+5V Supply Voltage (V)} {+5V Supply Current (mA)} \
		{-15V Supply Voltage (V)} {-15V Supply Current (mA)} \
		{Commom Mode Gain (V/V)} {Differential Mode Gain (V/V)}"

	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 129.64.37.79
	set config(daq_driver_socket) 1
	set config(daq_mux_socket) 1
	set config(daq_psc) 0
	set config(analysis_enable) 1
	set config(intensify) none
	set config(verbose_result) 0
	set config(daq_actions) "none"
	
	return 1
}

#
# LWDAQ_analysis_Diagnostic displays the power supply measurements
# carried by the $image_name and displays them in the diagnostic
# instrument window. It calculates average values for the power supply
# voltages and current consumption and returns these parameters, as
# well as other information about the driver. By default, the routine
# uses the image $config(memory_name).
#
proc LWDAQ_analysis_Diagnostic {{image_name ""}} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[catch {
		set v_min [expr $info(display_V_offset) - \
			($info(display_num_div) * $info(display_V_per_div) / 2)]
		set v_max [expr $info(display_V_offset) + \
			($info(display_num_div) * $info(display_V_per_div) / 2)]
		set t_min 0
		set t_max [expr $info(display_num_div) * $info(display_s_per_div)]
		set result [lwdaq_diagnostic $image_name \
			-v_max $v_max -v_min $v_min -t_min $t_min -t_max $t_max \
			-ac_couple [string match -nocase $info(display_V_coupling) "AC"] ]
	} error_result]} {return "ERROR: $error_result"}
	return $result
}

#
# LWDAQ_refresh_Diagnostic refreshes the display of the data, 
# given new display settings. It calls the Diagnostic instrument's
# analysis procedure.
#
proc LWDAQ_refresh_Diagnostic {{image_name ""}} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[lwdaq_image_exists $image_name] != ""} {
		set result [LWDAQ_analysis_Diagnostic $image_name]
		lwdaq_draw $image_name $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
	return $result
}

#
# LWDAQ_on_Diagnostic turns on the LWDAQ device power.
#
proc LWDAQ_on_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Turning device and multiplexer power supplies ON..."
	LWDAQ_update
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_on $sock
	LWDAQ_wait_for_driver $sock
	LWDAQ_print $info(text) "done."
	return 1
}

#
# LWDAQ_off_Diagnostic turns off the device power.
#
proc LWDAQ_off_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Turning device and multiplexer power supplies OFF..."
	LWDAQ_update
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_off $sock
	LWDAQ_wait_for_driver $sock
	LWDAQ_print $info(text) "done."
	return 1
}

#
# LWDAQ_reset_Diagnostic reboots the controller logic.
#
proc LWDAQ_reset_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Resetting controller registers and state machines..."
	LWDAQ_update
	LWDAQ_controller_reset $sock
	LWDAQ_wait_for_driver $sock
	LWDAQ_print $info(text) "done."
	return 1
}

#
# LWDAQ_reboot_Diagnostic re-boots the server.
#
proc LWDAQ_reboot_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Sending reboot command to relay..."
	LWDAQ_relay_reboot $sock
	LWDAQ_print $info(text) "done."
	return 1
}

#
# LWDAQ_sleep_Diagnostic sends the target device to sleep.
#
proc LWDAQ_sleep_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Putting target device to sleep..."
	LWDAQ_update
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_sleep $sock
	LWDAQ_wait_for_driver $sock
	LWDAQ_print $info(text) "done."
	return 1
}

#
# LWDAQ_sleepall_Diagnostic sends a range of devices to sleep. The 
# routine starts with driver socket 1 and multiplexer socket 1, and
# proceeds to driver socket 1, multiplexer socket b, where b is the
# second number in sleepall_params. The routine moves on to 
# driver socket 2 and repeats the same procedure, and so on, up to
# driver socket a, where a is the first number in sleepall_params.
#
proc LWDAQ_sleepall_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket)
	set d [lindex $info(sleepall_params) 0]
	set b [lindex $info(sleepall_params) 1]
	for {set driver_socket 1} {$driver_socket <= $d} {incr driver_socket} {
		LWDAQ_print -nonewline $info(text) \
			"Sleep: driver socket $driver_socket, branch sockets"
		LWDAQ_update
		for {set branch_socket 1} {$branch_socket <= $b} {incr branch_socket} {
			LWDAQ_set_driver_mux $sock $driver_socket $branch_socket
			LWDAQ_sleep $sock
			LWDAQ_print -nonewline $info(text) " $branch_socket"
		}
		LWDAQ_wait_for_driver $sock
		LWDAQ_print $info(text) "."
	}
	return 1
}

#
# LWDAQ_wake_Diagnostic wakes up the target device.
#
proc LWDAQ_wake_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Waking target device..."
	LWDAQ_update
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_wake $sock
	LWDAQ_wait_for_driver $sock
	LWDAQ_print $info(text) "done."
	return 1
}

#
# LWDAQ_loop_Diagnostic executes a loop job on the Diagnostic instrument's
# target device, reads out the LWDAQ Driver's loop timer, and prints the
# loop time in the Diagnostic text window.
#
proc LWDAQ_loop_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	LWDAQ_print -nonewline $info(text) "Measuring loop time..."
	LWDAQ_update
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_wake $sock
	LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
	LWDAQ_execute_job $sock $LWDAQ_Driver(loop_job)
	LWDAQ_sleep $sock
	set time [expr [LWDAQ_loop_time $sock] * $LWDAQ_Driver(loop_timer_period)]
	LWDAQ_print $info(text) "done. Loop time is $time ns. Target now asleep."
	return $time
}

#
# LWDAQ_transmit_Diagnostic transmits each hex word in info(commands)
# to the target device (info(repeat) + 1) times.
#
proc LWDAQ_transmit_Diagnostic {sock} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	if {[llength $info(commands)] == 0} {
		LWDAQ_print $info(text) "ERROR: no command specified."
		return 0
	}
	if {[llength $info(commands)] == 1} {
		LWDAQ_print -nonewline $info(text) \
			"Transmitting $info(commands) (hex) to target [expr $info(repeat) + 1] times..."
		LWDAQ_update
		LWDAQ_set_repeat_counter $sock $info(repeat)
		LWDAQ_transmit_command_hex $sock $info(commands)
		LWDAQ_wait_for_driver $sock
		LWDAQ_print $info(text) "done."
	}
	if {[llength $info(commands)] > 1} {
		LWDAQ_print -nonewline $info(text) \
			"Transmitting \"$info(commands)\" to target [expr $info(repeat) + 1] times..."
		for {set counter 0} {$counter < $info(repeat)} {incr counter} {
			foreach cmd $info(commands) {
				LWDAQ_transmit_command_hex $sock $cmd
			}
			if {[expr $counter % 10] == 0} {
				LWDAQ_wait_for_driver $sock
				if {$info(control) == "Stop"} {break}
			}
		}
		LWDAQ_print $info(text) "done."
	}
	return 1
}

#
# LWDAQ_exec_Diagnostic opens a socket to a driver and calls the specified
# operation routine.
#
proc LWDAQ_exec_Diagnostic {operation} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info
	global LWDAQ_Driver LWDAQ_Info
	set info(control) "Execute"
	if {[catch {
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		set result [LWDAQ_$operation\_Diagnostic $sock]
		LWDAQ_socket_close $sock
	} error_result]} { 
		if {[info exists sock]} {LWDAQ_socket_close $sock}
		incr LWDAQ_Info(num_daq_errors)
		LWDAQ_print $info(text) "\nERROR: $error_result" red
		set result 0
	}
	set info(control) "Idle"
	return $result
}

#
# LWDAQ_psc_Diagnostic checks the power supply voltages recorded in a Diagnostic
# image to see if they are within the bounds defined by the min_* and max_* info
# parameters. The routine returns a string of warnings. If this string is empty, no
# problems were encountered.
#
proc LWDAQ_psc_Diagnostic {image_name} {
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info

	set result [LWDAQ_analysis_Diagnostic $image_name]
	set p15 [lindex $result 6]
	set p15_mA [lindex $result 7]
	set p5 [lindex $result 8]
	set p5_mA [lindex $result 9]
	set n15 [lindex $result 10]
	set n15_mA [lindex $result 11]

	set warnings ""
	if {$p15 < $info(min_p15)} {
		append warnings "+15V low "
	}
	if {$p15 > $info(max_p15)} {
		append warnings "+15V high "
	}
	if {$p15_mA > $info(max_p15_mA)} {
		append warnings "+15V current high "
	}
	if {$p5 < $info(min_p5)} {
		append warnings "+5V low "
	}
	if {$p5 > $info(max_p5)} {
		append warnings "+5V high "
	}
	if {$p5_mA > $info(max_p5_mA)} {
		append warnings "+5V current high "
	}
	if {$n15 < $info(min_n15)} {
		append warnings "-15V low "
	}
	if {$n15 > $info(max_n15)} {
		append warnings "-15V high "
	}
	if {$n15_mA > $info(max_n15_mA)} {
		append warnings "-15V current high "
	}
	
	return $warnings
}

#
# LWDAQ_daq_Diagnostic reads configuration paramters from the LWDAQ
# hardware, and records them in a result string, which it returns.
#
proc LWDAQ_daq_Diagnostic {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Diagnostic info
	upvar #0 LWDAQ_config_Diagnostic config

	set image_size [expr $info(daq_image_width) * $info(daq_image_height)]

	if {[catch {
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		LWDAQ_ram_delete $sock 0 $image_size 0
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_base_addr_hex $sock $config(daq_driver_socket)
		
		foreach a $config(daq_actions) {
			set a [string tolower $a]
			if {[string is integer $a]} {
				LWDAQ_print -nonewline $info(text) "Waiting for $a ms..."
				LWDAQ_wait_ms $a
				LWDAQ_print $info(text) "done."
			} {
				if {[info commands "LWDAQ_$a\_Diagnostic"] != ""} {
					LWDAQ_$a\_Diagnostic $sock
				} {
					if {$a != "none"} {
						error "Invalid action \"$a\"."
					}
				}
			}
		}
		
		set rv [LWDAQ_software_version $sock]
		set hid [LWDAQ_hardware_id $sock]
		set hv [LWDAQ_hardware_version $sock]
		set fv [LWDAQ_firmware_version $sock]
		set time [expr [LWDAQ_loop_time $sock] * $LWDAQ_Driver(loop_timer_period)]
		set display_s [expr $info(display_s_per_div) * $info(display_num_div)]
		set period [expr $display_s / $info(daq_image_width)]
		set delay [expr $period - $LWDAQ_Driver(min_adc16_sample_period)]
		if {$delay < 0} {
			set delay 0
			set period $LWDAQ_Driver(min_adc16_sample_period)
		}
		LWDAQ_set_data_addr $sock $info(daq_image_width)
		for {set branch 0} {$branch <= 8} {incr branch 1} {
			LWDAQ_set_driver_mux $sock 0 $branch
			LWDAQ_delay_seconds $sock $LWDAQ_Driver(adc16_settling_delay)
			LWDAQ_set_repeat_counter $sock [expr $info(daq_image_width) - 1]
			LWDAQ_set_delay_seconds $sock $delay
			LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
			LWDAQ_wait_for_driver $sock $display_s
		}
		set start_us [clock microseconds]
		set image_contents [LWDAQ_ram_read $sock 0 $image_size]
		set end_us [clock microseconds]
		set rate [expr 1000.0 * $image_size / ($end_us - $start_us)]
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
		-results "$rv $hid $hv $fv $time [format %.1f $rate] [format %1.5e $period]" \
		-name "$info(name)\_$info(counter)"]
		
	if {!$config(daq_psc)} {
		set info(psc_num_tries) 0
		return $config(memory_name)
	} 

	incr info(psc_counter)
	set warnings [LWDAQ_psc_Diagnostic $config(memory_name)]
	if {$warnings != ""} {LWDAQ_print $info(text) "WARNING: $warnings"}

	if {($warnings != "") \
			&& ($info(control) != "Stop") \
			&& ($info(psc_counter)<$info(psc_max_tries))} {
		if {[winfo exists $info(window)]} {
			lwdaq_draw $config(memory_name) $info(photo) \
				-intensify $config(intensify) -zoom $info(zoom)
		} 
		return [LWDAQ_daq_$info(name)]
	} {
		set info(psc_num_tries) $info(psc_counter)
		set info(psc_counter) 0
		return $config(memory_name) 
	}
} 

#
# LWDAQ_controls_Diagnostic creates secial controls 
# for the Diagnostic instrument.
#
proc LWDAQ_controls_Diagnostic {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_Diagnostic config
	upvar #0 LWDAQ_info_Diagnostic info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set g $w.custom1
	frame $g
	pack $g -side top -fill x

	foreach {label_name element_name} {
			"Offset (V)" display_V_offset
			"Scale (V/div)" display_V_per_div
			"Coupling (AC/DC)" display_V_coupling 
			"Scale (s/div)" display_s_per_div } {
		label $g.l$element_name -text $label_name \
			-width [string length $label_name]
		entry $g.e$element_name -textvariable LWDAQ_info_Diagnostic($element_name) \
			-relief sunken -bd 1 -width 6
		pack $g.l$element_name $g.e$element_name -side left -expand 1
		bind $g.e$element_name <Return> LWDAQ_refresh_Diagnostic
	}

	set f $w.custom2	
	frame $f
	pack $f -side top -fill x
	
	label $f.controller -text "Controller:" 
	button $f.on -text "Head Power On" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic on"}
	button $f.off -text "Head Power Off" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic off"}
	button $f.reset -text "Reset" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic reset"}
	button $f.reboot -text "Reboot" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic reboot"}
	button $f.sleepall -text "Sleep All" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic sleepall"}
	pack $f.controller $f.on $f.off $f.reset $f.reboot $f.sleepall  -side left -expand 1

	set f $w.custom3	
	frame $f
	pack $f -side top -fill x
	
	label $f.target -text "Target:" 
	button $f.sleep -text "Sleep" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic sleep"}
	button $f.wake -text "Wake" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic wake"}
	button $f.loop -text "Loop" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic loop"}
	button $f.transmit -text "Transmit" \
		-command {LWDAQ_post "LWDAQ_exec_Diagnostic transmit"}
	label $f.cl -text "Command (Hex)" -width 13
	entry $f.command -textvariable LWDAQ_info_Diagnostic(commands) -width 5
	label $f.rl -text "Repeat (Dec)" -width 12
	entry $f.repeat -textvariable LWDAQ_info_Diagnostic(repeat) -width 5
	pack $f.target $f.sleep $f.wake $f.loop $f.transmit \
		$f.cl $f.command $f.rl $f.repeat -side left -expand 1
}



