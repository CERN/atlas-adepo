# Acquisifier.tcl, Calls LWDAQ Instruments, formats results, and 
# stores data to disk according to an Acquisifier Script. It is a 
# Polite LWDAQ Tool.
#
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

# Version 30: requires LWDAQ 6.8 or higher. You can now run the
# Acquisifier from tclsh or any other TCL-only shell, with no 
# graphical user interface. Before we delete anything
# from a text window, or perform any other graphics-related tasks, we 
# check to see if the window exists, using the winfo procedure. LWDAQ
# defines a dummy version of winfo when it runs in TCL. The dummy
# version returns zero always. We also provide the Acquisifier_close
# procedure, which shuts down the Acquisifier.

# Version 34: Gets rid of the daq_results file, in which the Acquisifier
# stored all instrument results as a backup of data acquisition. All data-
# recording to disk must now be performed explicitly by post-processing in
# acquisifier scripts. See Acquisifier_Script.txt for an example.

# Version 35: Improves handling of Wait state so that Acquisifier starts
# at step 1 after we abort a Wait. Allows you to switch between Run and
# other active states by pressing the command buttons.

# Version 38: Allows Acquisifier_store_script to be called from the 
# console with a specified file name. Also fixes bug whereby you could
# not store the Acquisifier script in a new file.

# Version 41: We greatly improve the error-handling of the acquisifier
# steps, as we document in the manual for LWDAQ 7.0.19. Each step now
# returns a result string, which is either a completion result or an
# error result. All steps can now have names, and these names appear in
# the step's completion result. If the script does not specify a name,
# the Acquisifier creats a default name that includes the step number.
# We also improve the display of script execution in the Acquisifier
# window, and re-format the script summary after Load Script.

# Version 42: We add warning of extended acquisition during acquire
# steps.

# Version 43: We add support for the disable: field. We add the 
# Acquisifier_put_field and Acquisifier_get_field routines so we can
# name fields without adding the colon.

# Version 44: We adjust the call to LWDAQ_socket_close in the result
# upload so it no longer specifies an empty termination string.

# Version 45: Default is now upload_step_result 1 with target stdout.
# We modified response to auto_quit so that LWDAQ quits when the we
# enter the Idle state after executing one or more steps.

# Version 46: Fix error generated when close window during operation.

# Version 47: Add device analysis option with analyze checkbutton. 
# Add script List button. Expand step entry box and allow entry of
# step names as well as step numbers.

# Version 48: Stopped double-printing of error messages.

# Version 49: Switched to global num_lines_keep.

# Version 50: Text window now includes horizontal scroll bar and does
# not wrap.

# Version 51: Disabled steps do not upload their step results.

# Version 52: Allow colons in post-processing.

# Version 53: Corrected some problems with error-handling during acquire
# steps. Previous behavior passed error string in the result variable to
# post processing, which would lead to a post-processing error, and it would
# be this post-processing error that was reported. Now the post-processing
# error, and other errors consequent to the original error, are not reported.
# Only the original error is reported.

proc Acquisifier_init {} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config
	global LWDAQ_Info LWDAQ_Driver

	LWDAQ_tool_init "Acquisifier" 53
	if {[winfo exists $info(window)]} {return 0}

	set info(dummy_step) "dummy: end.\n"
	set info(control) "Idle"
	set info(steps) [list $info(dummy_step)]
	set info(step) 0
	set info(num_steps) 1
	set info(next_run_time) [clock seconds]
	set info(last_run_time) [clock seconds]

	set config(cycle_period_seconds) 0
	set config(daq_script) [file join $info(data_dir) A\cquisifier_Script.txt]
	set config(run_results) [file join $info(data_dir) Acquisifier_Results.txt]
	set config(auto_load) 0
	set config(auto_run) 0
	set config(auto_repeat) 0
	set config(auto_quit) 0
	set config(title_color) purple
	set config(analysis_color) orange
	set config(result_color) green
	set config(restore_instruments) 0
	set config(upload_step_result) 0
	set config(upload_target) stdout
	set config(extended_acquisition) 0
	set config(analyze) 0
	set config(run_analysis) [file join $info(data_dir) Acquisifier_Analysis.txt]
	set config(num_steps_show) 20
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1	
}

