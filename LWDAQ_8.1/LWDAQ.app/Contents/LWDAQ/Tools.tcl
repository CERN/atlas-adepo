# Tool Creation and Management Software
# Copyright (C) 2005-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
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
# Tools.tcl contains routines that configure and manage polite and standard 
# LWDAQ tools. It provides the Tool Maker and Run Tool commands for the Tool
# menu.
#

#
# LWDAQ_tools_init initializes the Tools routines.
#
proc LWDAQ_tools_init {} {
	global LWDAQ_Info
	set LWDAQ_Info(quiet_update) 0
	set LWDAQ_Info(name_substitutions) "\
		daq_driver_addr daq_ip_addr\
		daq_sensor_driver_socket daq_driver_socket\
		daq_sensor_mux_socket daq_mux_socket\
		daq_sensor_element daq_device_element\
		daq_sensor_type daq_device_type\
		daq_sensor_name daq_device_name\
		daq_target_driver_socket daq_driver_socket\
		daq_target_mux_socket daq_mux_socket\
		daq_source_driver_addr daq_source_ip_addr\
		daq_source_element daq_source_device_element\
		daq_source_type daq_source_device_type\
		daq_element daq_device_element\
		memory_or_file_or_daq image_source\
		lwdaq_create_image lwdaq_image_create\
		lwdaq_draw_image lwdaq_draw\
		lwdaq_shift_rasnik lwdaq_rasnik_shift\
		lwdaq_destroy_image lwdaq_image_destroy\
		lwdaq_manipulate_image lwdaq_image_manipulate\
		LWDAQ_text_window LWDAQ_text_widget\
		LWDAQ_controller_firmware_version LWDAQ_firmware_version\
		LWDAQ_controller_hardware_version LWDAQ_hardware_version\
		LWDAQ_relay_version_read LWDAQ_software_version\
		Acquisifier_print {LWDAQ_print \$info(text)}\
		LWDAQ_relay_byte_poll LWDAQ_byte_poll\
		LWDAQ_relay_byte_read LWDAQ_byte_read\
		LWDAQ_relay_byte_write LWDAQ_byte_write\
		LWDAQ_relay_config_read LWDAQ_config_read\
		LWDAQ_relay_config_write LWDAQ_config_write\
		LWDAQ_relay_integer_write LWDAQ_integer_write\
		LWDAQ_reset_controller LWDAQ_controller_reset\
		LWDAQ_relay_login LWDAQ_login\
		LWDAQ_relay_mac_read LWDAQ_mac_read\
		LWDAQ_relay_receive_data LWDAQ_receive_data\
		LWDAQ_relay_send_message LWDAQ_send_message\
		LWDAQ_relay_shortint_write LWDAQ_shortint_write\
		LWDAQ_relay_stream_delete LWDAQ_stream_delete\
		LWDAQ_relay_stream_read LWDAQ_stream_read\
		LWDAQ_set_delay_timer_seconds LWDAQ_set_delay_seconds\
		LWDAQ_set_delay_timer_ticks LWDAQ_set_delay_ticks\
		LWDAQ_new_toplevel_window LWDAQ_toplevel_window\
		LWDAQ_new_toplevel_text_window LWDAQ_toplevel_text_window"
	return 1
}

