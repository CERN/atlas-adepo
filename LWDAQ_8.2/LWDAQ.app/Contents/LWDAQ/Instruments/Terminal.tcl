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
# Terminal.tcl defines the Terminal instrument.
#

#
# LWDAQ_init_Terminal creates all elements of the Terminal instrument's
# config and info arrays.
#
proc LWDAQ_init_Terminal {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Terminal info
	upvar #0 LWDAQ_config_Terminal config
	array unset config

	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Terminal"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(delete_old_images) 1
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 400
	set info(daq_image_height) 300
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) 0
	set info(daq_image_bottom) -1
	set info(daq_device_type) 3
	set info(daq_extended) 0
	set info(tx_string) ""
	set info(rx_terminators) "4 17 19"
	set info(receive_hex) "00D0"
	set info(transmit_decimal) "160"
	set info(loop_delay_ms) 30
	set info(daq_password) "no_password"
	set info(verbose_description) "{Received String}"
	set info(timeout) 0
	set info(tx_file_name) "./LWDAQ.tcl"

	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 10.0.0.37
	set config(daq_driver_socket) 1
	set config(daq_mux_socket) 1
	set config(analysis_enable) 0
	set config(intensify) none
	set config(verbose_result) 0
	set config(tx_ascii) "H16"
	set config(tx_header) "19"
	set config(tx_footer) "13 10"
	set config(tx_file_name) ""
	set config(rx_last) "0"
	set config(rx_timeout_ms) 1000
	set config(rx_size) 1000
	return 1
}

#
# LWDAQ_analysis_Terminal scans an image received from a Terminal
# data acquisition, and turns it into a string of numbers.
#
proc LWDAQ_analysis_Terminal {{image_name ""}} {
	upvar #0 LWDAQ_config_Terminal config
	upvar #0 LWDAQ_info_Terminal info
	if {$image_name == ""} {set image_name $config(memory_name)}
	
	set irs [lwdaq_image_results $image_name]
	scan $irs %u%u size terminator
	if {![info exists size] || ![info exists terminator]} {
		return "ERROR: Invalid image result string, \"$irs\"."
	}
	
	set bytes [lwdaq_data_manipulate $image_name read 0 $size]
	if {$terminator != 0} {
		set i [string first [binary format c $terminator] $bytes]
		if {$i >= 0} {set bytes [string range $bytes 0 $i]}
	}

	set result ""

	set a $config(analysis_enable)
	if {$a == 1} {set result $bytes}
	if {$a == 2} {binary scan $bytes "c*" result} 
	return $result
}

