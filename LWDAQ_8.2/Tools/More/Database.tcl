# XML Database Management Software
# Copyright (C) 2005 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
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
# Database.tcl defines XML database management routines, and opens up a
# management window.
#

#
# DB_init sets the database manager's global array, assuming it has not
# been set already. 
#
proc DB_init {} {
	upvar #0 DB_info info
	if {![info exists info]} {
		set info(window) .db_window
		set info(read_var) "xml"
		set info(write_var) "xml"
		set info(delete_var) "xml"
		set info(variables) [list]
		set info(commands) [list]
		set info(command_index) 0
		set info(entry_tag) "entry"
		set info(entry_mark) "\\n"
		set info(field_mark) ","
		set info(scrub_saves) 1
	}
}

#
# DB_txt_to_xml reads a flat text database file, in which the first record gives the
# field names, and all subsequent records are data. The field names will become tags
# in the xml (extendable markup language) output, so the routine puts a leading
# underscore before tags that begin with a number, and replaces all spaces, commas,
# hyphens, periods, forward slashes, semicolons with underscores. The xml output
# records will contain no empty fields. The entries will be indented by tabs for your
# convenience when looking at the xml file with a text editor. The routine takes
# up to four optional parameters. The file name is the first, and if you don't specify
# this one, or pass an empty string in its place, the routine will open a browser
# window and ask you to select a file. The second is the xml tag name you want to
# assign to the records in the database. A flat database does not explicitly name
# its records, and will not allow you to gather more than one type of record in the
# same file. An xml database allows you to have as many different types of record as
# you like, so long as each type has its own tag. All the records in the flat text
# database will be of the same type, so you give DB_txt_to_xml a name for the record
# type, which is by default "entry", but might be "customer" or "donor" instead. You
# can then combine the file produced by DB_txt_to_xml with other xml databases with
# different entry tags, and you will still be able to extract your "customers" and
# "donors" even though you have "events" and "meetings" in the same database. The
# purpose of DB_txt_to_xml is to help you move from a traditional flat database
# structure supported by some office program into a more flexible xml database structure
# supported by our free and simple TCL database searcher and editor, or by some
# other, more powerful, xml database manager. When it's done, DB_txt_to_xml returns
# the number of records it transferred from the txt database to the xml database.
# The routine also creates for you a prototype version of your xml record. Because
# the xml database will not contain any empty fields, you may have no individual
# record in the xml database that manifests all the fields. The prototype record
# corresponding to your record type has tag <entry_prototype> where "entry" is your
# record type. All fields will be present in the prototype record, even though they
# will all be empty. The order of the fields will be the order they occured in the
# original database file. Later, when you want to add to the xml database, you can
# pull out the prototype field, add entries, and then append it to the xml database
# with DB_scrub, which removes empty fields.
#
proc DB_txt_to_xml {{file_name ""} {entry_tag "entry"} {entry_mark "\n"} {field_mark ","}} {
	if {$file_name == ""} {
		set file_name [tk_getOpenFile]
	}
	if {$file_name==""} {return ""}
	set entry_mark [string map {\\n \n \\t \n} $entry_mark]
	set field_mark [string map {\\n \n \\t \n} $field_mark]
	set f [open $file_name r]
	set raw_data [read $f]
	close $f	
	set raw_database [list]
	set index 0
	set i_end [string first $entry_mark $raw_data $index]
	while {$i_end>0} {
		DB_update
		lappend raw_database \
			[string range $raw_data $index \
				[expr $i_end + [string length $entry_mark] - 1] \
			]
		set index [expr $i_end + [string length $entry_mark]]
		set i_end [string first $entry_mark $raw_data $index]
	}
	set database [list]
	foreach e $raw_database {
		DB_update
		set entry [list]
		set field ""
		set in_quotes 0
		for {set index 0} {$index < [string length $e]} {incr index}  {
			set c [string index $e $index]
			if {$in_quotes} {
				if {$c == "\""} {
					set in_quotes 0
				} {
					append field $c
				}
			} {
				if {$c == "\""} {
					set in_quotes 1
				} {
					if {$c == $field_mark} {
						lappend entry $field
						set field ""
					} {
						append field $c
					}
				}
			}
		}
		lappend database $entry
	}
	if {[string match *.??? $file_name]} {
		set file_name [string replace $file_name end-3 end .xml]
	} {
		set file_name "$file_name\.xml"
	}
	set f [open $file_name w]
	set field_names [list]
	foreach n [lindex $database 0] {
		set n [string map {\  _ - _ / _ , _ . _ ; _} $n]
		if {![regexp {^[a-zA-Z]+.*} $n]} {
			set n "_$n"
		}
		lappend field_names $n
	}
	puts $f "<$entry_tag\_prototype>"
	for {set i 0} {$i < [llength $field_names]} {incr i} {
		set n [lindex $field_names $i]
		puts $f "\t<$n></$n>"
	}
	puts $f "</$entry_tag\_prototype>"
	for {set index 1} {$index <[llength $database]} {incr index} {
		DB_update
		puts $f "<$entry_tag>"
		for {set i 0} {$i < [llength $field_names]} {incr i} {
			set e [lindex $database $index $i]
			if {$e != ""} {
				set n [lindex $field_names $i]
				puts $f "\t<$n>$e</$n>"
			}
		}
		puts $f "</$entry_tag>"
	}
	close $f
	return [llength $database]
}