# Acquisifier_spawn creates a new and independent acquisifier
# by reading the original acquisifier script and substituting 
# a new name, of the form Acquisifier_n, where n is an integer
# greater than 1, for Acquisifier in all the right places. In 
# the spawn procedure, we use a backslash before the c-character
# in "Acquisifier" to prevent substitution of that particular 
# instance of the name.
proc Acquisifier_spawn {} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config
	global LWDAQ_Info

	# Read the Acquisifier.tcl script from the tools directory.
	set f [open [file join $LWDAQ_Info(tools_dir) A\cquisifier.tcl] r]
	set script [read $f]
	close $f
	
	# Find an unused Acquisifier instance number.
	set i 2
	while {[winfo exists .acquisifier_$i]} {incr i}
	
	# Rename all Acquisifier routines and variables.
	regsub -all "A\cquisifier" $script "A\cquisifier_$i" script
	
	# Restore the Spawn procedure. 
	regsub -all "A\cquisifier_$i\_spawn" $script "A\cquisifier_spawn" script
		
	# Change the final return line so that it returns $i.
	regsub "\nreturn 1" $script "\nreturn $i" script
	
	# Now run the modified script at the global scope. The 
	# script will return the name of the new acquisifier.
	uplevel #0 $script
}

proc Acquisifier_command {command} {
	upvar #0 Acquisifier_info info
	global LWDAQ_Info
	
	if {$command == $info(control)} {
		return 1
	}

	if {$command == "Reset"} {
		if {$info(control) != "Idle"} {set info(control) "Stop"}
		LWDAQ_reset
		return 1
	}
	
	if {$command == "Stop"} {
		if {$info(control) == "Idle"} {
			return 1
		}
		set info(control) "Stop"
		set event_pending [string match "Acquisifier*" $LWDAQ_Info(current_event)]
		foreach event $LWDAQ_Info(queue_events) {
			if {[string match "Acquisifier*" $event]} {
				set event_pending 1
	 		}
		}
		if {!$event_pending} {
			set info(control) "Idle"
		}
		return 1
	}
	
	if {$info(control) == "Idle"} {
		set info(control) $command
		LWDAQ_post Acquisifier_execute
		return 1
	} 
	
	set info(control) $command
	return 1	
}

proc Acquisifier_browse_daq_script {} {
	upvar #0 Acquisifier_config config
	set f [LWDAQ_get_file_name]
	if {$f != ""} {set config(daq_script) $f}
}

#
# Acquisifier_get_param_index returns the list-style
# index of the value of the parameter named $param_name
# in step number $step_num in the current Acquisifier
# script. This script is stored in info(steps). Thus the
# value of parameter $param_name in step number $step_num
# is the N'th list element in the string that defines
# step number $step_num, where N is the value returned by
# this routine. If N=0, there is no such parameter named
# in the script.
#
proc Acquisifier_get_param_index {step_num param_name} {
	upvar #0 Acquisifier_info info
	set e [lindex $info(steps) $step_num]
	set index [expr [lsearch $e "$param_name"] + 1]
	return $index
}

#
# Acquisifier_get_param returns the value of the parameter
# named $param_name in step $step_num of the current Acquisifier
# script. If there is no such parameter, the routine returns
# and empty string.
#
proc Acquisifier_get_param {step_num param_name} {
	upvar #0 Acquisifier_info info
	set index [Acquisifier_get_param_index $step_num $param_name]
	if {$index == 0} {return ""}
	return [lindex $info(steps) $step_num $index]
}

#
# Acquisifier_put_param sets the value of the parameter named
# $param_name in step $step_num of the currrent Acqusifier
# script. If there is no such parameter, the routine does nothing.
#
proc Acquisifier_put_param {step_num param_name value} {
	upvar #0 Acquisifier_info info
	set index [Acquisifier_get_param_index $step_num $param_name]
	if {$index == 0} {return 0}
	lset info(steps) $step_num $index $value
	return 1
}

