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
# Interface.tcl creates the LWDAQ graphical user interface.
#

#
# LWDAQ_interface_init initializes the interface routines, installs
# operating-system dependent event handlers, and configures the default
# fonts for the graphical user interface.
#
proc LWDAQ_interface_init {} {
	global LWDAQ_Info LWDAQ_server_line
	
	set LWDAQ_Info(monitor_ms) 100
	
	set LWDAQ_Info(server_address_filter) "127.0.0.1"
	set LWDAQ_Info(server_listening_port) "1090"
	set LWDAQ_Info(server_listening_sock) "none"
	set LWDAQ_Info(server_control) "Stop"
	set LWDAQ_Info(server_mode) "execute"
	set LWDAQ_server_line ""
	
	set LWDAQ_Info(default_to_stdout) 0
	set LWDAQ_Info(error_color) red
	set LWDAQ_Info(warning_color) blue
	set LWDAQ_Info(numbered_colors) "red green blue orange yellow\
		magenta brown salmon LightSlateBlue black gray40 gray60 maroon\
		green4 blue4 brown4"

	if {!$LWDAQ_Info(gui_enabled)} {return 1}
	
	if {($LWDAQ_Info(platform) == "MacOS") && $LWDAQ_Info(gui_enabled)} {
		font configure TkTextFont -size 12
		font configure TkDefaultFont -size 14
		font configure TkFixedFont -size 14 -family Courier
		font configure TkCaptionFont -size 12
		proc tk::mac::OpenDocument {args} {foreach f $args {LWDAQ_post [list LWDAQ_open_document $f]}}
	}
	if {($LWDAQ_Info(platform) == "Linux") && $LWDAQ_Info(gui_enabled)} {
		font configure TkTextFont -size 10 -family Sanserif
		font configure TkDefaultFont -size 10 -family Sanserif
		font configure TkFixedFont -size 10 -family Courier
		font configure TkMenuFont -size 10 -family Sanserif
		font configure TkCaptionFont -size 10 -family Sanserif
	}
	if {($LWDAQ_Info(platform) == "Windows") && $LWDAQ_Info(gui_enabled)} {
		font configure TkTextFont -size 8
		font configure TkDefaultFont -size 8
		font configure TkFixedFont -size 8 -family Courier
		font configure TkMenuFont -size 10
		font configure TkCaptionFont -size 10 -family Sanserif
	}
	LWDAQ_init_main_window

	LWDAQ_bind_command_key all q [list exit]
	LWDAQ_bind_command_key all w "destroy \[winfo toplevel %W\]"
	
	return 1
}

#
# LWDAQ_init_main_window initialize the main window and defines 
# the menubar.
#
proc LWDAQ_init_main_window {} {
	upvar #0 LWDAQ_Info info
	if {!$info(gui_enabled)} {return 1}
# Give a title to the main window
	wm title . $info(program_name)
# Create a new menubar for the main window
	set info(menubar) ".menubar"
	set m $info(menubar)
	catch {destroy $m}
	menu $m
	. config -menu $m
# Create a new program menu for the main window menubar, and add the About command.
	if {$info(platform) == "MacOS"} \
		{set info(program_menu) $m.apple} \
		{set info(program_menu) $m.program}
	catch {destroy $info(program_menu)}
	menu $info(program_menu) -tearoff 0
	$m add cascade -menu $info(program_menu) -label "LWDAQ"
	$info(program_menu) add command -label "About $info(program_name)" \
		-command LWDAQ_about	
	if {$info(platform) != "MacOS"} {
		$info(program_menu) add command -label "Quit" -command exit
	}
# Create the File menu
	set info(file_menu) $m.file 
	catch {destroy $info(file_menu)}
	menu $info(file_menu) -tearoff 0
	$m add cascade -menu $info(file_menu) -label "File"
	if {$info(slave_console)} {
		$info(file_menu) add command -label "Show Console" -command "console show"	
		$info(file_menu) add command -label "Hide Console" -command "console hide"	
		$info(file_menu) add separator
	}
	$info(file_menu) add command -label "Save Settings" -command LWDAQ_save_settings
	$info(file_menu) add command -label "Load Settings" -command LWDAQ_load_settings
	$info(file_menu) add separator
	$info(file_menu) add command -label "System Server" -command LWDAQ_server_open
	$info(file_menu) add command -label "System Monitor" -command LWDAQ_monitor_open
	$info(file_menu) add command -label "System Reset" -command LWDAQ_reset
# Create the Instrument menu
	LWDAQ_make_instrument_menu
# Create the Tool menu
	LWDAQ_make_tool_menu
# Set up the main window.
	catch {destroy .frame}
	frame .frame
	pack .frame -side top -fill x
	button .frame.quit -text "Quit" -command "exit"
	pack .frame.quit -side top -expand 1 -padx 100 -pady 20
}

