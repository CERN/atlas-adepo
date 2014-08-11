# Configurator, a Standard and Polite LWDAQ Tool
# Copyright (C) 2004-2012, Kevan Hashemi, Brandeis University
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

proc Configurator_init {} {
	upvar #0 Configurator_info info
	upvar #0 Configurator_config config
	global LWDAQ_Info
	
	LWDAQ_tool_init "Configurator" "21"
	if {[winfo exists $info(window)]} {return 0}

	set config(contact_ip_addr) 10.0.0.37
	set config(contact_ip_port) 90
	set config(contact_password) "LWDAQ"
	set config(contact_base_addr) 00000000
	
	foreach b {read write} {
		foreach a {password ip_addr ip_port gateway_addr operator subnet_mask\
				configuration_time security_level driver_id tcp_timeout} {
			set config($b\_$a:) ""
		}
	}
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1   
}

proc Configurator_contact {} {
	upvar #0 Configurator_config config
	upvar #0 Configurator_info info
	global LWDAQ_Info
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Attempting to open socket..." green
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(contact_ip_addr):$config(contact_ip_port)]
		LWDAQ_print $info(text)  "success." green
		LWDAQ_print -nonewline $info(text) "Attempting login..." green
		LWDAQ_update
		switch [LWDAQ_login $sock $config(contact_password) 0] {
			-1 {LWDAQ_print $info(text) "failed." red}
			0  {LWDAQ_print $info(text) "skipped." blue}
			1  {LWDAQ_print $info(text) "success." green}
		}
		
		if {[string match "00000000" $config(contact_base_addr)]} {
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
			LWDAQ_set_base_addr_hex $sock $config(contact_base_addr)
			LWDAQ_print $info(text) "Driver Hardware ID: [LWDAQ_hardware_id $sock]" 
			LWDAQ_print $info(text) "Driver Hardware Version: [LWDAQ_hardware_version $sock]" 
			LWDAQ_print $info(text) "Driver Firmware Version: [LWDAQ_firmware_version $sock]"
			LWDAQ_set_base_addr_hex $sock "00000000"
		}
		LWDAQ_print -nonewline $info(text) "Closing socket..." green
		LWDAQ_socket_close $sock
		LWDAQ_print $info(text)  "closed.\n" green
	} error_result]} {
		LWDAQ_print $info(text) "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
		return 0
	}	
	return 1
}

proc Configurator_read {} {
	upvar #0 Configurator_config config
	upvar #0 Configurator_info info
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Reading configuration file..." green
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(contact_ip_addr):$config(contact_ip_port)]
		LWDAQ_login $sock $config(contact_password)
		set c [LWDAQ_config_read $sock]
		LWDAQ_socket_close $sock
		LWDAQ_print $info(text) "succeeded." green
		foreach {e v} $c {set config(read_$e) $v}
		LWDAQ_print $info(text)  "See entries below Read button.\n"
	} error_result]} {
		LWDAQ_print $info(text)
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
		return 0
	}	
	return 1
}

proc Configurator_write {} {
	upvar #0 Configurator_config config
	upvar #0 Configurator_info info
	if {[catch {
		if {$config(write_configuration_time:) == ""} {
			set config(write_configuration_time:) [LWDAQ_time_stamp]
		}
		set c [list]
		foreach e [array names config write_*] {
			lappend c [string map {write_ {}} $e] $config($e)
		}
		LWDAQ_print -nonewline $info(text) "Writing new configuration file to EEPROM..." green
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(contact_ip_addr):$config(contact_ip_port)]
		LWDAQ_login $sock $config(contact_password)
		LWDAQ_config_write $sock $c
		LWDAQ_wait_for_driver $sock
		LWDAQ_print $info(text) "succeeded." green
		LWDAQ_socket_close $sock
		LWDAQ_print $info(text)  "New configuration will be loaded after reboot.\n"
	} error_result]} {
		LWDAQ_print $info(text)
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
		return 0
	}	
	return 1
}

proc Configurator_copy {} {
	upvar #0 Configurator_config config
	foreach e [array names config read_*] {
		set config([string map {read write} $e]) $config($e)
	}
	set config(write_configuration_time:) ""
}

proc Configurator_reboot {} {
	upvar #0 Configurator_config config
	upvar #0 Configurator_info info
	global LWDAQ_Driver
	if {[catch {
		LWDAQ_print -nonewline $info(text) "Resetting server..." green
		LWDAQ_update
		set sock [LWDAQ_socket_open $config(contact_ip_addr):$config(contact_ip_port)]
		LWDAQ_login $sock $config(contact_password)
		LWDAQ_relay_reboot $sock
		LWDAQ_socket_flush $sock
		LWDAQ_wait_ms 500
	} error_result]} {
		LWDAQ_print $info(text)
		LWDAQ_print $info(text)  "ERROR: $error_result\n"
		catch {LWDAQ_socket_close $sock}
		return 0
	}	
	catch {LWDAQ_socket_close $sock}

	LWDAQ_print $info(text) "succeeded." green
	LWDAQ_print $info(text)  "New configuration will be loaded after reboot.\n"

	return 1
}

proc Configurator_open {} {
	upvar #0 Configurator_config config
	upvar #0 Configurator_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.buttons
	frame $f
	pack $f -side top -fill x
	
	foreach a {Contact Reboot Read Copy Write} {
		set b [string tolower $a]
		button $f.$b -text $a -command [list LWDAQ_post Configurator_$b]
		pack $f.$b -side left -expand 1
	}
	foreach a {Help Save} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Configurator"
		pack $f.$b -side left -expand 1
	}

	set f $w.c
	frame $f
	pack $f -side top -fill x
	
	foreach a {contact read write} {
		frame $f.$a
		pack $f.$a -side left -fill y
		set l [array names config $a\*]
		set l [lsort -dictionary $l]
		foreach c $l {
			label $f.$a.l$c -text "$c" -anchor w
			entry $f.$a.e$c -textvariable Configurator_config($c) \
				-relief sunken -bd 1 -width 15
			grid $f.$a.l$c $f.$a.e$c -sticky news
		}
	}
	
	set info(text) [LWDAQ_text_widget $w 100 15]
	
	return 1
}

Configurator_init
Configurator_open

return 1

----------Begin Help----------

The Configurator has its own chapter in the LWDAQ_Manual, at:

http://alignment.hep.brandeis.edu/Electronics/LWDAQ/Manual.html#Configurator


Kevan Hashemi hashemi@brandeis.edu
----------End Help----------

