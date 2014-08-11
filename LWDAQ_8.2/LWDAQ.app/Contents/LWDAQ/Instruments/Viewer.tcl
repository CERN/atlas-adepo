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
# Viewer.tcl defines the Viewer instrument.
#

#
# LWDAQ_init_Viewer creates all elements of the Viewer instrument's
# config and info arrays.
#
proc LWDAQ_init_Viewer {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Viewer info
	upvar #0 LWDAQ_config_Viewer config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Viewer"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(daq_extended) 0
	set info(delete_old_images) 1
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 344
	set info(daq_image_height) 244
	set info(daq_image_left) -1
	set info(daq_image_right) -1
	set info(daq_image_top) -1
	set info(daq_image_bottom) -1
	set info(image_results) ""
	set info(verbose_description) " {Image Height} {Image Width} \
		{Bounds Left} {Bounds Top} {Bounds Right} {Bounds Bottom} \
		{Results String}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "Camera"
	set config(file_name) ./Images/\*
	set config(memory_name) lwdaq_image_1
	set config(intensify) exact
	set config(analysis_enable) 1
	set config(verbose_result) 0
	
	return 1
}

#
# LWDAQ_analysis_Viewer returns the results string of an image in the 
# lwdaq image list. By default, the routine uses the image 
# $config(memory_name).
#
proc LWDAQ_analysis_Viewer {{image_name ""}} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[lwdaq_image_exists $image_name] == ""} {
		set result "ERROR: Image \"$image_name\" does not exist."
	} {
		set stats [lwdaq_image_characteristics $image_name]
		set result [list]
		foreach i {8 9 0 1 2 3} {lappend result [lindex $stats $i]}
		lappend result [lwdaq_image_results $image_name]
		lwdaq_image_manipulate $image_name none -clear 1
	}
	return $result
}

#
# LWDAQ_daq_Viewer is a dummy procedure for the standard aquire button. 
#
proc LWDAQ_daq_Viewer {} {
	return "ERROR: The Viewer does not have its own data acquisition procedure."
} 

#
# LWDAQ_special_analysis_Viewer calls the analysis of other instruments,
# displays the results on the screen, and prints them to the text
# window.
#
proc LWDAQ_special_analysis_Viewer {instrument} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	upvar #0 LWDAQ_config_$instrument iconfig
	upvar #0 LWDAQ_info_$instrument iinfo
	LWDAQ_print -nonewline $info(text) "$instrument\> " green
	set iconfig(memory_name) $config(memory_name)
	set result [LWDAQ_instrument_analyze $instrument]
	if {$instrument != $info(name)} {
		set saved_verbose_description $info(verbose_description)
		set info(verbose_description) $iinfo(verbose_description)
		LWDAQ_instrument_print $info(name) $result
		set info(verbose_description) $saved_verbose_description
		if {[winfo exists $info(window)]} {
			lwdaq_draw $config(memory_name) $info(photo) \
				-intensify $config(intensify) -zoom $info(zoom)
		}
	}
	return 1
}

#
# LWDAQ_DAQ_to_GIF_Viewer opens a browser in which you select
# multiple DAQ image files, and converts them to GIF files, writing
# them into the same directory with suffix ".gif".
#
proc LWDAQ_DAQ_to_GIF_Viewer {} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	if {$info(control) != "Idle"} {return 0}
	set info(control) "Convert"
	set file_list [lsort -dictionary [LWDAQ_get_file_name 1]]
	set num [llength $file_list]
	set index 1
	foreach f $file_list {
		set tail [file tail $f]
		set dir [file dirname $f]
		set gif [file rootname $tail].gif 
		if {$info(delete_old_images)} {lwdaq_image_destroy $info(name)\*}
		incr info(counter)
		set config(memory_name) [LWDAQ_read_image_file $f $info(name)\_$info(counter)]
		LWDAQ_write_image_file $config(memory_name) [file join $dir $gif]
		LWDAQ_print $info(text) "$index of $num\: Created $gif."	
		incr index
		if {$info(control)=="Stop"} {break}
	}
	set info(control) "Idle"
	return 1
}

#
# LWDAQ_GIF_to_DAQ_Viewer opens a browser in which you select
# multiple GIF image files, and converts them to DAQ files, writing
# them into the same directory with suffix ".daq".
#
proc LWDAQ_GIF_to_DAQ_Viewer {} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	if {$info(control) != "Idle"} {return 0}
	set info(control) "Convert"
	set file_list [lsort -dictionary [LWDAQ_get_file_name 1]]
	set num [llength $file_list]
	set index 1
	foreach f $file_list {
		set tail [file tail $f]
		set dir [file dirname $f]
		set daq [file rootname $tail].daq 
		if {$info(delete_old_images)} {lwdaq_image_destroy $info(name)\*}
		incr info(counter)
		set config(memory_name) [LWDAQ_read_image_file $f $info(name)\_$info(counter)]
		LWDAQ_write_image_file $config(memory_name) [file join $dir $daq]
		LWDAQ_print $info(text) "$index of $num\: Created $daq."			
		incr index
		if {$info(control)=="Stop"} {break}
	}
	set info(control) "Idle"
	return 1
}

