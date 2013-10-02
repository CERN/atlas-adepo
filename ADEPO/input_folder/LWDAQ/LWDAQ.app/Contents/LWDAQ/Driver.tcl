# Long-Wire Data Acquisition Software (LWDAQ)
# Copyright (C) 2003-2009 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
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
# Driver.tcl defines procedures that communicate with data acquisition
# drivers and system controllers through TCPIP sockets. The Driver.tcl
# routines call the sockeet-handling routines defined in Utils.tcl.
#
# The original purpose of the Driver.tcl routines, when we wrote them in
# 2004, was to provide communication with the Long-Wire Data Acquisition 
# Driver with Ethernet Interface (A2037E). In 2005 we enhanced the 
# routines to support communication with the TCPIP-VME Interface (A2037A 
# and A2037F). All these circuits used the LWDAQ Message Protocol for the 
# exchange of TCPIP messages. In the code below, as well as in Utils.tcl, 
# we refer to this protocol as "lwdaq". The lwdaq protocol uses a prefix
# byte at the start of any message, followed by a four-byte, big-endian message
# identifier, a four-byte big-endian content length, the message content 
# (if any), and finally a suffix byte. When a client closes a lwdaq we
# send a termination character to accelerate the socket closure in the 
# lwdaq server. We describe the lwdaq message protocol, including the 
# reserved message identifiers, in our LWDAQ Specification. Each socket 
# opened by LWDAQ_socket_open has an entry in the open_sockets list of the 
# LWDAQ_Info array.
#
# There are three components to the TCPIP communication with data
# acquisition hardware. The Master is the computer that runs this software
# and connects as a client to the server. The Relay is the embedded computer
# that acts as the server. The Controller is the hardware and address
# space we read from and write to with routines like LWDAQ_byte_write
# and LWDAQ_byte_read.
#

