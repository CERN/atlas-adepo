# The Analyzer measures the current consumption signature of 
# a LWDAQ device and compares the signature to a database of
# signatures contained in the data section of the Analyzer
# script.
#
# Copyright (C) 2008, Kevan Hashemi, Brandeis University
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
# Version 10: Edited the BCAM circuit signature laser consumptions.
#
# Version 11: Analyze all starts from existing sockets.
#
# Version 13: Add errors and warnings to device string at end of single-
# line result. Add check for termination current on the branch and root 
# cables to see if there is a device plugged in. Add power supply check.
#
# Version 14: We check for termination current only when we detect a 
# repeater-multiplexer combination.
#
# Version 15: Add a signature for an RTD head with no sensors attached (-NT),
# with RTD2 only (-T2) and with RTD2 and RTD11 (-T2T11).
#
# Version 16: Add support for Fourteen Way Injector (A2078A).
#

proc Analyzer_init {} {
	upvar #0 Analyzer_info info
	upvar #0 Analyzer_config config
	global LWDAQ_Info
	
	LWDAQ_tool_init "Analyzer" "16"
	if {[winfo exists $info(window)]} {return 0}

	set info(lines_per_measurement) 18
	set info(data_image) "_analyzer_data_image"
	
	set config(ip_addr) "129.64.37.79"
	set config(base_addr) "00000000"
	set config(driver_start_socket) 1
	set config(driver_end_socket) 8
	set config(mux_start_socket) 1
	set config(mux_end_socket) 10
	set config(mux_null_socket) 15
	set config(driver_socket) 1
	set config(mux_socket) 1
	set config(password) "no_password"
	set config(commands) "0000 0080 0001 1080 0480 8280"
	set config(max_mux_current) 30
	set config(min_mux_current) 10
	set config(max_error) 20.0
	set config(max_error_zero_loopback) 40.0
	set config(max_error_fractional) 0.20
	set config(max_loop_time) 3125
	set config(sample_period) 0.0001
	set config(num_samples) 100
	set config(verbose) 1
	set config(settling_delay_s) 0.2
	set config(command_delay_s) 0.1
	set config(leave_repeater_off) 0
	set config(min_p15v) 14.0
	set config(max_n15v) -14.0
	set config(min_p5v) 4.0
	set config(termination_min) 2.0
	set config(termination_max) 6.0
	
	set info(control) "Idle"
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 
	
	set data [split [LWDAQ_tool_data Analyzer] :]
	set info(signatures) [list]
	foreach a $data {
		set b [string trim $a]
		if {$b != ""} {
			lappend info(signatures) $b
		}
	}
	
	return 1   
}

proc Analyzer_command {command} {
	upvar #0 Analyzer_info info
	upvar #0 Analyzer_config config
	global LWDAQ_Info
	
	if {$command == $info(control)} {
		return 1
	}

	if {$command == "Stop"} {
		if {$info(control) == "Idle"} {
			return 1
		}
		set info(control) "Stop"
		set event_pending [string match "Analyzer*" $LWDAQ_Info(current_event)]
		foreach event $LWDAQ_Info(queue_events) {
			if {[string match "Analyzer*" $event]} {
				set event_pending 1
	 		}
		}
		if {!$event_pending} {
			set info(control) "Idle"
		}
		return 1
	}
	
	if {$info(control) == "Idle"} {
		set info(control) $command
		LWDAQ_post Analyzer_execute
		return 1
	} 
	
	set info(control) $command
	return 1	
}