#
# LWDAQ_read_script reads a text file, which we assume to be a LWDAQ
# tool, or some script that serves a LWDAQ tool. The routine substitutes 
# new names for obsolete names. To see the substitutions the current 
# version of the routine performs, enter LWDAQ_obsolete_names at the 
# console prompt, and it will print a list of obsolete names and their
# new values. If LWDAQ_read_script finds obsolete names, and it also
# sees that LWDAQ_Info(quiet_update) is not set, it opens a window, 
# warns the user which obsolete names the script file contains, and asks 
# if the user wants to update the script file with a new file that contains 
# the new names.
#
proc LWDAQ_read_script {{file_name ""}} {
	global LWDAQ_Info
	if {$file_name == ""} {set file_name [LWDAQ_get_file_name]}
	if {[file exists $file_name]} {
		set f [open $file_name r]
		set script [read $f]
		close $f
		set replacements ""
		foreach {old new} $LWDAQ_Info(name_substitutions) {
			if {[regsub -all $old $script $new script]} {
				append replacements "$old -> $new\n"
			}
		}
		if {($replacements != "") && ($LWDAQ_Info(quiet_update) == 0)} {
			set w [LWDAQ_toplevel_window "Obsolete Names"]
			set f [frame $w.f1]
			pack $f -side top -fill x
			set t [LWDAQ_text_widget $f 60 30]
			LWDAQ_print $t "WARNING: Found obsolete names in [file tail $file_name]."
			LWDAQ_print $t "\nLWDAQ replaced obsolete names as follows:"
			LWDAQ_print $t $replacements
			LWDAQ_print $t "\n\
				You can replace the obsolete names in your file on disk\n\
				with Update File. If you update your file, it won't be\n\
				compatible with earlier versions of LWDAQ. Instead of\n\
				updating the file, you can press Stop Warning Me, and\n\
				LWDAQ will replace obsolete names in scrips without\n\
				warning you, and leave the files unchanged." blue
			set f [frame $w.f2]
			pack $f -side top -fill x
			button $f.b1 -text "Close" -command \
				[list LWDAQ_rsr C $w $file_name $script]
			button $f.b2 -text "Update File" -command \
				[list LWDAQ_rsr UF $w $file_name $script]
			button $f.b3 -text "Stop Warning Me" -command \
				[list LWDAQ_rsr SWM $w $file_name $script]
			pack $f.b1 $f.b2 $f.b3 -side left -expand 1
			proc LWDAQ_rsr {c w fn s} {
				global LWDAQ_Info
				if {$c == "C"} {destroy $w}
				if {$c == "UF"} {
					set f [open $fn w]
					puts -nonewline $f $s
					close $f
					LWDAQ_print $w.f1.text \
						"\nObsolete names replaced in [file tail $fn]."
				}
				if {$c == "SWM"} {
					set LWDAQ_Info(quiet_update) 1
					destroy $w
				}
			}
		}
		return $script
	} {
		error "script file \"$file_name\" does not exist"
	}
}

#
# LWDAQ_obsolete_names returns a list of obsolete names and their
# new values.
#
proc LWDAQ_obsolete_names {} {
	global LWDAQ_Info
	set s ""
	foreach {old new} $LWDAQ_Info(name_substitutions) {
		if {$s != ""} {append s "\n"}
		append s "$old $new"
	}
	return $s
}