#
# LWDAQ_about creates a message box that pops up and tells us 
# about the program.
#
proc LWDAQ_about {} {
	upvar #0 LWDAQ_Info info
	
	set w .lwdaq_about
	if {[winfo exists $w]} {focus $w.b; return 0}
	toplevel $w
	wm title $w "About $info(program_name)"
	label $w.l -text "$info(program_name) Version $info(program_patchlevel)\n \
		You are running TCL/TK version $info(tcl_version) on $info(platform).\n \
		Distributed under GNU Public License.\n \
		Copyright 2003-2009, Kevan Hashemi, Brandeis University.\n \
		This program comes with absolutely no warranty.\n \
		You will find a link to the LWDAQ User Manual at: \n \
		http://alignment.hep.brandeis.edu/Software"
	button $w.b -text OK -command "destroy $w"
	button $w.gpl -text "View License" \
		-command "LWDAQ_view_text_file [file join $info(scripts_dir) License.txt]" 
	pack $w.l $w.gpl $w.b
	focus $w.b
	return 1
}

#
# LWDAQ_make_tool_menu destroys the current tool menu and
# makes a new one that matches the current selection of
# tools in the Tools folder.
#
proc LWDAQ_make_tool_menu {} {
	upvar #0 LWDAQ_Info info
# Install the tool menu in the menu bar.
	set info(tool_menu) $info(menubar).tools
	set m $info(tool_menu)
	catch {destroy $m}
	menu $m -tearoff 0
	$info(menubar) add cascade -menu $m -label "Tool"
	$info(tool_menu) add command -label "Run Tool" -command \
		[list LWDAQ_post LWDAQ_run_tool front]
	$info(tool_menu) add command -label "Toolmaker" -command \
		[list LWDAQ_post LWDAQ_Toolmaker front]
# Add entries for each tool in the tool folder.
	set files [glob -nocomplain [file join $info(tools_dir) *.tcl]]
	if {[llength $files] != 0} {
		set tools ""
		foreach t $files {lappend tools [file tail $t]}
		set tools [lsort -dictionary $tools]
		$m add separator
		foreach t $tools {
			set menu_name [lindex [split $t .] 0]
			set file_name [file join $info(tools_dir) $t]
			$m add command -label $menu_name -command \
				[list LWDAQ_post [list LWDAQ_run_tool $file_name] front]
		}
	}
# Add entries for subdirectory in the tool folder.
	set allsubdirs [glob -nocomplain -types d [file join $info(tools_dir) *]]
	set toolsubdirs ""
	if {[llength $allsubdirs] != 0} {
		foreach d $allsubdirs {
			if {[llength [glob -nocomplain [file join $d *.tcl]]] != 0} {
				if {$d != [file join $info(tools_dir) Data]} {lappend toolsubdirs $d}
			}
		}
	}
	if {[llength $toolsubdirs] != 0} {
		set tooldirs ""
		foreach d $toolsubdirs {lappend tooldirs [file tail $d]}
		set tooldirs [lsort -dictionary $tooldirs]
		foreach d $tooldirs {
			set menu_name [string map {_ \ } [lindex [split $d .] 0]]
			set menu_widget [string tolower [lindex [split $d .] 0]]
			$m add cascade -label $menu_name -menu $m.$menu_widget
			set mm [menu $m.$menu_widget -tearoff 0]
			set files [glob -nocomplain [file join $info(tools_dir) $d *.tcl]]
			set tools ""
			foreach t $files {lappend tools [file tail $t]}
			set tools [lsort -dictionary $tools]
			foreach t $tools {
				set menu_name [lindex [split $t .] 0]
				set file_name [file join $info(tools_dir) $d $t]
				$mm add command -label $menu_name -command \
					[list LWDAQ_post [list LWDAQ_run_tool $file_name] front]
			}
		}
	}
# Done.
	return 1
}

