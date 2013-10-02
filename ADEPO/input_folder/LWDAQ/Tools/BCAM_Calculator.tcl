# BCAM_Calculator, a Standard and Polite LWDAQ Tool
# Copyright (C) 2004, 2005, 2006 Kevan Hashemi, Brandeis University
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
# Version 20: Add support for JK plates.
#

proc BCAM_Calculator_init {} {
	upvar #0 BCAM_Calculator_info info
	upvar #0 BCAM_Calculator_config config
	global LWDAQ_Info
	
	LWDAQ_tool_init "BCAM_Calculator" "22"
	if {[winfo exists $info(window)]} {return 0}
	
	set info(apparatus_database) ""
	set info(calibration_database) ""

	set config(apparatus_database_file) "apparatus_database.txt"
	set config(calibration_database_file) "calibration_database.txt"
	set config(verbose_output) 0
	set config(remove_warnings) 1
	set config(remove_good_ones) 0
	set config(check) 1
	set config(device_id) "*"
	set config(calibration_time) "*"
	set config(calibration_type) "*"
	set config(apparatus_version) "*"
	set config(operator_name) "*"
	set config(print_device_id) 1
	set config(print_calibration_time) 1
	set config(print_calibration_type) 0
	set config(print_apparatus_version) 0
	set config(print_operator_name) 0
	set config(title_color) purple
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	set info(control) "Idle"
	set info(state) "Start"
	set info(counter) 0
	
	return 1	
}

proc BCAM_Calculator_stop {} {
	upvar #0 BCAM_Calculator_info info
	if {$info(control) != "Idle"} {
		set info(control) "Stop"
	}
}

proc BCAM_Calculator_get_param {entry name} {
	if {![regexp -nocase "$name\:\[ \]*(\[^\n \]*)" $entry match value]} {return ""}
	return $value
}

proc BCAM_Calculator_matching_am {dc} {
	upvar #0 BCAM_Calculator_info info
	set match ""
	foreach am $info(apparatus_database) {
		if {([BCAM_Calculator_get_param $dc calibration_type] == \
				[BCAM_Calculator_get_param $am calibration_type]) \
			&& ([BCAM_Calculator_get_param $dc apparatus_version] == \
				[BCAM_Calculator_get_param $am apparatus_version]) } {
			set match $am
		}
	}
	return $match
}

proc BCAM_Calculator_repeat_dc {dc1 dc2} {
	if {([BCAM_Calculator_get_param $dc1 device_id] == \
			[BCAM_Calculator_get_param $dc2 device_id]) \
		&& ([BCAM_Calculator_get_param $dc1 calibration_type] == \
			[BCAM_Calculator_get_param $dc2 calibration_type])} {
		return 1
	} {
		return 0
	}
}

