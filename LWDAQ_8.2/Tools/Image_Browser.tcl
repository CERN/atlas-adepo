# Image_Browser.tcl, allows you to browse LWDAQ images on your hard drive.
# Copyright (C) 2007 Kevan Hashemi, Open Source Instruments Inc.
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

proc Image_Browser_init {} {
	upvar #0 Image_Browser_info info
	upvar #0 Image_Browser_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Image_Browser" "9"
	if {[winfo exists $info(window)]} {return 0}

	set info(initial_width) 120
	set info(initial_height) 40
	set info(control) "Idle"	

	set config(file_filter) "*.daq"
	set config(zoom) 0.3
	set config(instrument) Viewer
	set config(images_per_line) 4
	if {$LWDAQ_Info(os)=="Windows"} {
		set config(tab_spacing) 6
	} {
		set config(tab_spacing) 8
	}
	set config(tab_margin) 0.1
	set config(change_focus) 0
	set config(sort) "a_to_z"
	set config(intensify) "exact"
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1   
}

proc Image_Browser_stop {} {
	upvar #0 Image_Browser_info info
   	if {$info(control) != "Idle"} {
   		set info(control) "Stop"
		return 0
	}
	return 1
}

proc Image_Browser_choose {} {
	global LWDAQ_Info
	set d [LWDAQ_get_dir_name]
	if {$d != ""} {
		set LWDAQ_Info(working_dir) $d
		Image_Browser_refresh
	}
}

proc Image_Browser_display {file_name} {
	global LWDAQ_Info
	upvar #0 Image_Browser_config config
	set image_name [LWDAQ_read_image_file $file_name]
	set name $config(instrument)
	LWDAQ_open $name
	if {$config(change_focus)} {
		upvar #0 LWDAQ_info_$name iinfo
		focus $iinfo(window)
	}
	upvar #0 LWDAQ_config_$name iconfig
	set iconfig(image_source) "file"
	set iconfig(file_name) $file_name
	LWDAQ_acquire $name
	return 0
}

proc Image_Browser_sort {a b} {
	upvar #0 Image_Browser_config config
   	if {![file exists $a]} {return -1}
   	if {![file exists $b]} {return 1}
   	set diff [expr [file mtime $a] - [file mtime $b]]
   	if {$config(sort) == "new_to_old"} {
   		return $diff
   	}
   	if {$config(sort) == "old_to_new"} {
   		return [expr - $diff]
   	}
	if {$config(sort) == "a_to_z"} {
		return [string compare $a $b]
	}
	if {$config(sort) == "z_to_a"} {
		return [string compare $b $a]
	}
	return 0
}

proc Image_Browser_refresh {} {
	global LWDAQ_Info
	upvar #0 Image_Browser_config config
	upvar #0 Image_Browser_info info
	
	set info(control) "Refresh"

	foreach image_name [image names] {
		if {[string match "Image_Browser*" $image_name]} {
			image delete $image_name
		}
	}
	
	set w $info(window)
	if {![winfo exists $w]} {return 0}
	if {[winfo exists $w.browse]} {
		$w.browse.text delete 1.0 end
	} {
		set f $w.browse
		frame $f -border 2
		pack $f -side top -fill x
		set info(text) [LWDAQ_text_widget $f $info(initial_width) $info(initial_height)]
	}
	set tabs ""
	for {set index 0} {$index <= $config(images_per_line)} {incr index} {
		append tabs [expr $config(tab_spacing) * $index + $config(tab_margin)]
		append tabs "c "
	}
	$info(text) configure -tabs $tabs
	
	set files [glob -nocomplain [file join $LWDAQ_Info(working_dir) $config(file_filter)]]
	set files [lsort -command Image_Browser_sort $files]
	set index 0
	set saved_names ""
	foreach f $files {
		if {[file exists $f]} {
			incr index
			image create photo Image_Browser$index
			if {[catch {set image_name [LWDAQ_read_image_file $f]} error_result]} {
				set image_name [lwdaq_image_create -width 100 -height 100 ]
			}
			lwdaq_draw $image_name Image_Browser$index \
				-zoom $config(zoom) -intensify $config(intensify)
			lwdaq_image_destroy $image_name
			$info(text) insert end "\t"
			button $info(text)\.b$index -image Image_Browser$index \
				-command "Image_Browser_display $f"
			$info(text) window create end -window $info(text)\.b$index
			lappend saved_names [file tail $f]
			if {[expr $index % $config(images_per_line)] == 0} {
				LWDAQ_print $info(text) 
				foreach n $saved_names {
					LWDAQ_print -nonewline $info(text) "\t$n" blue
				}
				LWDAQ_print $info(text) "\n"
				set saved_names ""
			}
		}
		if {$info(control) == "Stop"} {
			break
		}
		if {![winfo exists $w]} {return 0}
	}
	LWDAQ_print $info(text)
	foreach n $saved_names {
		LWDAQ_print -nonewline $info(text) "\t$n" blue
	}
	set info(control) "Idle"
	return 1
}

