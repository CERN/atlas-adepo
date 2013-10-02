# Motion Sensor
# Copyright 2004, 2006, Kevan Hashemi, Brandeis University
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


proc Motion_Sensor_init {} {
	upvar #0 Motion_Sensor_info info
	upvar #0 Motion_Sensor_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Motion_Sensor" "3"
	if {[winfo exists $info(window)]} {return 0}
	
	set info(control) "Idle"
	set info(photo) "motion_sensor_image"
	set info(previous_image) "mspi"
	set info(measure) 0
	set info(file_extension) ".gif"
	
	set config(instrument) Camera
	set config(max_difference) 20
	set config(image_directory) ~/Desktop/Images
	set config(replay_ms) 200
	set config(characteristic_index) 6 
	set config(zoom) 2
	set config(intensify) exact
	set config(num_lines_keep) 100

	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1   
}

proc Motion_Sensor_browse_image_directory {} {
	upvar #0 Motion_Sensor_config config
	set d [LWDAQ_get_dir_name]
	if {$d != ""} {set config(image_directory) $d}
}

proc Motion_Sensor_command {command} {
	upvar #0 Motion_Sensor_info info
	global LWDAQ_Info

	if {$command == "Stop"} {
		if {$info(control) != "Idle"} {set info(control) "Stop"}
		set event_pending [string match "Motion_Sensor*" $LWDAQ_Info(current_event)]
		foreach event $LWDAQ_Info(queue_events) {
			if {[string match "Motion_Sensor*" $event]} {
				set event_pending 1
	 		}
		}
		if {$event_pending == 0} {set info(control) "Idle"}
		return
	}
	
	if {$command == $info(control)} {return}
	
	if {$info(control) == "Idle"} {
		set info(control) $command
		LWDAQ_post Motion_Sensor_execute
	} {
		LWDAQ_print $info(text) "ERROR: Can't $command during $info(control)."
	}
	return 1
}


proc Motion_Sensor_execute {} {
	upvar #0 Motion_Sensor_info info
	upvar #0 Motion_Sensor_config config
	upvar #0 LWDAQ_config_$config(instrument) iconfig

	global LWDAQ_Info
	
	if {![array exists info]} {return 0}

	if {$info(window) != ""} {
		if {![winfo exists $info(window)]} {return 0}
	}
	if {$info(control) == "Stop"} {
		set info(control) "Idle"
		return 1
	}
	 
	if {[winfo exists $info(text)]} {
		$info(text) delete 1.0 "end [expr 0 - $config(num_lines_keep)] lines"
	}

	if {$info(control) == "Run"} {
		if {![file exists $config(image_directory)]} {
			LWDAQ_print $info(text) \
				"ERROR: directory \"$config(image_directory)\" does not exist."
			set info(control) "Idle"
			return 0
		}
	
		set result [LWDAQ_acquire $config(instrument)]

		if {![LWDAQ_is_error_result $result]} {
			lwdaq_draw $iconfig(memory_name) $info(photo) \
				-intensify $config(intensify) \
				-zoom $config(zoom)
			if {[lwdaq_image_exists $info(previous_image)] != ""} {
				set difference [lwdaq_image_manipulate $iconfig(memory_name) subtract \
					$info(previous_image)]
				set info(measure) [lindex \
					[lwdaq_image_characteristics $difference] \
						$config(characteristic_index)]
				if {$info(measure) > $config(max_difference)} {
					lwdaq_image_destroy $info(previous_image)
					lwdaq_image_manipulate $iconfig(memory_name) copy \
						-name $info(previous_image)
					set timestamp [clock seconds]
					LWDAQ_write_image_file $iconfig(memory_name) \
						[file join $config(image_directory) $timestamp$info(file_extension)]
					LWDAQ_print $info(text) "Motion at \
						[clock format $timestamp -format {%c}] \
						with measure $info(measure)."
				}
				lwdaq_image_destroy $difference
			} {
				LWDAQ_write_image_file $iconfig(memory_name) \
					[file join $config(image_directory) [clock seconds]$info(file_extension)]
				lwdaq_image_manipulate $iconfig(memory_name) copy \
					-name $info(previous_image)
			}
		} {
			LWDAQ_print $info(text) $result
		}
		LWDAQ_post Motion_Sensor_execute
		return 1
	}
	
	if {$info(control) == "Replay"} {
		LWDAQ_print $info(text) "\nReplay:" purple

		if {![file exists $config(image_directory)]} {
			LWDAQ_print $info(text) \
				"ERROR: directory \"$config(image_directory)\" does not exist."
			set info(control) "Idle"
			return 0
		}
	
		foreach image_name [lsort -dictionary \
				[glob -tails -directory $config(image_directory) *]] {
			set replay_image [LWDAQ_read_image_file \
				[file join $config(image_directory) $image_name]]
			lwdaq_draw $replay_image $info(photo) \
				-intensify $config(intensify) \
				-zoom $config(zoom)
			lwdaq_image_destroy $replay_image
			LWDAQ_print $info(text) [clock format [file root $image_name] -format {%c}]
			LWDAQ_wait_ms $config(replay_ms)
			if {$info(control) == "Stop"} {
				break
			}
		}
		LWDAQ_print $info(text) "End.\n" purple
		set info(control) "Idle"
		return 1
	}

	set info(control) "Idle"
	return 1
}

proc Motion_Sensor_open {} {
	upvar #0 Motion_Sensor_config config
	upvar #0 Motion_Sensor_info info
	global LWDAQ_Info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	label $f.lstate -textvariable $info(name)_info(control) -width 6 -fg blue
	pack $f.lstate -side left -expand 1
	foreach a {Stop Run Replay} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Motion_Sensor_command $a"
		pack $f.$b -side left -expand 1
	}
	foreach a {Help Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Motion_Sensor"
		pack $f.$b -side left -expand 1
	}

	foreach a {image_directory} {
		set f $w.$a
		frame $f
		pack $f -side top -fill x
	
		label $f.l -text $a
		entry $f.e -textvariable $info(name)_config($a) -width 60
		button $f.b -text Browse -command [list LWDAQ_post $info(name)_browse_$a]
		pack $f.l $f.e $f.b -side left -expand 1
	}

	set f $w.display
	frame $f
	pack $f -side top -fill x
	
   	image create photo $info(photo)
	label $f.image -image $info(photo) 
	pack $f.image -side left
	
	set f $w.status
	frame $f
	pack $f -side top -fill x
	label $f.a -text "Difference Measure"
	label $f.b -textvariable $info(name)_info(measure)
	pack $f.a $f.b -side left -expand 1

	set info(text) [LWDAQ_text_widget $w 60 5]

	LWDAQ_print $info(text) "$info(name) Version $info(version) \n"
	
	return 1
}

Motion_Sensor_init
Motion_Sensor_open
	
return 1

----------Begin Help----------
The Motion Sensor tool captures images from the Camera instrument. It
compares each new image with the previous image. If the two are
significantly different, the Motion Sensor stores the new image in its
image_directory. Otherwise it ignores the new image. Each new image
gets stored in the image_directory, and its name will be a time stamp
in seconds, as returned by [clock seconds], followed by the "gif"
extension. The Motion Sensor stores images as GIF files. You can
replay the images stored by the Motion Sensor with the Replay button.

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