#
# LWDAQ_make_instrument_menu destroys the current instrument menu and
# makes a new one that matches the current list of instruments.
#
proc LWDAQ_make_instrument_menu {} {
	upvar #0 LWDAQ_Info info
# Install the instrument menu in the menu bar.
	set info(instrument_menu) $info(menubar).instruments
	set m $info(instrument_menu)
	catch {destroy $m}
	menu $m -tearoff 0
	$info(menubar) add cascade -menu $m -label "Instrument"
# Add entries for each instrument in the instrument folder.
	foreach i $info(instruments) {$m add command -label $i \
		-command [list LWDAQ_post [list LWDAQ_open $i] front]}
# Add entry to stop all instruments from looping.
	$m add separator
	$m add command -label "Reset Counters" -command LWDAQ_reset_instrument_counters
# Done.
	return 1
}

#
# LWDAQ_widget_list returns a list of all existing children
# of the window or widget you pass to the routine. If you
# pass just ".", then the routine will list all existing
# widgets and windows. The routine calls itself recursively.
#
proc LWDAQ_widget_list {w} {
	set wl [list]
	foreach c [winfo children $w] {
		lappend wl $c
		set wl [concat $wl [LWDAQ_widget_list $c]]
	}
	return $wl
}

#
# LWDAQ_text_widget opens a text window within the specified 
# window frame. The text window has its "undo" stack turned off.
# The text widget is a subwindow of $wf, and has name $wf.text, 
# and it is this name that is returned by the routine. By default,
# the window has a y scrollbar, but no x scrollbar. If we have an
# x scrollbar we turn off the text wrapping.
#
proc LWDAQ_text_widget {wf width height {scrolly 1} {scrollx 0}} {
	global LWDAQ_Info

	set t [text $wf.text -relief sunken -border 2 -setgrid 1 \
		-height $height -width $width -wrap word]
	if {$scrolly} {
		$t configure -yscrollcommand "$wf.vsb set"
		set vsb [scrollbar $wf.vsb -orient vertical -command "$t yview"]
		pack $vsb -side right -fill y
	}
	if {$scrollx} {
		$t configure -xscrollcommand "$wf.hsb set"
		set hsb [scrollbar $wf.hsb -orient horizontal -command "$t xview"]
		pack $hsb -side bottom -fill x
	}
	pack $t -expand yes -fill both
	LWDAQ_bind_command_key $t b [list $t delete 1.0 end]
	$t configure -tabs "0.25i left"
	$t configure -undo 0
	if {$scrollx} {$t configure -wrap none}
	return $t
}

#
# LWDAQ_enable_text_undo turns on a text widget's undo stack. This
# stack will consume memory as it gets larger, so you should leave
# the stack off when you are repeatedly and automatically updating
# the text window contents, as we do in the System Monitor or the
# Acquisifier windows.
#
proc LWDAQ_enable_text_undo {t} {
	$t configure -undo 1 -autosep 1
}