#
# Acquisifier_get_field returns the value of the field
# named $field_name in step $step_num of the current Acquisifier
# script. If there is no such field, the routine returns
# and empty string.
#
proc Acquisifier_get_field {step_num field_name} {
	return [Acquisifier_get_param $step_num "$field_name\:"]
}

#
# Acquisifier_put_field sets the value of the field named
# $field_name in step $step_num of the currrent Acqusifier
# script. If there is no such field, the routine does nothing.
#
proc Acquisifier_put_field {step_num field_name value} {
	return [Acquisifier_put_param $step_num "$field_name\:" $value]
}

#
# Acquisifier_get_config returns the config field of a step.
#
proc Acquisifier_get_config {step_num} {
	upvar #0 Acquisifier_info info
	set step [lindex $info(steps) $step_num]
	set i_start [string first "config:" $step]
	set i_end [string first "end." $step]
	if {$i_start < 0} {return ""}
	if {$i_end < 0} {set i_end end}
	return [string range $step [expr $i_start + [string length "config:"]] [expr $i_end - 1]]
}

#
# Acquisifier_step_list_print prints a list of steps to a text
# widget. It is used by the _list_script and _load_script routines.
# If $num_lines>0, the routine prints the first $num_lines steps and
# the last $num_lines steps.
#
proc Acquisifier_step_list_print {text_widget num_lines} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config

	LWDAQ_print $text_widget "[format {%6s} Step] \
			[format {%-12s} Type] \
			[format {%-22s} Name] \
			[format {%-12s} Instrument]" $config(title_color)
	for {set step_num 1} {$step_num <= $info(num_steps)} {incr step_num} {
		set type [string replace [lindex $info(steps) $step_num 0] end end ""]
		set name [Acquisifier_get_field $step_num "name"]
		if {$name == ""} {set name "None"}
		set instrument [Acquisifier_get_field $step_num "instrument"]
		if {$instrument == ""} {set instrument "None"}
		LWDAQ_print $text_widget \
			"[format {%6d} $step_num] \
			[format {%-12s} $type] \
			[format {%-22s} $name] \
			[format {%-12s} $instrument]"
		if {($step_num == $num_lines) && ($info(num_steps) > [expr $num_lines + $num_lines])} {
			set step_num [expr $info(num_steps) - $num_lines]
			LWDAQ_print $text_widget "[format {%6s} ...] \
					[format {%-12s} ...] \
					[format {%-22s} ...] \
					[format {%-12s} ...]" $config(title_color)
		}
	}
	
	return 1
}

#
# Acquisifier_load_script loads a script into memory from a
# file. If we specify no file, the routine uses the file name
# given in config(daq_script).
#
proc Acquisifier_load_script {{fn ""}} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config
	
	if {$info(control) == "Load_Script"} {return}
	if {$info(control) != "Idle"} {
		return 0
	}
	set info(control) "Load_Script"
	set info(step) 0
	LWDAQ_update

	if {$fn == ""} {set fn $config(daq_script)}
	LWDAQ_print $info(text) "\nLoad: $fn" $config(title_color)

	if {![file exists $fn]} {
		LWDAQ_print $info(text) "ERROR: Can't find acquisifier data acquisition script."
		LWDAQ_print $info(text) "SUGGESTION: Press 'Browse' and locate a data acquisition script."
		set info(control) "Idle"
		return 0
	}
	
	# Read file contents and remove comment lines.
	set as "\n"
	append as [LWDAQ_read_script $fn]
	regsub -all {\n[ \t]*#[^\n]*} $as "" as

	# Parse steps.
	set info(num_steps) 0
	set index 0
	set info(steps) [list $info(dummy_step)]
	while {1} {
		set i_end [string first "\nend." $as $index]
		if {$i_end < 0} {break}
		set s [string range $as $index [expr $i_end + [string length "\nend."] - 1]]
		lappend info(steps) $s		
		incr info(num_steps)
		set index [expr $i_end + [string length "\nend."]]
		if {$i_end <= 0} {break}
		LWDAQ_support
	}

	Acquisifier_step_list_print $info(text) $config(num_steps_show)	
	LWDAQ_print $info(text) "Load okay." $config(result_color)
	
	set info(control) "Idle"
	return 1
}