#
# DB_scrub removes all empty fields from an xml record and deletes double
# line breaks. We don't intend this routine to be used upon an xml database,
# because it would remove the prototype records from the database. This routine
# is for new records constructed from a prototype form. You extract the prototype
# from your database, fill in some fields, scrub the resulting record, and store
# the scrubbed version in your database.
#
proc DB_scrub {xml} {
	set database ""
	regsub -all {<([^>/]+?)></\1>} $xml "" a
	regsub -all {(?n)\n\s*$} $a "" b
	return $b
}

#
# DB_scrub_text applies DB_scrub to the entire contents of a text window and 
# replaces the contents with the result.
#
proc DB_scrub_text {t} {
	if {![winfo exists $t]} {return 0}
	set r [$t get 1.0 end]
	$t delete 1.0 end
	DB_print $t [DB_scrub $r]
	return 1
}

#
# DB_read opens a file and reads its entire contents into memory, returning
# these contents. If you don't specify a file name, the routine will open
# a file browser for you.
#
proc DB_read {{file_name ""}} {
	if {$file_name == ""} {set file_name [tk_getOpenFile]}
	if {$file_name==""} {return ""}
	set f [open $file_name r]
	set xml [read $f]
	close $f
	return $xml
}

#
# DB_write opens a file for writing and writes the entire contents of a string
# into the file.
#
proc DB_write {xml {file_name ""}} {
	if {$file_name == ""} {set file_name [tk_getSaveFile -initialfile Database.xml]}
	if {$file_name==""} {return 0}
	set f [open $file_name w]
	puts $f $xml
	close $f
	return [string length $xml]
}


#
# DB_append opens a file for writing and appends the entire contents of a string
# into the file.
#
proc DB_append {xml {file_name ""}} {
	if {$file_name == ""} {set file_name [tk_getOpenFile]}
	if {$file_name==""} {return 0}
	set f [open $file_name a]
	puts $f $xml
	close $f
	return [string length $xml]
}


#
# DB_get_list takes an xml string, such as you would create by reading in your
# xml database with DB_read, and gets the list of records from the database
# that matches the tag you specify. If your database contains one thousand
# entries of type <donor>, and hundreds of entries of other types, DB_get_list
# returns a TCL list of the contents of all the <donor> entries when you
# pass it the xml string and the tag "donar". You don't pass it the brackets
# on either side of the tag, even though these brackets always appear in the
# xml string. Each element in the list the routine returns will be the contents
# of a single record, with its start and end tags removed. You can now apply
# DB_get_list to each element in this list sequentially, to extract fields from
# each record, and you can apply DB_get to these fields to look at sub-fields
# and so on.
#
proc DB_get_list {xml tag} {
	set result [list]
	set index 0
	while {[regexp -start $index <$tag> $xml match]} {
		set i_start [string first "<$tag>" $xml $index]
		set i_end [string first "</$tag>" $xml $index]
		if {$i_start < 0} {break}
		if {$i_end < 0} {break}
		set field \
			[string range $xml \
				[expr $i_start + [string length "<$tag>"]] \
				[expr $i_end - 1]]
		set index [expr $i_end + [string length "</$tag>"]]
		lappend result $field
	}
	return $result
}

