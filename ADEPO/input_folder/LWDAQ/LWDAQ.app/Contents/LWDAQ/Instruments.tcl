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
# Instruments.tcl contains the routines that set up the common
# foundations upon which all LWDAQ instruments are built.

#
# LWDAQ_instruments_init initializes the instruments routines.
#
proc LWDAQ_instruments_init {} {
	upvar #0 LWDAQ_Info info
	set info(num_lines_keep) 1000
	set info(line_purge_period) 100
	set info(max_daq_attempts) 5
	set info(num_daq_errors) 0
	set instrument_files [glob [file join $info(instruments_dir) *.tcl]]
	set info(instruments) [list]
	foreach i $instrument_files {
		lappend info(instruments) [lindex [split [file tail $i] .] 0]
	}
	set info(instruments) [lsort -dictionary $info(instruments)]
	foreach i $instrument_files {source $i}
	foreach i $info(instruments) {LWDAQ_init_$i}
	return 1
}

#
# LWDAQ_reset_instrument_counters sets all the counters to 
# the specifiec value, or to 1 if no value is specified.
#
proc LWDAQ_reset_instrument_counters {{value 0}} {
	upvar #0 LWDAQ_Info info
	foreach e $info(instruments) {
		upvar #0 LWDAQ_info_$e info_instr
		set info_instr(counter) $value
	}
}

#
# LWDAQ_info_button makes a new toplevel window with
# a button that lets you see the instrument script. Below
# the button are the elements of the instrument's info
# array. You can change the elements by typing in the
# entry boxes.
#
proc LWDAQ_info_button {name} {
	upvar #0 LWDAQ_info_$name info
	global LWDAQ_Info
	
	# Create the info windoe.
	set w $info(window)\.info
	if {[winfo exists $w]} {destroy $w}
	toplevel $w
	wm title $w "$info(name) Info Array"
	
	# Make three frames: one for buttons and two for entries.
	frame $w.buttons
	pack $w.buttons -side top -fill x
	frame $w.f1
	frame $w.f2
	pack $w.f1 $w.f2 -side left -fill y
	
	# Make the script button
	button $w.buttons.script -text "Script" -command \
		[list LWDAQ_view_text_file [file join $LWDAQ_Info(instruments_dir) $info(name)\.tcl]]
	pack $w.buttons.script -side left -expand 1
	
	# Call the info buttons creation routine, if it exists, passing it
	# the name of the buttons frame.
	if {[info commands LWDAQ_infobuttons_$name] != ""} {
		LWDAQ_infobuttons_$name $w.buttons
	}
	
	# List the info variables in the window and associate each with a text entry.
	set info_list [lsort -dictionary [array names info]]
	set count 0
	set half [expr [llength $info_list] / 2]
	set label_width 0
	foreach l $info_list {
		if {[string length $l] > $label_width} {
			set label_width [string length $l]
		}
	}
	foreach i $info_list {
		incr count
		if {$count > $half} {set f f2} {set f f1}
		label $w.$f.l$i -text $i -anchor w -width $label_width
		entry $w.$f.e$i -textvariable LWDAQ_info_$info(name)\($i) \
			-relief sunken -bd 1 -width 30
		grid $w.$f.l$i $w.$f.e$i -sticky news
	}
	
	# Return the name of the window.
	return $w
}

#
# LWDAQ_write_button writes the current image to disk
#
proc LWDAQ_write_button {name} {
	upvar #0 LWDAQ_info_$name info
	upvar #0 LWDAQ_config_$name config
	global LWDAQ_Info
	if {$info(control) == "Idle"} {
		if {[lwdaq_image_exists $config(memory_name)] != ""} {
			set f [LWDAQ_put_file_name $config(memory_name)\.daq]
			if {$f == ""} {return 0}
			LWDAQ_write_image_file $config(memory_name) $f 
		} {
			LWDAQ_print $info(text) \
				"ERROR: Image '$config(memory_name)' does not exist."
			return 0
		}
	}
	return 1
}

#
# LWDAQ_read_button reads an image from disk. It allows the user
# to specify multiple files, and opens them one after another.
#
proc LWDAQ_read_button {name} {
	upvar #0 LWDAQ_info_$name info
	upvar #0 LWDAQ_config_$name config
	if {$info(control) == "Idle"} {
		set fl [LWDAQ_get_file_name 1]
		if {$fl == ""} {return 0}
		set config(image_source) "file"
		set config(file_name) $fl
		LWDAQ_post [list LWDAQ_acquire $name]
	}
	return 1
}
 