#
# LWDAQ_print prints a string to the end of a text device. The text
# device can be a text window or a file. When the routine writes to
# a text window, it does so in a specified color, unless the string
# begins with "ERROR: " or "WARNING: ", in which case the routine 
# picks the color itself. If you pass "-nonewline" as an option after 
# LWDAQ_print, the routine does not add a carriage return to the end of
# the print string. The routine also recognises "-newline", which is 
# the default. The routine assumes the text device is a text window
# if its name starts with a period and this period is not followed by 
# a forward slash or a backslash. If the text window exists, the routine 
# writes the print string to the end of the window. If the text device is 
# either "stdout" or "stderr", the routine writes directly to these channels.
# If the text device is a file name and the directory of the file exists, 
# the routine appends the string to the file, or creates the file if the 
# file does not exist. The routine will not accept any file name that
# contains a space, is an empty string, or is a real number. If the routine
# cannot find any valid device that matches the device name, it will write 
# the print string to stdout when the global default_to_stdout flag is set.
#
proc LWDAQ_print {args} {
	global LWDAQ_Info
	
	set option "-newline"
	if {[string match "-nonewline" [lindex $args 0]]} {
		set option "-nonewline"
		set args [lreplace $args 0 0]
	}
	if {[string match "-newline" [lindex $args 0]]} {
		set args [lreplace $args 0 0]
	}

	set destination [lindex $args 0]

	set print_str [lindex $args 1]
	if {$option == "-newline"} {append print_str \n}

	set color [lindex $args 2]
	if {$color == ""} {set color black}
	if {[regexp {^WARNING: } $print_str]} {set color $LWDAQ_Info(warning_color)}
	if {[regexp {^ERROR: } $print_str]} {set color $LWDAQ_Info(error_color)}

	set printed 0
	
	if {([string index $destination 0] == ".") && \
		([string index $destination 1] != "/") && \
		([string index $destination 1] != "\\") } {
		if {[winfo exists $destination]} {
			catch {
				$destination tag configure $color -foreground $color
			}
			catch {
				$destination insert end $print_str $color
				$destination yview moveto 1
				set printed 1
			}
		}
	} {
		if {($destination == "stdout") || ($destination == "stderr")} {
			puts -nonewline $destination $print_str
			set printed 1
		} {
			if {[file exists [file dirname $destination]] \
				&& ![string is double -strict [file tail $destination]]} {
				set f [open $destination a]
				puts -nonewline $f $print_str
				close $f
				set printed 1
			}
		}
	}

	if {!$printed} {
		if {$LWDAQ_Info(default_to_stdout)} {
			puts -nonewline stdout $print_str
		} {
			set destination "null"
		}
	}
	
	return $destination
}

#
# LWDAQ_clock_widget creates a text widget that displays 
# second-by-second current time. If you specify a window name,
# the clock widget will appear in the window, packed towards
# the top. Otherwise the routine creates a new toplevel window
# for the clock.
#
proc LWDAQ_clock_widget {{wf ""}} {
	if {$wf == ""} {
		set wf .[LWDAQ_global_var_name]
		toplevel $wf
		wm title $wf Clock
	} {
		if {![winfo exists $wf]} {return 0}
	}
	if {![winfo exists $wf\.clock]} {
		text $wf.clock -undo 0 -width 30 -height 1
		pack $wf.clock
	}
	$wf.clock delete "end -1 lines" end
	set s [clock format [clock seconds] -format {%c}]
	$wf.clock insert end $s
	LWDAQ_post "LWDAQ_clock_widget $wf"
	return 1
}

#
# LWDAQ_bind_command_key binds the specified command letter
# to the specified command on all platforms.
#
proc LWDAQ_bind_command_key {window letter command} {
	upvar #0 LWDAQ_Info info
	if {$info(platform) == "MacOS"} {
		bind $window <Command-KeyPress-$letter> $command
	}
	if {$info(platform) == "Linux"} {
		bind $window <Control-KeyPress-$letter> $command
	}
	if {$info(platform) == "Windows"} {
		bind $window <Alt-KeyPress-$letter> $command
	}
}

#
# LWDAQ_toplevel_window will make a new top-level window with a
# unique name, and returns its name.
#
proc LWDAQ_toplevel_window { {title ""} } {
	set count 0
	set w ".toplevel[incr count]"
	while {[winfo exists $w]} {set w ".toplevel[incr count]"}
	toplevel $w
	if {$title != ""} {wm title $w $title}
	return $w
}

