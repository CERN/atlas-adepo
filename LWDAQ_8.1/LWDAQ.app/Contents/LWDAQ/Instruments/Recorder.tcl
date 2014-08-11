# Long-Wire Data Acquisition Software (LWDAQ)
# Copyright (C) 2006-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
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
# Recorder.tcl defines the Recorder instrument.
#

#
# LWDAQ_init_Recorder creates all elements of the Recorder instrument's
# config and info arrays.
#
proc LWDAQ_init_Recorder {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Recorder info
	upvar #0 LWDAQ_config_Recorder config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Recorder"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(daq_extended) 0
	set info(delete_old_images) 1
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 400
	set info(daq_image_height) 300
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) 0
	set info(daq_image_bottom) -1
	set info(daq_device_type) 3
	set info(loop_delay_ms) 100
	set info(daq_password) "no_password"
	set info(verbose_description) "{Channel Number} \
		{Number of Samples Recorded} \
		{Average Value} \
		{Standard Deviation} "
	set info(timeout) 0
	set info(transmit_file_name) "./LWDAQ.tcl"
	set info(max_sample) 65535
	set info(min_sample) 0
	set info(display_range) [expr $info(max_sample) - $info(min_sample) + 1]
	set info(display_offset) $info(min_sample)
	set info(display_coupling) DC
	set info(message_length) 4
	set info(upload_command) 00D0
	set info(reset_command) 0081
	set info(min_messages_per_clock) 1
	set info(max_messages_per_clock) 100
	set info(messages_per_clock) 1
	set info(extra_clocks) 20
	set info(max_attempts) 10
	set info(channel_activity) ""
	set info(activity_threshold) "20"
	set info(errors_for_reset) 10
	set info(error_test) 0
	set info(show_errors) 0
	set info(clock_frequency) 128
	
	set info(buffer_image) "_recorder_buffer_image_"
	catch {lwdaq_image_destroy $info(buffer_image)}
	set info(scratch_image) "_recorder_scratch_image_"
	catch {lwdaq_image_destroy $info(scratch_image)}
		
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 10.0.0.37
	set config(daq_driver_socket) 1
	set config(daq_mux_socket) 2
	set config(analysis_enable) 1
	set config(analysis_channels) *
	set config(intensify) none
	set config(verbose_result) 0
	set config(daq_num_clocks) 128

	return 1
}

#
# LWDAQ_analysis_Recorder applies Recorder analysis to an image 
# in the lwdaq image list. By default, the routine uses the
# image $config(memory_name).
#
proc LWDAQ_analysis_Recorder {{image_name ""}} {
	upvar #0 LWDAQ_config_Recorder config
	upvar #0 LWDAQ_info_Recorder info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[catch {
		scan [lwdaq_recorder $image_name "clocks"] %d%d%d \
			num_errors num_clocks num_messages
		if {$num_errors > 0} {
			LWDAQ_print $info(text) "WARNING: Analysis found $num_errors errors\
				in message block."
		}
		if {[string match -nocase "AC" $info(display_coupling)]} {
			set coupling "AC"
			set display_min [expr $info(display_offset) - $info(display_range) / 2 ]
			set display_max [expr $info(display_offset) + $info(display_range) / 2]
		} {
			set coupling "DC"
			set display_min $info(display_offset)
			set display_max [expr $info(display_offset) + $info(display_range)]
		}
		set result [lwdaq_recorder $image_name \
			"plot $display_min $display_max $coupling $config(analysis_channels)"]
		set channels [lwdaq_recorder $image_name "list"]
		if {![LWDAQ_is_error_result $channels]} {
			set ca ""
			foreach {c a} $channels {
				if {$a > $info(activity_threshold)} {
					append ca "$c\:$a "
				}
			}
			set info(channel_activity) $ca
		} {
			set info(channel_activity) $channels
		}
	} error_result]} {return "ERROR: $error_result"}

	return $result
}

