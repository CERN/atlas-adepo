# OPM, Optical Power Meter a Standard and Polite LWDAQ Tool
# Copyright (C) 2011, Kevan Hashemi, Brandeis University

proc OPM_init {} {
	upvar #0 OPM_info info
	upvar #0 OPM_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "OPM" "2"
	if {[winfo exists $info(window)]} {return 0}

	set config(list_of_times_ms) "0.0 0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5 1.0 2.0 5.0 10.0"
	set config(current_time_ms) "0.0"
	set config(num_samples) 10
	set config(subtract_background) 0
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	set info(control) "Idle"
	set info(sample_num) "0"

	return 1	
}

proc OPM_command {command} {
	upvar #0 OPM_info info
	global LWDAQ_Info
	
	if {$command == $info(control)} {
		return 1
	}

	if {$command == "Stop"} {
		if {$info(control) == "Idle"} {
			return 1
		}
		set info(control) "Stop"
		set event_pending [string match "OPM*" $LWDAQ_Info(current_event)]
		foreach event $LWDAQ_Info(queue_events) {
			if {[string match "OPM*" $event]} {
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
		LWDAQ_post OPM_execute
		return 1
	} 
	
	set info(control) $command
	return 1	
}

proc OPM_execute {} {
	upvar #0 OPM_info info
	upvar #0 OPM_config config
	upvar #0 LWDAQ_config_BCAM iconfig
	upvar #0 LWDAQ_info_BCAM iinfo
	global LWDAQ_Info

	if {![array exists info]} {return 0}

	if {$LWDAQ_Info(reset)} {
		set info(control) "Idle"
		return 1
	}
	
	if {$LWDAQ_Info(gui_enabled) && ![winfo exists $info(window)]} {
		array unset info
		array unset config
		return 0
	}
	
	if {$info(control) == "Stop"} {
		set info(control) "Idle"
		return 1
	}

	set iconfig(daq_adjust_flash) 0
	set iconfig(daq_subtract_background) $config(subtract_background)
	set iconfig(daq_flash_seconds) [expr $config(current_time_ms)/1000.0]
	set iconfig(analysis_enable) 0

	set clist [list]
	for {set info(sample_num) 1} \
		{$info(sample_num) <= $config(num_samples)} \
		{incr info(sample_num)} {
		if {$info(control) == "Stop"} {
			LWDAQ_print $info(text) "WARNING: Acquisition aborted."
			set info(control) "Idle"
			return 0
		}
		set result [LWDAQ_acquire BCAM]
		if {[LWDAQ_is_error_result $result]} {
			LWDAQ_print $info(text) $result
			LWDAQ_print $info(text) "WARNING: Acquisition aborted."
			set info(control) "Idle"
			return 0
		}
		set c [lwdaq_image_characteristics $iconfig(memory_name)]
		lappend clist $c
		LWDAQ_update
	}
	
	set ave_ave 0
	set ave_max 0
	foreach r $clist {
		set ave_ave [expr $ave_ave + [lindex $r 4]]
		set ave_max [expr $ave_max + [lindex $r 6]]
	}
	set ave_ave [format %.2f [expr $ave_ave / $config(num_samples)]]
	set ave_max [format %.2f [expr $ave_max / $config(num_samples)]]
	set stdev_ave 0
	set stdev_max 0
	foreach r $clist {
		set stdev_ave [expr $stdev_ave + pow([lindex $r 4]-$ave_ave,2)]
		set stdev_max [expr $stdev_max + pow([lindex $r 6]-$ave_max,2)]
	}
	set stdev_ave [format %.2f [expr sqrt($stdev_ave/$config(num_samples))]]
	set stdev_max [format %.2f [expr sqrt($stdev_max/$config(num_samples))]]
	LWDAQ_print $info(text) "$config(current_time_ms)\
		$ave_ave $stdev_ave $ave_max $stdev_max"
	set info(sample_num) 0

	set done 1
	if {($info(control) == "Step") || ($info(control) == "Run")} {
		foreach t $config(list_of_times_ms) {
			if {$t > $config(current_time_ms)} {
				set config(current_time_ms) $t
				set done 0
				break
			}
		}
		if {$done && ($info(control) == "Step")} {
			set config(current_time_ms) [lindex $config(list_of_times_ms) 0]
		}
	}

	if {($info(control) == "Run") && !$done} {
		LWDAQ_post OPM_execute
	} {
		set info(control) "Idle"
	}

	return 1
}

proc OPM_open {} {
	upvar #0 OPM_config config
	upvar #0 OPM_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	label $f.state -textvariable OPM_info(control) -width 20 -fg blue
	pack $f.state -side left
	foreach a {Acquire Step Run Stop} {
		set b [string tolower $a]
		button $f.$b -text $a -command "OPM_command $a"
		pack $f.$b -side left -expand 1
	}
	foreach a {Help Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b $info(name)"
		pack $f.$b -side left -expand 1
	}
	checkbutton $f.bs -variable OPM_config(subtract_background) \
		-text "Subtract Background"
	pack $f.bs -side left -expand 1
	label $f.sn -textvariable OPM_info(sample_num) -width 4 -fg blue
	pack $f.sn -side left

	set f $w.config
	frame $f
	pack $f -side top -fill x
	foreach a "num_samples list_of_times_ms current_time_ms" {
		label $f.$a\_l -text $a
		entry $f.$a\_e -textvariable OPM_config($a) -width 80
		grid $f.$a\_l $f.$a\_e -sticky news
	}
	

	set info(text) [LWDAQ_text_widget $w 80 15]
	LWDAQ_print $info(text) "Optical Power Monitor (OPM) Version $info(version) \n"
	
	return 1
}

OPM_init
OPM_open

return 1

----------Begin Help----------

The Optical Power Monitor measures the increase in image intensity with increasing exposure to a light source. It acquires its image from the BCAM Instrument. Set up the BCAM Instrument to flash your light source and take a picture with an image sensor. The light source and image sensor can be any combination supported by the BCAM Instrument. When the OPM acquires with the BCAM Instrument, it sets the daq_flash_seconds parameter of the BCAM Instrument to its current exposure-time, which has units of milliseconds in the OPM window. The OPM determines the average intensity of the image it aquires, and the maximum intensity, both calculations being constrained to the pixels within the image's analysis boundaries, as defined by the BCAM Instrument's parameters. If you set num_samples to a number greater than 1, the OPM obtains this number of images from the BCAM Instrument and calculates the average of the average intensity for the set of images, and the average of the maximum intensity. It calculates the standard deviation of the average image intensity and the standard deviation of the maximum intensity. It prints in its text window a string of five numbers like this one, which we obtained with ten images:

0.05 64.18 0.04 255.00 0.00

Here we have exposure time in milliseconds (0.05 is 50 us), average of the average intensity (64.18), the standard deviation of the average intensity (0.04), the maximum intensity (255), and the standard deviation of the maximum intensity (0.00). In this example, we see that the image is saturated with a 0.05 ms exposure. 

The OPM will go through a list of increasing exposure times (they must be increasing for the program to function properly) as specified in its list of exposure times. These times are in milliseconds, and must be separated by spaces. Here is an example list:

0.0 0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5 1.0 2.0 5.0 10.0

The current exposure time is the one that will be used when we next press Acquire or Step. The OPM will acquire a number of sample images, calculated its results, and use for all samples the current exposure time. With Acquire, the current exposure time remains the same. With Step, it increments to the next higher exposure time in the list of exposure times.

If you press Run, the OPM keeps executing a Step until it gets to the end of the list of exposure times. Starting with 0.0 as the current time, we obtain the following results with the default settings of the BCAM Instrument, which takes images from our demonstration stand.

0 63.91 0.03 98.60 0.49
0.001 63.90 0.00 107.20 0.40
0.002 63.90 0.00 116.90 0.54
0.005 63.90 0.00 145.20 0.60
0.01 63.92 0.04 190.40 0.80
0.02 63.95 0.05 255.00 0.00
0.05 64.11 0.03 255.00 0.00
0.1 64.27 0.05 255.00 0.00
0.2 64.76 0.14 255.00 0.00
0.5 66.15 0.16 255.00 0.00
1.0 68.42 0.22 255.00 0.00
2.0 71.57 0.20 255.00 0.00
5.0 78.74 0.49 255.00 0.00
10.0 88.26 0.35 255.00 0.00

Here we see the maximum intensity in the image, which is at the center of the BCAM laser images, rising to 255 at exposure time 20 us. 

We can have the BCAM Instrument perform background subtraction for each sample also. Check the subtract background box, and the OPM will take an image with and without the light source turned on, each for the same exposure time, and subtract the two images to obtain an image that, in theory, contains only light from the light source. This is a way of rejecting ambient light that may leak into your sensitive optical apparatus.

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