#
# LWDAQ_acquire_button is for use with instrument acquire buttons.
#
proc LWDAQ_acquire_button {name} {
	upvar #0 LWDAQ_info_$name info
	if {$info(control) == "Idle"} {
		set info(control) "Acquire"
		LWDAQ_post [list LWDAQ_acquire $info(name)]
	}
	if {$info(control) == "Loop"} {
		set info(control) "Acquire"
	}
}
 
#
# LWDAQ_loop_button is for use with instrument loop buttons.
#
proc LWDAQ_loop_button {name} {
	upvar #0 LWDAQ_info_$name info
	if {$info(control) == "Idle"} {
		set info(control) "Loop"
		LWDAQ_post [list LWDAQ_acquire $info(name)]
	} 
	if {$info(control) == "Acquire"} {
		set info(control) "Loop"
		LWDAQ_post [list LWDAQ_acquire $info(name)]
	} 
}

#
# LWDAQ_stop_button is for use with instrument stop buttons.
#
proc LWDAQ_stop_button {name} {
	upvar #0 LWDAQ_info_$name info
	if {$info(control) != "Idle"} {set info(control) "Stop"}
}

#
# LWDAQ_stop_instruments stops all looping instruments.
#
proc LWDAQ_stop_instruments {} {
	global LWDAQ_Info
	foreach i $LWDAQ_Info(instruments) {
		LWDAQ_stop_button $i
	}
	return 1
}

#
# LWDAQ_instrument_print prints the result of analysis to an instrument
# text window using LWDAQ_print. If the verbose_result is set in the
# instrument's config array, then the routine uses the verbose_description
# list in the info array to describe each element of the result on
# on separate lines. We intend for this routine to be used only for
# printing instrument results in the instrument window. If you want
# to print anything else in the instrument window, use LWDAQ_print with
# the text window name $info(text). The info(text) element is set even
# if the instrument window is not open, and LWDAQ_print checks to
# see if the text window exists before it prints.
#
proc LWDAQ_instrument_print {instrument s {color black}} {
	upvar #0 LWDAQ_info_$instrument info
	upvar #0 LWDAQ_config_$instrument config
	if {![winfo exists $info(window)]} {return 0}
	if {(![LWDAQ_is_error_result $s]) && ($config(verbose_result) != 0)} {
		set verbose "\n[lindex $s 0]\n"
		set s [lreplace $s 0 0]
		for {set i 0} {$i < [llength $s]} {incr i} {
			set k [expr $i % [llength $info(verbose_description)]]
			set value [lindex $s $i]
			if {$value == ""} {set value "\"$value\""}
			append verbose "[lindex $info(verbose_description) $k]: $value\n"
		}
		set s $verbose
	}
	LWDAQ_print $info(text) $s $color
	return 1
}

