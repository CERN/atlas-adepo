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
# Init.tcl is the initialization script that calls all other 
# LWDAQ program scripts. Here we set the LWDAQ environment variables
# in the LWDAQ_Info array.
#

# Clear our initialization error flag.
set num_errors 0

# Set version numbers in a few entries of the global LWDAQ_Info array
set LWDAQ_Info(program_name) "LWDAQ"
set LWDAQ_Info(program_version) "7.7"
set LWDAQ_Info(program_patchlevel) "7.7.26"
set LWDAQ_Info(tcl_version) [info patchlevel]
	
# Tell LWDAQ what platform it is running on.
set LWDAQ_Info(platform) [lindex [split $tcl_platform(os)] 0]
if {$LWDAQ_Info(platform) == "Darwin"} {set LWDAQ_Info(platform) "MacOS"}
if {($LWDAQ_Info(platform) != "MacOS") \
	&& ($LWDAQ_Info(platform) != "Windows") \
	&& ($LWDAQ_Info(platform) != "Linux")} {
	set LWDAQ_Info(platform) "Unix"	
}

# Set the user-defined flags to their default values.
set LWDAQ_Info(console_enabled) 1
set LWDAQ_Info(configuration_file) ""
set LWDAQ_Info(argv) ""

# Go through the list of arguments passed to this script, and set the
# user-defined flags. We may overrule these values later. 
foreach a $argv {
	switch -glob -- $a {
		"" {
		# We often get empty arguments, and we ignore them.
		}
		"-psn*" {
		# We ignore these process serial number arguments.
		}
		"--console" {
			set LWDAQ_Info(console_enabled) 1
		}
		"--no-console" {
			set LWDAQ_Info(console_enabled) 0
		}
		"--*gui" {
			set LWDAQ_Info(console_enabled) 1
		}
		"-*" {
			puts "ERROR: bad option \"$a\": must be --console or --no-console"
			incr num_errors
		}
		default {
			if {$LWDAQ_Info(configuration_file) == ""} {
				if {[file exists $a]} {
					set LWDAQ_Info(configuration_file) $a
				} {
					puts "ERROR: file $a does not exist."
					incr num_errors
				}
			} {
				lappend LWDAQ_Info(argv) $a
			}
		}
	}
}

# Decide whether or not we should enable LWDAQ's graphical user
# interface (GUI). If LWDAQ is running in the "wish" shell, which is the
# TclTk shell, we turn on the GUI. But if LWDAQ is running in "tclsh", 
# the Tcl-only shell, we turn off the GUI
set LWDAQ_Info(gui_enabled) \
	[string match -nocase "*wish*" \
		[file tail [info nameofexecutable]]]

# If the GUI is disabled, create a dummy TK window procedure. The winfo
# procedure returns 0 always to indicate that windows don't exist.
if {!$LWDAQ_Info(gui_enabled)} {
	proc winfo {args} {return 0}
}

# If the GUI is enabled, we enable the LWDAQ console. If the
# GUI is disabled, and enable_console has been set to 0, we 
# will disable the console. When the console is disabled, 
# LWDAQ can run in the background. If enable_console has been
# set already, we make sure that it has been set to zero, or
# else we set it to 1.
if {$LWDAQ_Info(gui_enabled)} {
	set LWDAQ_Info(console_enabled) 1
} {
	if {![info exists LWDAQ_Info(console_enabled)]} {
		set LWDAQ_Info(console_enabled) 1
	} {
		if {$LWDAQ_Info(console_enabled) != "0"} {
			set LWDAQ_Info(console_enabled) 1
		}
	}
} 

# Determine whether or not we have a graphical slave console available
# through the TK "console" command.
if {$LWDAQ_Info(console_enabled)} {
	if {[info commands console] == "console"} {
		set LWDAQ_Info(slave_console) 1
	} {
		set LWDAQ_Info(slave_console) 0
	}
} {
	set LWDAQ_Info(slave_console) 0
}