proc Acquisifier_list_script {} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config

	set w $info(window)\.list
	if {[winfo exists $w]} {destroy $w}
	toplevel $w
	wm title $w "Step List"
	set step_list ""
	set t [LWDAQ_text_widget $w 80 20]
	Acquisifier_step_list_print $t 0

	return 1
}

proc Acquisifier_script_string {} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config

	set s ""
	
	for {set step_num 1} {$step_num <= $info(num_steps)} {incr step_num} {
		set title 1
		set in_config 0
		set param_name 1
		set field_name 1
		foreach e [lindex $info(steps) $step_num] {
			if {$title == 1} {
				append s "$e\n"
				set title 0
				continue
			}
			if {$e == "end."} {
				append s "end.\n\n"
				break
			}
			if {$e == "config:"} {
				set in_config 1
				append s "config:\n"
				continue
			}
			if {$in_config == 0} {
				if {$field_name} {
					append s "$e "
					set field_name 0
				} {
					append s "\{$e\}\n"
					set field_name 1
				}	
			} {
				if {$param_name == 1} {
					append s "	$e "
					set param_name 0
				} {
					append s "\{$e\}\n"
					set param_name 1
				}	
			}
		}
	}
	return [string trim $s]
}

proc Acquisifier_store_script {{fn ""}} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config

	if {$info(control) == "Store_Script"} {return}
	if {$info(control) != "Idle"} {
		LWDAQ_print $info(text) "ERROR: Can't Store_Script while in \"$info(control)\" state."
		return 0
	}
	set info(control) "Store_Script"
	LWDAQ_update

	if {$fn == ""} {set fn [LWDAQ_put_file_name $config(daq_script)]}
	if {[file exists [file dirname $fn]]} {
		LWDAQ_print $info(text) "\nStore: $config(daq_script)" $config(title_color)
		set f [open $fn w]
		puts $f [Acquisifier_script_string]
		close $f
	}
	
	set info(control) "Idle"
	return 1
}