proc Analyzer_contact {} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[catch {
		LWDAQ_print -nonewline $info(text) \
			"Attempting to open socket..." green
		set sock [LWDAQ_socket_open $config(ip_addr)]
		LWDAQ_print $info(text)  "success." green
		LWDAQ_print -nonewline $info(text) "Attempting login..." green
		LWDAQ_login $sock $config(password)
		LWDAQ_print $info(text)  "success." green
		if {[string match "00000000" $config(base_addr)]} {
			LWDAQ_set_base_addr_hex $sock "00000000"
			LWDAQ_print $info(text) "Relay Software Version: [LWDAQ_software_version $sock]"
			LWDAQ_print $info(text) "Relay MAC Address: [LWDAQ_mac_read $sock]"
			LWDAQ_print $info(text) "Controller Hardware ID: [LWDAQ_hardware_id $sock]" 
			LWDAQ_print $info(text) "Controller Hardware Version: [LWDAQ_hardware_version $sock]" 
			LWDAQ_print $info(text) "Controller Firmware Version: [LWDAQ_firmware_version $sock]" 
		} {
			LWDAQ_set_base_addr_hex $sock "00000000"
			LWDAQ_print $info(text) "Interface Software Version: [LWDAQ_software_version $sock]"
			LWDAQ_print $info(text) "Interface MAC Address: [LWDAQ_mac_read $sock]"
			LWDAQ_print $info(text) "Interface Hardware ID: [LWDAQ_hardware_id $sock]" 
			LWDAQ_print $info(text) "Interface Hardware Version: [LWDAQ_hardware_version $sock]" 
			LWDAQ_print $info(text) "Interface Firmware Version: [LWDAQ_firmware_version $sock]" 
			LWDAQ_set_base_addr_hex $sock $config(base_addr)
			LWDAQ_print $info(text) "Driver Hardware ID: [LWDAQ_hardware_id $sock]" 
			LWDAQ_print $info(text) "Driver Hardware Version: [LWDAQ_hardware_version $sock]" 
			LWDAQ_print $info(text) "Driver Firmware Version: [LWDAQ_firmware_version $sock]"
			LWDAQ_set_base_addr_hex $sock "00000000"
		}
		LWDAQ_print -nonewline $info(text) "Closing socket..." green
		LWDAQ_socket_close $sock
		LWDAQ_print $info(text)  "closed.\n" green
	} error_result]} {
		LWDAQ_print $info(text)
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
	}	
	return 1
}

proc Analyzer_power_off {} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Turning off device power..."
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(ip_addr)]
		LWDAQ_login $sock $config(password)
		if {![string match "00000000" $config(base_addr)]} {
			LWDAQ_set_base_addr_hex $sock $config(base_addr)
		}
		LWDAQ_off $sock
		LWDAQ_socket_close $sock
		LWDAQ_print $info(text) "done."
	} error_result]} {
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
	}	
	return 1
}

proc Analyzer_power_on {} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Turning on device power..."
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(ip_addr)]
		LWDAQ_login $sock $config(password)
		if {![string match "00000000" $config(base_addr)]} {
			LWDAQ_set_base_addr_hex $sock $config(base_addr)
		}
		LWDAQ_on $sock
		LWDAQ_socket_close $sock
		LWDAQ_print $info(text) "done."
	} error_result]} {
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
	}	
	return 1
}

#
# Analyzer_sleep turns on all repeaters and sends all devices to sleep.
# It leaves the repeaters turned on. To eliminate the current consumed
# by an active LVD transmitter driving a 100-Ohm load, we set each
# multiplexer to select socket $config(mux_null_socket).
#
proc Analyzer_sleep {} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[catch {
		set sock [LWDAQ_socket_open $config(ip_addr)]
		LWDAQ_login $sock $config(password)
		if {![string match "00000000" $config(base_addr)]} {
			LWDAQ_set_base_addr_hex $sock $config(base_addr)
		}
		for {set driver_socket $config(driver_start_socket)} \
				{$driver_socket <= $config(driver_end_socket)} \
				{incr driver_socket} {
			# Turn on all the repeaters and wait for devices to settle.
			LWDAQ_print -nonewline $info(text) \
				"Sleep: driver socket $driver_socket, multiplexer sockets"
			LWDAQ_update
			LWDAQ_set_driver_mux $sock $driver_socket $config(mux_start_socket)
			LWDAQ_delay_seconds $sock $config(settling_delay_s)
			
			# Go through each multiplexer socket and send any device
			# attached to it to sleep.
			for {set mux_socket $config(mux_start_socket)} \
					{$mux_socket <= $config(mux_end_socket)} \
					{incr mux_socket} {
				LWDAQ_set_driver_mux $sock $driver_socket $mux_socket
				LWDAQ_sleep $sock
				LWDAQ_print -nonewline $info(text) " $mux_socket"
			}

			# Select the null socket.
			LWDAQ_set_driver_mux $sock $driver_socket $mux_socket

			# Wait for the driver to execute all these commands. We
			# don't want to overflow its input buffer.
			LWDAQ_wait_for_driver $sock
			LWDAQ_print $info(text) "."
		}
		LWDAQ_socket_close $sock
	} error_result]} {
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
	}	
	return 1
}