#
# LWDAQ_driver_init initializes the global variable LWDAQ_Driver that
# describes the LWDAQ Relay and LWDAQ Controller sections of the 
# LWDAQ Driver. 
#
proc LWDAQ_driver_init {} {
	global LWDAQ_Driver
#
# VME Access.
#
	set LWDAQ_Driver(default_base_addr) "00000000"
#
# Device Types.
#
	set LWDAQ_Driver(LED_device) 1
	set LWDAQ_Driver(TC255_device) 2
	set LWDAQ_Driver(data_device) 3
	set LWDAQ_Driver(KAF0400_device) 4
	set LWDAQ_Driver(TC237_device) 5
	set LWDAQ_Driver(ICX424_device) 6
	set LWDAQ_Driver(ICX424Q_device) 7
#
# Device Details. For image image sensors, we have the image height
# and width, and the left, top, right, and bottom edges of the largest
# acceptable analysis boundary for light-sensitive pixels.
#
	set LWDAQ_Driver(image_sensors) "TC255 TC237 KAF0400 ICX424 ICX424Q"
	set LWDAQ_Driver(TC255_details) "244 344 20 2 343 243 10.0"
	set LWDAQ_Driver(KAF0400_details) "520 800 20 8 784 516 9.0"
	set LWDAQ_Driver(TC237_details) "500 690 35 5 685 495 7.4"
	set LWDAQ_Driver(ICX424_details) "520 700 24 14 682 506 7.4"
	set LWDAQ_Driver(ICX424Q_details) "260 350 12 7 341 253 14.8"
#
# Message Identifiers.
#
	set LWDAQ_Driver(version_read_id) 0
	set LWDAQ_Driver(byte_read_id) 1
	set LWDAQ_Driver(byte_write_id) 2
	set LWDAQ_Driver(stream_read_id) 3
	set LWDAQ_Driver(data_return_id) 4
	set LWDAQ_Driver(byte_poll_id) 5
	set LWDAQ_Driver(login_id) 6
	set LWDAQ_Driver(config_read_id) 7
	set LWDAQ_Driver(config_write_id) 8
	set LWDAQ_Driver(mac_read_id) 9
	set LWDAQ_Driver(stream_delete_id) 10
	set LWDAQ_Driver(echo_id) 11
	set LWDAQ_Driver(stream_write_id) 12
	set LWDAQ_Driver(reboot_id) 13
#
# LWDAQ Message Protocol
#
	set LWDAQ_Driver(lwdaq_prefix) a5
	set LWDAQ_Driver(lwdaq_suffix) 5a
	set LWDAQ_Driver(lwdaq_header_length) 9
	set LWDAQ_Driver(lwdaq_suffix_length) 1
#
# Relay Configuration Files.
#
	set LWDAQ_Driver(lwdaq_heading) "lwdaq_relay_configuration:"
#
# Controller Jobs
#
	set LWDAQ_Driver(null_job) 0 
	set LWDAQ_Driver(wake_job) 1 ;# also called expose_job
	set LWDAQ_Driver(move_job) 2 ;# also called clear_job
	set LWDAQ_Driver(read_job) 3
	set LWDAQ_Driver(fast_toggle_job) 4 ;# replaces alt_read_job
	set LWDAQ_Driver(alt_move_job) 5 ;# also called transfer_job
	set LWDAQ_Driver(flash_job) 6
	set LWDAQ_Driver(sleep_job) 7
	set LWDAQ_Driver(toggle_job) 8 ;# also called ab_expose_job
	set LWDAQ_Driver(loop_job) 9
	set LWDAQ_Driver(command_job) 10
	set LWDAQ_Driver(adc16_job) 11
	set LWDAQ_Driver(adc8_job) 12
	set LWDAQ_Driver(delay_job) 13
	set LWDAQ_Driver(fast_adc_job) 15
#
# Controller Address Map
#
	set LWDAQ_Driver(id_addr) 0 ;# identifying byte at 512K boundry (byte)
	set LWDAQ_Driver(sr_addr) 1 ;# status register location (byte)
	set LWDAQ_Driver(mrb_addr) 2 ;# most recent byte written to ram (byte)
	set LWDAQ_Driver(djr_addr) 3 ;# device job register location (byte)
	set LWDAQ_Driver(dar_addr) 5 ;# device address register location (byte)
	set LWDAQ_Driver(do_addr) 7 ;# digital outputs location (byte)
	set LWDAQ_Driver(di_addr) 9 ;# digital inputs location (byte)
	set LWDAQ_Driver(daclr_addr) 11 ;# data address clear location (byte)
	set LWDAQ_Driver(dtr_addr) 13 ;# device type register location (byte)
	set LWDAQ_Driver(der_addr) 15 ;# device element register location (byte)
	set LWDAQ_Driver(lt_addr) 17 ;# loop timer location (byte)
	set LWDAQ_Driver(hv_addr) 18 ;# hardware version number location (byte)
	set LWDAQ_Driver(fv_addr) 19 ;# firmware version number location (byte)
	set LWDAQ_Driver(dt_addr) 20 ;# delay timer location (four-byte)
	set LWDAQ_Driver(da_addr) 24 ;# data address location (four-byte)
	set LWDAQ_Driver(edp_addr) 29 ;# enable device power location (byte)
	set LWDAQ_Driver(clen_addr) 31 ;# clamp enable location (byte)
	set LWDAQ_Driver(cr_addr) 32 ;# command register location (two-byte)
	set LWDAQ_Driver(rc_addr) 34 ;# repeat counter location (four-byte)
	set LWDAQ_Driver(ctcr_addr) 39 ;# c-t config reg location (byte)
	set LWDAQ_Driver(srst_addr) 41 ;# software reset location (byte)
	set LWDAQ_Driver(ba_addr) 42 ;# base address location (four-byte)
	set LWDAQ_Driver(ram_portal_addr) 63 ;# rcm interface RAM Portal location (byte)
#
# Timing Parameters
#
	set LWDAQ_Driver(delay_timer_frequency) 8000000 ;# Hz
	set LWDAQ_Driver(loop_timer_period) 25 ;# ns
	set LWDAQ_Driver(loop_time_per_meter) 10 ;# ns/m
	set LWDAQ_Driver(min_adc16_sample_period) 0.000010 ;# s
	set LWDAQ_Driver(adc16_startup_ticks) 3;# ticks before starts timer
	set LWDAQ_Driver(adc16_settling_delay) 0.001 ;# s
	set LWDAQ_Driver(max_delay_seconds) 1.0
#
# Memory Parameters
#
	set LWDAQ_Driver(server_buffer_size) 1400 ;# maximum content for message to server.
#
# Version Parameters
#
	set LWDAQ_Driver(min_sv_for_reboot) 13

	return 1
}


#
# LWDAQ_transmit_message sends a message through a socket. 
# The routine detects which protocol the socket uses and
# formats the message accordingly. The message identifier is
# passed to the procedure in $id and the contents are in
# $contents. The routine supports the lwdaq and basic message 
# formats. The id parameter is a string of chracters that 
# represent a decimal number. The contents parameter is a 
# block of binary bytes.
#
proc LWDAQ_transmit_message {sock id contents} {
	global LWDAQ_Driver LWDAQ_Info
	
	set protocol [LWDAQ_socket_protocol $sock]
	
	if {$protocol == "lwdaq"} {
		set message [binary format H2II \
			$LWDAQ_Driver(lwdaq_prefix) \
			$id \
			[string length $contents] ]
		append message $contents
		append message [binary format H2 $LWDAQ_Driver(lwdaq_suffix)]
		LWDAQ_socket_write $sock $message
	} 
	
	if {$protocol == "basic"} {
		LWDAQ_socket_write $sock "$id "
		LWDAQ_socket_write $sock $contents
	}
	
	return 1
}