#
# LWDAQ_instrument_analyze calls an instrument's analysis 
# routine after checking its analysis_enable flag, and catches errors 
# from the analysis routine. It assumes that the image it is to analyze
# is the image named in the instrument's memory_name parameter. The 
# routine places an identifier in the result, as provided by
# the id parameter. By default, id becomes the memory name. The 
# routine also prints the result to the panel text window.
#
proc LWDAQ_instrument_analyze {instrument {id ""}} {
	upvar #0 LWDAQ_info_$instrument info
	upvar #0 LWDAQ_config_$instrument config

	if {$id == ""} {set id $config(memory_name)}

	if {![string is integer -strict $config(analysis_enable)]} {
		set result "ERROR: Expected integer for analysis_enable,\
			got \"$config(analysis_enable)\"."
		LWDAQ_instrument_print $info(name) $result
		set analyze 0
	} {
		set result ""
		set analyze $config(analysis_enable)
	}

	if {$analyze} {
		if {[catch {
			set result [LWDAQ_analysis_$info(name) $config(memory_name)]
			if {![LWDAQ_is_error_result $result]} {
				set result "$id $result"
			} {
				set result [string replace $result end end]
				set result "$result on $id\."			
			}
		} error_report]} {
			set result "ERROR: $error_report"
		}
		LWDAQ_instrument_print $info(name) $result
	} {
		lwdaq_image_manipulate $config(memory_name) none -clear 1
	}


	if {[winfo exists $info(window)]} {
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
	
	return $result
}

#
# LWDAQ_acquire acquires data for the instrument called $instrument
# from either a file, or an existing image in memory, or 
# directly from the daq. It returns a result string.
#
proc LWDAQ_acquire {instrument} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_$instrument info
	upvar #0 LWDAQ_config_$instrument config

	if {![info exists info]} {
		error "No instrument called \"$instrument\"."
	}
	if {$info(control) == "Stop"}  {
		set info(control) "Idle"
		return
	}
	if {$info(control) == "Idle"} {
		set info(control) "Acquire"
		if {[winfo exists $info(window)]} {
			LWDAQ_update
		}
	}
	
	if {[winfo exists $info(window)]} { 
		set saved_lwdaq_config [lwdaq_config]
		lwdaq_config -text_name $info(text) -photo_name $info(photo)
		if {[expr $info(counter) % $LWDAQ_Info(line_purge_period)] == 0} {
			$info(text) delete 1.0 "end [expr 0 - $LWDAQ_Info(num_lines_keep)] lines"
		}
	}
	
	incr info(counter) 
	set result ""
	set match 0
	
	if {[string match "file" $config(image_source)]} {
		set match 1
		set image_list ""
		if {[llength $config(file_name)] > 1} {
			set image_list $config(file_name)
			set restore_file_name ""
		} {
			set image_list [glob -nocomplain [lindex $config(file_name) 0]]
			set restore_file_name $config(file_name)
		}
		foreach f $image_list {
			if {$info(control) == "Stop"} {break}
			set config(file_name) $f
			if {$f != [lindex $image_list 0]} {
				incr info(counter)
				append result "\n"
			}
			if {![file exists $f]} {
				lappend result "ERROR: Cannot find file \"$f\"."
				continue
			}
			if {$info(delete_old_images)} {lwdaq_image_destroy $info(name)\*}
			set config(memory_name) [LWDAQ_read_image_file $f $info(name)\_$info(counter)]
			if {$info(file_use_daq_bounds)} {
				lwdaq_image_manipulate $config(memory_name) none \
					-left $info(daq_image_left) \
					-top $info(daq_image_top) \
					-right $info(daq_image_right) \
					-bottom $info(daq_image_bottom) \
					-results ""
			}	
			lappend result [LWDAQ_instrument_analyze $info(name) [file tail $f]]
			if {[llength $image_list] > 1} {LWDAQ_update}
		}
		if {[llength $image_list] == 0} {
			set result "ERROR: No files match $config(file_name)"
			LWDAQ_print $info(text) $result
		}
		if {[llength $image_list] == 1} {
			set result [join $result]
		}
		if {$restore_file_name != ""} {
			set config(file_name) $restore_file_name
		}
	}
		
	if {([string match "daq" $config(image_source)]) ||
			($info(name) == $config(image_source))} {
		set match 1
		set success 0
		set error_counter 0
		set daq_result "ERROR: Acquisition aborted."
		if {$info(delete_old_images)} {lwdaq_image_destroy $info(name)\*}
		while {!$success && \
				($error_counter < $LWDAQ_Info(max_daq_attempts)) \
				&& !$LWDAQ_Info(reset)} {
			if {$info(daq_extended) && [info commands LWDAQ_extended_$info(name)] != ""} {
				set daq_result [LWDAQ_extended_$info(name)]
			} {
				set daq_result [LWDAQ_daq_$info(name)]
			}
			if {[LWDAQ_is_error_result $daq_result]} {
				incr error_counter
				incr LWDAQ_Info(num_daq_errors)
				if {[winfo exists $info(window)]} {$info(state_label) config -fg red} 
				LWDAQ_random_wait_ms 0 $LWDAQ_Info(daq_wait_ms)
			} {
				set success 1
			}
			if {$info(control) == "Stop"} {break}
		}
		if {[winfo exists $info(window)]} {$info(state_label) config -fg black} 
		if {$success} {
			set result [LWDAQ_instrument_analyze $info(name)]
		} {
			set result $daq_result
			LWDAQ_instrument_print $info(name) $result
		} 
	}
	
	if {[string match "memory" $config(image_source)]} {
		set match 1
		if {[lwdaq_image_exists $config(memory_name)] != ""} {
			set result [LWDAQ_instrument_analyze $info(name)]
		} {
			set result "ERROR: Image '$config(memory_name)' does not exist."
			LWDAQ_print $info(text) $result 
		}
	}
	
	if {([lsearch $LWDAQ_Info(instruments) $config(image_source)] >= 0)
			&& ($info(name) != $config(image_source))} {
		set match 1
		set iresult [LWDAQ_acquire $config(image_source)]
		if {[LWDAQ_is_error_result $iresult]} {
			set result $iresult
		} {
			upvar #0 LWDAQ_config_$config(image_source) iconfig
			set config(memory_name) $iconfig(memory_name)
			set result [LWDAQ_instrument_analyze $info(name)]
		}
	}
	
	if {!$match} {
		LWDAQ_print $info(text) "ERROR: no such image source, \"$config(image_source)\"." red	
	}
	
	if {$info(control) == "Loop"} {
		if {[winfo exists $info(window)]} {
			LWDAQ_post [list LWDAQ_acquire $info(name)]
		} {
			set info(control) "Idle"
		}
	}
	if {$info(control) == "Acquire"} {
		set info(control) "Idle"
	}
	if {$info(control) == "Stop"}  {
		set info(control) "Idle"
	}
	
	if {[info exists saved_lwdaq_config]} {
		eval "lwdaq_config $saved_lwdaq_config"
	}

	return $result 
} 