#
# Analyzer_sleep_mux puts all devices on a multiplexer to sleep,
# then selects the multiplexer null socket and waits for the driver
# to execute all its commands.
#
proc Analyzer_sleep_mux {sock driver_socket} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	for {set mux_socket $config(mux_start_socket)} \
			{$mux_socket <= $config(mux_end_socket)} \
			{incr mux_socket} {
		LWDAQ_set_driver_mux $sock $driver_socket $mux_socket
		LWDAQ_sleep $sock
	}
	LWDAQ_set_driver_mux $sock $driver_socket $config(mux_null_socket)
	LWDAQ_wait_for_driver $sock
	return 0
}

#
# Analyzer_repeaters_off turns off power downstream of all repeaters 
# attached to driver sockets. If a driver socket has no repeater, the 
# routine has no effect.
#
proc Analyzer_repeaters_off {} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Repeater Off: driver sockets"
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(ip_addr)]
		LWDAQ_login $sock $config(password)
		if {![string match "00000000" $config(base_addr)]} {
			LWDAQ_set_base_addr_hex $sock $config(base_addr)
		}
		for {set driver_socket $config(driver_start_socket)} \
				{$driver_socket <= $config(driver_end_socket)} \
				{incr driver_socket} {
			LWDAQ_set_driver_mux $sock $driver_socket 0
			LWDAQ_print -nonewline $info(text) " $driver_socket"
		}
		LWDAQ_print $info(text) "."
		LWDAQ_socket_close $sock
	} error_result]} {
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
	}	
	return 1
}

proc Analyzer_record_supplies {sock} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	global LWDAQ_Driver
	for {set branch 0} {$branch <= 8} {incr branch} {
		LWDAQ_set_driver_mux $sock 0 $branch
		LWDAQ_set_repeat_counter $sock [expr $config(num_samples) - 1]
		LWDAQ_set_delay_seconds $sock $config(sample_period)
		LWDAQ_execute_job $sock $LWDAQ_Driver(adc16_job)
	}
	LWDAQ_wait_for_driver $sock

	return 1
}

proc Analyzer_supplies {{basis "0 0 0 0 0 0"}} {
	upvar #0 Analyzer_info info	
	set result [lwdaq_diagnostic $info(data_image)]
	set supplies [lrange $result 6 11]
	for {set i 0} {$i < 6} {incr i} {
		lset supplies $i [format %.3f [expr [lindex $supplies $i] - [lindex $basis $i]]]
	}
	return $supplies
}

proc Analyzer_print {s {color black}} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[LWDAQ_is_error_result $s] || $config(verbose)} {
		LWDAQ_print $info(text) $s $color
	}
}

proc Analyzer_print_supplies {supplies comment} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	if {[LWDAQ_is_error_result $supplies]} {
		LWDAQ_print $info(text) $supplies
	} {
		if {$config(verbose)} {
			foreach s $supplies {
				LWDAQ_print -nonewline $info(text) "[format %7.3f $s] "
			}
			LWDAQ_print $info(text) $comment orange
		}
	}
	return 1
}