proc Image_Browser_open {} {
	upvar #0 Image_Browser_config config
	upvar #0 Image_Browser_info info
	global LWDAQ_Info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.controls
	frame $f -border 2
	pack $f -side top -fill x
	label $f.state -textvariable $info(name)_info(control) -width 12 -fg blue
	pack $f.state -side left -expand 1
	foreach a {Stop Refresh} {
		set b [string tolower $a]
		button $f.$b -text $a -command Image_Browser_$b
		pack $f.$b -side left -expand 1
	}
	foreach a {Help Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Image_Browser"
		pack $f.$b -side left -expand 1
	}
	label $f.analysis -text "Analysis:" -width 10
	pack $f.analysis -side left -expand 1
	tk_optionMenu $f.instrument Image_Browser_config(instrument) "Viewer"
	pack $f.instrument -side left -expand 1
	foreach i $LWDAQ_Info(instruments) {
		$f.instrument.menu add command \
			-label $i -command "set Image_Browser_config(instrument) $i"
	}
	
	set f $w.files
	frame $f -border 2
	pack $f -side top -fill x
	label $f.l -text "Directory"
	entry $f.e -textvariable LWDAQ_Info(working_dir) \
		-relief sunken -bd 1 -width 40
	button $f.b -text "Choose" -command [list Image_Browser_choose]
	pack $f.l $f.e $f.b -side left -expand 1
	label $f.fl -text "Filter"
	entry $f.fe -textvariable Image_Browser_config(file_filter) \
		-relief sunken -bd 1 -width 15
	pack $f.fl $f.fe -side left -expand 1
	label $f.tsort -text "Sort:" -width 6
	pack $f.tsort -side left -expand 1
	tk_optionMenu $f.msort Image_Browser_config(sort) "a_to_z"
	pack $f.msort -side left -expand 1
	foreach s {a_to_z z_to_a new_to_old old_to_new} {
		$f.msort.menu add command \
			-label $s -command "set Image_Browser_config(sort) $s"
	}

	return 1
}

proc Image_Browser_cleanup {} {
	upvar #0 Image_Browser_info info
	
	if {![winfo exists $info(window)]} {
		foreach image_name [image names] {
			if {[string match "Image_Browser*" $image_name]} {
				image delete $image_name
			}
		}
	} {
		after 1000 Image_Browser_cleanup
	}
}

Image_Browser_init
Image_Browser_open
Image_Browser_refresh
Image_Browser_cleanup
	
return 1

----------Begin Help----------

The Image_Browser displays all files in the LWDAQ working directory
that match the browser's file_filter variable. You choose the working
directory with the Choose button, and you set the filter with the file
filter text entry box. You can use * and ? characters for file name
matching. The "*" is a string wildcard, and the "?" is a character
wildcard. When you change the file filter, press Refresh to update the
display. The display refreshes automatically after you select a new
directory.

The Image_Browser displays images in any format supported by the
LWDAQ_read_image_file routine. When you ask it to display a file that does not
match one of these formats, the browser creates a small blank image and displays
that instead. You will see a red error message in the TCLTK console for each
such file the browser tries to open.

The browser displays images in a text widget. Each image is an
embedded label in the text, like a bullet or a smiley-face, only
bigger. After each image is a tab character. We set the tab spacing
for the text widget so that the images are spaced in a pleasing and
regular manner, and so that the image names, which occupy the text
line beneath each line of images, do not overlap.

You can set the tab spacing with the config(tab_spacing) variable.
According to the TK manual, the units of tab_spacing are centimeters.
But we find that this is not the case in practice. We set the default
tab values according to platform (Windows, Linux, etc), but we expect
you will have to modify them afterwards.

By default, each image the browser displays is a fraction of its
natural size on the screen. The config(zoom) variable tells the
browser what this fraction should be. With zoom=0.3, the browser will
fit the image into a rectangle with only 30% the number of columns and
rows as the original image, and therefore only 10% of the pixels in
total. For more details about zoom, see the LWDAQ Command Reference
(Google lwdaq_draw). Note that you increase zoom, you may need to
increase the tab_spacing also, to accommodate the larger images.

If you click on an image, the browser will open an instrument window,
display the image in the instrument window, and analyze the image
(provided that you have analysis_enable not equal to zero in the
instrument configuration array). Which instrument the browser uses to
display and analyze the image is determined by the option menu on the
top left of the browser tool bar.

When the browser displays images, it sorts them in one of four orders:
a_to_z, z_to_a, new_to_old, or old_to_new, depending upon the option
menu on the bottom left of the browser tool bar.


Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
