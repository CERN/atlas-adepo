# Image Contrast Measures image contrast with cable length.
# Copyright (C) 2006 Kevan Hashemi, Brandeis University
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
# See below for description.
#

proc Image_Contrast_init {} {
	upvar #0 Image_Contrast_info info
	upvar #0 Image_Contrast_config config

	LWDAQ_tool_init "Image_Contrast" "3"
	if {[winfo exists $info(window)]} {return 0}

	set info(control) "Idle"
	
	set config(comment) ""
	set config(instrument) BCAM
	set config(diagnostic_actions) "loop"
	set config(root_1) "0"
	set config(root_2) "-1"
	set config(branch) "-1"

	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 
}

proc Image_Contrast_capture {} {
	upvar #0 Image_Contrast_info info
	upvar #0 Image_Contrast_config config
	upvar #0 LWDAQ_config_$config(instrument) iconfig
	upvar #0 LWDAQ_config_Diagnostic dconfig
	set info(control) "Capture"
	LWDAQ_acquire $config(instrument)
	set characteristics [lwdaq_image_characteristics $iconfig(memory_name)]
	set dconfig(daq_driver_socket) $iconfig(daq_driver_socket)
	set dconfig(daq_mux_socket) $iconfig(daq_mux_socket)
	set dconfig(daq_ip_addr) $iconfig(daq_ip_addr)
	set dconfig(daq_actions) $config(diagnostic_actions)
	set diagnostic [LWDAQ_acquire Diagnostic]
	set max [lindex $characteristics 6]
	set min [lindex $characteristics 7]
	set contrast [expr $max - $min]
	set loop_time [lindex $diagnostic 5]
	set Ip15V [lindex $diagnostic 8]
	set Ip5V [lindex $diagnostic 10]
	set Im15V [lindex $diagnostic 12]	
	LWDAQ_print -nonewline $info(text) \
		"$contrast $max $min $loop_time $Ip15V $Ip5V $Im15V \
		$config(root_1) $config(root_2) $config(branch)"
	LWDAQ_print $info(text)  " $config(comment)" green
	set info(control) "Idle"
}

proc Image_Contrast_open {} {
	upvar #0 Image_Contrast_config config
	upvar #0 Image_Contrast_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.setup
	frame $f
	pack $f -side top -fill x
	
	label $f.l1 -textvariable $info(name)_info(control) -width 20 -fg blue
	pack $f.l1 -side left -expand 1

	foreach a {Capture} {
		set b [string tolower $a]
		button $f.$b -text $a -command [list LWDAQ_post Image_Contrast_$b]
		pack $f.$b -side left -expand 1
	}
	foreach a {Configure Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Image_Contrast"
		pack $f.$b -side left -expand 1
	}

	set f $w.lengths
	frame $f
	pack $f -side top -fill x
	foreach a {Root_1 Root_2 Branch} {
		set b [string tolower $a]
		label $f.l$b -text $a 
		entry $f.e$b -textvariable $info(name)_config($b)
		pack $f.l$b $f.e$b -side left -expand 1
	}

	set f $w.comment
	frame $f
	pack $f -side top -fill x
	label $f.l1 -text "Comment:" -width 8
	entry $f.l2 -textvariable $info(name)_config(comment) -width 60 -fg green
	pack $f.l1 $f.l2 -side left -expand 1
	
	set info(text) [LWDAQ_text_widget $w 80 20]
	
	return 1
}

Image_Contrast_init
Image_Contrast_open

return 1

----------Begin Help----------

The Image_Contrast tool captures images from a specified instrument, which you
configure yourself beforehand, and obtains the intensity characteristics of the
image. The tool takes the instrument`s sensor driver and mux sockets and uses
the Diagnostic instrument to determine the sensor device`s loop time. A comment
field in the tool`s window allows you to describe the circumstances under which
you obtained your image. When you press "Capture", the tool posts its capture
job to the LWDAQ event queue. The comment field, the intensity characteristics,
and the loop time all get printed to the script`s window, in the following
order, and delimited by tabs:

Contrast (ADC counts)
Max Intensity (ADC counts)
Min Intensity (ADC counts)
Loop Time (ns)
+15V current (mA)
+5V current (mA)
-15V current (mA)
Comment (string)

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