proc Acquisifier_execute {} {
	upvar #0 Acquisifier_info info
	upvar #0 Acquisifier_config config
	global LWDAQ_Info

	# If the info array has been destroyed, abort.	
	if {![array exists info]} {return 0}

	# Detect global LWDAQ reset.
	if {$LWDAQ_Info(reset)} {
		set info(control) "Idle"
		return 1
	}
	
	# If the window is closed, quit the Acquisifier.
	if {$LWDAQ_Info(gui_enabled) && ![winfo exists $info(window)]} {
		array unset info
		array unset config
		return 0
	}
	
	# Interpret the step name, if it's not an integer
	if {![string is integer -strict $info(step)]} {
		LWDAQ_print $info(text) "\nSearching for step \"$info(step)\"..." \
			$config(title_color)
		for {set i 1} {$i <= $info(num_steps)} {incr i} {
			set name [Acquisifier_get_field $i "name"]
			if {$name == $info(step)} {
				set info(step) $i
				LWDAQ_print $info(text) "Done." $config(title_color)
				break
			}
		}
		if {![string is integer -strict $info(step)]} {
			LWDAQ_print $info(text) "ERROR: Cannot find step \"$info(step)\"."
			set info(step) 1
		}
	}
	
	# Interpret the control variable.
	if {$info(control) == "Stop"} {
		set info(control) "Idle"
		return 1
	}
	if {$info(control) == "Step"} {
		incr info(step)
		if {$info(step) > $info(num_steps)} {set info(step) 1}
	}
	if {$info(control) == "Run"} {
		incr info(step)
		if {$info(step) > $info(num_steps)} {set info(step) 1}
	}
	if {$info(control) == "Repeat_Run"} {
		incr info(step)
		if {$info(step) > $info(num_steps)} {
			set info(step) 0
			set info(next_run_time) [expr $info(last_run_time) + $config(cycle_period_seconds)]
			if {$info(next_run_time) <= [clock seconds]} {
				set info(last_run_time) [clock seconds]
				set info(next_run_time) [expr $info(last_run_time) + $config(cycle_period_seconds)]
			}
			set info(control) "Wait"
			LWDAQ_print $info(text) \
				"\nWaiting until [clock format $info(next_run_time) -format {%c}]\.\n"
			LWDAQ_post Acquisifier_execute
			return 1
		}
	}
	if {$info(control) == "Wait"} {
		if {[clock seconds] < $info(next_run_time)} {
			LWDAQ_post Acquisifier_execute
			return 1
		} {
			set info(step) 1
			set info(control) "Repeat_Run"
		}
	}
	
	# If this is step one, clear the text window.
	if {$info(step) == 1} {
		if {[winfo exists $info(text)]} {
			$info(text) delete 1.0 "end [expr 0 - $LWDAQ_Info(num_lines_keep)] lines"
		}
		set info(last_run_time) [clock seconds]
	}
	
	# Obtain the step type from the script.
	set step_type [string replace [lindex $info(steps) $info(step) 0] end end ""]

	# Obtain the name of the step. Some steps, like acquisifier and default
	# steps, may have no specific name, in which case we assign a default
	# name which is the step type.
	set name [Acquisifier_get_field $info(step) "name"]
	if {$name == ""} {set name $step_type\_$info(step)}
	
	# Determine the instrument name, if any.
	set instrument [Acquisifier_get_field $info(step) "instrument"]
	if {$instrument == ""} {set instrument "None"}
	
	# Print a title line to the screen.
	LWDAQ_print $info(text) "\nStep $info(step), $step_type, $name, $instrument" \
		$config(title_color)

	# Read this step's metadata out of the script.
	set metadata [Acquisifier_get_field $info(step) "metadata"]
	
	# Read this step's disable value. If it's defined as non-zero, 
	# we set the step type to "disabled".
	set disable [Acquisifier_get_field $info(step) "disable"]
	if {($disable != "") && ($disable != "0")} {set step_type "disabled"}
		
	# Set the default result string.
	set result "$name okay."
		
	if {$step_type == "acquire"} {
		# Check to see if the instrument exists. If not, create an
		# error message in the result string.
		if {[info command LWDAQ_daq_$instrument] == ""} {
			set result "ERROR: no instrument called \"$instrument\"."
		}

		# Declare the instrument info and config arrays for local 
		# access as iinfo and iconfig respectively.
		upvar #0 LWDAQ_info_$instrument iinfo
		upvar #0 LWDAQ_config_$instrument iconfig
		
		# Set up extended acquisition of all instruments if required.
		set iinfo(daq_extended) $config(extended_acquisition)
		if {$config(extended_acquisition)} {
			LWDAQ_print $info(text) "WARNING: Extended acquisition."
		}
	
		# Save the existing instrument parameters and set them to the 
		# values required by this step. If a parameter does not exist
		# in either the iconfig or iinfo arrays, generate an error.
		set param_list [Acquisifier_get_config $info(step)] 
		foreach {p v} $param_list {
			if {[info exists iinfo($p)]} {
				set saved($p) $iinfo($p)
				set iinfo($p) $v
				LWDAQ_print $info(text) "$p = $v"
			} elseif {[info exists iconfig($p)]} {
				set saved($p) $iconfig($p)
				set iconfig($p) $v
				LWDAQ_print $info(text) "$p = $v"
			} elseif {![LWDAQ_is_error_result $result]} {
				set result "ERROR: no parameter called \"$p\"."
			}
		}

		# Acquire from the instrument. If we obtain an error, over-write
		# the existing result string. If we don't obtain an error, and 
		# we have not yet encountered an error, set the result string
		# to the name of the step followed by the data in the result string.
		# We drop the image name from the acquire result.
		set daq_result [LWDAQ_acquire $instrument]
		if {![LWDAQ_is_error_result $result]} {
			if {![LWDAQ_is_error_result $daq_result]} {
				set result "$name [lreplace $daq_result 0 0]"
			} {
				set result $daq_result
			}
		}
		
	}
	
	# Set the default analysis string.
	set analysis "$name disabled."

	# Perform device analysis if requested.
	if {($step_type == "acquire") && $config(analyze)} {
		upvar #0 Analyzer_config aconfig
		if {![info exists aconfig]} {
			LWDAQ_run_tool [file join $LWDAQ_Info(tools_dir) Analyzer.tcl]
			upvar #0 Analyzer_info ainfo
			destroy $ainfo(window)
		}
		if {[string first : $iconfig(daq_driver_socket)] > 0} {
			scan [split $iconfig(daq_driver_socket) :] %s%u base_addr driver_socket
		} {
			set base_addr "00000000"
			set driver_socket $iconfig(daq_driver_socket)
		}
		set a [Analyzer_analyze $iconfig(daq_ip_addr) \
			$base_addr $driver_socket $iconfig(daq_mux_socket)]
		set analysis "$name $info(step) $a"

		if {[info exists iconfig(daq_source_driver_socket)] \
				&& ![LWDAQ_is_error_result $analysis]} {
			if {[string first : $iconfig(daq_source_driver_socket)] > 0} {
				scan [split $iconfig(daq_source_driver_socket) :] %s%u base_addr driver_socket
			} {
				set base_addr "00000000"
				set driver_socket $iconfig(daq_source_driver_socket)
			}
			if {$iinfo(daq_source_ip_addr) == "*"} {
				set ip_addr $iconfig(daq_ip_addr)
			} {
				set ip_addr $iinfo(daq_source_ip_addr)
			}
			set a [Analyzer_analyze $ip_addr \
				$base_addr $driver_socket $iconfig(daq_source_mux_socket)]
			append analysis "\n$name $info(step) $a"
		}		
		LWDAQ_print $info(text) $analysis $config(analysis_color)
		LWDAQ_print $config(run_analysis) $analysis
	}
	
	if {($step_type == "acquire")} {
		# Read and execute the acquire step post-processing. If we encounter
		# an error, we set the result to an error string.
		set pp [Acquisifier_get_field $info(step) "post_processing"]
		if {[catch {eval $pp} error_result]} {
			if {![LWDAQ_is_error_result $result]} {
				set result "ERROR: $error_result"
			}
		}
		
		# Read and execute the default instrument post-processing. if we
		# encounter an error, we set the result to an error string.
		if {[info exists info($instrument\_post_processing)]} {
			if {[catch {eval $info($instrument\_post_processing)} error_result]} {
				if {![LWDAQ_is_error_result $result]} {
					set result "ERROR: $error_result"
				}
			}
		}
		
		# Transfer the final instrument parameters to the current script,
		# and if required, restore the previous instrument parameters.
		foreach {p v} $param_list {
			if {[info exists iinfo($p)]} {
				Acquisifier_put_param $info(step) $p $iinfo($p)
				if {$config(restore_instruments)} {
					set iinfo($p) $saved($p)
				}
			}
			if {[info exists iconfig($p)]} {
				Acquisifier_put_param $info(step) $p $iconfig($p)
				if {$config(restore_instruments)} {
					set iconfig($p) $saved($p)
				}
			}
		}		
	}

	if {$step_type == "default"} {
		# Check to see if the instrument exists. If not, create an
		# error message in the result string.
		if {[info command LWDAQ_daq_$instrument] == ""} {
			if {![LWDAQ_is_error_result $result]} {
				set result "ERROR: no instrument called \"$instrument\"."
			}
		}

		# Declare the instrument info and config arrays for local 
		# access as iinfo and iconfig respectively.
		upvar #0 LWDAQ_info_$instrument iinfo
		upvar #0 LWDAQ_config_$instrument iconfig
		
		# Set the instrument parameters according to the new values
		# contained in the default step data. If a parameter does
		# not exist in the config or info arrays, generate an error.
		foreach {p v} [Acquisifier_get_config $info(step)] {
			if {[info exists iinfo($p)]} {
				set iinfo($p) $v
				LWDAQ_print $info(text) "$p = $v"
			} elseif {[info exists iconfig($p)]} {
				set iconfig($p) $v
				LWDAQ_print $info(text) "$p = $v"
			} elseif {![LWDAQ_is_error_result $result]} {
				set result "ERROR: no parameter called \"$p\"."
			}
		}
		
		# Extract the default post-processing script. If there is no such
		# script, we obtain an empty string.
		set dpp [Acquisifier_get_field $info(step) "default_post_processing"]
		set info($instrument\_post_processing) $dpp
		LWDAQ_print $info(text) "default_post_processing: \{$dpp\}"
		
		# Read and execute the acquire post-processing. If we encounter
		# an error, we set the result to an error string.
		set pp [Acquisifier_get_field $info(step) "post_processing"]
		if {[catch {eval $pp} error_result]} {
			if {![LWDAQ_is_error_result $result]} {
				set result "ERROR: $error_result"
			}
		}
	}
		
	if {$step_type == "acquisifier"} {
		# Set elements of the Acquisifier config and info arrays
		# according to the data field of the acqisifier step. If
		# the element does not exist already, generate an error.
		foreach {p v} [Acquisifier_get_config $info(step)] {
			set found 0
			if {[info exists info($p)]} {
				set info($p) $v
				LWDAQ_print $info(text) "$p = $v"
			} elseif {[info exists config($p)]} {
				set config($p) $v
			} elseif {![LWDAQ_is_error_result $result]} {
				set result "ERROR: no parameter called \"$p\"."
			}
		}

		# Read and execute the acquire post-processing. If we encounter
		# an error, we set the result to an error string.
		set pp [Acquisifier_get_field $info(step) "post_processing"]
		if {[catch {eval $pp} error_result]} {
			if {![LWDAQ_is_error_result $result]} {
				set result "ERROR: $error_result"
			}
		}
	}
	
	if {$step_type == "disabled"} {
		set result "$name disabled."
	}
	
	# Here we append the step name to error results so we'll know where
	# the error result comes from.
	if {[LWDAQ_is_error_result $result]} {
		if {[string index $result end] == "."} {
			set result [string replace $result end end ""]
		}
		set result "$result in $name\."
	}

	# Store the final result, time, and metadata to the current script.
	# It may be that this step does not record the result or the time,
	# in which case our put-parameter routine will do nothing.
	Acquisifier_put_field $info(step) "result" $result
	Acquisifier_put_field $info(step) "time" [clock seconds]
	Acquisifier_put_field $info(step) "metadata" $metadata

	# If upload_step_result, we upload the result over a TCPIP socket. 
	# The Acquisifier will open a new socket if upload_target is an 
	# IP address with port number. Otherwise it assumes that upload_target 
	# is an existing open channel, and writes the result to this channel.
	# We flush the open channel after we write to it, to make sure that
	# the data is delivered immediately. If the step is disabled, however,
	# we don't upload its step result.
	if {$config(upload_step_result) && ($step_type != "disabled")} {
		LWDAQ_print -nonewline $info(text) "Uploading to $config(upload_target)..." 
		if {[catch {
			if {[string match *.*.*.*:* $config(upload_target)]} {
				set sock [LWDAQ_socket_open $config(upload_target) basic]	
				puts $sock $result
				LWDAQ_socket_close $sock
			} {
				puts $config(upload_target) $result
				flush $config(upload_target)
			}
		} error_result]} {
			LWDAQ_print $info(text) ""
			LWDAQ_print $info(text) "ERROR: $error_result"
		} {
			LWDAQ_print $info(text) "done."
		}
	}

	# Print the step result of the result to the screen.
	LWDAQ_print $info(text) $result $config(result_color)
	
	# Adjust the step number and decide whether to post another step
	# execution now.
	if {$info(control) == "Repeat_Run"} {
		LWDAQ_post Acquisifier_execute
		return $result
	} 
	if {($info(control) == "Run") && ($info(step) < $info(num_steps))} {
		LWDAQ_post Acquisifier_execute
		return $result
	}
	if {$info(control) == "Repeat_Previous"} {
		LWDAQ_post Acquisifier_execute
		return $result
	} 
	if {($info(control) == "Run") && ($info(step) == $info(num_steps))} {
		LWDAQ_print $info(text) "\nEnd" $config(title_color)
	}
	
	set info(control) "Idle"
	
	if {$config(auto_quit)} {exit}
	
	return $result
}