proc Analyzer_analyze {ip_addr base_addr driver_socket mux_socket} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info
	global LWDAQ_Driver

	Analyzer_print "Analyzing $ip_addr\:$base_addr\:$driver_socket\:$mux_socket" green	
	Analyzer_print " V1 (V)  I1 (mA)  V2 (V) I2 (mA) V3 (V)  I3 (mA)" orange
	LWDAQ_update
	
	if {[catch {
		set sock [LWDAQ_socket_open $ip_addr]
		LWDAQ_login $sock $config(password)

		# We set the device type to 0 because some drivers
		# do not perform the adc16 job properly when the
		# device type is non-zero.
		LWDAQ_set_device_type $sock 0
		
		if {![string match "00000000" $base_addr]} {
			LWDAQ_set_base_addr_hex $sock $base_addr
		}

		# Set up the driver ram to record the power supply measurements.
		LWDAQ_set_data_addr $sock $config(num_samples)
		
		# In case there is no repeater attached to the driver socket,
		# send all devices on the multiplexer to sleep and select the
		# multiplexer null socket.
		Analyzer_sleep_mux $sock $driver_socket
		
		# If there is a repeater on the driver socket, turn off downstream 
		# power by transmitting device address zero. 
		LWDAQ_set_driver_mux $sock $driver_socket 0
		
		# Record "total_with_repeater_off".
		Analyzer_record_supplies $sock 

		# Turn on the repeater.
		LWDAQ_set_driver_mux $sock $driver_socket $config(mux_null_socket)

		# Let the circuits downstream of the repeater settle into their 
		# quiescent current consumption. Some devices have power-up resets 
		# that last for a hundred milliseconds (A2036). Most have power-up
		# resets that last for a few tens of milliseconds.
		LWDAQ_delay_seconds $sock $config(settling_delay_s)
		
		# Send all downstream devices to sleep
		Analyzer_sleep_mux $sock $driver_socket	

		# Record "total_with_repeaters_on".
		Analyzer_record_supplies $sock 

		# Add termination current on the T+/T- lines and record again. 
		LWDAQ_set_driver_mux $sock $driver_socket $mux_socket
		Analyzer_record_supplies $sock
		
		# For each of our current signature commands we transmit the command
		# to the target and record the power supplies. 
		foreach command $config(commands) {
			# We have to keep selecting the target because the recording
			# operation uses the internal monitors on the driver, and these 
			# reside at driver socket zero. 
			LWDAQ_set_driver_mux $sock $driver_socket $mux_socket
			
			# Transmit the command.
			LWDAQ_transmit_command_hex $sock $command
			
			# Some faulty devices will give different signatures if we wait 
			# a while. In particular, burned-out A2045 and A2052 circuits
			# will start up with full drive current and then stop after
			# a few tens of milliseconds.
			LWDAQ_delay_seconds $sock $config(command_delay_s)
			
			# We select the multiplxer null socket to eliminate the current
			# that will flow down the transmit lines to a device's terminating
			# resistor.
			LWDAQ_set_driver_mux $sock $driver_socket $config(mux_null_socket)			
			
			# Record "increase_with_$command".
			Analyzer_record_supplies $sock
		}
		
		
		# Read out all the recording data.
		set data_size [expr $config(num_samples) \
			* $info(lines_per_measurement) \
			* ([llength $config(commands)] + 3) ]
		set data [LWDAQ_ram_read $sock $config(num_samples) $data_size]

		# Measure the loop time.	
		LWDAQ_set_driver_mux $sock $driver_socket $mux_socket
		LWDAQ_wake $sock
		LWDAQ_execute_job $sock $LWDAQ_Driver(loop_job)
		set lt [expr [LWDAQ_loop_time $sock] * $LWDAQ_Driver(loop_timer_period)]

		# Put the target to sleep.
		LWDAQ_sleep $sock

		# Turn off repeater, if one exists and instructed to do so.
		if {$config(leave_repeater_off)} {
			LWDAQ_set_driver_mux $sock $driver_socket 0
		}
		
		# Close the socket.
		LWDAQ_socket_close $sock
	} error_result]} {
		Analyzer_print "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
		return "ERROR: $error_result"
	}	
	
	# Create an image to hold the power supply data and
	# copy the data into the image's data area.
	lwdaq_image_create -name $info(data_image) \
		-width $config(num_samples) \
		-height [expr ([llength $config(commands)] + 3) \
			* $info(lines_per_measurement) \
				+ 1 ]
	lwdaq_data_manipulate $info(data_image) write 0 $data
	
	# We have multiple measurements in the image. Each has
	# the following size.
	set measurement_size [expr $config(num_samples) * $info(lines_per_measurement)]
	
	# Analyze the repeater-off, repeater-on, and termination measurements.
	set r_off [Analyzer_supplies]
	Analyzer_print_supplies $r_off total_with_repeater_off
	lwdaq_data_manipulate $info(data_image) shift $measurement_size
	
	# Analyze the repeater-on measurements.
	set r_on [Analyzer_supplies]
	Analyzer_print_supplies $r_on total_with_repeater_on
	lwdaq_data_manipulate $info(data_image) shift $measurement_size

	# Analyze the termination measurements.
	set r_tc [Analyzer_supplies]
	lwdaq_data_manipulate $info(data_image) shift $measurement_size

	# Detect a repeater-multiplexer combination on the driver socket.
	set mux_repeater 0
	foreach i {1 3 5} {
		if {[expr [lindex $r_on $i] - [lindex $r_off $i]] > $config(min_mux_current)} {
			set mux_repeater 1
		}
	}
	
	# Check to see if the current consumption of the multiplexer and its
	# devices is excessive.
	set excessive 0
	if {$mux_repeater} {
		foreach i {1 3 5} {
			if {[expr [lindex $r_on $i] - [lindex $r_off $i]] > $config(max_mux_current)} {
				set excessive 1
			}
		}
	}

	# Our basis for further measurements is the final measurement 
	# from our repeater-exercising.
	set basis $r_on
	
	# We compose a list of results. Each entry contains the voltages and
	# currents for one current signature command. The currents are relative
	# to the basis currents, but the voltages are absolute.
	set results [list]
	foreach c $config(commands) {
		set r [Analyzer_supplies $basis]
		Analyzer_print_supplies $r increase_with_$c
		lappend results "$r increase_with_$c"
		lwdaq_data_manipulate $info(data_image) shift $measurement_size
	}
	
	# Go through the list of device signatures and calculate the current
	# error for each, when compared to the measured currents. We also 
	# extract from the device signatures the loopback and termination 
	# properties of each device, so we can use these later in interpreting
	# our termination and loopback observations.
	set matches [list]
	foreach {d s} $info(signatures) {
		set error_length 0
		set nominal_length 0
		set parameters [split $s \n]
		set loopback [lindex $parameters 0 1]
		set termination [lindex $parameters 1 1]
		foreach rm [lrange $parameters 2 end] {
			foreach am $results {
				if {[lindex $am end] == [lindex $rm end]} {
					scan $rm %f%f%f%f%f%f rv1 ri1 rv2 ri2 rv3 ri3
					scan $am %f%f%f%f%f%f av1 ai1 av2 ai2 av3 ai3
					set error_length [expr $error_length + \
						($ri1-$ai1)*($ri1-$ai1) \
						+ ($ri2-$ai2)*($ri2-$ai2) \
						+ ($ri3-$ai3)*($ri3-$ai3) ]
					set nominal_length [expr $nominal_length + \
						$ai1*$ai1 + $ai2*$ai2 + $ai3*$ai3 ]
				}
			}
		}
		set error_length [expr sqrt($error_length)]
		set nominal_length [expr sqrt($nominal_length)]
		if {!(($lt == 0) && ($loopback != "zero"))} {
			lappend matches [list $d $error_length $nominal_length $loopback $termination]
		}
	}
	
	# If the power supply voltages are too low, issue a warning to the user.
	if {([lindex $r_off 0] < $config(min_p15v)) \
		|| ([lindex $r_off 2] < $config(min_p5v)) \
		|| ([lindex $r_off 4] > $config(max_n15v))} {
		Analyzer_print "WARNING: Device power may be switched off."
	}

	# Report on the presence of a multiplexer-repeater combination and
	# warn of excessive current consumption.
	if {$mux_repeater} {
		Analyzer_print "Multplexer-Repeater Detected = Yes."
	} {
		Analyzer_print "Multplexer-Repeater Detected = No."
	}
	if {$excessive} {
		Analyzer_print "WARNING: Excessive current consumption by multiplexer-repeater."
	} 

	set match [lindex [lsort -increasing -real -index 1 $matches] 0]
	set device [lindex $match 0]
	set error_length [format %.1f [lindex $match 1]]
	set nominal_length [lindex $match 2]
	set loopback [lindex $match 3]
	set termination [lindex $match 4]

	Analyzer_print "Device Type = $device."
	set result "$device"
	
	Analyzer_print "Loop Time = $lt ns."
	set problem ""
	if {($lt == $config(max_loop_time)) && ($loopback == "yes")} {
		set problem "WARNING: Expect loop-back."
	}
	if {($lt == $config(max_loop_time)) && ($loopback == "required")} {
		set problem "ERROR: Require loop-back."
	}
	if {($lt < $config(max_loop_time)) && ($loopback == "no")} {
		set problem "WARNING: Unexpected loop-pack."
	}
	if {($lt == 0) && (($loopback == "no") || ($loopback == "yes"))} {
		set problem "WARNING: Unexpected zero loop-back."
	}
	if {($lt == 0) && ($loopback == "required")} {
		set problem "ERROR: Require non-zero loop-back."
	}
	if {($lt != 0) && ($loopback == "zero")} {
		set problem "WARNING: Expect zero loop-back."
	}
	if {$problem != ""} {
		Analyzer_print $problem
		append result " $problem"
	}

	if {$mux_repeater} {
		set tc [format %.1f [expr [lindex $r_tc 3] - [lindex $r_on 3]]]
		Analyzer_print "Termination Current = $tc mA."
		set problem ""
		if {($tc < $config(termination_min)) && ($termination == "yes")} {
			set problem "WARNING: Expect termination current."
		}
		if {($tc > $config(termination_max)) && ($termination == "yes")} {
			set problem "WARNING: Excessive termination current."
		}
		if {($tc > $config(termination_min)) && ($termination == "no")} {
			set problem "WARNING: Unexpected termination current."
		}
		if {$problem != ""} {
			Analyzer_print $problem
			append result " $problem"
		}
	}
	
	Analyzer_print "Current Error = $error_length mA."	
	set problem ""
	if {($error_length > $config(max_error)) && ($lt > 0)} {
		if {$error_length/$nominal_length > $config(max_error_fractional)} {
			set problem "WARNING: Poor current signature match."	
		}
	}
	if {($error_length > $config(max_error_zero_loopback)) && ($lt == 0)} {
		set problem "WARNING: Poor current signature match with zero loopback."	
	}
	if {$problem != ""} {
		Analyzer_print $problem
		append result " $problem"
	}
	
	Analyzer_print "Done.\n" green
	
	set result "$ip_addr $base_addr $driver_socket $mux_socket\
		$mux_repeater $excessive $error_length \"$result\""
	if {!$config(verbose)} {LWDAQ_print $info(text) $result}

	return $result
}