#
# LWDAQ_toplevel_text_window creates a new text window. It returns
# the name of the toplevel window containing the text widget. You can
# construct the name of the text widget itself by adding .text to the
# window name.
#
proc LWDAQ_toplevel_text_window {{width 84} {height 30}} {
	set w [LWDAQ_toplevel_window]
	set t [LWDAQ_text_widget $w $width $height]
	return $w
}

#
# LWDAQ_save_text_window saves the contents of text window
# $window_name to a file named $file_name.
#
proc LWDAQ_save_text_window {window_name file_name} {
	set f [open $file_name w]
	puts $f [$window_name get 1.0 end]
	close $f
}

#
# LWDAQ_view_text_file reads a text file into a new
# top-level text window. The routine returns the name
# of the top-level window. The name of the text widget
# used to display the file is $w.text, where $w is
# the top-level window name.
#
proc LWDAQ_view_text_file {file_name} {
	set w [LWDAQ_toplevel_window]
	wm title $w [file tail $file_name]
	set t [LWDAQ_text_widget $w 80 30]
	set f [open $file_name r]
	set contents [read $f]
	close $f
	$w.text insert end $contents
	return $w
}

#
# LWDAQ_Macos_Open_File opens files dropped on the LWDAQ icon
# in Macos. Our code is based upon an example script
# provided to the MACTCL forum on 28-FEB-07 by Jon Guyer.
# Whe it opens image files, the routine looks at the 
# first word in the image results string. If that word
# is the name of an Instrument, the routine opens the
# file in that instrument. Otherwise, it opens the file
# in the Viewer instrument.
#
proc LWDAQ_MacOS_Open_File {theAppleEvent theReplyAE} {
	upvar #0 LWDAQ_Info info
	set pathDesc [::tclAE::getKeyDesc $theAppleEvent ----]
	if {[tclAE::getDescType $pathDesc] ne "list"} {
		set pathDesc [::tclAE::coerceDesc $pathDesc list]
	}
	set count [::tclAE::countItems $pathDesc]
	set paths [list]
	for {set item 0} {$item < $count} {incr item} {
	set fileDesc [::tclAE::getNthDesc $pathDesc $item]
	set alisDesc [::tclAE::coerceDesc $fileDesc alis]
		lappend paths [::tclAE::getData $alisDesc TEXT]
	}
}