#
# DB_get calls DB_get_list on an xml string, and returns the contents of the first
# list entry in the result. We use DB_get to extract the value of a field in an
# xml record.
#
proc DB_get {xml tag} {
	return [lindex [DB_get_list $xml $tag] 0]
}

#
# DB_display_list takes a list of xml records, such as you would create with DB_get_list,
# and displays them for the user. You pass a list of fields within each record that
# you want displayed. 
#
proc DB_display_list {xml_list args} {
	set w [DB_new_window]
	wm title $w "Display List"
	set t [DB_text_window $w 60 30]
	$t configure -tabs {5c 10c}
	puts $t
	foreach e $xml_list {
		foreach a $args {
			DB_print -nonewline $t "[DB_get $e $a]\t"
		}
		DB_print $t ""
	}
}


# DB_prototype gets the prototype record for records of type $tag from the
# specified xml string and returns it with $tag fields at beginning and 
# end.
#
proc DB_prototype {xml tag} {
	set tagp "$tag\_prototype"
	if {[regexp <$tagp> $xml match]} {
		set i_start [string first "<$tagp>" $xml]
		set i_end [string first "</$tagp>" $xml]
		set field \
			[string range $xml \
				[expr $i_start + [string length "<$tagp>"]] \
				[expr $i_end - 1]]
	} {
		set field ""
	}
	set field "<$tag>$field</$tag>"
}

#
# DB_execute_command extracts the contents of the Database Manager's command
# text window and executes them in the TCL interpreter. The final command's
# returned value gets printed to a new text window, and the list of commands
# gets printed to another new text window in the same top-level window. The
# commands in the command text window can refer to any of the Database Manager's
# variables (in the info(variables) array), by their global names. The new toplevel
# window provides two buttons, one to save the result to a file, and another to
# append the result to an existing file. The routine adds the command text
# window's contents to the Database Manager's list of previously-executed 
# commands, and clears the command text window for the next command. The command
# itself can refer to the execut window's lower text display as $r, and if 
# the local "result" variable is not empty, it also will appear in the execute
# result text window.
#
proc DB_execute_command {} {
	upvar #0 DB_info info
	foreach v $info(variables) {
		global [lindex $v 0]
	}

	set command [string trim [$info(command_text) get 1.0 end]]
	lappend info(commands) $command
	set info(command_index) [llength $info(commands)]
	$info(command_text) delete 1.0 end

	set w [DB_new_window]
	wm title $w "Command Execution $info(command_index)"

	set f1 [frame $w.f1] 
	pack $f1 -side top -fill x
	set f2 [frame $w.f2] 
	pack $f2 -side top -fill x
	set t [DB_text_window $f2 80 10]	
	set f3 [frame $w.f3] 
	pack $f3 -side top -fill x
	set r [DB_text_window $f3 80 40]	
	
	button $f1.save -text "Save Result" -command "DB_write \[$r get 1.0 end\]"
	button $f1.append -text "Append Result" -command "DB_append \[$r get 1.0 end\]"
	button $f1.scrub -text "Scrub Result" -command "DB_scrub_text $r"
	pack $f1.save $f1.append $f1.scrub -side left -expand 1
	
	DB_print $t $command blue
	
	if {[catch {eval $command} result]} {
		DB_print $t "ERROR: '$result'" red
		DB_print $t "\nError Information:"
		if {[info exists errorInfo]} {
			DB_print $t $errorInfo blue
		} {
			DB_print $t "No error information available." blue
		}
		set result ""
	}
	
	if {$result != ""} {
		DB_print -nonewline $r [string trim $result]
	}
	return 1
}

#
# DB_back_command clears the command text window, decrements the command index,
# and displays the remembered command in the command text window, rather like
# the up-arrow brings back a previous command in the TCL interpreter shell, or
# at a DOS or UNIX prompt.
#
proc DB_back_command {} {
	upvar #0 DB_info info
	if {$info(command_index) > 0} {
		set info(command_index) [expr $info(command_index) -1]
		set command [lindex $info(commands) $info(command_index)]
		$info(command_text) delete 1.0 end
		DB_print $info(command_text) $command
	}
	return 1
}