proc Analyzer_execute {{control ""}} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info

	if {$control != ""} {
		set info(control) $control
	}
	
	if {$info(control) == "Stop"} {
		set info(control) "Idle"
		return 0
	}
	
	if {($info(control) == "Analyze") || ($info(control) == "Analyze_All")} {
		set analysis [Analyzer_analyze \
			$config(ip_addr) $config(base_addr) \
			$config(driver_socket) $config(mux_socket)]
		
		if {$info(control) == "Analyze_All"} {
			incr config(mux_socket)
			if {$config(mux_socket) > $config(mux_end_socket)} {
				set config(mux_socket) $config(mux_start_socket)
				incr config(driver_socket)
			}
			if {$config(driver_socket) <= $config(driver_end_socket)} {
				LWDAQ_post Analyzer_execute
				return 1
			} {
				set config(driver_socket) $config(driver_start_socket)
			}
		}
	}
	
	foreach c {Sleep Contact Power_Off Power_On Repeaters_Off} {
		if {$info(control) == $c} {
			Analyzer_[string tolower $c]
		}
	}

	set info(control) "Idle"
	return 1
}

proc Analyzer_open {} {
	upvar #0 Analyzer_config config
	upvar #0 Analyzer_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
	
	frame $w.a
	pack $w.a -side top -fill x
	label $w.a.control -textvariable $info(name)_info(control) -width 12 -fg blue
	pack $w.a.control -side left -expand 1
	foreach p {Contact Power_Off Power_On Sleep Repeaters_Off} {
		set q [string tolower $p]
		button $w.a.$q -text $p -command "Analyzer_command $p"
		pack $w.a.$q -side left -expand 1
	}

	frame $w.b
	pack $w.b -side top -fill x
	foreach p {Analyze Analyze_All Stop} {
		set q [string tolower $p]
		button $w.b.$q -text $p -command "Analyzer_command $p"
		pack $w.b.$q -side left -expand 1
	}
	foreach p {Configure Help} {
		set q [string tolower $p]
		button $w.b.$q -text $p -command "LWDAQ_tool_$q Analyzer"
		pack $w.b.$q -side left -expand 1
	}
	checkbutton $w.b.verbose -variable Analyzer_config(verbose) -text Verbose
	pack $w.b.verbose -side left -expand 1

	frame $w.c
	pack $w.c -side top -fill x
	frame $w.c.c1
	frame $w.c.c2
	pack $w.c.c1 $w.c.c2 -side left -fill y

	set config_list "mux_socket driver_socket base_addr ip_addr"
	set half [expr [llength $config_list] / 2]
	set count 0
	foreach i $config_list {
		incr count
		if {$count <= $half} {set f c1} {set f c2}
		label $w.c.$f.l$i -text $i -anchor w -width 15
		entry $w.c.$f.e$i -textvariable Analyzer_config($i) \
			-relief sunken -bd 1 -width 20
		grid $w.c.$f.l$i $w.c.$f.e$i -sticky news
	}
	
	set info(text) [LWDAQ_text_widget $w 75 17]
	
	return 1
}