proc BCAM_Calculator_duplicate_dc {dc1 dc2} {
	if {([BCAM_Calculator_get_param $dc1 device_id] == \
			[BCAM_Calculator_get_param $dc2 device_id]) \
		&& ([BCAM_Calculator_get_param $dc1 calibration_type] == \
			[BCAM_Calculator_get_param $dc2 calibration_type]) \
		&& ([BCAM_Calculator_get_param $dc1 calibration_time] == \
			[BCAM_Calculator_get_param $dc2 calibration_time]} {
		return 1
	} {
		return 0
	}
}

proc BCAM_Calculator_update {} {
	upvar #0 BCAM_Calculator_info info
	upvar #0 BCAM_Calculator_config config
	incr info(counter)
	if {[expr $info(counter) % 100] == 0} {
		LWDAQ_print -nonewline $info(text) "."
		LWDAQ_update
		return 1
	} {
		return 0
	}
}

proc BCAM_Calculator_sort_dc {dc1 dc2} {
	set sort [string compare -nocase \
		[BCAM_Calculator_get_param $dc1 device_id] \
		[BCAM_Calculator_get_param $dc2 device_id]]
	if {$sort != 0} {return $sort}
	set sort [string compare -nocase \
		[BCAM_Calculator_get_param $dc1 calibration_type] \
		[BCAM_Calculator_get_param $dc2 calibration_type]]
	if {$sort != 0} {return $sort}
	set sort [string compare -nocase \
		[BCAM_Calculator_get_param $dc1 calibration_time] \
		[BCAM_Calculator_get_param $dc2 calibration_time]]
	BCAM_Calculator_update
	return $sort
}

proc BCAM_Calculator_select_dc {} {
	upvar #0 BCAM_Calculator_info info
	upvar #0 BCAM_Calculator_config config
	LWDAQ_print -nonewline $info(text) "Selecting..."
	set match_list ""
	set time_selector $config(calibration_time)
	if {$time_selector == "last"} {set time_selector "*"}
	foreach a $info(calibration_database) {
		if {[string match -nocase $config(device_id) \
				[BCAM_Calculator_get_param $a device_id]] &&
			[string match -nocase $config(calibration_type) \
				[BCAM_Calculator_get_param $a calibration_type]] &&
			[string match -nocase $config(apparatus_version) \
				[BCAM_Calculator_get_param $a apparatus_version]] &&
			[string match -nocase $config(operator_name) \
				[BCAM_Calculator_get_param $a operator_name]] &&
			[string match -nocase $time_selector \
				[BCAM_Calculator_get_param $a calibration_time]]} {
			lappend match_list $a
			BCAM_Calculator_update
			if {$info(control) == "Stop"} {
				LWDAQ_print $info(text) "\nWARNING: Selection aborted."
				return ""
			}
		}
	}
	if {[llength $match_list] == 0} {return ""}
	set index [expr [lsearch [lindex $match_list 0] "device_id:"] + 1]
	set match_list [lsort -command BCAM_Calculator_sort_dc $match_list]
	if {($config(calibration_time) == "last")} {
		set i 0
		set new_match_list [list]
		for {set i 0} {$i < [expr [llength $match_list] - 1]} {incr i} {
			if {![BCAM_Calculator_repeat_dc \
					[lindex $match_list $i] \
					[lindex $match_list [expr $i + 1]]]} {
				lappend new_match_list [lindex $match_list $i]
			}
			BCAM_Calculator_update
			if {$info(control) == "Stop"} {
				LWDAQ_print $info(text) "\nWARNING: Selection aborted."
				return ""
			}
		}
		lappend new_match_list [lindex $match_list end]
		set match_list $new_match_list
	}
	LWDAQ_print $info(text) "done."
	return $match_list
}

proc BCAM_Calculator_print_result {dc s} {
	upvar #0 BCAM_Calculator_config config
	upvar #0 BCAM_Calculator_info info
	set line ""
	if {!$config(verbose_output)} {
		foreach p {device_id calibration_time calibration_type \
				apparatus_version operator_name} {
			if {$config(print_$p)} {
				append line [BCAM_Calculator_get_param $dc $p]
				append line " "
			}
		}
	}
	append line $s
	set w [string first "WARNING: " $line]
	if {$w > 0} {
		if {$config(remove_warnings)} {
			set line [string replace $line $w end]
			set line [string trim $line]
		}
		LWDAQ_print $info(text) "$line" blue
	} {
		if {!$config(remove_good_ones)} {
			LWDAQ_print $info(text) $line black
		}
	}
	LWDAQ_support
	return 1
}

proc BCAM_Calculator_ct_change {ct} {
	upvar #0 BCAM_Calculator_config config
	upvar #0 BCAM_Calculator_info info
	set config(calibration_type) $ct
	if {$info(apparatus_database) == ""} {return}
	set available [list]
	foreach b $info(apparatus_database) {
		if {[BCAM_Calculator_get_param $b calibration_type] \
				== $config(calibration_type)} {
			lappend available [BCAM_Calculator_get_param \
				$b apparatus_version]
		}
	}	
	$info(apparatus_version_menu) delete 0 100
	$info(apparatus_version_menu) add command \
			-label * -command "set BCAM_Calculator_config(apparatus_version) *"
	foreach b $available {
		$info(apparatus_version_menu) add command \
			-label $b -command \
			[list set BCAM_Calculator_config(apparatus_version) $b]
	}	
	set config(apparatus_version) "*"
}

proc BCAM_Calculator_parse {database} {
	set database [regsub -all {\{.+?\}} $database ""]
	set database [regsub -all {end\.\n} $database "end.\n~"]
	set parsed [split $database ~]
	return [lrange $parsed 0 end-1]
}

proc BCAM_Calculator_load {} {
	upvar #0 BCAM_Calculator_config config
	upvar #0 BCAM_Calculator_info info

	if {$info(control) != "Idle"} {
		LWDAQ_print $info(text) "ERROR: Cannot load until 'Idle'."
		return 0
	}
	set info(control) "Load"
	LWDAQ_update

	if {![file exists $config(calibration_database_file)]} {
		LWDAQ_print $info(text) \
			"ERROR: Can't find calibration database."
		set info(control) "Idle"
		return 0
	}
	
	set f [open $config(calibration_database_file) r]
	set dc [read $f]
	close $f

	set info(calibration_database) [BCAM_Calculator_parse $dc]

	LWDAQ_print $info(text) ""
	LWDAQ_print $info(text) "Calibration Database:" $config(title_color)
	LWDAQ_print $info(text) "num_entries: [llength $info(calibration_database)]"		

	if {![file exists $config(apparatus_database_file)]} {
		LWDAQ_print $info(text) \
			"ERROR: Can't find apparatus database."
		set info(control) "Idle"
		return 0
	}

	set f [open $config(apparatus_database_file) r]
	set am [read $f]
	close $f

	set info(apparatus_database) [BCAM_Calculator_parse $am]

	LWDAQ_print $info(text) ""
	LWDAQ_print $info(text) "Apparatus Database:" $config(title_color)
	LWDAQ_print $info(text) "num_entries: [llength $info(apparatus_database)]"		

	set available ""
	foreach b $info(apparatus_database) {
		set ct [BCAM_Calculator_get_param $b calibration_type]
		if {($ct != "") && ([lsearch $available $ct] < 0)} {
			lappend available $ct
		}
	}
	if {[llength $available] == 0} {
		LWDAQ_print $info(text) \
			"ERROR: No valid entries in apparatus database."
		set info(control) "Idle"
		return 0
	}
	$info(calibration_type_menu) delete 0 100
	foreach b $available {
		$info(calibration_type_menu) add command \
			-label $b -command "BCAM_Calculator_ct_change $b"
	}
	$info(apparatus_version_menu) delete 0 100
	$info(apparatus_version_menu) add command \
			-label * -command "set BCAM_Calculator_config(apparatus_version) *"
	set info(control) "Idle"
	return 1
}

proc BCAM_Calculator_calculate {} {
	upvar #0 BCAM_Calculator_config config
	upvar #0 BCAM_Calculator_info info

	if {$info(control) != "Idle"} {
		LWDAQ_print $info(text) "ERROR: Cannot calculate until 'Idle'."
		return 0
	}

	set info(control) "Select"
	LWDAQ_print $info(text) ""
	LWDAQ_print $info(text) "Selection Criteria:" $config(title_color)
	LWDAQ_print $info(text) "calibration_type: $config(calibration_type)"
	LWDAQ_print $info(text) "apparatus_version: $config(apparatus_version)"
	LWDAQ_print $info(text) "operator_name: $config(operator_name)"
	LWDAQ_print $info(text) "device_id: $config(device_id)"
	LWDAQ_print $info(text) "calibration_time: $config(calibration_time)"
	LWDAQ_update
	
	set selected [BCAM_Calculator_select_dc]
	if {$info(control) == "Stop"} {
		LWDAQ_print $info(text) "WARNING: Calculation aborted."
		set info(control) "Idle"
		return 0
	}

	set number [llength $selected]
	if {$number == 0} {
		LWDAQ_print $info(text) \
			"WARNING: No device calibrations matched your criteria."
		set info(control) "Idle"
		return 0
	}
	LWDAQ_print $info(text) "Found $number matching device calibrations:"
	LWDAQ_print $info(text) ""
	LWDAQ_print $info(text) "Parameter Calculations:" $config(title_color)
	
	set info(control) "Calculate"
	LWDAQ_update
	set saved_lwdaq_config [lwdaq_config]
	lwdaq_config -text_name $info(text) 
	foreach dc $selected {
		set am [BCAM_Calculator_matching_am $dc]
		set result [lwdaq_calibration $dc $am \
			-verbose $config(verbose_output) \
			-check $config(check)]
		if {[LWDAQ_is_error_result $result]} {
			LWDAQ_print $info(text) $result
			LWDAQ_print $info(text) "Encountered with device\
				\"[BCAM_Calculator_get_param $dc device_id]\", \
				calibration type \"[BCAM_Calculator_get_param $dc device_id]\",\
				apparatus version \"[BCAM_Calculator_get_param $am apparatus_version]\"."
			break
		}
		BCAM_Calculator_print_result $dc $result
		if {$info(control) != "Calculate"} {
			LWDAQ_print $info(text) "WARNING: Calculation aborted."
			break
		}
	}
	eval "lwdaq_config $saved_lwdaq_config"		
	LWDAQ_print $info(text) "Done." $config(title_color)
	set info(control) "Idle"
	return 1
}

proc BCAM_Calculator_add {} {
	upvar #0 BCAM_Calculator_config config
	upvar #0 BCAM_Calculator_info info

	if {$info(control) != "Idle"} {
		LWDAQ_print $info(text) "ERROR: Cannot calculate until 'Idle'."
		return 0
	}
	set info(control) "Read"
	LWDAQ_update
	
	if {![file exists $config(calibration_database_file)]} {
		LWDAQ_print $info(text) "ERROR: Can't find calibration database."
		set info(control) "Idle"
		return 0
	}
	
	set f [open $config(calibration_database_file) r]
	set dc [read $f]
	close $f

	set info(calibration_database) [BCAM_Calculator_parse $dc]

	LWDAQ_print $info(text) ""
	LWDAQ_print $info(text) "Add Calibration Measurements" $config(title_color)
	LWDAQ_print $info(text) "Number of existing entries: [llength $info(calibration_database)]"		

	set f [LWDAQ_get_file_name]
	if {$f == ""} {
		LWDAQ_print $info(text) "WARNING: Addition of measurements canceled."
		set info(control) "Idle"
		return 0
	}

	set ff [open $f r]
	set new [read $ff]
	close $ff

	set new_database [BCAM_Calculator_parse $new]
	LWDAQ_print $info(text) "Number of entries in addition file: [llength $new_database]"		

	set info(control) "Sort"
	LWDAQ_update
	
	set num_added 0
	set index 0
	foreach n $new_database {
		LWDAQ_support
		set ct [BCAM_Calculator_get_param $n calibration_time]
		set duplicate [regexp $ct $info(calibration_database) match]
		incr index
		if {$duplicate} {
			LWDAQ_print $info(text) "$index\: Duplicate, will ignore."
		} {
			LWDAQ_print $info(text) "$index\: Unique, will add." blue
			incr num_added
			lappend info(calibration_database) $n
		}
		if {$info(control) != "Sort"} {
			LWDAQ_print $info(text) "WARNING: Addition of measurements aborted."
			set info(control) "Idle"
			return 0
		}
	}

	LWDAQ_print $info(text) "Found $num_added new measurements."		
	
	if {$num_added > 0} {
		LWDAQ_support
		set info(control) "Write"
		set ff [open $config(calibration_database_file) w]
		foreach m $info(calibration_database) {
			puts $ff "[string trim $m]\n"
		}
		close $ff	
		LWDAQ_print $info(text) "Appended $num_added measurements to calibration database file."		
	}
	
	LWDAQ_print $info(text) "Done." $config(title_color)
	
	set info(control) "Idle"	
	return 1
}

proc BCAM_Calculator_open {} {
	upvar #0 BCAM_Calculator_config config
	upvar #0 BCAM_Calculator_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	label $f.control -textvariable BCAM_Calculator_info(control) -width 10 -fg blue
	pack $f.control -side left
	
	foreach a {Load Calculate} {
		set b [string tolower $a]
		button $f.$b -text $a -command [list LWDAQ_post "BCAM_Calculator_$b" front]
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	foreach a {Stop} {
		set b [string tolower $a]
		button $f.$b -text $a -command BCAM_Calculator_$b
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	foreach a {Configure Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b BCAM_Calculator"
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	checkbutton $f.v -variable BCAM_Calculator_config(verbose_output) -text "Verbose"
	pack $f.v -side left
	
	set f $w.choose
	frame $f
	pack $f -side top -fill x
	button $f.scd -text "Select Calibration Database" -command {
		set f [LWDAQ_get_file_name]
		if {$f != ""} {set BCAM_Calculator_config(calibration_database_file) $f}
	}
	pack $f.scd -side left -expand 1
	button $f.sad -text "Select Apparatus Database" -command {
		set f [LWDAQ_get_file_name]
		if {$f != ""} {set BCAM_Calculator_config(apparatus_database_file) $f}
	}
	pack $f.sad -side left -expand 1
	button $f.acm -text "Add Calibration Measurements" \
		-command [list LWDAQ_post "BCAM_Calculator_add"]
	pack $f.acm -side left -expand 1

	
	set f $w.type_ver_id
	frame $f 
	pack $f -side top -fill x
	
	label $f.ptitle -text "Parameter:" 	
	label $f.lct -text "calibration_type"
	label $f.lav -text "apparatus_version"
	label $f.lon -text "operator_name"
	label $f.ldi -text "device_id"
	label $f.lts -text "calibration_time"

	label $f.stitle -text "Select:"
	tk_optionMenu $f.sct BCAM_Calculator_config(calibration_type) *
	set info(calibration_type_menu) $f.sct.menu
	tk_optionMenu $f.sav BCAM_Calculator_config(apparatus_version) *
	set info(apparatus_version_menu) $f.sav.menu
	tk_optionMenu $f.son BCAM_Calculator_config(operator_name) * Kevan Alex Mike Sarah Netta Jim
	tk_optionMenu $f.sdi BCAM_Calculator_config(device_id) * HBCAM* 20MABND*
	tk_optionMenu $f.sts BCAM_Calculator_config(calibration_time) * last
	
	label $f.rtitle -text "Enter:"
	entry $f.rct -textvariable BCAM_Calculator_config(calibration_type) -width 14
	entry $f.rav -textvariable BCAM_Calculator_config(apparatus_version) -width 6
	entry $f.ron -textvariable BCAM_Calculator_config(operator_name) -width 10
	entry $f.rdi -textvariable BCAM_Calculator_config(device_id) -width 14
	entry $f.rts -textvariable BCAM_Calculator_config(calibration_time) -width 14

	label $f.ctitle -text "Print:"
	checkbutton $f.cct -variable BCAM_Calculator_config(print_calibration_type)
	checkbutton $f.cav -variable BCAM_Calculator_config(print_apparatus_version) 
	checkbutton $f.con -variable BCAM_Calculator_config(print_operator_name)
	checkbutton $f.cdi -variable BCAM_Calculator_config(print_device_id) 
	checkbutton $f.cts -variable BCAM_Calculator_config(print_calibration_time) 

	grid $f.ptitle $f.ldi $f.lts $f.lct $f.lav $f.lon -padx 5 -sticky news
	grid $f.stitle $f.sdi $f.sts $f.sct $f.sav $f.son -padx 5 -sticky ew
	grid $f.rtitle $f.rdi $f.rts $f.rct $f.rav $f.ron -padx 5 -sticky ew
	grid $f.ctitle $f.cdi $f.cts $f.cct $f.cav $f.con -padx 5 -sticky ew

	set info(text) [LWDAQ_text_widget $w 100 20]
	
	return 1
}

BCAM_Calculator_init
BCAM_Calculator_open

return

The BCAM Calculator allows you to extract device calibrations from a
calibration database, combine them with apparatus measurements from an
apparatus database, and calculate calibration constants.

Your first task, when using the BCAM Calculator, is to provide it with a
text file containing measurements made during BCAM calibrations, and
another text file containing measurements of the calibration apparatus
referred to in the calibration measurements. The first of these files we
call the calibration database, and the second is the apparatus database.
You can fetch the latest versions of our databases from the following
web site.

http://alignment.hep.brandeis.edu/Devices/BCAM/

Select the files using the "Select Calibration Database" and "Select
Apparatus Databse" buttons.

The calibration database contains device calibrations made with the BCAM
Calibrator during a device calibration. Each device calibration produces
an entry in the calibration database text file. The apparatus database
contains apparatus measurements made by a combination of procedures, and
brought together into entries in a text file.

Load the calibration and apparatus databases with the "Load" button.

Specify your BCAM selection criteria using the menu buttons. These allow
you to select a subset of the device calibrations in the calibration
database. Check the "Print" boxes to tell the BCAM Calculator which of
selection criteria values to print on the output line before the
calibration parameters.

When you have made your selection, press the "Calculate" button. If your
selection is large, you will see the text window updating once every
second or so. If you want to abort the calculation, press "Abort".

By default, the BCAM Calculator prints out calibration constants on a
single line. But if you check the "Verbose" box, it prints out a full
account of the calibration calculation, and names the calibration
parameters in order.

The BCAM device calibrations contain more measurements than necessary.
The BCAM Calculator calculates calibration constants in a six different
ways, once for each of the six pairs of roll-cage orientations. If the
spread of values for any calibration constant exceeds a limit we have
hard-coded in our analysis library, the BCAM Calculator prints the
constants in orange. Otherwise it prints them in black. If you choose
the verbose output, you can examine the parameter spreads and compare
them to the hard-coded limits, which the verbose output displays along
with the average values for the six pairs.

The "Add Calibration Measurements" button allows you to add calibration
measurements to your calibration database. You specify a file containing
calibration measurements, and the BCAM Calculator goes through the file
checking each measurement to see if it matches an existing measurement
in its calibration database. If the measurement is unique, the BCAM
Calculator adds it to the end of its calibration database on disk.
Otherwise it passes on to the next calibration measurement in the file.

You can use the BCAM Calculator to find bad poor or invalid calibrations
in a large calibration database. The remove_good_ones option in the Config
array tells the calibrator to print only those calibrations that carry
warnings. If you set remove_warnings to 0, these warnings will be printed
to the screen along with the calibration constants.