#
# LWDAQ_daq_Terminal reads a string of characters or a block of data
# froma  data device.
#
proc LWDAQ_daq_Terminal {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Terminal info
	upvar #0 LWDAQ_config_Terminal config

	# Check that the image will be large enough to hold the received
	# data. Sometimes it's nice to make the image dimensions small and
	# use zoom to look closely at the bytes displayed by intensity. In
	# such cases, we can overflow the image if we are not careful.
	set data_size [expr $info(daq_image_width) * ($info(daq_image_height) - 1)]
	if {$config(rx_size) >= $data_size} {
		set info(daq_image_width) [expr round(sqrt($config(rx_size))) + 1]
		set info(daq_image_height) [expr $info(daq_image_width) + 2]
	}

	# Create decimal-only versions of rx_last, tx_header, and tx_footer.
	foreach a {rx_last tx_header tx_footer} {
		set $a ""
		foreach b $config($a) {
			if {[string is integer -strict $b]} {
				lappend $a $b
			} {
				if {[string index $b 0] == "x"} {
					set b [string range $b 1 end]
					if {[string is xdigit -strict $b]} {
						lappend $a [scan $b %x]
					} {
						LWDAQ_print $info(text) "WARNING: Invalid hex number \"$b\"."
					}
				} {
					LWDAQ_print $info(text) "WARNING: Invalid code \"$b\"."
				}
			}
		}
	}

	# Compose the transmit string.
	set info(tx_string) ""
	foreach a $tx_header {append info(tx_string) [binary format c $a]}
	append info(tx_string) $config(tx_ascii)
	if {$config(tx_file_name) != ""} {
		if {[file exists $config(tx_file_name)]} {
			set f [open $config(tx_file_name) r]
			append info(tx_string) [read $f]
			close $f
		} {
			LWDAQ_print $info(text) "WARNING: file $config(tx_file_name) does not exist."	
		}
	}
	foreach a $tx_footer {append info(tx_string) [binary format c $a]}

	# The data acquisition commands are contained within an error trap.
	if {[catch {
		# Open a socket to the driver and select the target device.
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) \
			$config(daq_mux_socket)

		# We set up the driver to receive characters as much as we can, so as
		# to reduce the number of things it must do between transmitting its
		# final character and starting to listen for the first answering character.
		if {$config(rx_size) > 0} {
			# Fill the RAM with rx_last in anticipation of a timeout, 
			# and then clear the most recent byte register by writing 
			# a zero to RAM.
			LWDAQ_ram_delete $sock 0 $config(rx_size) $config(rx_last)
			LWDAQ_byte_write $sock $LWDAQ_Driver(ram_portal_addr) 0

			# Set up recording of bytes in driver memory.
			LWDAQ_set_device_type $sock $info(daq_device_type)
			LWDAQ_set_data_addr $sock 0
		}

		# Transmit the string.
		set txl [string length $info(tx_string)]
		for {set i 0} {$i < $txl} {incr i} {
			# We translate the i'th character in the transmit string into
			# an ascii code, and then create a sixteen-bit command word in
			# which the upper byte is the character and the lower byte is
			# the transmission command for a terminal instrument.
			set char [string index $info(tx_string) $i]		
			binary scan $char c ascii
			set cmd [expr (256 * $ascii) + $info(transmit_decimal)]
			
			# We write the command to the outgoing socket butter, but we
			# do not transmit it just yet. We will flush the socket later.
			LWDAQ_transmit_command $sock $cmd

			# We flush the socket if the next character is the last
			# character we transmit. This way, the driver receives all 
			# transmit character commands up to but not including the last
			# character. The device receiving the characters should wait to
			# respond until it receives the last character. The command to
			# transmit the last character will be sent to the driver in a block
			# along with the commands to receive characters. Thus the transmit
			# and receive instructions will follow closely upon one another
			# and the driver will not miss the first character received by the
			# Terminal device.
			if {$i == [expr $txl - 2]} {
				LWDAQ_socket_flush $sock
			}
			
			# We must avoid over-flowing the driver's input buffer.
			if {([expr $i % 100] == 0) && ($i < [expr $txl - 2])} {
				LWDAQ_wait_for_driver $sock
			}
		}

		# If we have receiving to do, we do it now.
		if {$config(rx_size) > 0} {
			# Instruct the device to transfer bytes as they become available.
			LWDAQ_transmit_command_hex $sock $info(receive_hex)

			# Set up repeated execution of the read job.
			LWDAQ_set_repeat_counter $sock [expr $config(rx_size) - 1]

			# Start recording.
			LWDAQ_start_job $sock $LWDAQ_Driver(read_job)

			# Send all pending commands to the driver.
			LWDAQ_socket_flush $sock
			
			# Set up a timeout.
			set info(timeout) 0
			if {$config(rx_timeout_ms) > 0} {
				set cmd_id [after $config(rx_timeout_ms) {set LWDAQ_info_Terminal(timeout) 1}]
			}

			# Wait for timeout or termination character or enough characters received.
			while {1} {
				if {$config(rx_last) != 0} {
					set mrb [LWDAQ_most_recent_byte $sock]
					if {($mrb == $config(rx_last)) \
						|| ([lsearch $mrb $info(rx_terminators)] >= 0)} {
						LWDAQ_controller_reset $sock
						break
					}
				}
				if {$info(timeout) == 1} {
					if {$config(rx_last) != 0} {
						LWDAQ_print $info(text) \
							"WARNING: timeout waiting for receive terminator."
					}
					LWDAQ_controller_reset $sock
					break
				}
				if {[LWDAQ_job_done $sock]} {
					if {$config(rx_last) != "0"} {
						LWDAQ_print $info(text) "WARNING:\
							read $config(rx_size) bytes, but no receive terminator."
					}
					break
				}
				if {$info(control) == "Stop"} {
					LWDAQ_print $info(text) "WARNING: acquisition interrupted."
					LWDAQ_controller_reset $sock
					break
				}
				LWDAQ_wait_ms $info(loop_delay_ms)
			} 
			
			# Cancel the timeout.
			catch {after cancel $cmd_id}
		}
		
		set data [LWDAQ_ram_read $sock 0 $config(rx_size)]
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
		-results "$config(rx_size) $config(rx_last)" \
		-name "$info(name)\_$info(counter)"]
	lwdaq_data_manipulate $config(memory_name) write 0 $data
	
	return $config(memory_name) 
} 

