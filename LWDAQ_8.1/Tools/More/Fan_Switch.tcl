# Turns on and off the fan on the LWDAQ demonstration stand.
# Copyright (C) 2004 Kevan Hashemi, Brandeis University
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
proc Fan_Switch_init {} {
	upvar #0 Fan_Switch_info info
	upvar #0 Fan_Switch_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Fan_Switch" "2"
	if {[winfo exists $info(window)]} {return 0}

	set config(daq_ip_addr) 129.64.37.79
	set config(daq_driver_password) "no_password"
	set config(daq_driver_socket) 3
	set config(daq_mux_socket) 1
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	}
	
	return 1    
}

proc Fan_Switch_on {} {
	upvar #0 Fan_Switch_config config
	upvar #0 Fan_Switch_info info
	set sock [LWDAQ_socket_open $config(daq_ip_addr)]
    LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_transmit_command_hex $sock 0001
	LWDAQ_print $info(text) "Fan On" green
	close $sock
}

proc Fan_Switch_off {} {
	upvar #0 Fan_Switch_config config
	upvar #0 Fan_Switch_info info
	set sock [LWDAQ_socket_open $config(daq_ip_addr)]
    LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
	LWDAQ_transmit_command_hex $sock 0000
	LWDAQ_print $info(text) "Fan Off" red
	close $sock
}

proc Fan_Switch_open {} {
	upvar #0 Fan_Switch_config config
	upvar #0 Fan_Switch_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
	
	set f $w.controls
	frame $f 
	pack $f -side top -fill x
		
	button $f.on -text "On" -command Fan_Switch_on
	button $f.off -text "Off" -command Fan_Switch_off
	pack $f.on $f.off -side left -expand 1 
	foreach a {Configure Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Fan_Switch"
		pack $f.$b -side left -expand 1
	}

		
	set info(text) [LWDAQ_text_widget $w 40 15]
	LWDAQ_print $info(text) "$info(name) Version $info(version) \n" purple
	
	return 1
	
}

Fan_Switch_init
Fan_Switch_open

return 1

----------Begin Help----------

Turns on and off the fan on our demonstration stand.

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