#
# DB_forward_command clears the command text window, increments the command index,
# and displays the remembered command in the command text window, rather like
# the down-arrow brings back the next command in the TCL interpreter shell, or
# at a DOS or UNIX prompt.
#
proc DB_forward_command {} {
	upvar #0 DB_info info
	if {$info(command_index) < [llength $info(commands)]} {
		incr info(command_index)
		set command [lindex $info(commands) $info(command_index)]
		$info(command_text) delete 1.0 end
		DB_print $info(command_text) $command
	}
	return 1
}

#
# DB_save_command saves the current sequence of remembered commands to a file.
#
proc DB_save_command {} {
	upvar #0 DB_info info
	set file_name [tk_getSaveFile -initialfile commands.xml]
	if {$file_name == ""} {return 0}
	set f [open $file_name w]
	foreach c $info(commands) {
		puts $f "<command>"
		puts $f [string trim $c]
		puts $f "</command>\n"
	}
	close $f
	return 1
}

#
# DB_restore_command restores a previously-saved sequence of commands from a file.
#
proc DB_restore_command {} {
	upvar #0 DB_info info
	set file_name [tk_getOpenFile]
	if {$file_name == ""} {return 0}
	set f [open $file_name r]
	set contents [read $f]
	close $f
	set info(commands) [list]
	set clist [DB_get_list $contents command]
	foreach c $clist {lappend info(commands) [string trim $c]}
	set info(command_index) [llength $info(commands)]
	$info(command_text) delete 1.0 end
	return 1
}

#
# DB_delete_command deletes the currently-displayed command in the command text window
# from the info(commands) array.
#
proc DB_delete_command {} {
	upvar #0 DB_info info
	set info(commands) [lreplace $info(commands) \
		$info(command_index) $info(command_index)]
	set info(command_index) [expr $info(command_index) - 1]
	$info(command_text) delete 1.0 end
	DB_print $info(command_text) [lindex $info(commands) $info(command_index)]
	return 1
}

#
# DB_data_read reads the contents of a file into a global variable whose name
# is stored in info(read_var).
#
proc DB_data_read {} {
	upvar #0 DB_info info
	upvar $info(read_var) v
	set file_name [tk_getOpenFile]
	if {$file_name == ""} {return 0}
	set v [DB_read $file_name]
	set d [list $info(read_var) [file tail $file_name] [string length $v]]
	set index [lsearch $info(variables) "$info(read_var)\*"]
	if {$index < 0} {
		lappend info(variables) $d
	} {
		lset info(variables) $index $d
	}
	return [DB_status_refresh]
}

#
# DB_data_write writes the contents of a global varieabl whose name is stored in
# info(write_var) to a file.
#
proc DB_data_write {} {
	upvar #0 DB_info info
	upvar $info(write_var) v
	set file_name [tk_getSaveFile]
	if {$file_name == ""} {return 0}
	set f [open $file_name w]
	puts -nonewline $f $v
	close $f
	return 1
}

#
# DB_data_delete deletes and un-sets the global variable named in info(delete_var).
#
proc DB_data_delete {} {
	upvar #0 DB_info info
	upvar $info(delete_var) v
	set index [lsearch $info(variables) "$info(delete_var)\*"]
	if {$index >= 0} {
		unset v
		set info(variables) [lreplace $info(variables) $index $index]
	}
	return [DB_status_refresh]
}

#
# DB_status_refresh writes a list of currently-available global database variables
# from the info(variables) array.
#
proc DB_status_refresh {} {
	upvar #0 DB_info info
	set t $info(status_text)
	if {![winfo exists $t]} {return 0}
	$t delete 1.0 end
	DB_print $t "Variable, File, Size (bytes)" blue
	foreach e $info(variables) {
		DB_print $t $e
	}
	return 1
}