#
# LWDAQ_receive_data receives a LWDAQ Message Protocol 
# data return message from a socket and returns the 
# message contents. The routine returns the data as
# a block of binary bytes. It supports the lwdaq
# protocol only.
#
proc LWDAQ_receive_data {sock} {
	global LWDAQ_Driver LWDAQ_Info
	
	set protocol [LWDAQ_socket_protocol $sock]
	
	if {$protocol == "lwdaq"} {
		binary scan [LWDAQ_socket_read $sock $LWDAQ_Driver(lwdaq_header_length)] \
			H2II prefix id content_length
		if {![info exists prefix]} {
			error "Incomplete message received from socket."
		}
		if {$prefix != $LWDAQ_Driver(lwdaq_prefix)} {
			error "Invalid prefix in returned message."
		}
		if {$id != $LWDAQ_Driver(data_return_id)} {
			error "Invalid message identifier in returned message."
		}
		set contents [LWDAQ_socket_read $sock $content_length]
		set last_byte [LWDAQ_socket_read $sock $LWDAQ_Driver(lwdaq_suffix_length)]
		binary scan $last_byte H2 suffix
		if {$suffix != $LWDAQ_Driver(lwdaq_suffix)} {
			LWDAQ_socket_close $sock
			error "Invalid suffix in returned message."
		}
	}
	
	if {$protocol == "basic"} {
		set contents ""
	}
		
	return $contents
}

#
# LWDAQ_receive_integer receives a data return message
# and scans its contents for a four-byte integer in
# big-endian byte order (most significant byte received
# first). The routine returns a string of characters that
# represent a decimal number.
#
proc LWDAQ_receive_integer {sock} {
	set contents [LWDAQ_receive_data $sock]
	binary scan $contents I version
	return $version
}

#
# LWDAQ_receive_byte receives a data return message
# and scans its contents for single-byte integer. It
# returns this integer as a string of characters representing
# a decimal number.
#
proc LWDAQ_receive_byte {sock} {
	set contents [LWDAQ_receive_data $sock]
	binary scan $contents c value
	return $value
}

#
# LWDAQ_software_version fetches the relay software version
# from a driver through an open socket $sock.
#
proc LWDAQ_software_version {sock} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock $LWDAQ_Driver(version_read_id) ""
	return [LWDAQ_receive_integer $sock]
}

#
# LWDAQ_byte_read reads a byte from the controller address
# space on a driver. The read takes place through a socket open
# with the driver called $sock, and reads a byte from controller
# address $addr. The routine returns the byte as a decimal number.
# The addr parameter is a string of characters representing a 
# decimal number. The routine translates the parameter into a 
# four-byte integer before transmitting it to the driver. The routine
# returns a string of characters that represents a decimal number.
#
proc LWDAQ_byte_read {sock addr} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock \
		$LWDAQ_Driver(byte_read_id) \
		[binary format I $addr]
	return [LWDAQ_receive_byte $sock]
}

#
# LWDAQ_stream_read reads $stream_length bytes out of
# controller address $addr on the driver at the other end of
# TCPIP socket $sock, and returns the entire stream. The
# routine is intended for use with the controller's stream
# read location, which presents consecutive bytes in the 
# controller RAM on consecutive reads by the relay. The 
# addr and stream_length parameters are strings of characters
# that represent decimal numbers. The routine translates both
# into four-byte integers before transmitting them to the driver.
# The routine returns a block of binary data.
#
proc LWDAQ_stream_read {sock addr stream_length} {
	global LWDAQ_Driver
	if {$stream_length <= 0} {return ""}
	LWDAQ_transmit_message $sock \
		$LWDAQ_Driver(stream_read_id) \
		[binary format II $addr $stream_length]
	set result [LWDAQ_receive_data $sock]
	return $result
}