proc Acquisifier_status {} {
	upvar #0 Acquisifier_config config
	upvar #0 Acquisifier_info info   
	set status [list]
	lappend status $info(control)
	lappend status $info(step)
	set step_type [lindex $info(steps) $info(step) 0]
	lappend status $step_type
	if {$step_type == "acquire:"} {
		set instrument [Acquisifier_get_field $info(step) "instrument"]
		lappend status $instrument
		upvar #0 LWDAQ_info_$instrument iinfo
		lappend status $iinfo(control)
	} {
		lappend status "none"
		lappend status "none"
	}
	return $status
}

proc Acquisifier_run_results {} {
	upvar #0 Acquisifier_config config
	set f [open $config(run_results) r]
	set contents [read $f]
	close $f
	return [string trim $contents]
}

proc Acquisifier_clear_run_results {} {
	upvar #0 Acquisifier_config config
	set f [open $config(run_results) w]
	close $f
	return 1
}

proc Acquisifier_open {} {
	upvar #0 Acquisifier_config config
	upvar #0 Acquisifier_info info
	
	set w [LWDAQ_tool_open Acquisifier]
	if {$w == ""} {return 0}
	
	set f $w.setup
	frame $f
	pack $f -side top -fill x
	
	label $f.l1 -textvariable Acquisifier_info(control) -width 16 -fg blue
	label $f.l2 -text "Step" -width 4
	entry $f.l3 -textvariable Acquisifier_info(step) -width 25
	label $f.l4 -text "of" -width 2
	label $f.l5 -textvariable Acquisifier_info(num_steps) -width 5
	pack $f.l1 $f.l2 $f.l3 $f.l4 $f.l5 -side left -expand 1

	button $f.configure -text Configure -command "LWDAQ_tool_configure Acquisifier"
	pack $f.configure -side left -expand 1
	button $f.help -text Help -command "LWDAQ_tool_help A\cquisifier"
	pack $f.help -side left -expand 1
	button $f.spawn -text Spawn -command "LWDAQ_post A\cquisifier_spawn"
	pack $f.spawn -side left -expand 1

	set f $w.controls
	frame $f
	pack $f -side top -fill x
	foreach a {Stop Step Previous Repeat_Previous Run Repeat_Run Reset} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Acquisifier_command $a"
		pack $f.$b -side left -expand 1
	}

	set f $w.script
	frame $f
	pack $f -side top -fill x

	label $f.title -text "Script:"
	entry $f.entry -textvariable Acquisifier_config(daq_script) -width 45
	button $f.browse -text Browse -command [list LWDAQ_post Acquisifier_browse_daq_script]
	pack $f.title $f.entry $f.browse -side left -expand 1

	foreach a {Load Store List} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_post Acquisifier_$b\_script"
		pack $f.$b -side left -expand 1
	}


	set f $w.checkbuttons
	frame $f
	pack $f -side top -fill x
	foreach a {Extended_Acquisition Analyze Upload_Step_Result Restore_Instruments} {
		set b [string tolower $a]
		label $f.l$b -text $a
		checkbutton $f.c$b -variable Acquisifier_config($b)
		pack $f.l$b $f.c$b -side left -expand 1
	}
	
	set info(text) [LWDAQ_text_widget $w 90 25 1 1]
	
	return 1
}

#
# Acquisifier_close closes the Acquisifier and deletes its configuration and
# info arrays.
#
proc Acquisifier_close {} {
	upvar #0 Acquisifier_config config
	upvar #0 Acquisifier_info info
	
	if {[winfo exists $info(window)]} {
		destroy $info(window)
	}
	array unset config
	array unset info
	return 1
}

Acquisifier_init
Acquisifier_open

if {$Acquisifier_config(auto_load)} {
	Acquisifier_load_script
}

if {$Acquisifier_config(auto_repeat)} {
	Acquisifier_command Repeat_Run
} {
	if {$Acquisifier_config(auto_run)} {
		Acquisifier_command Run
	}
}

# This is the final return. There must be no tab or space in
# front of the return command, or else the spawn procedure
# won't work.
return 1

----------Begin Help----------

The Acquisifier has its own chapter in the LWDAQ_Manual, at:

http://alignment.hep.brandeis.edu/Electronics/LWDAQ/Manual.html#Acquisifier



Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