#
# LWDAQ_open opens the named instrument's window. We recommend that you post
# this routine to the event queue, or else it will conflict with acquisitions
# from the same instrument that are taking place with the window closed.
#
proc LWDAQ_open {name} { 
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_$name info
	upvar #0 LWDAQ_config_$name config
	
	set w $info(window)
	if {[winfo exists $w]} {
		raise $w
		return 1
	}

	toplevel $w
	wm title $w $name
	set info(control) "Idle" 

	frame $w.buttons
	pack $w.buttons -side top -fill x
	label $w.buttons.state -textvariable LWDAQ_info_$name\(control) -width 8
	label $w.buttons.counter -textvariable LWDAQ_info_$name\(counter) -width 4
	button $w.buttons.acquire -text "Acquire" -command [list LWDAQ_acquire_button $name]
	button $w.buttons.loop -text "Loop" -command [list LWDAQ_loop_button $name]
	button $w.buttons.stop -text "Stop" -command [list LWDAQ_stop_button $name]
	button $w.buttons.write -text "Write" \
		-command [list LWDAQ_post [list LWDAQ_write_button $name]]
	button $w.buttons.read -text "Read" \
		-command [list LWDAQ_post [list LWDAQ_read_button $name]]
	button $w.buttons.info -text "Info" -command [list LWDAQ_info_button $name]
	pack $w.buttons.state $w.buttons.counter $w.buttons.acquire $w.buttons.loop \
		$w.buttons.stop $w.buttons.write $w.buttons.read $w.buttons.info -side left -expand 1
	set info(state_label) $info(window).buttons.state
		
	frame $w.ic
	pack $w.ic -side top -fill x
	
	frame $w.ic.i
	pack $w.ic.i -side left -fill y
	image create photo $info(photo)
	label $w.ic.i.image -image $info(photo)
	pack $w.ic.i.image -side left
	
	frame $w.ic.c
	pack $w.ic.c -side right -fill y
	
	# List the config variables in the window and associate each with a text entry.
	set config_list [array names config]
	set config_list [lsort -dictionary $config_list]
	foreach c $config_list {
		label $w.ic.c.l$c -text $c -anchor w
		entry $w.ic.c.e$c -textvariable LWDAQ_config_$name\($c) \
			-relief sunken -bd 1 -width 25
		grid $w.ic.c.l$c $w.ic.c.e$c -sticky news
	}

	# Call the instrument's controls creation routine, if it exists.
	if {[info commands LWDAQ_controls_$name] != ""} {
		LWDAQ_controls_$name
	}

	# Make the text output window. We don't enable text undo because this gets us 
	# into trouble when we write a lot of text to the instrument window while running
	# for a long time.
	set info(text) [LWDAQ_text_widget $w 90 10 1 1]

	return 1
}

#
# LWDAQ_close closes the window of the named instrument.
#
proc LWDAQ_close {name} {
	upvar #0 LWDAQ_info_$name info
	catch {destroy $info(window)}
}