#
# LWDAQ_Set_Bounds_Viewer applies the analyisis boundaries
# specified in the viewer's info array to the image named by config
# memory_name.
#
proc LWDAQ_Set_Bounds_Viewer {} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	if {[lwdaq_image_exists $config(memory_name)] == ""} {
		LWDAQ_print $info(text) "ERROR: Image \"$config(memory_name)\" does not exist."
		return 0
	}
	lwdaq_image_manipulate $config(memory_name) none \
		-left $info(daq_image_left) \
		-top $info(daq_image_top) \
		-right $info(daq_image_right) \
		-bottom $info(daq_image_bottom) \
		-clear 1
	lwdaq_draw $config(memory_name) $info(photo) \
		-intensify $config(intensify) -zoom $info(zoom)
	return 1
}

#
# LWDAQ_Set_Dimensions_Viewer takes the contents of the image
# named by config(memory_name) and creates a new image with the
# dimensions specified in the dimension control boxes. The routine
# keeps the analysis boundaries the same.
#
proc LWDAQ_Set_Dimensions_Viewer {} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	if {[lwdaq_image_exists $config(memory_name)] == ""} {
		LWDAQ_print $info(text) "ERROR: Image \"$config(memory_name)\" does not exist."
		return 0
	}
	set data [lwdaq_image_contents $config(memory_name)]
	set stats [lwdaq_image_characteristics $config(memory_name)]
	set results [lwdaq_image_results $config(memory_name)]
	incr info(counter)
	if {$info(delete_old_images)} {lwdaq_image_destroy $info(name)\*}
	set config(memory_name) [lwdaq_image_create \
		-width $info(daq_image_width) \
		-height $info(daq_image_height) \
		-left [lindex $stats 0] \
		-top [lindex $stats 1] \
		-right [lindex $stats 2] \
		-bottom [lindex $stats 3] \
		-data $data \
		-results $results \
		-name "$info(name)\_$info(counter)"]
	lwdaq_draw $config(memory_name) $info(photo) \
		-intensify $config(intensify) -zoom $info(zoom)
	return 1
}

#
# LWDAQ_Set_Results_Viewer sets the results string of an image.
#
proc LWDAQ_Set_Results_Viewer {} {
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info
	if {[lwdaq_image_exists $config(memory_name)] == ""} {
		LWDAQ_print $info(text) "ERROR: Image \"$config(memory_name)\" does not exist."
		return 0
	}
	lwdaq_image_manipulate $config(memory_name) none \
		-results $info(image_results)
	lwdaq_draw $config(memory_name) $info(photo) \
		-intensify $config(intensify) -zoom $info(zoom)
	return 1
}

#
# LWDAQ_controls_Viewer creates secial controls for the 
# Viewer instrument.
#
proc LWDAQ_controls_Viewer {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_config_Viewer config
	upvar #0 LWDAQ_info_Viewer info

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	frame $w.f1
	frame $w.f2
	pack $w.f1 $w.f2 -side top -fill x
	set count 0
	set half [expr [llength $LWDAQ_Info(instruments)] / 2]
	foreach a $LWDAQ_Info(instruments) {
		incr count
		if {$count > $half} {set f f2} {set f f1}
		set b [string tolower $a]
		button $w.$f.$b -text $a -command \
			[list LWDAQ_post [list LWDAQ_special_analysis_Viewer $a] front]
		pack $w.$f.$b -side left -expand 1
	}

	set f $w.dimensions
	frame $f
	pack $f -side top -fill x
	button $f.setb -text "Set Boundaries" -command \
		LWDAQ_Set_Bounds_Viewer
	pack $f.setb -side left
	foreach l {left top right bottom} {
		label $f.l$l -text $l -width [string length $l]
		entry $f.e$l -textvariable LWDAQ_info_Viewer(daq_image_$l) \
			-width 4
		pack $f.l$l $f.e$l -side left
	}
	button $f.setd -text "Set Dimensions" -command \
		LWDAQ_Set_Dimensions_Viewer
	pack $f.setd -side left
	foreach l {width height} {
		label $f.l$l -text $l -width [string length $l]
		entry $f.e$l -textvariable LWDAQ_info_Viewer(daq_image_$l) \
			-width 4
		pack $f.l$l $f.e$l -side left
	}
	
	set f $w.results
	frame $f
	pack $f -side top -fill x
	button $f.setr -text "Set Results" -command \
		LWDAQ_Set_Results_Viewer
	pack $f.setr -side left
	entry $f.results -textvariable LWDAQ_info_Viewer(image_results) -width 40
	pack $f.results -side left
	foreach a {"DAQ_to_GIF" "GIF_to_DAQ"} {
		set b [string tolower $a]
		button $f.$b -text $a -command \
			[list LWDAQ_post LWDAQ_$a\_Viewer front]
		pack $f.$b -side left -expand 1
	}	
}