#
# LWDAQ_stream_delete writes a constant byte value
# repeatedly to the same controller address, so as to clear
# consecutive memory locations. It is like the stream read
# in reverse, except the data value is always $value, where
# $value is a string of digits that represent a decimal
# value. The addr, stream_length, and value parameters are all
# strings of characters that represent decimal numbers. The
# routine translates the strings into two four-byte integers
# and a byte value respectively before transmitting them to 
# the driver.
#
proc LWDAQ_stream_delete {sock addr stream_length value} {
	global LWDAQ_Driver
	if {$stream_length <= 0} {return 1}
	LWDAQ_transmit_message $sock \
		$LWDAQ_Driver(stream_delete_id) \
		[binary format IIc1 $addr $stream_length $value]
	return 1
}

#
# LWDAQ_stream_write writes a block of bytes to the same
# controller address so as to transfer them into a memory
# block through a memory portal. It is like the stream read
# in reverse. The addr parameter is a strings of characters 
# that represents decimal number. The data parameter is a
# block of binary bytes that will be transmitted without
# modification. The routine translates the addr string into
# a four-byte integer before transmitting to the driver.
#
proc LWDAQ_stream_write {sock addr data} {
	global LWDAQ_Driver
	set bs $LWDAQ_Driver(server_buffer_size)
	while {[string length $data] > 0} {
		set contents [binary format I $addr]
		append contents [string range $data 0 [expr $bs - 1]]
		set data [string replace $data 0 [expr $bs - 1]]
		LWDAQ_transmit_message $sock \
			$LWDAQ_Driver(stream_write_id) \
			$contents
	}
	return 1
}

#
# LWDAQ_byte_write writes byte $value through TCPIP socket
# $sock to controller address $addr. The addr and value 
# parameters are strings of characters that represent decimal
# numbers. The routine translates these into a four-byte integer
# and a single-byte value before transmitting them to the driver.
#
proc LWDAQ_byte_write {sock addr value} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock \
		$LWDAQ_Driver(byte_write_id) \
		[binary format Ic1 $addr $value]
	return 1
}

#
# LWDAQ_byte_poll tells the relay at the other end
# of TCPIP socket $sock to wait until the byte it reads
# from address $addr has value $value. The value we pass to 
# the routine is a string of characters that represent a decimal 
# number. The routine converts this string into a binary byte. The
# strings "-1" and "255" both get converted into the same binary
# value, 255, which is -1 in 2's compliment.
#
proc LWDAQ_byte_poll {sock addr value} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock \
		$LWDAQ_Driver(byte_poll_id) \
		[binary format Ic1 $addr $value]
	return 1
}

#
# LWDAQ_login attempts to log into a LWDAQ relay with a login message
# and password $password. The routine recognises "no_password" as a key
# phrase to skip the login attempt and return the value 0. Otherwise,
# the routine sends the password and waits for an answer from the relay.
# An answer of 1 is success and 0 is failure. On success, the routine
# returns 1. On failure, the routine will generate an error by default,
# or return -1 if you pass the value 0 for error_on_fail.
#
proc LWDAQ_login {sock password {error_on_fail 1}} {
	global LWDAQ_Driver
	if {$password == "no_password"} {return 0}
	LWDAQ_transmit_message $sock $LWDAQ_Driver(login_id) "$password\x00" 
	if {![LWDAQ_receive_byte $sock]} {
		if {$error_on_fail} {error "Login failed with \"$password\"."}
		return -1
	}
	return 1
}

#
# LWDAQ_config_read reads the configuration parameters
# from the LWDAQ relay at the other end of an open TCPIP socket
# $sock, and returns them if they are valid. If the contents
# are not valid, the routine reports an error. The parameters
# the routine reads are those in the relay's RAM. These are the
# the ones in effect on the relay. They are not the ones written
# in the relay's EEPROM configuration file. There is no way to
# read the EEPROM configuration directly. The EEPROM parameters
# are loaded into ram after a hardware reset, which can be performed
# by pressing a button on the driver, or with LWDAQ_relay_reboot.
#
proc LWDAQ_config_read {sock} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock $LWDAQ_Driver(config_read_id) ""
	set config [LWDAQ_split [LWDAQ_receive_data $sock]]
	set config [lreplace $config 0 0]
	return $config
}

#
# LWDAQ_config_write writes $config to the configuration
# EEPROM on the relay. The new configuration parameters will not
# take effect until you reboot the driver. Until then, the 
# existing parameters in the driver's RAM will remain in effect.
#
proc LWDAQ_config_write {sock config} {
	global LWDAQ_Driver
	set c $LWDAQ_Driver(lwdaq_heading)
	append c "\n"
	foreach {e v} [LWDAQ_split $config] {append c "$e $v\n"}
	append c "\0"
	LWDAQ_transmit_message $sock $LWDAQ_Driver(config_write_id) $c
	return $c
}