Analyzer_init
Analyzer_open

return 1

----------Begin Help----------

The Analyzer has its own chapter in the LWDAQ_Manual, at:

http://alignment.hep.brandeis.edu/Electronics/LWDAQ/Manual.html#Analyzer

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------

----------Begin Data----------


:NONE:
looback no
termination no
0 0 0 0 0 0 increase_with_0000
0 0 0 0 0 0 increase_with_0080
0 0 0 0 0 0 increase_with_0001
0 0 0 0 0 0 increase_with_1080
0 0 0 0 0 0 increase_with_0480
0 0 0 0 0 0 increase_with_8280

:DEAD:
looback yes
termination yes
0 0 0 0 0 0 increase_with_0000
0 0 0 0 0 0 increase_with_0080
0 0 0 0 0 0 increase_with_0001
0 0 0 0 0 0 increase_with_1080
0 0 0 0 0 0 increase_with_0480
0 0 0 0 0 0 increase_with_8280

:A2045L A2045R A2052A:
looback yes
termination yes
0  0 0 0 0  0 increase_with_0000
0  0 0 0 0  0 increase_with_0080
0 80 0 0 0 80 increase_with_0001
0  0 0 0 0  0 increase_with_1080
0  0 0 0 0  0 increase_with_0480
0  0 0 0 0  0 increase_with_8280