#
# LWDAQ_refresh_Recorder refreshes the display of the data, given new
# display settings.
#
proc LWDAQ_refresh_Recorder {} {
	upvar #0 LWDAQ_config_Recorder config
	upvar #0 LWDAQ_info_Recorder info
	if {[lwdaq_image_exists $config(memory_name)] != ""} {
		LWDAQ_analysis_Recorder $config(memory_name)
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
}

#
# LWDAQ_reset_Recorder resets the data recorder hardware and the recorder
# instrument.
#
proc LWDAQ_reset_Recorder {} {
	upvar #0 LWDAQ_config_Recorder config
	upvar #0 LWDAQ_info_Recorder info
	global LWDAQ_Driver LWDAQ_Info
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Resetting data recorder... "
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_transmit_command_hex $sock $info(reset_command)
		LWDAQ_wake $sock
		LWDAQ_wait_for_driver $sock
		LWDAQ_socket_close $sock
		lwdaq_image_destroy $info(buffer_image)
		lwdaq_image_destroy $config(memory_name)
		LWDAQ_print $info(text) "done."
	} error_result]} { 
		if {[info exists sock]} {LWDAQ_socket_close $sock}
		incr LWDAQ_Info(num_daq_errors)
		LWDAQ_print $info(text) "\nERROR: $error_result" red
		return "ERROR: $error_result"
	}
	return 1
}

#
# LWDAQ_controls_Recorder creates secial controls 
# for the Recorder instrument.
#
proc LWDAQ_controls_Recorder {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_Recorder config
	upvar #0 LWDAQ_info_Recorder info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set g $w.scale
	frame $g
	pack $g -side top -fill x

	foreach {label_name element_name} {
			"Offset (Counts)" {display_offset}
			"Range (Counts)" {display_range}
			"Coupling (AC/DC)" {display_coupling} } {
		label $g.l$element_name -text $label_name \
			-width [string length $label_name]
		entry $g.e$element_name -textvariable LWDAQ_info_Recorder($element_name) \
			-relief sunken -bd 1 -width 6
		pack $g.l$element_name $g.e$element_name -side left -expand 1
		bind $g.e$element_name <Return> LWDAQ_refresh_Recorder
	}
	
	button $g.reset -text "Reset" -command "LWDAQ_post LWDAQ_reset_Recorder"
	pack $g.reset -side left -expand 1

	set g $w.channels
	frame $g
	pack $g -side top -fill x

	label $g.l -text "Channel Activity (id:qty) "
	pack $g.l -side left
	label $g.c -textvariable LWDAQ_info_Recorder(channel_activity) \
		-relief sunken -anchor w -width 70
	pack $g.c -side left -expand yes
}

#
# LWDAQ_error_test_Recorder simulates data acquisition errors by reading bytes
# out of the data recorder without saving them.
#
proc LWDAQ_error_test_Recorder {sock} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Recorder info
	
	if {[expr rand()] < 0.2} {
		set i [expr 1 + round(20*rand())]
		LWDAQ_print $info(text) "Reading $i bytes out of the recorder." brown
		LWDAQ_set_repeat_counter $sock [expr $i - 1]			
		LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)
	}
}

#
# LWDAQ_error_fix_Recorder looks for timestamp errors in the data of  an image
# called image_name. It extracts messages before the  first timestamp error and
# shifts the remaining data one place  to the left, so that we discard the first
# byte in what remains.  The routine repeatst this procedure until there are no
# more  timestamp errors, which could be because there are no more messages  in
# the image or because misalignment has been corrected. As it  goes along, the
# routine keeps track of how many times it has shifted  the data to the left by
# one byte and returns this number so the calling  routine can apply the same
# shift to the recorder's data buffer, and so  realign the buffer with the
# message boundaries. 
#
proc LWDAQ_error_fix_Recorder {image_name} {
	upvar #0 LWDAQ_info_Recorder info

	set data ""
	set fixed 0
	set misalignment 0
	while {!$fixed} {
		scan [lwdaq_recorder $image_name "clocks 0"] %d%d%d%d \
			num_errors num_clocks num_messages first_clock_index
		set report [lwdaq_recorder $image_name "print 0 1"]
		if {$info(show_errors) && [regexp {index=([0-9]*) } $report match index]} {
			LWDAQ_print $info(text) [lwdaq_recorder $image_name \
				"print [expr $index - 10] [expr $index + 10]"]
		}
		if {[regexp {Timestamp.*?index=([0-9]*) } $report match index]} {
			if {$index > $first_clock_index} {
				append data [lwdaq_data_manipulate $image_name \
					read 0 [expr $index * $info(message_length)]]
			}
			lwdaq_data_manipulate $image_name shift [expr $index * $info(message_length) + 1]
			incr misalignment
		} {
			append data [lwdaq_data_manipulate $image_name \
				read 0 [expr $num_messages * $info(message_length)]]
			set fixed 1
		}
	}
	lwdaq_data_manipulate $info(scratch_image) write 0 $data

	return [expr $misalignment % $info(message_length)]
}