#
# LWDAQ_mac_read reads the mac address of the Ethernet
# chip on the LWDAQ relay at the other end of open TCPIP
# socket $sock, and returns the address as a string of
# hexadecimal characters.
#
proc LWDAQ_mac_read {sock} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock $LWDAQ_Driver(mac_read_id) ""
	binary scan [LWDAQ_receive_data $sock] H* mac
	return $mac
}

#
# LWDAQ_shortint_write writes a two-byte integer $value through
# open TCPIP socket $sock to controller address $addr. The addr
# and value parameters are strings of characters that represent
# decimal numbers.
#
proc LWDAQ_shortint_write {sock addr value} {
	set integer [binary format S $value]
	binary scan $integer cc b1 b2 
	LWDAQ_byte_write $sock $addr $b1
	LWDAQ_byte_write $sock [expr $addr + 1] $b2
	return 1
}

#
# LWDAQ_integer_write writes a four-byte integer $value through
# open TCPIP socket $sock to controller address $addr. The addr and
# value parameters are strings of characters that represent decimal
# numbers.
#
proc LWDAQ_integer_write {sock addr value} {
	set integer [binary format I $value]
	binary scan $integer cccc b1 b2 b3 b4
	LWDAQ_byte_write $sock $addr $b1
	LWDAQ_byte_write $sock [expr $addr + 1] $b2
	LWDAQ_byte_write $sock [expr $addr + 2] $b3
	LWDAQ_byte_write $sock [expr $addr + 3] $b4
	return 1
}

#
# LWDAQ_firmware_version reads the controller's firmware
# version number through open socket $sock, and returns the version.
#
proc LWDAQ_firmware_version {sock} {
	global LWDAQ_Driver
	return [LWDAQ_byte_read $sock $LWDAQ_Driver(fv_addr)]
}

#
# LWDAQ_hardware_id reads the controller identifier number from
# the LWDAQ driver at the other end of TCPIP socket $sock, and 
# returns the identifier.
#
proc LWDAQ_hardware_id {sock} {
	global LWDAQ_Driver
	return [LWDAQ_byte_read $sock $LWDAQ_Driver(id_addr)]
}

#
# LWDAQ_hardware_version reads the controller's hardware
# version number through open socket $sock, and returns it.
#
proc LWDAQ_hardware_version {sock} {
	global LWDAQ_Driver
	return [LWDAQ_byte_read $sock $LWDAQ_Driver(hv_addr)]
}

#
# LWDAQ_loop_time reads the contents of a LWDAQ Driver's loop
# timer register and returns it. The driver is at the other
# end of an open TCPIP socket named $sock.
#
proc LWDAQ_loop_time {sock} {
	global LWDAQ_Driver
	return [LWDAQ_byte_read $sock $LWDAQ_Driver(lt_addr)]
}

#
# LWDAQ_most_recent_byte reads the contents of a LWDAQ Driver's mrb
# register and returns it. The driver is at the other end of an open 
# TCPIP socket named $sock. The mrb register contains the most recent
# byte to be written to the Driver's ram, either by the relay or by
# the controller.
#
proc LWDAQ_most_recent_byte {sock} {
	global LWDAQ_Driver
	return [LWDAQ_byte_read $sock $LWDAQ_Driver(mrb_addr)]
}

#
# LWDAQ_set_data_addr sets the four bytes of the driver's
# data address to $value. The driver is at the other end of open
# TCPIP socket $sock. The value parameter is a string of characters
# representing a decimal number.
#
proc LWDAQ_set_data_addr {sock value} {
	global LWDAQ_Driver
	LWDAQ_integer_write $sock $LWDAQ_Driver(da_addr) $value
	return 1
}

#
# LWDAQ_set_base_addr_hex sets the four bytes of the driver's
# base address to $value. The value parameter is a string of 
# characters representing an eight-digit hexadecimal number, plus
# an optional colon and number as in daq_driver_socket of an
# instrument configuration. The routine uses only the hex number.
# The routine translates the character string into a four-byte
# integer. The driver is at the other end of open TCPIP socket 
# $sock. The base address register exists in LWDAQ components 
# like the VME-TCPIP Interface (A2064), where it sets the base 
# position in VME address space of the LWDAQ Driver with VME
# Interface to which subsequent instructions to the A2064 should
# be directed. We call this routine whenever we open a TCPIP
# socket to a LWDAQ component. The routine accepts a hex number
# followed by a colon and an integer "00E00000:7". It uses
# the hex number before the colon as the base address.
#
proc LWDAQ_set_base_addr_hex {sock value} {
	global LWDAQ_Driver
	set value [lindex [split $value :] 0]
	set temporary [binary format H8 $value]
	binary scan $temporary I addr
	LWDAQ_integer_write $sock $LWDAQ_Driver(ba_addr) $addr
	return 1
}

