# Template, a Standard and Polite LWDAQ Tool
# Copyright (C) 2004-2012 Kevan Hashemi, Brandeis University
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


proc Template_init {} {
	upvar #0 Template_info info
	upvar #0 Template_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Template" "2"
	if {[winfo exists $info(window)]} {return 0}

	set config(example_configuration_parameter) example_parameter_value

	set info(example_info_parameter) example_parameter_value
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1   
}

proc Template_open {} {
	upvar #0 Template_config config
	upvar #0 Template_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
	
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	foreach a {Help Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b $info(name)"
		pack $f.$b -side left -expand 1
	}

	set info(text) [LWDAQ_text_widget $w 100 15]

	LWDAQ_print $info(text) "$info(name) Version $info(version) \n"
	
	return 1
}

Template_init
Template_open
	
return 1

----------Begin Help----------

The Template tool is a starting point from new, polite LWDAQ tools. 

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------

----------Begin Data----------

----------End Data----------