#
# LWDAQ_daq_Recorder reads data from a data device.
#
proc LWDAQ_daq_Recorder {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Recorder info
	upvar #0 LWDAQ_config_Recorder config

	# If they don't exist, create the buffer and scratch images.
	if {[lwdaq_image_exists $info(buffer_image)] == ""} {
		lwdaq_image_create \
			-width $info(daq_image_width) \
			-height $info(daq_image_height) \
			-name $info(buffer_image)
	}
	if {[lwdaq_image_exists $info(scratch_image)] == ""} {
		lwdaq_image_create \
			-width $info(daq_image_width) \
			-height $info(daq_image_height) \
			-name $info(scratch_image)
	}
		
	# Save the value of daq_num_clocks in case the user changes it 
	# during acquisition.
	set daq_num_clocks $config(daq_num_clocks)
	
	scan [lwdaq_recorder $info(buffer_image) "clocks 0 $daq_num_clocks"] %d%d%d%d%d \
		num_errors num_clocks num_messages start_index end_index

	if {[catch {
		# Open socket to driver and log in.
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)

		# Set up the Data Recorder for byte transfer.
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_transmit_command_hex $sock $info(upload_command)
			
		# Set the block counter, which counts how many times we download a 
		# block of messages from the recorder.
		set block_counter 0
		
		# We download data until we have more than daq_num_clocks clock messages,
		# as specified by the user.
		while {$num_clocks <= $daq_num_clocks} {

			# Call the error test routine if we want to test the code for its
			# resistance to errors. This routine will meddle with the data
			# block and shift the buffer in the recorder also.
			if {$info(error_test)} {LWDAQ_error_test_Recorder $sock}

			# Check that messages_per_clock lies within our limits.
			if {$info(messages_per_clock) < $info(min_messages_per_clock)} {
				set info(messages_per_clock) $info(min_messages_per_clock)
			}
			if {$info(messages_per_clock) > $info(max_messages_per_clock)} {
				set info(messages_per_clock) $info(max_messages_per_clock)
			}
			
			# Set the block length in bytes that we want to download from
			# the recorder.
			set block_length [expr \
				(1 + $daq_num_clocks - $num_clocks + $info(extra_clocks) ) \
				* $info(message_length) \
				* $info(messages_per_clock)]
			
			# Calculate a maximum block length. We want to make sure that 
			# we don't ask for more data than the receiver will provide
			# within the TCP timeout should the antenna be disconnected.
			set max_block_length [expr round(0.8 * $info(clock_frequency) \
				* $LWDAQ_Info(tcp_timeout_ms) / 1000) \
				* $info(message_length)]
				
			# If the block length is larger than our maximum, make it equal
			# to the maximum. This maximum must be a multiple of the message
			# length, which our calculation above guarantees.
			if {$block_length > $max_block_length} {
				set block_length $max_block_length
			}
			
			# Read the bytes out of the data recorder into the driver memory.
			LWDAQ_set_data_addr $sock 0
			LWDAQ_set_repeat_counter $sock [expr $block_length - 1]			
			LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)
			
			# Download data from the driver into a local byte array.
			set data [LWDAQ_ram_read $sock 0 $block_length]
			
			# We put the data in the scratch image and check it for
			# errors.
			lwdaq_data_manipulate $info(scratch_image) clear
			lwdaq_data_manipulate $info(scratch_image) write 0 $data
			scan [lwdaq_recorder $info(scratch_image) "clocks"] %d%d%d \
				num_errors num_new_clocks num_new_messages
				
			# If we have no errors in this new data block, and there is
			# at least one clock message in the block, we adjust the 
			# number of messages we will download per clock.
			if {($num_errors == 0) && ($num_new_clocks > 0)} {
				set info(messages_per_clock) \
					[expr round($num_new_messages/$num_new_clocks) + 1]
			}
			
			# If we see errors in the new messages, apply a fixit procedure
			# to remove as many errors as we can. The fixit procedure leaves
			# the corrected messages in place in the scratch image. It returns
			# a number of bytes we should read from the data recorder in order
			# to correct misalignment of the four-byte messages boundaries.
			if {$num_errors > 0} {
				LWDAQ_print $info(text) "WARNING: Received corrupted data."

				# Call the error-fixing procedure and obtain the misalignment.
				set misalignment [LWDAQ_error_fix_Recorder $info(scratch_image)]
				
				# Read however many bytes we need to from the data
				# recorder to bring the first byte of a message to the front
				# of the recoder's message buffer.
				if {$misalignment > 0} {
					LWDAQ_set_repeat_counter $sock [expr $misalignment - 1]			
					LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)
				}
				
				# Extract from the scratch image the corrected message block.
				scan [lwdaq_recorder $info(scratch_image) "clocks"] %d%d%d \
					num_errors num_new_clocks num_new_messages
				set data [lwdaq_data_manipulate $info(scratch_image) read \
					0 [expr $num_new_messages * $info(message_length)]]
			}
			
			# Append the new messages to buffer image.
			lwdaq_data_manipulate $info(buffer_image) write \
				[expr $num_messages * $info(message_length)] $data

			# Check the new buffer contents.
			scan [lwdaq_recorder $info(buffer_image) "clocks 0 $daq_num_clocks"] %d%d%d%d%d \
				num_errors num_clocks num_messages start_index end_index
			
			# If we have too many errors in the message buffer, we pass back the entire 
			# buffer and reset the data recorder.
			if {$num_errors > $info(errors_for_reset)} {
				LWDAQ_print $info(text) \
					"ERROR: Severely corrupted data, resetting data recorder."
				LWDAQ_transmit_command_hex $sock $info(reset_command)
				set start_index 0
				set end_index [expr $num_messages - 1]
				break
			}

			# Check the block counter to see if we have made too many attempts
			# to get our data. The block counter serves as a way of breaking out
			# of data acquisition when we have an unknown problem in our hardware
			# or software.
			incr block_counter
			if {$block_counter > $info(max_attempts)} {
				LWDAQ_print $info(text) "ERROR: Abandoned acquisition after\
					$info(max_attempts) attempts."
				set start_index 0
				set end_index [expr $num_messages -1]
				break
			}
		}

		# Disable data upload from Data Recorder and close socket.
		LWDAQ_wake $sock
		LWDAQ_socket_close $sock
	} error_result]} { 
		# We arrive at this error code only when we have encountered a problem
		# with TCPIP communication. In such cases, we close the socket and issue
		# an error message, but we do not throw away the existing data buffer.
		if {[info exists sock]} {LWDAQ_socket_close $sock}
		return "ERROR: $error_result"
	}
	
	# Create the new data image, storing extra data in the
	# Recorder's buffer image.
	set config(memory_name) [lwdaq_image_create \
		-width $info(daq_image_width) \
		-height $info(daq_image_height) \
		-left $info(daq_image_left) \
		-right $info(daq_image_right) \
		-top $info(daq_image_top) \
		-bottom $info(daq_image_bottom) \
		-name "$info(name)\_$info(counter)"]
	if {$start_index <= $end_index} {
		set start_addr [expr $info(message_length) * $start_index]
		set end_addr [expr $info(message_length) * $end_index]
		set data [lwdaq_data_manipulate $info(buffer_image) read \
			 $start_addr [expr $end_addr - $start_addr] ]
		lwdaq_data_manipulate $info(buffer_image) shift $end_addr
	} {
		set data ""
	}
	lwdaq_data_manipulate $config(memory_name) write 0 $data

	return $config(memory_name) 
} 