#
# LWDAQ_set_command_reg sets a driver's command register to
# $value through TCPIP socket $sock. The value parameter is a 
# string of characters representing a decimal number. This 
# decimal number will be translated into a sixteen-bit value
# before transmission to the driver.
#
proc LWDAQ_set_command_reg {sock value} {
	global LWDAQ_Driver
	LWDAQ_shortint_write $sock $LWDAQ_Driver(cr_addr) $value
	return 1
}

#
# LWDAQ_set_command_reg_binary sets a driver's command register to 
# $value, where $value is a binary string representation of the 
# register's sixteen bits. 
#
proc LWDAQ_set_command_reg_binary {sock value} {
	global LWDAQ_Driver
	set temporary [binary format B16 $value]
	binary scan $temporary S command
	LWDAQ_shortint_write $sock $LWDAQ_Driver(cr_addr) $command
	return 1
}

#
# LWDAQ_set_command_reg_hex sets a driver's command register 
# to $value, where $value is a hexadecimal string representation
# of the register's sixteen bits.
#
proc LWDAQ_set_command_reg_hex {sock value} {
	global LWDAQ_Driver
	set temporary [binary format H4 $value]
	binary scan $temporary S command
	LWDAQ_shortint_write $sock $LWDAQ_Driver(cr_addr) $command
	return 1
}

#
# LWDAQ_set_device_type sets a driver's device type register
# to $value through socket $sock. The value parameter is a 
# character string representing a decimal number.
#
proc LWDAQ_set_device_type {sock value} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(dtr_addr) $value
	return 1
}

#
# LWDAQ_set_device_element sets a driver's device type 
# register to $value through socket $sock. The value parameter
# is a character string representing a decimal number.
#
proc LWDAQ_set_device_element {sock value} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(der_addr) $value
	return 1
}

#
# LWDAQ_set_delay_ticks sets a driver's delay timer
# to $value through socket $sock.  The value parameter
# is a character string representing a decimal number.
#
proc LWDAQ_set_delay_ticks {sock value} {
	global LWDAQ_Driver
	LWDAQ_integer_write $sock $LWDAQ_Driver(dt_addr) $value
	return 1
}

#
# LWDAQ_set_delay_seconds sets a driver's delay timer
# to a number of ticks that will count down to zero in $value
# seconds. The driver is at the other end of TCPIP socket $sock.
# The value parameter is a character string representing a 
# decimal number.
#
#
proc LWDAQ_set_delay_seconds {sock value} {
	global LWDAQ_Driver
	set ticks [expr round( $value * $LWDAQ_Driver(delay_timer_frequency) )]
	LWDAQ_set_delay_ticks $sock $ticks
	return 1
}

#
# LWDAQ_set_repeat_counter sets a driver's repeat counter
# to $value through socket $sock.  The value parameter
# is a character string representing a decimal number.
#
proc LWDAQ_set_repeat_counter {sock value} {
	global LWDAQ_Driver
	LWDAQ_integer_write $sock $LWDAQ_Driver(rc_addr) $value
	return 1
}

#
# LWDAQ_controller_reset writes the value 1 to the software 
# reset byte on a controller at the other end of socket $sock, 
# thus resetting all its state machines and registers. The relay 
# remains unaffected.
#
proc LWDAQ_controller_reset {sock} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(srst_addr) 1 
	return 1
}

#
# LWDAQ_relay_reboot resets the relay without affecting the 
# controller. This routine is supported only by relay software
# versions thirteen and up. 
#
proc LWDAQ_relay_reboot {sock} {
	global LWDAQ_Driver
	if {[LWDAQ_software_version $sock] < $LWDAQ_Driver(min_sv_for_reboot)} {
		error "Relay software version < $LWDAQ_Driver(min_sv_for_reboot),\
			must reboot with switch."
	}
	LWDAQ_transmit_message $sock $LWDAQ_Driver(reboot_id) ""
	return 1
}

#
# LWDAQ_ram_read sets the LWDAQ Controller's data address equal to
# $addr, reads $length consecutive bytes from this same address 
# location, and returns these bytes as a byte array. The routine is
# intended for use with a RAM portal, where each consecutive
# read from the portal returns a consecutive byte in RAM. The addr
# and length parameters are character strings representing decimal
# numbers.
#
proc LWDAQ_ram_read {sock addr length} {
	global LWDAQ_Driver
	LWDAQ_set_data_addr $sock $addr
	return [LWDAQ_stream_read $sock $LWDAQ_Driver(ram_portal_addr) $length]
}