#
# LWDAQ_run_tool executes a tool script at the global scope. To
# read the tool file, the routine uses LWDAQ_read_script, which
# replaces obsolete parameter and procedure names with their
# new names. If the routine cannot find the script file, it looks
# in the Tools folder and the Tools/More folder.
#
proc LWDAQ_run_tool {{file_name ""}} {
	global LWDAQ_Info
	set fn $file_name
	if {$fn == ""} {set fn [LWDAQ_get_file_name]}
	if {$fn == ""} {return ""}
	if {![file exists $fn]} {
		set fn [file join $LWDAQ_Info(working_dir) $file_name]
		if {![file exists $fn]} {
			set fn [file join $LWDAQ_Info(tools_dir) $file_name]
			if {![file exists $fn]} {
				set fn [file join $LWDAQ_Info(tools_dir) More $file_name]
				if {![file exists $fn]} {
					error "cannot find tool file \"$file_name\""
				}
			}
		}
	}
	set script [LWDAQ_read_script $fn]
	if {$script != ""} {uplevel #0 $script}
	return $fn
}

#
# LWDAQ_tool_startup initializes the tool directory and file variables.
# We are retiring this routine, but keep in for backward-compatibility
# with older versions of LWDAQ. Before LWDAQ 7.1.10, a solitary too
# script in the Startup directory would use the main TK window, which
# is the one called ".". But we dropped this feature in 7.1.10.
#
proc LWDAQ_tool_startup {name} {
	upvar #0 $name\_info info
	upvar #0 $name\_config config
	global LWDAQ_Info
	set info(name) $name
	set info(window) [string tolower .$name]
	set info(text) $info(window).text
	set info(settings_file_name) \
		[file join $LWDAQ_Info(tools_dir) Data $name\_Settings.tcl]
	set info(tool_file_name) \
		[file join $LWDAQ_Info(tools_dir) $name\.tcl]
	if {![file exists $info(tool_file_name)]} {
		set info(tool_file_name) \
			[file join $LWDAQ_Info(tools_dir) More $name\.tcl]
	}
	set info(data_dir) [file join $LWDAQ_Info(tools_dir) Data]
}

#
# LWDAQ_tool_init replaces LWDAQ_tool_startup in newer tools. It provides
# more functionality, and requires that the calling routine, which we assume
# is a tool initializer, checks to see if the tool window exists. If so, the
# calling routine should abort. This routine drops support for the embedding
# of tools in the main window when they are alone in the startup directory. 
# This routine provides full support for tool Help and Data, so long as the 
# tool script is in the Tools or Tools/More directory.
#
proc LWDAQ_tool_init {name version} {
	upvar #0 $name\_info info
	upvar #0 $name\_config config
	global LWDAQ_Info
	
	# If a window with this tool's name already exists,
	# we don't want to re-initialize the tool's arrays
	# and re-open the window. Instead, we raise the existing
	# window to the top and return.
	set w [string tolower .$name]
	if {[winfo exists $w]} {
		raise $w
		return 0
	}
	
	# Delete any pre-existing info and config arrays.
	array unset info
	array unset config

	# Fill in elements common to all tools.
	set info(name) $name
	set info(version) $version
	set info(window) [string tolower .$name]	
	set info(text) $info(window).text
	
	# Do our best to find the script file, starting with the main
	# tool directory.
	set fn [file join $LWDAQ_Info(tools_dir) $name\.tcl]
	if {![file exists $fn]} {
		set fn [file join $LWDAQ_Info(tools_dir) More $name\.tcl]
		if {![file exists $fn]} {
			set fn [file join $LWDAQ_Info(working_dir) $name\.tcl]
			if {![file exists $fn]} {
				set fn $name\.tcl
			}
		}
	}
	set info(tool_file_name) $fn
	
	# No matter where the tool script is, we use the same settings and
	# data locations.
	set info(settings_file_name) \
		[file join $LWDAQ_Info(tools_dir) Data $name\_Settings.tcl]
	set info(data_dir) \
		[file join $LWDAQ_Info(tools_dir) Data]
		
	# Return 1 to show success.
	return 1
}

#
# LWDAQ_tool_open opens a tool window if none exists. It 
# checks to see if the window is already open, and if so 
# it raises the window to the front and returns an empty
# string. The calling routine should check to see if this
# routine returns an empty string, and if so it should 
# not attempt to perform any graphics operations in the
# existing window without checking for itself the mode
# in which LWDAQ is running: in no graphics mode, all
# graphics routines will fail.
#
proc LWDAQ_tool_open {name} {
	upvar #0 $name\_info info
	global LWDAQ_Info

	if {!$LWDAQ_Info(gui_enabled)} {return ""}
	set w $info(window)
	if {[winfo exists $w]} {
		raise $w
		return ""
	}
	toplevel $w
	wm title $w "$info(name) Version $info(version)"		
	
	return $w
}

#
# LWDAQ_tool_save writes a tool's configuration array to disk.
#
proc LWDAQ_tool_save {name} {
	upvar #0 $name\_config config
	upvar #0 $name\_info info
	set f [open $info(settings_file_name) w]
	foreach {name} [lsort -dictionary [array names config]] {
		puts $f "set $info(name)\_config($name) \"$config($name)\""
	}
	close $f
	return 1
}

#
# LWDAQ_tool_help extracts help lines from the tool script and prints
# them in the tool's text window.
#
proc LWDAQ_tool_help {name} {
	upvar #0 $name\_info info
	set w [LWDAQ_toplevel_text_window 85 40]
	wm title $w "$info(name) Version $info(version) Help\n"
	if {[file exists $info(tool_file_name)]} {
		set f [open $info(tool_file_name) r]
		while {[gets $f line] >= 0} {
			if {$line == "return"} {break}
			if {$line == "----------Begin Help----------"} {break}
		}
		while {[gets $f line] >= 0} {
			if {$line == "----------End Help----------"} {break}
			$w.text insert end "$line\n"
		}
		close $f
	} {
		LWDAQ_print $w.text "ERROR: Can't find $info(tool_file_name).\n"
		LWDAQ_print $w.text "SUGGESTION: Put the tool script in ./Tools or ./Tools/More.\n"
	}
	return 1
}

#
# LWDAQ_tool_data extracts data lines from a tool's script and returns
# them as a string. The routine trims white spaces from the start and end
# of the data.
#
proc LWDAQ_tool_data {name} {
	upvar #0 $name\_info info
	if {[file exists $info(tool_file_name)]} {
		set data ""
		set f [open $info(tool_file_name) r]
		while {[gets $f line] >= 0} {
			if {$line == "----------Begin Data----------"} {break}
		}
		while {[gets $f line] >= 0} {
			if {$line == "----------End Data----------"} {break}
			append data "$line\n"
		}
		close $f
	} {
		LWDAQ_print $info(text) "ERROR: Can't find $info(tool_file_name) to extract data.\n"
		LWDAQ_print $info(text) "SUGGESTION: Put the tool script in the Tools folder.\n"
	}
	return [string trim $data]
}

#
# LWDAQ_tool_configure opens a configuration window so
# we can set a tool's configuration array elements. It
# also provides for extra configuration buttons by returning
# the name of a frame below the Save button.
#
proc LWDAQ_tool_configure {name {num_columns 2}} {
	upvar #0 $name\_info info
	upvar #0 $name\_config config
	set w $info(window)\.config
	if {[winfo exists $w]} {destroy $w}
	toplevel $w
	wm title $w "$info(name) Configuration Array"
	button $w.save -text "Save" -command "LWDAQ_tool_save $name"
	pack $w.save
	set custom_frame [frame $w.custom]
	pack $custom_frame -side top -fill x
	for {set i 1} {$i <= $num_columns} {incr i} {
		frame $w.f$i
		pack $w.f$i -side left -fill y
	}
	set config_list [lsort -dictionary [array names config]]
	set num_rows [expr [llength $config_list] / $num_columns]
	if {[llength $config_list] % $num_columns != 0} {
		set num_rows [expr $num_rows + 1]
	}
	set count 1
	set frame_num 1
	foreach p_name $config_list {
		if {$count > $num_rows} {
			set count 1
			incr frame_num
		}
		set f f$frame_num
		label $w.$f.l$p_name -text $p_name -anchor w 
		entry $w.$f.e$p_name -textvariable $info(name)_config($p_name) \
			-relief sunken -bd 1 -width 25
		grid $w.$f.l$p_name $w.$f.e$p_name -sticky news
		incr count
	}
	return $custom_frame
}

#
# LWDAQ_Toolmaker_execute extracts the script in the Toolmaker's text window,
# appends it to the Toolmaker script list, writes the script to a new toplevel
# text window, and executes the script at the global level. It prints out results 
# as the script requires, and print errors in red when they occur. The script 
# can refer to the text widget with the global variable "t". Above the text window 
# is a frame, "f", also declared at the global level, which is packed in the top 
# of the window, but empty unless the script creates buttons and such like to fill 
# it.
#
proc LWDAQ_Toolmaker_execute {{save 1}} {
	upvar #0 Toolmaker_info info
	global t f

	# The script we execute will always be the one shown in the
	# text window.
	set script [string trim [$info(text) get 1.0 end]]
	
	# If we want to save the script, we add it to the script list
	# and we save the script list to a backup file.
	if {$save} {
		set script [string trim [$info(text) get 1.0 end]]
		lappend info(scripts) $script
		set info(scripts) [lrange $info(scripts) end-$info(max_scripts) end]
		set info(script_index) [llength $info(scripts)]
		LWDAQ_Toolmaker_save $info(list_backup)
		$info(text) delete 1.0 end
	}
	
	# Crate the tool execution window.
	set w [LWDAQ_toplevel_window "Toolmaker Execution"]
	set f [frame $w.f]
	pack $f -side top
	set t [LWDAQ_text_widget $w 60 15 1 1]	

	# Print out the script but move the cursor down to the
	# end of the script print-out.
	LWDAQ_print $t "Script:" green
	LWDAQ_print $t $script blue
	LWDAQ_print $t "Script Output:" green
	$t see end
	LWDAQ_update
		
	if {[catch {uplevel #0 $script} result]} {
		LWDAQ_print $t "ERROR: $result" red
		LWDAQ_print $t "Error Information:"
		if {[info exists errorInfo]} {
			LWDAQ_print $t $errorInfo blue
		} {
			LWDAQ_print $t "No error information available." blue
		}
	}
	
	# Notify user that execution is complete
	LWDAQ_print $t "Done" green
	return 1
}

#
# LWDAQ_Toolmaker_repeat executes the previous script without adding a copy of it to 
# the list of scripts.
#
proc LWDAQ_Toolmaker_repeat {} {
	LWDAQ_Toolmaker_execute 0
}

#
# LWDAQ_Toolmaker_back clears the script text window, decrements the script index,
# and displays the previous script in the Toolmaker comamnd list.
#
proc LWDAQ_Toolmaker_back {} {
	upvar #0 Toolmaker_info info
	if {$info(script_index) > 0} {
		set info(script_index) [expr $info(script_index) -1]
		set script [lindex $info(scripts) $info(script_index)]
		$info(text) delete 1.0 end
		LWDAQ_print $info(text) $script
		$info(text) see 0.0
	}
	return 1
}

#
# LWDAQ_Toolmaker_forward clears the script window, increments the script index,
# and displays the next script in the Toolmaker script list. If you have reached
# the end of the list, it displays a blank screen, ready for a fresh script.
#
proc LWDAQ_Toolmaker_forward {} {
	upvar #0 Toolmaker_info info
	if {$info(script_index) < [llength $info(scripts)]} {
		incr info(script_index)
		set script [lindex $info(scripts) $info(script_index)]
		$info(text) delete 1.0 end
		LWDAQ_print $info(text) $script
		$info(text) see 0.0
	}
	return 1
}

#
# LWDAQ_Toolmaker_save saves the current Toolmaker script list 
# to a file.
#
proc LWDAQ_Toolmaker_save {{file_name ""}} {
	upvar #0 Toolmaker_info info
	if {$file_name == ""} {set file_name [LWDAQ_put_file_name Scripts.tcl]}
	if {$file_name == ""} {return 0}
	set f [open $file_name w]
	foreach c $info(scripts) {
		puts $f "<script>"
		puts $f [string trim $c]
		puts $f "</script>\n"
	}
	close $f
	return 1
}

#
# LWDAQ_Toolmaker_load reads a previously-saved script library or an
# individual script from a file and appends the script or scripts
# to the current script list.
#
proc LWDAQ_Toolmaker_load {{file_name ""}} {
	upvar #0 Toolmaker_info info
	if {$file_name == ""} {set file_name [LWDAQ_get_file_name]}
	if {$file_name == ""} {return 0}
	set f [open $file_name r]
	set contents [read $f]
	close $f
	set clist [list]
	set index 0
	while {[regexp -start $index <script> $contents match]} {
		set i_start [string first "<script>" $contents $index]
		set i_end [string first "</script>" $contents $index]
		if {$i_start < 0} {break}
		if {$i_end < 0} {break}
		set field \
			[string range $contents \
				[expr $i_start + [string length "<script>"]] \
				[expr $i_end - 1]]
		set index [expr $i_end + [string length "</script>"]]
		lappend clist $field
	}
	if {[llength $clist] == 0} {
		set clist [list $contents]
	}
	foreach c $clist {lappend info(scripts) [string trim $c]}
	set info(scripts) [lrange $info(scripts) end-$info(max_scripts) end]
	set info(script_index) [llength $info(scripts)]
	LWDAQ_Toolmaker_save $info(list_backup)
	LWDAQ_Toolmaker_back
	return 1
}

#
# LWDAQ_Toolmaker_delete deletes the current entry from the script list.
#
proc LWDAQ_Toolmaker_delete {} {
	upvar #0 Toolmaker_info info
	set info(scripts) [lreplace $info(scripts) $info(script_index) $info(script_index)]
	$info(text) delete 1.0 end
	if {$info(script_index) > 0} {
		set info(script_index) [expr $info(script_index) - 1]
		LWDAQ_print $info(text) [lindex $info(scripts) $info(script_index)]
	}
	LWDAQ_Toolmaker_save $info(list_backup)
}

#
# LWDAQ_Toolmaker_delete_all clears all entries from the script list.
#
proc LWDAQ_Toolmaker_delete_all {} {
	upvar #0 Toolmaker_info info
	if {[LWDAQ_button_confirm "Delete all Toolmaker scripts?"] == "no"} {return}
	set info(scripts) [list]
	$info(text) delete 1.0 end
	LWDAQ_Toolmaker_save $info(list_backup)
}

#
# LWDAQ_Toolmaker makes a new toplevel window for the Toolmaker. You enter a sequence of
# commands in the text window, and you can execute this sequence, which we call a script,
# with the Execute button. When you press Execute, your script will disappear from the 
# text window, but you can make it re-appear with the Back button. The Toolmaker 
# keeps a list of the scripts you have executed, and allows you to navigate and edit the 
# list with the Forward, Back, and Clear buttons. You can save the list to a file with 
# Save, and read a previously-saved list with Load. The file will contain all your scripts
# delimited by XML-style <script> and </script> marks at the beginning and end of each
# script respectively. For each Execute, Toolmaker creates a new toplevel text window.
# You can print to the lower one (which is intended for results) by referring to it as $t, 
# and using it with a text widget routine like LWDAQ_print, or calling it directly with 
# its TK widget command, $t.
#
proc LWDAQ_Toolmaker {} {
	global LWDAQ_Info
	upvar #0 Toolmaker_info info
	set info(window) ".toolmaker"
	set w $info(window)
	if {[winfo exists $w]} {
		raise $w
		return 0
	}
	toplevel $w
	wm title $w "Toolmaker"
	set info(max_scripts) 40
	set info(scripts) [list]
	set info(script_index) [llength $info(scripts)]
	set info(list_backup) [file join $LWDAQ_Info(scripts_dir) Toolmaker.tcl]

	set f [frame $w.f1]
	pack $f -side top -fill x
	foreach a {Delete_All Delete Save Load} {
		set b [string tolower $a]
		button $f.$b -text $a -command LWDAQ_Toolmaker_$b
		pack $f.$b -side left -expand 1
	}

	set f [frame $w.f2]
	pack $f -side top -fill x
	foreach a {Back Forward Execute Repeat} {
		set b [string tolower $a]
		button $f.$b -text $a -command LWDAQ_Toolmaker_$b
		pack $f.$b -side left -expand 1
	}
	set info(text) [LWDAQ_text_widget $w 80 20 1 1]
	LWDAQ_enable_text_undo $info(text)

	if {[file exists $info(list_backup)]} {
		LWDAQ_Toolmaker_load $info(list_backup)
	}
}