:A2045L-B A2045R-B A2052A-B:
looback yes
termination yes
0   0 0 0 0   0 increase_with_0000
0   0 0 0 0   0 increase_with_0080
0 100 0 0 0 100 increase_with_0001
0   0 0 0 0   0 increase_with_1080
0   0 0 0 0   0 increase_with_0480
0   0 0 0 0   0 increase_with_8280

:A2056:
looback required
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 48 0 0.3 0 46 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 48 0 0.3 0 46 increase_with_1080
0 48 0 0.3 0 46 increase_with_0480
0 48 0 0.3 0 46 increase_with_8280

:A2053-NT:
looback zero
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 73 0 0.3 0 68 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 73 0 0.3 0 68 increase_with_1080
0 73 0 0.3 0 68 increase_with_0480
0 88 0 0.3 0 68 increase_with_8280

:A2053-T2:
looback zero
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 73 0 0.3 0 68 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 43 0 0.3 0 38 increase_with_1080
0 73 0 0.3 0 68 increase_with_0480
0 88 0 0.3 0 68 increase_with_8280

:A2053-T11:
looback zero
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 73 0 0.3 0 68 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 73 0 0.3 0 68 increase_with_1080
0 43 0 0.3 0 38 increase_with_0480
0 88 0 0.3 0 68 increase_with_8280

:A2053-T2T11:
looback zero
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 73 0 0.3 0 68 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 43 0 0.3 0 38 increase_with_1080
0 43 0 0.3 0 38 increase_with_0480
0 88 0 0.3 0 68 increase_with_8280

:A2044D:
looback required
termination yes
0   0 0 0.0 0   0 increase_with_0000
0  61 0 0.3 0  54 increase_with_0080
0   0 0 0.0 0   0 increase_with_0001
0  61 0 0.3 0  54 increase_with_1080
0 141 0 0.3 0 134 increase_with_0480
0 141 0 0.3 0 134 increase_with_8280

:A2048L A2048R A2051L-S A2051R-S:
looback required
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 51 0 0.3 0 48 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 85 0 0.3 0 48 increase_with_1080
0 51 0 0.3 0 48 increase_with_0480
0 51 0 0.3 0 48 increase_with_8280

:A2048L-B A2048R-B A2051L-S-B A2051R-S-B:
looback required
termination yes
0   0 0 0.0 0  0 increase_with_0000
0  51 0 0.3 0 48 increase_with_0080
0   0 0 0.0 0  0 increase_with_0001
0 105 0 0.3 0 48 increase_with_1080
0  51 0 0.3 0 48 increase_with_0480
0  51 0 0.3 0 48 increase_with_8280