#
# LWDAQ_ram_delete sets the LWDAQ Controller's data address equal to
# $addr and then clears a block of $length bytes starting from
# address $addr in the LWDAQ Controller memory. The bytes are set
# to zero unless another value is passed to the routine. The addr,
# length, and value parameter are character strings representing decimal
# numbers.
#
proc LWDAQ_ram_delete {sock addr length {value 0}} {
	global LWDAQ_Driver
	LWDAQ_set_data_addr $sock $addr
	return [LWDAQ_stream_delete $sock $LWDAQ_Driver(ram_portal_addr) $length $value]
}

#
# LWDAQ_ram_write sets the LWDAQ Controller's data address equal to
# $addr and writes a block of data byte by byte into the RAM Portal.
# The addr parameter is a string of characters representing a decimal 
# number. The data parameter is a block of binary bytes.
#
proc LWDAQ_ram_write {sock addr data} {
	global LWDAQ_Driver
	LWDAQ_set_data_addr $sock $addr
	return [LWDAQ_stream_write $sock $LWDAQ_Driver(ram_portal_addr) $data]
}

#
# LWDAQ_set_device_addr sets the device address register on
# a driver to $value through TCPIP socket $sock. The driver
# will be busy with this instruction for a few tens of microseconds
# thereafter, as it switches its driver sockets and transmits
# a new address down the newly active socket. The value parameter
# is a character string representing a decimal number.
# 
proc LWDAQ_set_device_addr {sock value} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(dar_addr) $value
	return 1
}

#
# LWDAQ_set_driver_mux sets the device address register on a driver so as
# to select driver socket $driver and multiplexer socket (also known as
# the branch socket) $mux. The driver will be busy for a few tens of
# microseconds thereafter, as it switches target sockets. The driver
# socket can be a simple integer specifying the socket on a LWDAQ driver,
# or it can be of the form b:a, where "b" is a 32-bit "base address"
# expressed as an eight-digit hex string, and "a" is a decimal number.
# The base address selects one of several drivers associated with $sock.
# We might have a VME crate holding twenty LWDAQ Drivers (A2037A) and
# a single VME-TCPIP interface (A2064). The $sock connection is with the
# A2064, and we instruct the A2064 to select one of the twenty drivers
# using "b" in $driver. For example, 00E0000:3 would select the driver 
# at VME base address hexadecimal 00E00000, and socket 3 within that 
# driver. If we do not specify a base address, the routine does not 
# bother setting the base address on the TCPIP interface at $sock. It
# uses $driver as the decimal socket number.
#
proc LWDAQ_set_driver_mux {sock driver {mux 1}} {
	set driver [string trim $driver]
	if {![regexp {^([0-9A-Fa-f]+)(:([0-9]+))?$} $driver match first second third]} {
		error "Invalid driver socket \"$driver\""
	}
	if {$third != ""} {
		LWDAQ_set_base_addr_hex $sock $first
		LWDAQ_set_device_addr $sock [expr ($third * 16) + $mux]
	} {
		if {![string is integer $first]} {
			error "Invalid driver socket \"$driver\""
		}
		LWDAQ_set_device_addr $sock [expr ($first * 16) + $mux]
	}
	return 1
}

#
# LWDAQ_on turns on power to all devices connected to the driver
# listening at the other end of $sock.
#
proc LWDAQ_on {sock} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(edp_addr) 1
	LWDAQ_socket_flush $sock
}

#
# LWDAQ_off turns off power to all devices connected to the driver
# listening at the other end of $sock.
#
proc LWDAQ_off {sock} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(edp_addr) 0
	LWDAQ_socket_flush $sock
}

#
# LWDAQ_start_job tells a driver to begin a job execution by
# writing job identifier $job to the job register at socket
# $sock. The job parameter is a string of characters representing
# a decimal number.
#
proc LWDAQ_start_job {sock job} {
	global LWDAQ_Driver
	LWDAQ_byte_write $sock $LWDAQ_Driver(djr_addr) $job
}

#
# LWDAQ_execute_job tells a driver to execute job with job
# identifier $job through socket $sock. The driver will be busy
# thereafter for however long it takes to execute the job, but
# the routine will return as soon as the TCPIP messages required
# to instruct the driver have been transmitted. Note that if you 
# have lazy_flush set to 1, the job won't execute until you 
# flush the socket, close it, or read from it. The job parameter 
# is a string of characters representing a decimal number.
#
proc LWDAQ_execute_job {sock job} {
	global LWDAQ_Driver
	LWDAQ_start_job $sock $job
	LWDAQ_byte_poll $sock $LWDAQ_Driver(djr_addr) 0
	return 1
}