#
# LWDAQ_stdin_console_start turns the standard input, which will exist when
# we start LWDAQ from a terminal on UNIX, LINUX, and even Windows and MacOS.
# The console is primitive in its current incarnation: no up or down-arrow 
# implementation to give you previous commands, no left or right arrows to
# navigate through the command. But it's better than nothing.
#
proc LWDAQ_stdin_console_start {} {
	fileevent stdin readable LWDAQ_stdin_console_execute
	fconfigure stdin -buffering line
	LWDAQ_stdin_console_prompt
}

#
# LWDAQ_stdin_console_prompt writes the LWDAQ prompt to the stdin console.
#
proc LWDAQ_stdin_console_prompt {} {
	puts -nonewline stdout "LWDAQ% "
	flush stdout
}

#
# LWDAQ_stdin_console_execute executes a command supplied from the stdin console,
# if it exists, and writes the result to the stdout console.
#
proc LWDAQ_stdin_console_execute {} {
	gets stdin line
	catch {uplevel $line} result
	if {$result != ""} {
		puts stdout $result
	}
	LWDAQ_stdin_console_prompt
}

#
# LWDAQ_init initializes the LWDAQ application. As we modify the scripts, we can call 
# this routine from the console instead of quitting and re-starting the LWDAQ program.
# We include error-catching in the LWDAQ_init to protect against the interpreter aborting 
# when we start up. The only things that LWDAQ_init will run again is itself and the 
# lwdaq.so, which it will not re-load. If you modify either the dynamic library or
# this initialization procedure, you must close and re-start the application to implement
# your changes.
#
proc LWDAQ_init {} {
	upvar #0 LWDAQ_Info info

	# Set the console title, if there is a console.
	if {$info(slave_console)} {
		console title "TCL/TK Console for LWDAQ $info(program_patchlevel) on $info(platform)"
	}
	
	# Set directory variables
	set info(exec_dir) [file dirname [info nameofexecutable]]

	if {$info(platform) == "MacOS"} {
		set info(contents_dir) [file normalize \
			[file join [file dirname [info nameofexecutable]] ..]]
	}
	if {$info(platform) == "Linux"} {
		set info(contents_dir) [file normalize [file join \
			[file dirname [info nameofexecutable]] .. ..]]
	}
	if {$info(platform) == "Windows"} {
		set info(contents_dir) [file normalize [file join \
			[file dirname [info nameofexecutable]] .. ..]]
	}
	if {$info(platform) == "Unix"} {
		set info(contents_dir) [file normalize [file join \
			.  LWDAQ.app Contents]]
	}

	set info(program_dir) [file normalize [file join $info(contents_dir) .. ..]]
	set info(lib_dir) [file join $info(contents_dir) LWDAQ]
	set info(scripts_dir) [file join $info(contents_dir) LWDAQ]
	set info(tools_dir) [file join $info(program_dir) Tools]
	set info(sources_dir)  [file join $info(program_dir) Sources]
	set info(instruments_dir) [file join $info(scripts_dir) Instruments]
	set info(startup_dir) [file join $info(contents_dir) LWDAQ/Startup]
	set info(working_dir) $info(program_dir)
	
	# Set file variabls
	set info(settings) [file join $info(scripts_dir) Settings.tcl]
	set info(startup_scripts) \
			[lsort -dictionary \
				[glob -nocomplain [file join $info(startup_dir) *.tcl]]]

	# For our help routines, we construct a list of all the TCL/TK script
	# files that define the LWDAQ routines.
	set info(scripts) [glob -nocomplain [file join $info(scripts_dir) *.tcl]]
	append info(scripts) " "
	append info(scripts) [glob -nocomplain [file join $info(instruments_dir) *.tcl]]	
	
	if {[catch {

	# Load the lwdaq dynamic library we compile from our Pascal source code. This
	# library defines a bunch of TCL commands whose names start with "lwdaq_". We
	# can do this only once for each execution of LWDAQ. When we call LWDAQ_init
	# a second time, the interpreter ignores this load command. After loading the
	# library, set up options for TCL commands defined in our analysis library. These 
	# vary from one platform to the next.
	if {$info(platform) == "MacOS"} {
		load [file join $info(lib_dir) lwdaq.dylib]
		lwdaq_config -stdout_available 1 -stdin_available 0 -wait_ms 100
	}
	if {$info(platform) == "Linux"} {
		load [file join $info(lib_dir) lwdaq.so]
		lwdaq_config -stdout_available 1 -stdin_available 0 -wait_ms 100
	}
	if {$info(platform) == "Windows"} {
		load [file join $info(lib_dir) lwdaq.dll]
		lwdaq_config -stdout_available 0 -stdin_available 0 -wait_ms 100
	}
	if {$info(platform) == "Unix"} {
		load [file join $info(lib_dir) lwdaq.so]
		lwdaq_config -stdout_available 1 -stdin_available 0 -wait_ms 100
	}

	# set up LWDAQ event queue and load utility routines.
	source [file join $info(scripts_dir) Utils.tcl]
	LWDAQ_utils_init
	LWDAQ_queue_start

	# set up the TCL commands that communicate with an LWDAQ Driver
	source [file join $info(scripts_dir) Driver.tcl]
	LWDAQ_driver_init

	# set up TCL commands that manage instruments.
	source [file join $info(scripts_dir) Instruments.tcl]
	LWDAQ_instruments_init

	# set up TCL commands that manage tools.
	source [file join $info(scripts_dir) Tools.tcl]
	LWDAQ_tools_init

	# set up TCL commands that create the graphical user interface (GUI).
	source [file join $info(scripts_dir) Interface.tcl]
	LWDAQ_interface_init
	
	# close all sockets
	LWDAQ_close_all_sockets

	} result]} {error $result}
	
	# if all has gone well, we return an empty string.
	return 1
}