:A2051L-W:
looback required
termination yes
0   0 0 0.0 0  0 increase_with_0000
0  51 0 0.3 0 48 increase_with_0080
0   0 0 0.0 0  0 increase_with_0001
0  51 0 0.3 0 48 increase_with_1080
0 131 0 0.3 0 48 increase_with_0480
0  51 0 0.3 0 48 increase_with_8280

:A2051L-D A2051R-D:
looback required
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 51 0 0.3 0 48 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 85 0 0.3 0 48 increase_with_1080
0 85 0 0.3 0 48 increase_with_0480
0 85 0 0.3 0 48 increase_with_8280

:A2051L-D-B A2051R-D-B:
looback required
termination yes
0   0 0 0.0 0  0 increase_with_0000
0  51 0 0.3 0 48 increase_with_0080
0   0 0 0.0 0  0 increase_with_0001
0 105 0 0.3 0 48 increase_with_1080
0 105 0 0.3 0 48 increase_with_0480
0 105 0 0.3 0 48 increase_with_8280

:A2051S-D:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0  0 0 0.0 0 0 increase_with_0001
0 30 0 0.3 0 0 increase_with_1080
0 30 0 0.3 0 0 increase_with_0480
0 30 0 0.3 0 0 increase_with_8280

:A2051S-S34:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0  0 0 0.0 0 0 increase_with_0001
0 30 0 0.3 0 0 increase_with_1080
0  0 0 0.3 0 0 increase_with_0480
0  0 0 0.3 0 0 increase_with_8280

:A2051S-S12:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0  0 0 0.0 0 0 increase_with_0001
0  0 0 0.3 0 0 increase_with_1080
0 30 0 0.3 0 0 increase_with_0480
0 30 0 0.3 0 0 increase_with_8280

:A2051S-D-B:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0  0 0 0.0 0 0 increase_with_0001
0 50 0 0.3 0 0 increase_with_1080
0 50 0 0.3 0 0 increase_with_0480
0 50 0 0.3 0 0 increase_with_8280

:A2051S-S34-B:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0  0 0 0.0 0 0 increase_with_0001
0 50 0 0.3 0 0 increase_with_1080
0  0 0 0.3 0 0 increase_with_0480
0  0 0 0.3 0 0 increase_with_8280

:A2051S-S12-B:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0  0 0 0.0 0 0 increase_with_0001
0  0 0 0.3 0 0 increase_with_1080
0 50 0 0.3 0 0 increase_with_0480
0 50 0 0.3 0 0 increase_with_8280

:A2047A A2047T A2033A A2036A:
looback required
termination yes
0  0 0 0.0 0  0 increase_with_0000
0 40 0 0.3 0 40 increase_with_0080
0  0 0 0.0 0  0 increase_with_0001
0 40 0 0.3 0 40  increase_with_1080
0 40 0 0.3 0 40  increase_with_0480
0 40 0 0.3 0 40  increase_with_8280

:A2050D A2050E A2050G:
looback yes
termination yes
0  0 0 0.0 0 0 increase_with_0000
0  0 0 0.3 0 0 increase_with_0080
0 30 0 0.0 0 0 increase_with_0001
0  0 0 0.3 0 0 increase_with_1080
0  0 0 0.3 0 0 increase_with_0480
0  0 0 0.3 0 0 increase_with_8280

:A2072A:
looback yes
termination yes
0   0 0 0.0 0   0 increase_with_0000
0  42 0 0.6 0  38 increase_with_0080
0   0 0 0.0 0   0 increase_with_0001
0  42 0 0.6 0  38 increase_with_1080
0 110 0 0.6 0 110 increase_with_0480
0 110 0 0.6 0 110 increase_with_8280

:A3022A:
looback yes
termination yes
0   0 0 0.0 0   0 increase_with_0000
0  43 0 0.6 0  38 increase_with_0080
0   0 0 0.0 0   0 increase_with_0001
0  43 0 0.6 0  38 increase_with_1080
0  43 0 0.6 0  38 increase_with_0480
0  70 0 0.6 0  65 increase_with_8280

:A2078A:
looback yes
termination yes
0   0 0 0.0 0   0 increase_with_0000
0   0 0 0.0 0   0 increase_with_0080
0   0 0 0.0 0   0 increase_with_0001
0 130 0 0.0 0   0 increase_with_1080
0 130 0 0.0 0   0 increase_with_0480
0 135 0 0.0 0   0 increase_with_8280





----------End Data----------