#
# LWDAQ_transmit_command instructs a driver to transmit 
# LWDAQ command $value to its current target device. The 
# routine instructs the driver through open TCPIP socket
# $sock. The driver will be busy for a few microseconds thereafter
# as it transmits the command, but the routine will return
# almost immediately. Note that if you have lazy_flush set
# to 1, the messages produced by the routine will remain in 
# $sock's output buffer until you flush the socket, close it,
# or read from it. The value parameter is a string of characters
# representing a decimal number.
#
proc LWDAQ_transmit_command {sock value} {
	global LWDAQ_Driver
	LWDAQ_set_command_reg $sock $value
	LWDAQ_execute_job $sock $LWDAQ_Driver(command_job)
	return 1
}

#
# LWDAQ_transmit_command_binary is the same as LWDAQ_transmit_command
# except it takes a binary string representation of the command
# value. Thus "0001001001001000" represents command "1248" in hexadecimal
# notation, or "4680" in decimal.
#
proc LWDAQ_transmit_command_binary {sock value} {
	global LWDAQ_Driver
	LWDAQ_set_command_reg_binary $sock $value
	LWDAQ_execute_job $sock $LWDAQ_Driver(command_job)
	return 1
}

#
# LWDAQ_transmit_command_hex is the same as LWDAQ_transmit_command
# except it takes a hexadecimal string representation of the command
# value. Thus "1248" represents command "4680" in decimal and "FFFF"
# represents "1111111111111111" as a binary string.
#
proc LWDAQ_transmit_command_hex {sock value} {
	global LWDAQ_Driver
	LWDAQ_set_command_reg_hex $sock $value
	LWDAQ_execute_job $sock $LWDAQ_Driver(command_job)
	return 1
}

#
# LWDAQ_wake wakes up a driver's target device through socket $sock.
#
proc LWDAQ_wake {sock} {
	global LWDAQ_Driver
	LWDAQ_execute_job $sock $LWDAQ_Driver(wake_job)
	return 1
}

#
# LWDAQ_sleep sends a driver's target device to sleep through $sock.
# 
proc LWDAQ_sleep {sock} {
	global LWDAQ_Driver
	LWDAQ_execute_job $sock $LWDAQ_Driver(sleep_job)
	return 1
}

#
# LWDAQ_delay_seconds tells a driver at the other end of
# $sock to pause for $value seconds. The routine does not
# itself take $value seconds, but the driver will be busy 
# for $value seconds after it receives the delay instructions.
# If the delay is larger than $LWDAQ_Driver(max_delay_seconds)
# then the routine submits multiple delay jobs to create
# a total delay of $value seconds.
#
proc LWDAQ_delay_seconds {sock value} {
	global LWDAQ_Driver 
	set remaining $value
	set max $LWDAQ_Driver(max_delay_seconds)
	while {$remaining > 0} {
		if {$remaining > $max} {
			LWDAQ_set_delay_seconds $sock $max
			set remaining [expr $remaining - $max]
		} {
			LWDAQ_set_delay_seconds $sock $remaining
			set remaining 0
		}
		LWDAQ_execute_job $sock $LWDAQ_Driver(delay_job)
	}
	LWDAQ_socket_flush $sock
	return $value 
}

#
# LWDAQ_job_done returns 1 if the driver's job register
# reads back zero, and 1 otherwise.
#
proc LWDAQ_job_done {sock} {
	global LWDAQ_Driver 
	if {[LWDAQ_byte_read $sock $LWDAQ_Driver(djr_addr)] == 0} {
		return 1
	} {
		return 0
	}
}

#
# LWDAQ_wait_for_driver waits until the driver has finished
# executing all pending commands. If you expect the commands
# to take more than a few seconds, specify how long you expect
# them to take with the optional $approx parameter. By specifying
# the approximate delay, you allow this routine to avoid a
# TCPIP read timeout.
#
proc LWDAQ_wait_for_driver {sock {approx 0}} {
	if {$approx != 0} {
		LWDAQ_socket_flush $sock
		LWDAQ_wait_seconds $approx
	}
	LWDAQ_software_version $sock
	return 0
}

#
# LWDAQ_echo takes a string and sends it to a driver in an echo
# message. It waits for a data return message containing a string,
# which should match the string it sent.
#
proc LWDAQ_echo {sock s} {
	global LWDAQ_Driver
	LWDAQ_transmit_message $sock $LWDAQ_Driver(echo_id) $s
	return [LWDAQ_receive_data $sock]
}