# Install some routines that mimic Unix.
proc ls {args} {
	if {$args==""} {
		glob *
	} {
		if {[file isdirectory $args]} {
			glob "$args/*"
		} {
			eval "glob $args"
		}
	}
}

# Initialize for the first time, taking care to catch errors so we don't abort.
# We report errors to the console. If there are no errors, we hide the console.
# The user should be able to open the console again either from a menu or from
# a script that the applicatin will allow you to edit and execute.
if {[catch {LWDAQ_init} error_message]} {
	puts "ERROR: In LWDAQ_init.tcl, $error_message"
	incr num_errors
}

# Load start-up settings script, if it exists.
if {[file exists $LWDAQ_Info(settings)]} {
	if {[catch {LWDAQ_load_settings $LWDAQ_Info(settings)} error_message]} {
		puts "ERROR: in LWDAQ_load_settings $error_message"
		incr num_errors
	}
}

# Run startup scripts. Let them know that they are operating as startup
# scripts, and which one they are in the order of execution, too. They will
# execute in alphabetical order.
set LWDAQ_Info(num_startup_scripts_loaded) 0
set LWDAQ_Info(loading_startup_scripts) 1
foreach s $LWDAQ_Info(startup_scripts) {
	if {[catch {source $s} error_message]} {
		puts "ERROR: $error_message in startup script \"[file tail $s]\"."
		incr num_errors
	}
	incr LWDAQ_Info(num_startup_scripts_loaded)
}
set LWDAQ_Info(loading_startup_scripts) 0

# Run the configuration script, if it exists.
if {$LWDAQ_Info(configuration_file) != ""} {
	if {[catch {source $LWDAQ_Info(configuration_file)} error_message]} {
		puts "ERROR: $error_message in configuration file \"$LWDAQ_Info(configuration_file)\"."
		incr num_errors
	}
}

# Report number of errors if greater than zero.
if {$num_errors > 0} {
	puts "[info script] concluded with $num_errors errors."
}

# If we have a slave console and we have errors, open it so that the errors will
# be visible. If we don't have a slave console, and our console interface is enabled,
# start our standard input console.
if {$LWDAQ_Info(slave_console)} {
	if {$num_errors > 0} {
		console show
	}
} {
	if {$LWDAQ_Info(console_enabled)} {
		LWDAQ_stdin_console_start
	}
}

# If you ran LWDAQ from tclsh, or any other TCL-only shell, the shell
# will be inclined to terminate now that it has run Init.tcl. We keep
# the shell alive by telling it to wait until LWDAQ_Info(quit) is set. 
# You can force the shell to quit with the "exit" command.
if {!$LWDAQ_Info(gui_enabled)} {
	vwait LWDAQ_Info(quit)
}

# Return a value of 1 to show success.
return 1