#
# DB_open makes a new toplevel window and fills it with a bunch of buttons and two
# text windows. The Convert button converts an existing text file to an xml file.
# The Read, Save, and Delete buttons allow you to manage global database variables.
# The lower set of buttons allow you to navigate through the command list.
#
proc DB_open {} {
	upvar #0 DB_info info
	set w $info(window)
	if {[winfo exists $w]} {return 0}
	toplevel $w
	wm title $w "Database Manager"


	set f [frame $w.f1]
	pack $f -side top -fill x
	button $f.translate -text "Convert" -command \
		{DB_txt_to_xml "" $DB_info(entry_tag) $DB_info(entry_mark) $DB_info(field_mark)}
	label $f.etl -text "entry_tag"
	entry $f.ete -textvariable DB_info(entry_tag) -relief sunken -bd 1 -width 10
	label $f.eml -text "entry_mark"
	entry $f.eme -textvariable DB_info(entry_mark) -relief sunken -bd 1 -width 3
	label $f.fml -text "field_mark"
	entry $f.fme -textvariable DB_info(field_mark) -relief sunken -bd 1 -width 3
	pack $f.translate $f.etl $f.ete $f.eml $f.eme $f.fml $f.fme -side left -expand 1
	
	set f [frame $w.f2]
	pack $f -side top -fill x
	foreach a {"Read" "Write" "Delete"} {
		set b [string tolower $a]
		button $f.$b -text $a -command "DB_data_$b"
		label $f.label$b -text "the contents of variable"
		entry $f.entry$b -textvariable DB_info($b\_var) -relief sunken -bd 1 -width 10
		grid $f.$b $f.label$b $f.entry$b -sticky news
	}
	
	set f [frame $w.f3]
	pack $f -side top -fill x
	set info(status_text) [DB_text_window $f 60 6]
	DB_status_refresh
	
	set f [frame $w.f4]
	pack $f -side top -fill x
	foreach a {Save Restore Delete} {
		set b [string tolower $a]
		button $f.$b -text $a -command DB_$b\_command
		pack $f.$b -side left -expand 1
	}

	set f [frame $w.f5]
	pack $f -side top -fill x
	foreach a {Back Execute Forward} {
		set b [string tolower $a]
		button $f.$b -text $a -command DB_$b\_command
		pack $f.$b -side left -expand 1
	}
	set info(command_text) [DB_text_window $w 60 15]
}


#
# DB_update is a routine that allows you to move the windows and press 
# application buttons once every second while running a database read,
# search or translation. The database routine includes a call to DB_update
# in its repeating loop. You will note that DB_txt_to_xml calls this routine
# in all of its repeat loops, and that's why the TCL interpreter responds
# while the txt to xml translation is taking place.
#
proc DB_update {} {
	global DB_update_time
	set c [clock seconds]
	if {![info exists DB_update_time]} {set DB_update_time [expr $c+1]}
	if {$DB_update_time < $c} {
		update
		set DB_update_time [expr [clock seconds] + 1]
	}
}

#
# DB_print prints a string to the end of a text window's contents
# in the specified color. If you pass "-nonewline" as an option after 
# the command, then the routine does not add a carriage return to the end 
# of its print-out. The routine also recognises the "-newline" option, which 
# is the default. If the text window does not exist, the routine returns zero.
#
proc DB_print {args} {
	set option "-newline"
	if {[string match "-nonewline" [lindex $args 0]]} {
		set option "-nonewline"
		set args [lreplace $args 0 0]
	}
	if {[string match "-newline" [lindex $args 0]]} {
		set args [lreplace $args 0 0]
	}
	set text_win [lindex $args 0]
	set print_str [lindex $args 1]
	if {$option == "-newline"} {append print_str \n}
	if {![winfo exists $text_win]} {
		return 0
	}
	set color [lindex $args 2]
	$text_win insert end "$print_str" $color
	$text_win yview moveto 1
	return 1
}

#
# DB_new_window opens a toplevel window with a unique name.
#
proc DB_new_window {} {
	set count 0
	set var ".db_window_[incr count]"
	global $var
	while {[winfo exists $var]} {
		set var ".db_window_[incr count]"
		global $var
	}
	return [toplevel $var]
}

#
# DB_text_window opens a text window within the specified 
# window frame.
#
proc DB_text_window {window width height} {
	set t [text $window.text -relief sunken -bd 1 \
		-border 2 -yscrollcommand "$window.scroll set" \
		-setgrid 1 -height $height -width $width]
	if {[info tclversion] >= 8.4} {$t configure -undo 1 -autosep 1}
	scrollbar $window.scroll -command "$t yview"
	pack $window.scroll -side right -fill y
	pack $t -expand yes -fill both
	foreach c {black red green blue orange yellow brown purple} {
		$t tag configure $c -foreground $c
	}
	$t configure -tabs "0.25i left"
	return $t
}

proc DB_number {s} {
	set s [string map {\" \ } $s]
	if {[string is double $s]} {
		return $s
	} {
		return 0
	}

}


DB_init
DB_open