#
# LWDAQ_open_document takes a file name and opens the file
# according to its file extensions. On MacOS, we call this 
# procedure from tk::mac::OpenDocument.
#
proc LWDAQ_open_document {fn} {
	if {[file exists $fn]} {
		set ft [string tolower [file tail $fn]]
		switch -glob -- $ft {
			"*.txt" {
				set w [LWDAQ_toplevel_text_window 80 40]
				wm title $w $fn
				set f [open $fn r]
				set contents [read $f]
				close $f
				$w.text insert end $contents black
			}
			"*.tcl" {
				set script [LWDAQ_read_script $fn]
				if {$script != ""} {uplevel #0 $script}
			}
			default {
				LWDAQ_open Viewer
				upvar #0 LWDAQ_config_Viewer config
				set config(image_source) "file"
				set config(file_name) [list $fn]
				LWDAQ_acquire Viewer
			}
		}
	}	
}

#
# LWDAQ_button_wait opens a toplevel window with a continue button
# and waits until the user presses the button before closing the window
# and continuing.
#
proc LWDAQ_button_wait {{s ""}} {
	if {$s == ""} {
		set s "Press OK to Continue"
	} {
		set s "$s\nPress OK to Continue"
	}
	return [tk_messageBox -type ok -title "Wait" -message $s]
}

#
# LWDAQ_button_warning opens a toplevel window called "Warning" and
# prints message $s in the window. The procedure returns after
# the user presses a button.
#
proc LWDAQ_button_warning {s} {
	return [tk_messageBox -type ok -title "Warning" -message "$s"]
}

#
# LWDAQ_button_confirm opens a toplevel window called "Confirm" and
# prints message $s in the window. The procedure returns after
# the user presses a button.
#
proc LWDAQ_button_confirm {s} {
	return [tk_messageBox -type yesno -title "Confirm" -message "$s"]
}

#
# LWDAQ_view_array opens a new window that displays the contents of a
# global TCL array. It and allows you to change the values of all elements 
# in the array.
#
proc LWDAQ_view_array {array_name} {
	upvar #0 $array_name array
	if {![info exists array]} {return 0}
	set w [LWDAQ_toplevel_window "$array_name"]
	frame $w.f1
	frame $w.f2
	pack $w.f1 $w.f2 -side left -fill y
	set array_list [array names array]
	set array_list [lsort -dictionary $array_list]
	set count 0
	set half [expr [llength $array_list] / 2]
	set label_width 0
	foreach l $array_list {
		if {[string length $l] > $label_width} {
			set label_width [string length $l]
		}
	}
	foreach i $array_list {
		incr count
		if {$count > $half} {set f f2} {set f f1}
		label $w.$f.l$i -text $i -anchor w -width $label_width
		entry $w.$f.e$i -textvariable $array_name\($i) \
			-relief sunken -bd 1 -width 30
		grid $w.$f.l$i $w.$f.e$i -sticky news
	}
	return $w

}

#
# LWDAQ_monitor_open opens the system monitor window.
#
proc LWDAQ_monitor_open {} {
	global LWDAQ_Info

	if {!$LWDAQ_Info(gui_enabled)} {return 0}

	set w ".monitorwindow"
	if {[winfo exists $w]} {
		raise $w
		return 0
	}
	
	toplevel $w
	wm title $w "LWDAQ System Monitor"
	
	frame $w.b
	pack $w.b -side top -fill x
	
	foreach n "Queue_Start Queue_Stop Queue_Clear Reset" {
		set m [string tolower $n]
		set p [string map {_ \ } $n]
		button $w.b.$m -text $p -command LWDAQ_$m
		pack $w.b.$m -side left -expand 1
	}
	
	button $w.b.info -text Info -command [list LWDAQ_view_array LWDAQ_Info]
	pack $w.b.info -side left -expand 1

	frame $w.v
	pack $w.v -side top -fill x
	set f [frame $w.v.left]
	pack $f -side left -fill y
	set info_list "max_daq_attempts num_daq_errors num_lines_keep queue_ms daq_wait_ms"
	foreach i $info_list {
		label $f.l$i -text "$i" -anchor w -width 15
		entry $f.e$i -textvariable LWDAQ_Info($i) -relief sunken -bd 1 -width 10
		grid $f.l$i $f.e$i -sticky news
	}
	set f [frame $w.v.right]
	pack $f -side right -fill y
	set info_list "blocking_sockets lazy_flush tcp_timeout_ms support_ms update_ms"
	foreach i $info_list {
		label $f.l$i -text "$i" -anchor w -width 15
		entry $f.e$i -textvariable LWDAQ_Info($i) -relief sunken -bd 1 -width 10
		grid $f.l$i $f.e$i -sticky news
	}

	frame $w.current
	pack $w.current
	LWDAQ_text_widget $w.current 60 2 0
	frame $w.queue
	pack $w.queue
	LWDAQ_text_widget $w.queue 60 8 0
	frame $w.vwaits
	pack $w.vwaits
	LWDAQ_text_widget $w.vwaits 60 4 0
	frame $w.sockets
	pack $w.sockets
	LWDAQ_text_widget $w.sockets 60 6 0
		
	after $LWDAQ_Info(monitor_ms) LWDAQ_monitor_refresh
	return 1
}

#
# LWDAQ_monitor_refresh updates the system monitor window, if it
# exists, and posts itself for re-execution in the TCL event
# loop.
#
proc LWDAQ_monitor_refresh {} {
	global LWDAQ_Info
	
	set w ".monitorwindow"
	if {![winfo exists $w]} {return 0}
	
	set t $w.current.text
	$t delete 1.0 end
	LWDAQ_print $t "Current Event:" blue
	LWDAQ_print -nonewline $t $LWDAQ_Info(current_event)
 
	set t $w.queue.text	
	$t delete 1.0 end
	LWDAQ_print $t "Event Queue:" blue
	foreach event $LWDAQ_Info(queue_events) {
		LWDAQ_print $t [string range $event 0 50]
	}
	
	set t $w.vwaits.text	
	$t delete 1.0 end
	LWDAQ_print $t "Control Variables:" blue
	foreach var $LWDAQ_Info(vwait_var_names) {
		upvar #0 $var v
		if {[info exists v]} {LWDAQ_print $t "$var = $v"}
	}

	set t $w.sockets.text	
	$t delete 1.0 end
	LWDAQ_print $t "Open Sockets:" blue
	foreach s $LWDAQ_Info(open_sockets) {
		LWDAQ_print $t "$s"
	}

	after $LWDAQ_Info(monitor_ms) LWDAQ_monitor_refresh
	return 1
}

#
# LWDAQ_reset stops all instruments, closes all sockets, stops all vwaits, 
# and the event queue, sets the global reset variable to 1 for a period of 
# time, and then sets all the instrument control variables to Idle.
#
proc LWDAQ_reset {} {
	global LWDAQ_Info
	
	if {$LWDAQ_Info(reset)} {
		if {[llength $LWDAQ_Info(queue_events)] > 0} {
			LWDAQ_post LWDAQ_reset
		} {
			foreach i $LWDAQ_Info(instruments) {
				upvar #0 LWDAQ_info_$i info
				set info(control) "Idle"
			}
			set LWDAQ_Info(reset) 0
		}
	} {
		set LWDAQ_Info(reset) 1
		LWDAQ_stop_instruments
		LWDAQ_stop_vwaits
		LWDAQ_close_all_sockets
		LWDAQ_post LWDAQ_reset
	}
	return $LWDAQ_Info(reset)
}

#
# LWDAQ_server_open opens the remote control window. In the window, you
# specify an IP address match string to filter incoming connection requests.
# You specify the IP port to at whith LWDAQ should listen. You provide match
# strings for the commands that the remote control command interpreter should
# process. When you press Run, the remote controller is running and listening.
# When you press Stop, it stops. You cannot adjust the listening port while
# the remote controller is running.
#
proc LWDAQ_server_open {} {
	global LWDAQ_Info

	if {!$LWDAQ_Info(gui_enabled)} {return 0}

	set w ".serverwindow"
	if {[winfo exists $w]} {
		raise $w
		return 0
	}
	
	toplevel $w
	wm title $w "LWDAQ System Server"
	
	set f [frame $w.b]
	pack $f -side top -fill x
	label $f.control -textvariable LWDAQ_Info(server_control) -width 20 -fg blue
	pack $f.control -side left -expand 1
	foreach n "Start Stop" {
		set m [string tolower $n]
		button $f.$m -text $n -command LWDAQ_server_$m
		pack $f.$m -side left -expand 1
	}

	set f [frame $w.v]
	pack $f -side top -fill x
	foreach i {address_filter listening_port} {
		label $f.l$i -text "$i" -width 10
		entry $f.e$i -textvariable LWDAQ_Info(server_$i) -relief sunken -bd 1 -width 10
		pack $f.l$i $f.e$i -side left
	}
	label $f.lmode -text "mode" -width 10
	tk_optionMenu $f.emode LWDAQ_Info(server_mode) execute echo receive
	pack $f.lmode $f.emode -side left

	LWDAQ_text_widget $w 60 20
	return 1
}

#
# LWDAQ_server_start starts up the remote control server socket.
#
proc LWDAQ_server_start {} {
	upvar #0 LWDAQ_Info info
	set t .serverwindow.text
	if {$info(server_control) == "Run"} {
		LWDAQ_server_stop
	}
	set sock [LWDAQ_socket_listen LWDAQ_server_accept $info(server_listening_port)]
	set info(server_listening_sock) $sock
	set info(server_control) "Run"
	LWDAQ_print $t "$sock listening on port $info(server_listening_port)." green
	return 1
}

#
# LWDAQ_server_stop stops the remote control server socket, and closes all open
# sockets.
#
proc LWDAQ_server_stop {} {
	upvar #0 LWDAQ_Info info
	set t .serverwindow.text
	LWDAQ_socket_close $info(server_listening_sock)
	LWDAQ_print $t "$info(server_listening_sock) closed." green
	foreach s $info(open_sockets) {
		if {[string match "*server*" $s]} {
			LWDAQ_socket_close [lindex $s 0]
			LWDAQ_print $t "[lindex $s 0] closed." blue
		}
	}
	set info(server_control) "Stop"
	return 1
}

#
# LWDAQ_server_accept is called when a remote control socket opens. 
# The first thing the routine does is check that the IP address
# of the TCPIP client matches the server's address_filter. The routine
# installs the LWDAQ_server_interpreter routine as the incoming data
# handler for the remote control socket, and it lists the new socket
# in the LWDAQ open socket list.
#
proc LWDAQ_server_accept {sock addr port} {
	upvar #0 LWDAQ_Info info
	set t .serverwindow.text
	if {![string match $info(server_address_filter) $addr]} {
		close $sock
		LWDAQ_print $t "Refused connection request from $addr."
		return 0
	} {
		fconfigure $sock -buffering line
		fileevent $sock readable [list LWDAQ_server_interpreter $sock]
		lappend info(open_sockets) "$sock $addr $port basic server"
		LWDAQ_print $t "$sock opened by $addr\:$port." blue
		return 1
	}
}

#
# LWDAQ_server_info returns a string giving the name of the specified
# socket. The routine is intended for use within the System Server, where
# we pass the name of a socket to the routine, and it returns the name
# and various other pieces of system information. If, however, you call
# the routine from the console or within a script, it will return the
# same information, but with the socket name set to its default value.
# When you send the command "LWDAQ_server_info" to the System Server 
# over a System Server socket, the System Server calls LWDAQ_server_info
# with the name of this same socket, and so returns the socket name
# along with the system information. The elements returned by the routine
# are a socket number, the time in seconds, the local platform, the 
# program patchlevel, and the TCL version.n
#
proc LWDAQ_server_info {{sock "nosocket"}} {
	upvar #0 LWDAQ_Info info
	return "$sock \
		[clock seconds] \
		$info(platform) \
		$info(program_patchlevel) \
		$info(tcl_version)"
}

#
# LWDAQ_server_interpreter receives commands from a TCPIP socket
#
proc LWDAQ_server_interpreter {sock} {
	upvar #0 LWDAQ_Info info
	global LWDAQ_server_line
	set t .serverwindow.text

	if {[eof $sock]} {
		LWDAQ_socket_close $sock
		LWDAQ_print $t "$sock closed by client." blue
		return 1
	}	
	
	if {[catch {gets $sock line} result]} {
		LWDAQ_socket_close $sock
		LWDAQ_print $t "$sock closed because broken." blue
		return 1
	}

	set line [string trim $line]
	if {$line == ""} {return 1}
	set LWDAQ_server_line $line

	if {[string length $line] > 50} {
		LWDAQ_print $t "$sock read: \"[string range $line 0 49]\...\""
	} {
		LWDAQ_print $t "$sock read: \"$line\""
	}
	
	set result ""
	
	if {$info(server_mode) == "execute"} {
		if {[string match "LWDAQ_server_info" $line]} {
			append line " $sock"
		}
		
		if {[catch {
			set result [uplevel #0 $line]
		} error_result]} {
			set result "ERROR: $error_result"
		}
	}
	
	if {$info(server_mode) == "echo"} {
		set result $line
	}
	
	if {$result != ""} {
		if {[catch {puts $sock $result} sock_error]} {
			LWDAQ_print $t "ERROR: $sock_error"
			LWDAQ_socket_close $sock
			LWDAQ_print $t "$sock closed." blue
			return 0
		} {
			if {[string length $result] > 50} {
				LWDAQ_print $t "$sock wrote: \"[string range $result 0 49]\...\""
			} {
				LWDAQ_print $t "$sock wrote: \"$result\""
			}
			return 1
		}
	}
}

