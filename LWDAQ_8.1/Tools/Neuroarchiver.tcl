# Neruoarchiver.tcl, Interprets, Analyzes, and Archives Data from 
# the LWDAQ Recorder Instrument. It is a Polite LWDAQ Tool.
#
# Copyright (C) 2007-2014 Kevan Hashemi, Open Source Instruments Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#
# The Neuroarchiver records signals from Subcutaneous Transmitters 
# manufactured by Open Source Instruments. For detailed help, see:
#
# http://www.opensourceinstruments.com/Electronics/A3018/Neuroarchiver.html
#
# The Neuroarchiver uses NDF (Neuroscience Data Format) files to store
# data to disk. It provides play-back of data stored on file, with signal
# plotting and processing.
#

#
# Neuroarchiver_init creates the info and config arrays and the images the 
# Neuroarchiver uses to hold data in memory. The config array is available
# through the Config button but the info array is private.
#
proc Neuroarchiver_init {} {
#
# Here we declare the names of variables we want defined at the global
# scope. Such variables may exist before this procedure executes, and they
# will endure after the procedure concludes. The "upvar #0" assigns a local
# name to a global variable. After the following line, we can, for the 
# duration of this procedure, refer to the global variable "Neuroarchiver_info"
# with the local name "info". The Neuroarchiver_info variable happens to be
# an array with a bunch of "elements". Each element has a name and a value.
# Here we will refer to the "name" element of the "Neuroarchiver_info" array
# with info(name).
#
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	global LWDAQ_Info
#
# We initialise the Neuroarchiver with LWDAQ_tool_init. Because this command
# begins with "LWDAQ" we know that it's one of those in the LWDAQ command
# library. We can look it up in the LWDAQ Command Reference to find out
# more about what it does.
#
	LWDAQ_tool_init "Neuroarchiver" "91"
	if {[winfo exists $info(window)]} {return 0}
#
# We start setting intial values for the private display and control variables.
#
	set info(play_control) "Idle"
	set info(record_control) "Idle"
	set info(record_control_label) "none"
	set info(play_control_label) "none"
#
# The Neuroarchiver uses four LWDAQ images to hold data. The vt_image and
# af_image are those behind the display of the signal trace and the signal
# spectrum respectively. The buffer_image and data_image are used by the
# play-back process to buffer data from disk and pass data to the recorder
# analysis routines respectively.
#
	set info(vt_image) "_neuroarchiver_vt_image_"
	set info(af_image) "_neuroarchiver_af_image_"
	set info(data_image) "_neuroarchiver_data_image_"
	set info(buffer_image) "_neuroarchiver_buffer_image_"
	set info(scratch_image) "_neuroarchiver_scratch_image_"
	lwdaq_image_destroy $info(vt_image)
	lwdaq_image_destroy $info(af_image)
	lwdaq_image_destroy $info(data_image)
	lwdaq_image_destroy $info(buffer_image)
#
# The plot window width and height get set here.
#
	set info(plot_width) 400
	set info(plot_height) 250
	lwdaq_image_create -width $info(plot_width) \
		-height $info(plot_height) -name $info(af_image)
	lwdaq_image_create -width $info(plot_width) \
		-height $info(plot_height) -name $info(vt_image)
#
# Here we specify names for the windows that open up when we click on the
# voltage-time or amplitude-frequency plots.
#
	set info(vt_view) $info(window)\.vt_view_window
	set info(af_view) $info(window)\.af_view_window
#
# Here we provide a list of color codes we want to use for the voltage-
# time and amplitude-frequency plots. The list gives us the color of each
# channel, starting with channel zero (the clock channel), which we never
# plot anyway, but we have it here anyway. There are times when you may wish
# to force a more distinct color on two traces.
#
	set config(color_table) "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"
#
# The size of the data and buffer images gets set here. We want
# both images to be large enough to hold the biggest block of messages
# the Neuroarchiver is likely to be called upon to display and analyze
# in one step. With a twenty-second time interval and ten subcutaneous
# transmitters running at 512 messages per second, we would have a block
# of roughly 400 kbytes. The space available for a single block of
# data is the square of the image width. 
#
	set width 1000
	lwdaq_image_create -name $info(buffer_image) -width $width -height $width
	lwdaq_image_create -name $info(data_image) -width $width -height $width
	lwdaq_image_create -name $info(scratch_image) -width $width -height $width
# 
# When we read data from disk, we want to be sure that we will never 
# read more data than our image can hold, but at the same time as much
# data as we can. We set the block size for reads from disk to be a
# fraction of the size of the data and buffer images.
#
	set info(block_size) [expr round($width * $width / 10) ]
#
# Properties of messages.
#
	set info(message_length) 4
	set info(max_sample) 65535
	set info(max_id) 15
#
# The file overview window is an extension of the Neuroarchiver that
# allows us to work with an overview of a file's contents to select
# sections for play-back.
#
	set config(overview_num_samples) 2000
	set config(overview_activity_fraction) 0.01
	set info(overview_width) 800
	set info(overview_height) 250
	set info(overview_image) "_neuroarchiver_ov_image_"
	lwdaq_image_destroy $info(overview_image)
	lwdaq_image_create -width $info(overview_width) \
		-height $info(overview_height) \
		-name $info(overview_image)
#
# During play-back and processing, we step through each channel selected
# by the user (see the "channels" element below) and for each channel
# we create a graph of its signal versus time, which we display in the
# v-t window, and its amplitude versus frequency, which we display in the
# a-t window. The empty value for these two graphs is a point at the origin.
# When we have real data in the graphs, each graph point is two numbers: an
# x and y value, which would give time and value or frequency and amplitude.
# Note that the info(signal) and info(spectrum) elements are strings of 
# characters. Their x-y values are represented as characters giving each number,
# with each number separated from its neighbors by spaces. On the one hand,
# handling numbers as strings is computationally intensive. On the other hand,
# the string-handling routines provided by TCL make it easy for us to write
# code that handles numbers in strings. As computers have become more
# powerful, passing numbers around in strings has become more practical. On
# a 1-GHz or faster computer, the Neuroarchiver Version can perform its most
# extensive signal processing on fourteen 512 SPS message streams faster 
# than the messages come in.
#
	set info(channel_code) "0"
	set info(channel_num) "0"
	set info(signal) "0 0"
	set info(spectrum) "0 0"
	set info(values) "0"
#
# During play-back, we obtain a list of the number of messages available in
# each channel number. We include in this list any channels that have more
# than the config(active_threshold) parameter, which we define below.
#
	set info(channel_activity) ""
#
# When we determine a channel's expected message frequency in one routine,
# we want to save the frequency in a place that other routines can read it.
# The default frequency is 512.
#
	set info(frequency) 512
#
# The separation of the components of the fourier transform is related to
# the playback interval. We set it to 1 Hz by default.
#
	set info(f_step) 1
#
# After we reconstruct a channel, we sometimes like to know how many messages
# we received from this channel. We cannot obtain this number from the signal
# string because reconstruction inserts substitute messages whenever a message
# is missing in the signal. So we save the number of messages received in
# its own info array parameter. We also save the number of messages after 
# reconstruction and the loss as a percentage. We obtain reception efficiency
# by subtracting the loss from 100%.
#
	set info(num_received) 0
	set info(num_messages) 0
	set info(loss) 0
#
# We define default standing values and unaccepted values for the reconstruction 
# of channels one to fifteen. See the Recorder Manual for details of signal
# construction.
#
	set info(default_standing_values) "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
	set info(default_unaccepted_values) "{} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}"
# 
# We set the baseline power values that we use for event detection to a value
# that is impossibly high, in units of k-square-counts. 
#
	set info(bp_reset) 10000.0
	for {set id 1} {$id < $info(max_id)} {incr id} {
		set info(bp_$id) $info(bp_reset)
	}
#
# We set the array of selected frequencies for reconstruction to an empty string.
# During reconstruction, we will set them to a value picked from the default
# frequency string.
#
	for {set id 1} {$id < $info(max_id)} {incr id} {
		set info(f_$id) "0"
	}
#
# When we read and write sets of baseline powers to archive metadata, we can use
# a name to distinguish different sets stored therein, or we can opt for no name
# at all, which is how things were before Neuroarchiver version 80.
#
	set info(no_name) "NONAME"
	set config(bp_name) $info(no_name)
#
# When we jump to an event in an event list or event library, we have a variety of 
# strategies for choosing the baseline power to apply when we arrive at the new 
# location. The "local" strategy is to use the current baseline power. The "read" 
# strategy is to read the baseline power out of the metadata. The "event" strategy 
# is to use the baseline power stored in the event to which we are jumping.
#
	set config(jump_strategy) "local"
#
# When we come to the end of an archive during playback, we can store the current 
# baseline powers in the metadata.
#
	set config(bp_autowrite) 0
#
# When we start a new archive, we have the option of reading the baseline powers
# out of the metadata.
#
	set config(bp_autoread) 0
#
# When we start a new archive, we should have the option of resetting the baseline
# powers in case it is an archive un-related to the source of the existing baseline
# powers.
#
	set config(bp_autoreset) 0
#
# We set the width fraction for the divisions in the graphs.
#
	set config(t_div) 0.1
	set config(v_div) 0.1
	set config(overview_t_div) 0.05
	set config(a_div) 0.1
	set config(f_div) 0.1
#
# Log plots require a list of values at which grid lines should appear
#
	set info(log_frequency_lines) "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9\
		1 2 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100 200 300 400 500 600\
		700 800 900 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000"
#
# When the user defines their own processor file, we read the file into a
# local string so that we can apply it quickly to multiple channels. W
# keep this string private because otherwise it would appear in an entry box
# of our configuration array panel.
#
	set info(processor_script) ""
#
# We now define the configuration variables that the user can look at
# and modify in the configuration panel. We begin with the files the
# Neuroarchiver uses to record, play back, process, and report.
#
	set config(play_dir) $LWDAQ_Info(working_dir)
	set config(record_dir) $LWDAQ_Info(working_dir)
	set config(record_file) [file join $config(record_dir) Archive.ndf]
	set config(play_file) [file join $config(play_dir) Archive.ndf]
	set config(processor_file) [file join $config(play_dir) Processor.tcl]
	set config(event_file) [file join $config(play_dir) Events.txt]
#
# The verbose flag tells the Neuroarchiver to print more process
# information in its text window.
#
	set config(verbose) 0
#
# For diagnostic purposes we can print out raw messages to the screen when 
# verbose is set.
#
	set config(show_messages) 0
#
# We set the number of messages to show when we have errors or show_messages
# is set.
#
	set config(show_num) 20
# 
# The archive indices give the current position and size of archives. At
# the moment, they are in units of messages, each of which is four bytes
# long. But we will change the units to clock messages one day.
#
	set config(record_end_time) 0
	set config(play_index) 0
	set config(play_time) 0.0
	set info(t_min) $config(play_time)
	set info(play_end_time) 0.0
#
# The maximum play time is a value we are certain will be greater than the
# play time in any archive.
#
	set info(max_play_time) 360000
#
# By default, the player moves from one file to the next automatically, or
# waits for data to be added to a file if there is no other later file. But
# we can force the player to stop with this configuration parameter. When
# LWDAQ is running as a background process, it will quit at the end of the
# file, which is what we want when we submit the processing of archives to 
# a cluster of computers.
#
	set config(play_stop_at_end) 0
#
# When we display events, we can isolate the channels to which the event 
# belongs. The channel select string is the third element in the event
# description. We isolate events with the following variable set to 1.
#
	set config(isolate_events) 1
	set info(num_events) 0
	set config(event_index) 1
#
# The saved play file name variable allows us to detect when the file name
# has been changed since the last time it was used.
#
	set info(saved_play_time) $config(play_time)
	set info(saved_play_file) $config(play_file)
#
# Each new NDF file we create will have a metadata string of the following
# size in characters.
#
	set config(ndf_metadata_size) 20000
#
# When autocreate is greater than zero, it gives the number of seconds
# after which we should stop using one archive and create another one.
# We find the Neuroarchiver to be efficient with archives hundreds of
# megabytes long, so autocreate can be set to 43200 seconds with no drop
# in performance, leading to twelve hours of data in one file.
#
	set config(autocreate) 3600
#
# The channel list tells the play-back process which channels it should
# extract from the message blocks for analysis. If we want reconstruction
# of the signal, which eliminates bad messages and replaces missing messages,
# we must specify the correct message frequency and the extent of the
# transmission scatter implemented by the tranmsitter. The phrase "5:512:8"
# specifies channel 5 with frequency 512 and scatter 8. We have default values
# for frequency and scatter, which will be used if we do not specify values.
#
	set config(channel_select) "*"
	set config(default_scatter) 8
	set config(default_frequency) "512"
	set config(standing_values) $info(default_standing_values) 
	set config(unaccepted_values) $info(default_unaccepted_values)
#
# We save the last clock message value in each message block so we can compare it 
# to the first message in the next message block. If the two are not consecutive,
# we issue a warning. The code for "undefined" is -1.
#
	set info(play_previous_clock) -1
#
# The Neuroarchiver provides several steps of signal processing. We can turn 
# these on and off with the following switches, each of which appears as a 
# checkbox in the Neuroarchiver panel. 
#
	set config(enable_processing) 0
	set config(save_processing) 0
	set config(enable_vt) 1
	set config(enable_af) 1
#
# The reconstruct flag turns on reconstruction. There are few times when we
# don't want reconstruction, but one such time might be when we don't know the
# frequency of the underlying signal.
#
	set config(enable_reconstruct) 1
#
# We record and play back data in intervals. Here we specify these intervals
# in seconds. The Neuroarchiver translates seconds to clock messages.
#
	set config(record_interval) 0.5
	set config(play_interval) 1.0
	set info(clocks_per_second) 128
	set info(ticks_per_clock) 256
	set info(max_message_value) 65535
	set info(value_range) [expr $info(max_message_value) + 1]
	set info(clock_cycle_period) \
		[expr ($info(max_message_value)+1)/$info(clocks_per_second)]
#
# Any channel with more than a threshold number of messages during the
# play-back interval will be considered active.
#
	set config(activity_threshold) 20
#
# Turn on and off the Recorder Instrument's data analysis. Turning off
# the analysis saves time during data acquisition. With the Recorder Panel
# closed, we never see the plots anyway. But if we do open the Recorder
# Panel, we can watch the live data coming in after switching the following
# configuration variable to 1.
#
	set config(recorder_plot_enable) 0
#
# Plot display controls, each of which appear in an entry or checkbox.
#
	set config(v_range) 65535
	set config(v_offset) 0
	set config(ac_couple) 0
	set config(a_range) 10000
	set config(f_min) 0
	set config(f_max) 256
	set config(log_frequency) 0
#
# The Neuroarchiver deletes old lines from its text window. It keeps
# the following number of most recent lines.
#
	set config(num_lines_keep) 200
#
# We apply a window function to the signal before we take the fourier 
# transform. This function smooths the signal to its average value 
# starting window_fraction*num_samples from the left and right edges.
#
	set config(window_fraction) 0.1
# 
# We zoom the plots in the separate signal and spectrum view windows.
#
	set config(vt_view_zoom) 2
	set config(af_view_zoom) 2
#
# When glitch_threshold is greater than zero, any sample that differs
# by more than the threshold value from the previous sample will be over-
# written by the previous sample. A threshold of zero disables the glitch
# filter. A value that works well with EEG detection in the A3019A or 
# A3019D subcutaneous transmitters is 2500. We set the threshold to zero
# here, which disables the glitch filter.
#
	set config(glitch_threshold) 0
# 
# The Event Classifier default settings. 
#
	set info(classifier_window) $info(window)\.classifier
	set config(classifier_types) ""
	set config(classifier_metrics) "event_pwr"
	set config(classifier_x_metric) "event_pwr"
	set config(classifier_y_metric) "event_pwr"
	set info(classifier_match) 0.0	
	set config(classifier_match_limit) 0.2
	set config(classifier_threshold) 0.5
	set config(enable_handler) 0
	set info(handler_script) ""
#
# The Save button in the Configuration Panel allows you to save your own
# configuration parameters to disk a file called settings_file_name. This
# file was declared earlier in LWDAQ_tool_startup. Now we check to see
# if there is such a file, and if so we read it in and execute the TCL
# commands it contains. Each of the commands sets an element in the 
# configuration array. Try pressing the Save button and look for the
# settings file in ./Tools/Data. You can open it and take a look.
#
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 
#
# We have file tail variables that we display in the Neuroarchiver
# window. We set these now, after we have read in the saved settings.
#
	foreach n {record play processor event} {
		set info($n\_file_tail) [file tail $config($n\_file)]
	}
#
# We are done with initialization. We return a 1 to show success.
#
	return 1   
}

#
# Neuroarchiver_configure calls the standard LWDAQ tool configuration
# routine to produce a window with an array of configuration parameters
# that the user can edit. In addition, the routine adds some buttons that
# are particular to the Neuroarchvier.
#
proc Neuroarchiver_configure {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	LWDAQ_tool_configure Neuroarchiver 3
}

#
# Neuroarchiver_print writes a line to the text window. If the color
# specified is "verbose", the message prints only when the verbose flag
# is set, and in black. Warnings and errors are always printed in the warning
# and error colors.
#
proc Neuroarchiver_print {line {color "black"}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {$config(verbose) \
			|| [regexp "^WARNING: " $line] \
			|| [regexp "^ERROR: " $line] \
			|| ($color != "verbose")} {
		if {$color == "verbose"} {set color black}
		LWDAQ_print $info(text) $line $color
	}
}

#
# Neuroarchiver_play_time_format stops the play time from becoming corrupted
# by rounding errors, and makes sure that there is always one number after the
# decimal point, while at the same time dropping unecessary trailing zeros.
#
proc Neuroarchiver_play_time_format {play_time} {
	set play_time [format %.6g $play_time]
	if {![string match "*.*" $play_time]} {
		set play_time [format %.1f $play_time]
	}
	return $play_time
}

#
# Neuroarchiver_pick allows the user to pick a new play_file, record_file, 
# processor_file, event_file, record_dir, or play_dir.
#
proc Neuroarchiver_pick {name {post 0}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	global LWDAQ_Info

	# If we call this routine from a button, we prefer to post
	# its execution to the event queue, and this we can do by
	# adding a parameter of 1 to the end of the call.
	if {$post} {
		LWDAQ_post [list Neuroarchiver_pick $name]
		return ""
	}

	if {[regexp "_file" $name]} {
		set fn [LWDAQ_get_file_name 0 [file dirname [set config($name)]]]
		if {$fn == ""} {return ""}
		set config($name) $fn
		set info($name\_tail) [file tail $fn]
		return $fn
	} 
	if {[regexp "_dir" $name]} {
		set dn [LWDAQ_get_dir_name [set config($name)]]
		if {$dn == ""} {return ""}
		set config($name) $dn
		return $dn
	}
	return ""
}

#
# Neuroarchiver_comment_list prints a list of NDF files and their metadata 
# comments. The routine takes as input a list of files. If the list
# is empty, it asks the user to select the files to list.
#
proc Neuroarchiver_comment_list {{fl ""}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	
	if {$fl == ""} {
		set fl [LWDAQ_get_file_name 1]
		if {$fl == ""} {
			return 0
		}
	}
	set fl [lsort -dictionary $fl]

	set i 1
	while {[winfo exists [set w $info(window)\.comments_$i]]} {incr i}
	toplevel $w
	wm title $w "List of [llength $fl] Selected Archives"
	LWDAQ_text_widget $w 70 40
	LWDAQ_enable_text_undo $w.text	
	$w.text tag configure textbutton -background lightblue
	$w.text tag bind textbutton <Enter> {%W configure -cursor arrow} 
	$w.text tag bind textbutton <Leave> {%W configure -cursor xterm} 

	set i 1
	foreach fn $fl {
		LWDAQ_print -nonewline $w.text "[file tail $fn]   " purple
		$w.text tag bind s_$i <Button> [list LWDAQ_post \
			[list Neuroarchiver_jump "[file tail $fn] 0.0 * Selected from list"]]
		$w.text insert end "  Step  " "s_$i textbutton"
		$w.text insert end "   "
		$w.text tag bind e_$i <Button> [list LWDAQ_post \
			[list Neuroarchiver_metadata_view $fn]]
		$w.text insert end "  Metadata  " "e_$i textbutton"
		$w.text insert end "   "
		$w.text tag bind o_$i <Button> [list LWDAQ_post \
			[list Neuroarchiver_overview $fn]]
		$w.text insert end "  Overview  " "o_$i textbutton"
		$w.text insert end "\n"
		if {![catch {LWDAQ_ndf_data_check $fn} message]} {
			set metadata [LWDAQ_ndf_string_read $fn]
			set comments [LWDAQ_xml_get_list $metadata "c"]
			foreach c $comments {
				$w.text insert end [string trim $c]\n
			}
			$w.text insert end "\n"
		} {
			LWDAQ_print $w.text "ERROR: $message.\n"
		}
		incr i
		LWDAQ_support
	}
	return 1
}

#
# Neuroarchiver_metadata_write writes the contents of a text window, which is 
# $w.text, into the metadata of a file $fn. We use this procedure in the Save 
# button of the metadata display window.
#
proc Neuroarchiver_metadata_write {w fn} {
	LWDAQ_ndf_string_write $fn [string trim [$w.text get 1.0 end]]\n
}

#
# Neuroarchiver_metadata_view reads the metadata from an NDF file called
# $fn and displays the metadata string in a new text window. You 
# can edit the string and save it to the same file with a Save button.
#
proc Neuroarchiver_metadata_view {fn} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	
	# Determine the file name.
	switch $fn {
		"play" {set fn $config(play_file)}
		"record" {set fn $config(record_file)}
		default {
			if {![file exists $fn]} {
				Neuroarchiver_print "ERROR: file \"$fn\" does not exist."
				return ""
			}
		}
	}
	
	# Check the file.
	if {[catch {LWDAQ_ndf_data_check $fn} message]} {
		Neuroarchiver_print "ERROR: $message."
		return ""
	}
	
	# Create a new top-level text window that is a child of the 
	# Neuroarchiver window. 
	set i 1
	while {[winfo exists [set w $info(window)\.metadata_$i]]} {incr i}
	toplevel $w
	wm title $w "[file tail $fn] Metadata"
	LWDAQ_text_widget $w 60 20
	LWDAQ_enable_text_undo $w.text	

	# Create the Save button.
	frame $w.f
	pack $w.f -side top
	button $w.f.save -text "Save" -command [list Neuroarchiver_metadata_write $w $fn]
	pack $w.f.save -side left
	
	# Print the metadata to the text window.
	LWDAQ_print $w.text [LWDAQ_ndf_string_read $fn]

	return 1
}

#
# Neuroarchiver_seek_time determines the index of the clock message that
# occurs just befor seek_time and also just after seek time. It returns
# four numbers lo_time, lo_index, hi_time, and hi_index. The routine assumes
# that the data stream represented by the archive contains a clock message 
# immediately after the last message in the archive. We call this the 
# message the "end clock", and the routine will choose the end clock for
# hi_time and hi_index if the seek time is equal to or greater than the
# length of the archive. If the seek time is negative, the routine takes 
# this to mean that it should find the end time of the archive, which will
# be the time and index of the end clock. Note that the index of a message
# is its index in the data block, which is different from its byte address
# in the archive file. The return string "0 2 0 2" means time zero occurs at 
# message 2, which is the third message in the data block. We might obtain
# such a result when we specify seek time of 0 and apply it to an archive
# that, for some reason, does not start with a clock message.
#
proc Neuroarchiver_seek_time {fn seek_time} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	set max_consecutive_non_clocks 200
	set jump_scale 0.1
	
	if {$seek_time < 0} {set seek_time -1}
	set lo_time 0
	set lo_index 0
	set hi_time 0
	set hi_index 0

	scan [LWDAQ_ndf_data_check $fn] %u%u data_start data_length
	set end_index [expr $data_length / $info(message_length) - 1]

	set f [open $fn r]
	fconfigure $f -translation binary
	set jump_size $info(max_message_value)
	set value -1
	set previous_clock_value -1
	set clock_time $lo_time
	set previous_clock_time $lo_time
	set index $lo_index
	set previous_clock_index $lo_index
	set num_consecutive_non_clocks -1
	while {$index <= $end_index} {
		# We find the index'th message in the archive and read its 
		# id, value, and timestamp from the file. We won't be using
		# the timestamp.
		seek $f [expr $data_start + ($info(message_length) * $index)]
		binary scan [read $f $info(message_length)] cSc id value timestamp
		set id [expr $id & 0xff] 
		set value [expr $value & 0xffff]
		if {$id == 0} {
			# We have found a clock message.
			set num_consecutive_non_clocks 0
			
			# Check to see if this is the first clock message we have found.
			if {$previous_clock_value < 0} {
				# If this is the first clock message, as indicated by the negative
				# previous_clock_value, we intialize our clock message tracking.
				set previous_clock_value $value
				set previous_clock_time $lo_time
				set clock_time $lo_time
			} {
				# If this is not our first clock message, we save the existing clock
				# time and calculate the new clock time using the difference in the
				# clock message values. We never jump more than max_message_value 
				# messages through an archive, so we are certain that the difference
				# in the values gives us an unambiguous measurement of the time 
				# difference.
				if {$previous_clock_value != $value} {
					set previous_clock_time $clock_time
					set clock_time [expr $clock_time \
						+ 1.0 * ($value - $previous_clock_value) / $info(clocks_per_second)]
					if {$value < $previous_clock_value} {
						set clock_time [expr $clock_time + $info(clock_cycle_period)]
					}
				}
			}
			if {($clock_time > $seek_time) && ($seek_time > 0)} {
				if {$jump_size == 1} {
					# We moved one message at a time from the previous clock, which
					# had time less than the seek time, and now we arrive at a clock
					# with time greater than the seek time. So the previous and current
					# clocks straddle the seek time. The two times should be separated
					# by exactly one clock period, but their indicese can be separated
					# by many transmitter messagse. If there are missing clock messages
					# in the recording, the two times can be separated by many clock
					# periods, as when there is missing data from a recording.
					set lo_time $previous_clock_time
					set lo_index $previous_clock_index
					set hi_time $clock_time
					set hi_index $index
					set index [expr $end_index +1]
				} {
					# We jumped past the clock that is just after the seek time, or
					# there is no such clock just after the seek time. We don't know
					# which yet, but to find out, we reduce the jump size and go back 
					# to the previous clock. We must restore the clock time to the 
					# previous clock time and the index to the previous clock index.
					set jump_size [expr round($jump_scale*$jump_size)]
					set clock_time $previous_clock_time
					set index $previous_clock_index
				}
			} {
				if {$clock_time == $seek_time} {
					# This is the ideal case of seek time within the archive range
					# and we find a clock that has exactly that time. Thus the lo and
					# hi clocks are the same.
					set lo_time $clock_time
					set lo_index $index
					set hi_time $lo_time
					set hi_index $lo_index
					set index [expr $end_index +1]
				} {
					# The clock time is still less than the seek time, so we must keep
					# going to find a higher clock time. We jump farther into the archive,
					# after saving the current clock value and index.
					set previous_clock_value $value
					set previous_clock_index $index
					set index [expr $index + $jump_size]
					if {$index > $end_index} {
						if {$jump_size == 1} {
							# Our previous clock message is the last message in the archive.
							# The next clock message is the end clock, and our clock time
							# is either less than the seek time or we are seeking the end
							# time. So we use the index that is just past the end of the
							# archive and we increment our clock time by one clock period
							# to get both the lo and hi clocks.
							set lo_time [expr $clock_time + 1.0/$info(clocks_per_second)]
							set lo_index $index
							set hi_time $lo_time
							set hi_index $lo_index
						} {
							# We jumped past the end of the archive, missing some messages
							# between our current clock and the end. So reduce the jump
							# size and go back to the previous clock.
							set jump_size [expr round($jump_scale*$jump_size)]
							set index $previous_clock_index
						}
					}
				}
			}
		} {
			# This message is not a clock message. Either we have just jumped to this
			# location in the archive, ready to search for the next clock message, or 
			# we have been stepping through the archive one message at a time performing
			# the search. We must step to the next message.
			incr index

			# We keep track of the number of non-clocks. If we encounter more than is
			# possible in valid data, we force another jump. If this jump takes us past
			# the end of the archive, we set the time and index parameters as best
			# we can.
			incr num_consecutive_non_clocks
			if {$num_consecutive_non_clocks >= $max_consecutive_non_clocks} {
				set num_consecutive_non_clocks 0
				set index [expr $index + $jump_size]
				if {$index > $end_index} {
					set lo_time [expr $clock_time + 1.0/$info(clocks_per_second)]
					set lo_index $index
					set hi_time $lo_time
					set hi_index $lo_index
					break
				}
			}
			
			if {$index > $end_index} {
				# Our index now points past the end of the archive, to the end clock.
				if {$jump_size <= 1} {
					# The jump size is 1, which means we have examined every message 
					# between the previous clock and the end clock. So we can determine
					# the end clock time by adding a clock period to the previous clock
					# time. We know that the previous clock time was either less than
					# the seek time or we were seeking the end clock, so we will use
					# the end clock for both our clocks.
					set lo_time [expr $clock_time + 1.0/$info(clocks_per_second)]
					set lo_index $index
					set hi_time $lo_time
					set hi_index $lo_index
				} {
					# The jump size is more than 1, so we may have jumped over a clock
					# message that lies between the previous clock and the end clock. 
					# We must go back to the previous clock and use a smaller jump size.
					set index $previous_clock_index
					set jump_size [expr round($jump_scale*$jump_size)]
				}
			}
		}

		LWDAQ_support
	}

	close $f

	if {$num_consecutive_non_clocks >= $max_consecutive_non_clocks} {
		Neuroarchiver_print "WARNING: Archive contains severely corrupted data."
	}
	
	return "$lo_time $lo_index $hi_time $hi_index"
}

#
# Neuroarchiver_end_time determines the time interval spanned by a file.
# It calls Neuroarchiver_seek_time with value -1 to obtain the length of 
# the archive. We curtail the end time to two decimal places in order to
# avoid display problems for archives that have unusual end times as a result
# of data loss during recording.
#
proc Neuroarchiver_end_time {fn} {
	scan [Neuroarchiver_seek_time $fn -1] %f%u%f%u lo_time lo_index hi_time hi_index
	return [Neuroarchiver_play_time_format $hi_time]
}

#
# Neuroarchiver_filter is for use in processor scripts as a means of detecting
# events in a signal. The routine scales the amplitude of the discrete transform 
# components according to four numbers, which specify the center of a pass-band
# and the upper and lower extremes of the pass-band. The scaling is linear,
# which is not something we can do easily with recursive filters, or with
# analog filters, but is simple in software. The four numbers are band_lo_end,
# band_lo_center, band_hi_center, and band_hi_end. They are in units of frequency.
# Components below band_lo_end and above band_hi_end are multiplied by zero. 
# Components between band_lo_end and band_lo_center are scaled by zero to one
# from the lower to the upper frequency. Components from band_lo_center to 
# band_hi_center are added as they are. Components from band_hi_center to
# band_hi_end are scaled from one to zero from the lower to the upper frequency.
# Thus we have a pass-band that might be sharp or gentle. We can implement
# a high-pass filter by setting band_lo_end and band_lo_center to zero. The
# routine returns the total power of the remaining components, which is the
# sum of their squares. We do not multiply the combined power by any scaling
# factor because there are several variants of the discrete fourier transform
# with different scaling factors, and we want to avoid hiding such multiplications
# in our code. If show is set, the routine plots the filtered signal on the 
# screen by taking the inverse transform of the selected frequency components. 
# If values is set, the routine calculates the inverse transform of the filtered 
# signal, making it available to the calling routine in the info(values) variable. 
# By default, the routine does not plot nor does it perform the inverse transform, 
# both of which take time and slow down processing. The show parameter, if not 
# zero, is used to scale the signal for display.
#
proc Neuroarchiver_filter {band_lo_end band_lo_center \
		band_hi_center band_hi_end \
		{show 0} {values 0}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	# Check the inputs.
	foreach f "$band_lo_end $band_lo_center $band_hi_center $band_hi_end" {
		if {![string is double -strict $f]} {
			error "invalid frequency \"$f\""
		}
	}
	if {$band_lo_end > $band_lo_center} {
		error "cannot have band_lo_end > band_lo_center"
	}
	if {$band_lo_center > $band_hi_center} {
		error "cannot have band_lo_center > band_hi_center"
	}
	if {$band_hi_center > $band_hi_end} {
		error "cannot have band_hi_center > band_hi_end"
	}

	# Check the current spectrum.
	if {[llength $info(spectrum)] <= 1} {
		error "no spectrum exists to filter"
	}
	
	# Filter the current spectrum and calculate the total power.
	set filtered_spectrum ""
	set f 0
	set band_power 0.0
	foreach {a p} $info(spectrum) {
		if {($f > $band_lo_end) && ($f < $band_lo_center)} {
			set b [expr $a*($f-$band_lo_end)/($band_lo_center-$band_lo_end)]
		} elseif {($f >= $band_lo_center) && ($f <= $band_hi_center)} {
			set b $a
		} elseif {($f > $band_hi_center) && ($f < $band_hi_end)} {
			set b [expr $a*($f-$band_hi_center)/($band_hi_end-$band_hi_center)]
		} else {
			set b 0.0
		}
		append filtered_spectrum "$b $p "
		set band_power [expr $band_power + ($b * $b)]
		set f [expr $f + $info(f_step)]
	}

	# If show or values, take the inverse transform. The filtered
	# values will be available to the calling procedure in a variable
	# of the same name.
	if {$show || $values} {
		set filtered_values [lwdaq_fft $filtered_spectrum -inverse 1]
	}
	
	# If show, plot the filtered signal to the screen. If our  
	# frequency band does not include zero, we add the zero-frequency
	# component to every sample value so that the filtered signal 
	# will be super-imposed upon the unfiltered signal in the display.
	if {$show} {
		if {$band_lo_center > 0} {
			set offset [lindex $info(spectrum) 0]
		} {
			set offset 0
		}
		set filtered_signal ""
		set timestamp 0
		foreach {v} $filtered_values {
			append filtered_signal "$timestamp [expr $show*$v + $offset] "
			incr timestamp
		}
		Neuroarchiver_plot_signal [expr $info(channel_num) + 32] $filtered_signal
	}
	
	# If values, replace the existing info(values) string with the new
	# filtered values.
	if {$values} {
		set info(values) $filtered_values
	}
	
	# Return the power.
	return $band_power
}

#
# Neuroarchiver_band_power is for use in processor scripts as a means of detecting
# events in a signal. The routine selects the frequency components in
# $info(spectrum) that lie between band_lo and band_hi Hertz (inclusive), adds the
# power of all components in this band, and returns the total. If show is set, the
# routine plots the filtered signal on the screen by taking the inverse transform
# of the selected frequency components. If values is set, the routine calculates
# the inverse transform of the filtered signal, making it available to the calling
# routine in the info(values) variable. By default, the routine does not plot
# nor does it perform the inverse transform, both of which take time and slow down
# processing.
#
proc Neuroarchiver_band_power {band_lo band_hi {show 0} {values 0}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	# Check the inputs.
	foreach f "$band_lo $band_hi" {
		if {![string is double -strict $f]} {
			error "unvalid frequency \"$f\""
		}
	}
	if {$band_lo > $band_hi} {
		error "cannot have band_lo_end > band_lo_center"
	}
	
	# Check the current spectrum.
	if {[llength $info(spectrum)] <= 1} {
		error "no spectrum exists to filter"
	}
	
	# We call Neuroarchiver_filter with sharp upper and lower edges to 
	# the pass band, and so obtain the power, plot the inverse, and prepare
	# the inverse if requested.
	return [Neuroarchiver_filter $band_lo $band_lo $band_hi $band_hi $show $values]
}

#
# Neuroarchiver_command handles the various control commands generated by
# the record and play buttons. It refers to the LWDAQ event queue
# with the global LWDAQ_Info(queue_events) variable. The event queue
# is LWDAQ's way of getting several independent processes to run at
# the same time without coming into conflict when they access shared
# variables and shared data acquisition hardware. The TCL interpreter
# does provide several forms of multi-tasking, but none of them are
# adequate for our purposes. This procedure controls the record
# process when $target == record and the play process when $target ==
# play.
#
proc Neuroarchiver_command {target action} {
	upvar #0 Neuroarchiver_info info
	global LWDAQ_Info

	set event_executing [string match "Neuroarchiver_$target\*" $LWDAQ_Info(current_event)]
	set event_pending 0
	foreach event $LWDAQ_Info(queue_events) {
		if {[string match "Neuroarchiver_$target\*" $event]} {
			set event_pending 1
		}
	}

	if {$action != $info($target\_control)} {
		if {!$event_executing} {
			set info($target\_control) $action
			if {!$event_pending} {
				if {$action != "Stop"} {
					LWDAQ_post Neuroarchiver_$target
				} {
					set info($target\_control) "Idle"
				}
			}
		} {
			if {$action != "Stop"} {
				LWDAQ_post [list Neuroarchiver_command $target $action]	
			} {
				set info($target\_control) $action
			}
		}
	}
	
	return "$target $action"
}

#
# Neuroarchiver_signal extracts or reconstructs the signal from one channel in the
# data image. It updates config(unaccepted_values), updates info(num_received)
# config(standing_values), sets info(frequency), sets info(num_messages), and
# returns the extracted or reconstructed signal. The signal is a sequence of
# messsages. Each message is a timestamp followed by a sample value. The timestamp
# is an integer number of clock ticks from the beginning of the playback interval.
# The timestamps and vsample alues alternate in the return string, separated by
# single spaces. The "extracted" signal is a list of messages that exist in the
# data image. The "reconstructed" signal is the extracted signal with substitute
# messages inserted and bad messages removed, so as to create a signal with
# info(frequency) messages. To perform extraction and reconstruction, the routine
# calls lwdaq_recorder from the lwdaq library. See the Recorder Manual for more
# information, and also the LWDAQ Command Reference. The routine takes a single
# parameter: a channel code, which is of the form "id" or "id:f" or "id:f:s" where
# "id" is the channel number, "f" is its nominal message rate per second, and "s"
# is the transmission scatter in clock ticks.
# 
proc Neuroarchiver_signal {{channel_code ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	
	# We split the channel code into id, frequency, and scatter, and
	# we do so in such a way that if frequency and scatter are not
	# specified, we don't get an error.
	if {$channel_code == ""} {set channel_code $info(channel_code)}
	set parameters [split $channel_code ":"] 
	set id [lindex $parameters 0]
	set frequency [lindex $parameters 1]
	set scatter [lindex $parameters 2]
	
	# We look up how many messages were received in the activity string.
	set num_received 0
	if {[regexp " $id:(\[0-9\]*)" $info(channel_activity) m a]} {
		set num_received $a 
	}
	set info(num_received) $num_received

	# We set the frequency if it is not already set. The default
	# frequency can be a single frequency or a list of frequencies,
	# the closest of which to the number of messages received is the
	# one that will be picked. If our search for a good frequency fails
	# because there are too many messages, we use the highest frequency
	# in the default list.
	if {![string is integer -strict $frequency]} {
		set fl [lsort -increasing [string trim $config(default_frequency)]]
		set frequency [lindex $fl end]
		foreach f $fl {
			if {![string is integer -strict $f]} {
				Neuroarchiver_print "ERROR: Invalid frequency \"$f\" in default frequency list."
				return "0 0 "	
			}
			if {$num_received < [expr 1.1 * $f * $config(play_interval)]} {
				set frequency $f
			}
		}
	}
	set info(frequency) $frequency
	set info(f_$id) $frequency
	
	# We calculate the number of messages expected and the period
	# of the nominal sample rate in clock ticks.
	set num_expected [expr $frequency * $config(play_interval)]
	set period [expr round(1.0 * $info(ticks_per_clock) \
		* $info(clocks_per_second) / $frequency)]
	
	# Set the scatter if it's not defined.
	if {![string is integer -strict $scatter]} {
		set scatter $config(default_scatter)
	}
	
	# Reconstruct of extract the signal.	
	if {$config(enable_reconstruct)} {
		set signal [lwdaq_recorder $info(data_image) \
			"reconstruct $id $period $scatter \
				[lindex $config(standing_values) $id] \
				[lindex $config(unaccepted_values) $id]"]
	} {
		set signal [lwdaq_recorder $info(data_image) "extract $id $period"]
	}
	if {[LWDAQ_is_error_result $signal]} {
		Neuroarchiver_print $signal
		return "0 0 "	
	}

	lset config(standing_values) $id [lindex $signal end]
	set results [lwdaq_image_results $info(data_image)]
	if {$config(enable_reconstruct)} {
		scan $results %d%d%d%d num_clocks num_messages num_bad num_missing
		lset config(unaccepted_values) $id [lrange $results 4 end]
		set info(loss) [expr 100.0 * $num_missing / $num_expected]
		Neuroarchiver_print "Channel [format %2d $id],\
			[format %4.1f $info(loss)]% loss,\
			[format %4d $num_messages] reconstructed,\
			$num_bad bad." verbose
	} {
		scan $results %d%d num_clocks num_messages
		lset config(unaccepted_values) $id ""
		set info(loss) [expr 100.0 - 100.0 * $num_messages / $num_expected]
		Neuroarchiver_print "Channel [format %2d $id],\
			[format %4.1f $info(loss)]% loss,\
			[format %4d $num_messages] extracted." verbose
	}
	
	set info(num_messages) $num_messages

	return $signal
}

#
# Neuroarchiver_values extracts only the voltage values from the Neuroarchiver
# signal. If there are values missing, it adds values so that we have a power
# of two number of values to pass to the fft later. If there are too many values,
# we remove some until the number is correct.
#
proc Neuroarchiver_values {{signal ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	if {$signal == ""} {set signal $info(signal)}

	set values ""
	foreach {t v} $info(signal) {append values "$v "}
	
	if {!$config(enable_reconstruct)} {
		set missing [expr round($info(frequency) * $config(play_interval) \
			- [llength $values])]
		for {set m 1} {$m <= $missing} {incr m} {
			append values "[lindex $values end] "
		}
		for {set m $missing} {$m < 0} {incr m} {
			set values [lreplace $values end end]
		}
	}
		
	return $values
}

#
# Neuroarchiver_spectrum calculates the discrete frourier transform of the signal. It
# returns the spectrum as a sequence of real numbers separated by spaces. Each pair
# of numbers is the amplitude and phase of a component in the transform. The k'th
# pair represent the cosinusoidal component of frequency k/t, where t is the play
# interval. If we pass an empty string to the routine, it uses info(values). The 
# procedure calls the lwdaq_fft. You can read more about the fourier transform 
# routine in the LWDAQ Command Reference. Before taking the transform, we apply
# a glitch filter with threshold glitch_threshold to remove bad message spikes.
#
proc Neuroarchiver_spectrum {{values ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	upvar result result
	
	if {$values == ""} {set values $info(values)}

	set info(f_step) [expr 1.0/$config(play_interval)]	
	set spectrum [lwdaq_fft $values \
		-glitch $config(glitch_threshold) \
		-window [expr round([llength $values] * $config(window_fraction))]]
	if {[LWDAQ_is_error_result $spectrum]} {
		Neuroarchiver_print $spectrum
		set spectrum "0 0 "
	}
	
	LWDAQ_support
	return $spectrum
}

#
# Neuroarchiver_overview displays an overview of a file's contents. This
# routine sets up the overview window and calles a plot routine to sample
# the archvie and plot the results. An Export button provides a way to
# export the graph data to disk for plotting in other programs.
#
proc Neuroarchiver_overview {{fn ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	global LWDAQ_Info
	
	# Delete all unused overview images.
	foreach name [image names] {
		if {![image inuse $name]} {
			if {[string match "_neuroarchiver_ov_photo_*" $name]} {
				image delete $name
			}
		}
	}

	# Open a new toplevel window and a global configuration array.
	set i 1
	while {[winfo exists [set w $info(window)\.overview_$i]]} {incr i}
	upvar #0 Neuroarchiver_overview_$i ov_config
	toplevel $w
	set ov_config(w) $w

	# Use the play file if none is specified.
	if {$fn != ""} {
		set ov_config(fn) $fn
	} {
		set ov_config(fn) $config(play_file)
	}
	
	# Set title of window.
	wm title $w "Overview of [file tail $ov_config(fn)]"

	# Create a new photo in which to plot our graph.
	set ov_config(photo) [image create photo "_neuroarchiver_ov_photo_$i" \
		-width $info(overview_width) -height $info(overview_height)]

	# Initialize the display parameters.
	set ov_config(t_min) 0
	set ov_config(t_max) 0
	set ov_config(num_samples) $config(overview_num_samples)
	set ov_config(activity) ""
	set ov_config(select) $config(channel_select)
	set ov_config(status) "Idle"
	foreach v {v_range v_offset ac_couple} {
		set ov_config($v) $config($v)
	}
	
	# Create graph display.
	set f $w.graph
	frame $f -relief sunken
	pack $f -side top -fill x
	label $f.graph -image $ov_config(photo)
	pack $f.graph -side top	
	
	# Create value controls.	
	set f $w.value
	frame $f 
	pack $f -side top -fill x
	label $f.status -textvariable Neuroarchiver_overview_$i\(status) \
		-fg blue -bg white -width 10
	pack $f.status -side left -expand 1
	button $f.plot -text "Plot" -command \
		[list LWDAQ_post [list Neuroarchiver_overview_plot $i 0]]
	pack $f.plot -side left -expand 1
	button $f.export -text "Export" -command \
		[list LWDAQ_post [list Neuroarchiver_overview_plot $i 1]]
	pack $f.export -side left -expand 1
	checkbutton $f.ac -text "AC" -variable Neuroarchiver_overview_$i\(ac_couple)
	pack $f.ac -side left -expand 1
	foreach v {v_range v_offset num_samples} {
		label $f.l$v -text $v
		entry $f.e$v -textvariable Neuroarchiver_overview_$i\($v) -width 8
		pack $f.l$v $f.e$v -side left -expand 1
	}	

	# Create time controls
	set f $w.time
	frame $f 
	pack $f -side top -fill x
	label $f.lt_min -text "t_min"
	entry $f.et_min -textvariable Neuroarchiver_overview_$i\(t_min) -width 8
	label $f.ls -text "Select:" -anchor e
	label $f.lt_max -text "t_max"
	entry $f.et_max -textvariable Neuroarchiver_overview_$i\(t_max) -width 8
	entry $f.es -textvariable Neuroarchiver_overview_$i\(select) -width 35
	label $f.lt_end -text "t_end"
	label $f.et_end -textvariable Neuroarchiver_overview_$i\(t_end) -width 8
	pack $f.lt_min $f.et_min $f.lt_max $f.et_max \
		$f.lt_end $f.et_end $f.ls $f.es -side left -expand 1

	# Create activity display
	set f $w.activy
	frame $f
	pack $f -side top -fill x
	label $f.la -text "Points Used (id:qty):" -anchor e
	label $f.ea -textvariable Neuroarchiver_overview_$i\(activity) \
		-anchor w -width 70 -bg gray
	pack $f.la $f.ea -side left -expand 1
	
	LWDAQ_update 
	
	# Get the end time of the archive and check the file syntax.
	set ov_config(status) "Seeking"
	if {[catch {
		set ov_config(t_end) [Neuroarchiver_end_time $ov_config(fn)]
	} message]} {
		Neuroarchiver_print "ERROR: $message."
		return 0
	}
	set ov_config(t_max) $ov_config(t_end)
	set ov_config(status) "Idle"

	Neuroarchiver_overview_plot $i
	
	return 1
}

#
# Neuroarchiver_overview_plot selects an existing overview window and re-plots
# its graphs using the current display parameters. If the export parameter is 
# non-zero, the routine exports the selected channels each to a separate file
# named En.txt, where n is the channel number. Each line in the export file 
# will contain the archive time of a sample and the sample value. These files
# will be written to the same directory that contains the overview archive.
#
proc Neuroarchiver_overview_plot {i {export 0}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_overview_$i ov_config
	global LWDAQ_Info

	# Check the window and declare the overview array.
	if {![info exists ov_config]} {return 0}
	if {![winfo exists $ov_config(w)]} {return 0}
	set w $ov_config(w)
	if {$ov_config(status) != "Idle"} {return 0}

	# Check that the archive exists and is an ndf file. Extract the
	# data start address and data length.
	if {[catch {
		scan [LWDAQ_ndf_data_check $ov_config(fn)] %u%u data_start data_length
	} message]} {
		Neuroarchiver_print "ERROR: $message."
		return 0
	}
	
	# Draw a grid on the overview graph.
	lwdaq_graph "0 0" $info(overview_image) -fill 1 \
		-x_min 0 -x_max 1 -x_div $config(overview_t_div) \
		-y_min 0 -y_max 1 -y_div $config(v_div) \
		-color 1
	lwdaq_draw $info(overview_image) $ov_config(photo)
	set ov_config(activity) ""
	LWDAQ_update
	
	# Check the input parameters.
	if {$ov_config(t_min) < 0} {set ov_config(t_min) 0}
	if {$ov_config(num_samples) <= 1} {set ov_config(num_samples) 1}
	
	# Create an array of graphs, one for each possible channel.
	for {set id 0} {$id < $info(max_id)} {incr id} {
		set graph($id) ""
	}

	# Seek the clock message just before and just after the plot interval.
	set ov_config(status) "Seeking"
	LWDAQ_update
	scan [Neuroarchiver_seek_time $ov_config(fn) $ov_config(t_min)] \
		%f%u%f%u ov_config(t_min) index_min dummy1 dummy2
	scan [Neuroarchiver_seek_time $ov_config(fn) $ov_config(t_max)] \
		%f%u%f%u dummy1 dummy2 ov_config(t_max) index_max

	# Read num_samples messages from the archive at random locations.
	set ov_config(status) "Reading"
	set ave_step [expr 2.0 * ($index_max - $index_min) / $ov_config(num_samples)]
	set addr [expr $data_start + $info(message_length) * $index_min]
	set addr_end [expr $data_start + $info(message_length) * $index_max]
	set f [open $ov_config(fn) r]
	fconfigure $f -translation binary
	set samples ""
	while {$addr < $addr_end} {
		LWDAQ_support
		seek $f $addr
		binary scan [read $f $info(message_length)] cSc id value timestamp
		lappend samples "[expr $id & 0xff] [expr $value & 0xffff]"
		set addr [expr $addr + $info(message_length) * round(1 + ($ave_step-1)*rand())]
	}
	close $f
	
	# Go through the list of messages, calculating the time of each message
	# by interpolating between the times of existing clock messages. We assume
	# that less than one clock cycle period (that's 512 s) passes between clock 
	# messages so that we can keep time by looking at the clock message values.
	set ov_config(status) "Analyzing"
	LWDAQ_update
	set offset_time -1
	set lo_time $ov_config(t_min)
	set time_step 0
	set previous_clock_index 0
	set clock_cycles 0
	set previous_clock 0
	for {set sample_num 0} {$sample_num < [llength $samples]} {incr sample_num} {
		scan [lindex $samples $sample_num] %u%u id value
		if {$id == 0} {
			if {$value < $previous_clock} {incr clock_cycles}
			set previous_clock $value
			set lo_time [expr $info(clock_cycle_period) * $clock_cycles \
				+ (1.0 * $previous_clock / $info(clocks_per_second))]
			if {$offset_time < 0} {set offset_time $lo_time}
			set lo_time [expr $lo_time - $offset_time]
			set next_clock_sample_num [lsearch -start \
				[expr $sample_num + 1] -index 0 $samples 0]
			if {$next_clock_sample_num > 0} {
				set next_clock [lindex $samples $next_clock_sample_num 1]
				set hi_time [expr $clock_cycles * $info(clock_cycle_period) \
					+ (1.0 * $next_clock / $info(clocks_per_second)) - $offset_time]
				if {$next_clock < $previous_clock} {
					set hi_time [expr $hi_time + $info(clock_cycle_period)]
				}
				set time_step [expr ($hi_time - $lo_time) \
					/ ($next_clock_sample_num - $sample_num)]
			} {
				set hi_time [expr $ov_config(t_max) - $ov_config(t_min)]
				set time_step [expr ($hi_time - $lo_time) \
					/ ([llength $samples] - $sample_num)]
			}
			set previous_clock_index $sample_num
			set archive_time [expr $lo_time + $ov_config(t_min)]
		} {
			set archive_time [expr $lo_time \
				+ $time_step * ($sample_num - $previous_clock_index) \
				+ $ov_config(t_min)]
		}
		lappend graph($id) "[format %.3f $archive_time] $value"
	}	
	
	# Create the plot viewing ranges from the user parameters.
	if {$ov_config(ac_couple)} {
		set v_min [expr $ov_config(v_offset) - $ov_config(v_range) / 2 ]
		set v_max [expr $ov_config(v_offset) + $ov_config(v_range) / 2]
	} {
		set v_min $ov_config(v_offset)
		set v_max [expr $ov_config(v_offset) + $ov_config(v_range)]
	}

	# Plot all graphs that have more than the activity threshold number of 
	# points in them.
	if {$export} {
		set ov_config(status) "Exporting"
	} {
		set ov_config(status) "Plotting"
	}
	set ov_config(activity) ""
	for {set id 0} {$id < $info(max_id)} {incr id} {
		LWDAQ_update
		if {![winfo exists $w]} {return 0}
		if {[llength $graph($id)] < \
			[expr $config(overview_activity_fraction)\
			* $ov_config(num_samples)]} {continue}
		append ov_config(activity) "$id:[llength $graph($id)] "
		if {($ov_config(select) != "*") \
			&& ([lsearch $ov_config(select) "$id\*"] < 0)} {continue}
		if {($ov_config(select) == "*") \
			&& ($id == 0)} {continue}
		set graph_string [join $graph($id)]
		if {[string length $graph_string] > $LWDAQ_Info(lwdaq_long_string_capacity)} {
			Neuroarchiver_print "ERROR: Too many points in overview of No$id."
			continue
		}
		lwdaq_graph $graph_string $info(overview_image) \
			-x_min $ov_config(t_min) -x_max $ov_config(t_max) \
			-y_min $v_min -y_max $v_max \
			-color [lindex $config(color_table) $id] -ac_couple $ov_config(ac_couple) 
		lwdaq_draw $info(overview_image) $ov_config(photo)
		if {$export} {
			set f [open [file join [file dirname $ov_config(fn)] E$id\.txt] w]
			foreach p $graph($id) {puts $f $p}
			close $f
		}		
	}
	
	# Done.
	set ov_config(status) "Idle"
	return 1
}

#
# Neuroclassifier allows us to view, jump to, and manipulate a list 
# of reference events with which new events may be compared for
# classification. The event classifier lists events like this:
#
# archive.ndf time channel event_type baseline_power m1 m2...
#
# It expects the Neuroarchiver's processor to produce characteristics
# lines in the same format, except the line can contain characteristics
# for multiple channels. The baseline power should be in units of kilo
# square ADC counts. The remaining characteristics are "metrics", which
# each indicated something about the shape of the interval signal, and
# which vary between 0 to 1, with 0.5 being roughly in the middle of 
# the expected range for recorded data. In particular, the Classifier
# assumes that a value of 0.5 or greater in the metric1 characteristic
# indicates an event worthy of classification has occurred. We reserve 
# three event type words for the processor to allocate to each interval
# before classification, "N" for "Normal", meaning no event has occurred,
# "U" for "Unclassified", meaning the event has not yet been compared to
# a set of reference events for classification, and "L" for "Loss", meaning
# reception is poor.
#
proc Neuroclassifier_open {} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	# Size of the map and its points.
	set info(classifier_map_size) 450
	set info(classifier_point_size) 10
	
	# Some internal variables.
	set info(classifier_index) 0
	set info(classifier_continue) 0
	catch {unset info(reprocessing_event_list)}

	# Channel id index in a reference event.
	set info(cii) 2 
	
	# Event type location, offset from channel id.
	set info(cto) 1 

	# Baseline power location, offset from channel id.
	set info(cbo) 2 

	# Open the classifier window.
	set w $info(classifier_window)
	if {[winfo exists $w]} {
		raise $w
		return 0
	}
	toplevel $w
	wm title $w "Event Classifier for Neuroarchiver Version $info(version)"
	
	# Create the classifier user interface.
	frame $w.controls1
	pack $w.controls1 -side top -fill x
	
	set f $w.controls1
	label $f.cv -text "0 Events" -width 15 -bg black -fg white
	set info(classification_label) $f.cv
	pack $f.cv -side left -expand yes

	label $f.rl -text "Match:" 
	label $f.rv -textvariable Neuroarchiver_info(classifier_match) -width 5 
	pack $f.rl $f.rv -side left -expand yes

	label $f.mrl -text "Limit:" 
	entry $f.mre -textvariable Neuroarchiver_config(classifier_match_limit) -width 5
	pack $f.mrl $f.mre -side left -expand yes

	label $f.etl -text "Threshold:" 
	entry $f.ete -textvariable Neuroarchiver_config(classifier_threshold) -width 5
	pack $f.etl $f.ete -side left -expand yes

	foreach a {Add Continue Play Stop Batch_Classification} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Neuroclassifier_$b"
		pack $f.$b -side left -expand yes
	}

	frame $w.controls2
	pack $w.controls2 -side top -fill x
	set f $w.controls2
	foreach a {x y} {
		label $f.$a\ml -text "$a\:"
		set info(classifier_$a\_menu) [tk_optionMenu $f.$a\m \
			Neuroarchiver_config(classifier_$a\_metric) "none"]
		pack $f.$a\ml $f.$a\m -side left -expand yes
	}

	checkbutton $f.handler -text "Handler" \
		-variable Neuroarchiver_config(enable_handler)
	pack $f.handler -side left -expand yes
	
	foreach a {Refresh Load Save Reprocess Compare} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_post Neuroclassifier_$b"
		pack $f.$b -side left -expand yes
	}

	frame $w.data
	pack $w.data -side top -expand yes -fill both
	
	frame $w.data.metrics
	pack $w.data.metrics -side left
	
	set c [canvas $w.data.metrics.map \
		-height $info(classifier_map_size) \
		-width $info(classifier_map_size) \
		-bd 2 -relief sunken]
	set info(classifier_map) $c
	pack $c -side left -fill y
	
	frame $w.data.events
	pack $w.data.events -side left -expand yes -fill both
	
	set t [LWDAQ_text_widget $w.data.events 50 10 1 1]
	LWDAQ_enable_text_undo $t
	$t tag configure jumpbutton -background green
	$t tag configure changebutton -background orange
	$t tag bind "jumpbutton changebutton" <Enter> {%W configure -cursor arrow} 
	$t tag bind "jumpbutton changebutton" <Leave> {%W configure -cursor xterm} 
	set info(classifier_text) $t
		
	Neuroclassifier_display ""
}

#
# Neuroclassifier_plot takes an event and plots it at a point in the map
# given by the x and y metrics selected by the user. These metrics come from
# the characteristics provided with the event string. The color of the point
# on the map is given by the list of event types and colors in the Classifier
# types parameter. The relationship between the names of metrics and their
# location in the characteristics is given by the Classifier metrics 
# parameters. Point (0,0) is the lower-left corner of the map. Point (1,1)
# is the upper-right corner. The tag allows the routine to tag the point
# it plots. If the tag is "displayed", we plot the point as a white square
# with tag "displayed" and "event". Otherwise, the routine deletes all points
# with tag $tag and plots the new point with the event type color.
#
proc Neuroclassifier_plot {tag event} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	set pointsize $info(classifier_point_size)
	set c $info(classifier_map)

	set x 0
	set y 0
	set metric_index [expr $info(cii)+$info(cbo)+1]
	foreach metric $config(classifier_metrics) {
		set m [lindex $event $metric_index]
		if {$m == ""} {break}
		if {[string match -nocase $metric $config(classifier_x_metric)]} {
			set x [expr $m * $info(classifier_map_size)]
		}
		if {[string match -nocase $metric $config(classifier_y_metric)]} {
			set y [expr $info(classifier_map_size) * (1 - $m)]
		}
		incr metric_index
	}
		
	set type [lindex $event [expr $info(cii)+$info(cto)]]
	set color white
	foreach {et fc} [string trim "$config(classifier_types) Unknown black"] {
		if {[string match -nocase $et $type]} {
			set color $fc
		}
	}

	if {$tag != "displayed"} {
		# For library events, we create a point with the color
		# corresponding to the type, and we set the point so that
		# clicking on it jumps to the event.
		$c delete $tag
		set point [$c create rectangle $x $y \
			[expr $x+$pointsize] [expr $y+$pointsize] \
			-fill $color -tag "event $tag"]
		$c bind $tag <Button> [list Neuroclassifier_jump $event]
	} {
		# For displayed events, we plot a white point and we leave
		# it to the classifier processing routine to delete all
		# displayed points before arranging to plot the new set
		# of displayed points.
		set point [$c create rectangle $x $y \
			[expr $x+$pointsize] [expr $y+$pointsize] \
			-fill white -tag "event displayed"]
	}	
	
	# Set the classification label text and color.
	if {$color != "black"} {
		$info(classification_label) configure -text $type \
			-fg black -bg $color
	} {
		$info(classification_label) configure -text $type \
			-fg $color -bg white
	}

	return $point
}

#
# Neuroclassifier_event takes the file name, file time, and channel 
# number of an event and looks for it in the Classifier text window. 
# It returns the event as it appears in the text window, or returns 
# the event it was passed otherwise.
#
proc Neuroclassifier_event {event} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	set t $info(classifier_text)
	set index [$t search [lrange $event 0 $info(cii)] 1.0]
	if {$index != ""} {
		set event [$t get "$index" "$index lineend"]
	}
	return $event
}

#
# Neuroclassifier_select hilites and event in the text window.
#
proc Neuroclassifier_select {event} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	# We remove any hilites in the text window.
	set t $info(classifier_text)
	$t tag delete hilite

	# We locate the most up to date form of the event in the
	# text window. If we can't find the event in the text window,
	# we abort.
	set index [$t search [lrange $event 0 $info(cii)] 1.0]
	if {$index != ""} {
		set event [$t get "$index" "$index lineend"]
	} {
		Neuroarchiver_print "ERROR: Cannot find event \"[lrange $event 0 2]\"."
		return 0
	}

	# We hilite the event and move it into the visible area of the
	# text window.
	$t tag add hilite "$index" "$index lineend"
	$t tag configure hilite -background lightgreen
	$t see $index
}

#
# Neuroclassifier_jump jumps to an event.
#
proc Neuroclassifier_jump {event} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	Neuroclassifier_select $event
	Neuroarchiver_jump $event
}

#
# Neuroclassifier_change finds an event in the text window
# and changes its event type. It then re-plots the event in the map.
#
proc Neuroclassifier_change {event} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	# Find the event in the text window.
	set t $info(classifier_text)
	set index [$t search [lrange $event 0 $info(cii)] 1.0]
	
	if {$index != ""} {
		# Extract the event, delete the line, change the type
		# and insert the new event string into the text window.
		set event [$t get "$index" "$index lineend"]
		$t delete "$index" "$index lineend"
		set type [lindex $event [expr $info(cii)+$info(cto)]]
		set type_index [lsearch "$config(classifier_types) Unknown black" $type]
		if {$type_index > 1} {
			lset event [expr $info(cii)+$info(cto)]\
				[lindex "$config(classifier_types) Unknown black" $type_index-2]
		} {
			lset event [expr $info(cii)+$info(cto)]\
				[lindex "$config(classifier_types) Unknown black" end-1]
		}
		$t insert $index $event

		# Hilite the event in the text window.
		Neuroclassifier_select $event

		# Determine the event's index using the tag on its Go button,
		# and use this to re-plot the event in its new color.	
		set go_index [lindex [split $index .] 0]\.1
		set tags [$t tag names $go_index]
		if {[regexp {event_([0-9]+)} $tags tag event_index]} {
			Neuroclassifier_plot event_$event_index $event
		} 
	} {
		Neuroarchiver_print "ERROR: Cannot find event \"[lrange $event 0 $info(cii)]\"."
	}
}

#
# Neuroclassifier_add adds an event to the event list. If the event
# is empty, the routine composes the event from the displayed play
# interval, and so adds the displayed interval to the event list. In
# doing so, the routine also jumps to the interval so as to set the
# characteristics of the event. The index we pass to the routine tells 
# it how to tag the buttons in the event line.
#
proc Neuroclassifier_add {{index ""} {event ""}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	if {$index == ""} {
		set index $info(classifier_index)
		incr info(classifier_index)
	}
	if {$event == ""} {
		set id [lindex $config(channel_select) 0]
		if {([llength $id]>1) || ($id == "*")} {
			raise $info(window)
			Neuroarchiver_print "ERROR: Select a single channel to add to the library."
			return ""
		}
		set event "[file tail $config(play_file)]\
			[Neuroarchiver_play_time_format \
				[expr $config(play_time) - $config(play_interval)]]\
			$id\
			Added"
		set jump 1
	} {
		set jump 0
	}
	
	set t $info(classifier_text)
	$t insert end " "
	$t tag bind event_$index <Button> [list Neuroclassifier_jump $event]
	$t insert end "<J>" "event_$index jumpbutton"
	$t tag bind type_$index <Button> [list Neuroclassifier_change $event]
	$t insert end "<C>" "type_$index changebutton"
	$t insert end " $event\n"
	$t see end
	
	if {$jump} {Neuroclassifier_jump $event}

	return $event
}

#
# Neuroclassifier_display writes an entire event list to 
# the classifier text window and plots the events on the map.
#
proc Neuroclassifier_display {event_list} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	# Clear the text window and map.
	set t $info(classifier_text)
	set c $info(classifier_map)
	$t delete 1.0 end
	$c delete event
	
	# Plot grid lines in map.
	set b $info(classifier_map_size)
	set s [expr $b * 0.1]
	for {set a [expr $b + 4]} {$a >= 0.0} {set a [expr $a - $s]} {
		$c create line 0.0 $a $b $a -fill gray
		$c create line $a 0.0 $a $b -fill gray
	}
	$c create line 0.0 $b $b $b -fill gray
	$c create line $b 0.0 $b $b -fill gray
	
	# Print and plot the events in turn.
	set info(classifier_index) 1
	set info(classifier_display_control) "Run"
	foreach event $event_list {
		Neuroclassifier_add $info(classifier_index) $event
		Neuroclassifier_plot event_$info(classifier_index) $event
		incr info(classifier_index)
		LWDAQ_support
		if {$info(classifier_display_control) != "Run"} {
			return 0
		}
	}

	# Set up the x and y metric selection menues. Make sure the current 
	# value of the metric menus is one of those available.
	foreach a {x y} {
		$info(classifier_$a\_menu) delete 0 end
		foreach b $config(classifier_metrics) {
			$info(classifier_$a\_menu) add command -label $b \
				-command "set Neuroarchiver_config(classifier_$a\_metric) $b"
		}
		if {[lsearch $config(classifier_metrics) $config(classifier_$a\_metric)] < 0} {
			set config(classifier_$a\_metric) "none"
		}
	}

	# Display the number of reference events in the classification
	# label.
	set num_events [llength $event_list]
	$info(classification_label) configure \
		-text "$num_events Events" -fg white -bg black

	# Return the number of events displayed.
	return $num_events
}

#
# Neuroclassifier_event_list extracts an event list from the text
# window.
#
proc Neuroclassifier_event_list {} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	set t $info(classifier_text)
	set contents [split [string trim [$t get 1.0 end]] \n]
	set event_list ""
	foreach event $contents {
		while {![string match -nocase "*.ndf" [lindex $event 0]]} {
			set event [lrange $event 1 end]
		}
		if {([llength $event] >= $info(cii)+$info(cbo))} {
			lappend event_list $event
		}
	}
	return $event_list
}

#
# Neuroclassifier_refresh extracts the event list from the text window,
# then calls the list command to re-write the text window and re-plot
# the map.
#
proc Neuroclassifier_refresh {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	set event_list [Neuroclassifier_event_list]
	Neuroclassifier_display $event_list
	return [llength $event_list]
}

#
# Neuroclassifier_classify finds the event in a classifier library that
# is the best match to one with the metrics provided. The routine
# assumes the existence of a list of classifier events called 
# classifier_library in the scope of the calling routine. It returns
# the closest event in a string. It also sets the global classifier
# match parameter, which gives the distance of the closest library
# point. With setup set to 1, the routine sets up the lwdaq nearest
# neighbor routine by passing the classifier library metrics into the
# routine. Subsequent calls to the routine will use the previously
# established library.
#
proc Neuroclassifier_classify {metrics {setup 0}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	upvar 1 classifier_library cl
	

	if {[llength $cl] == 0} {return ""}

	if {[catch {	
		if {$setup} {
			set nnl ""
			foreach c $cl {
				append nnl [lrange $c [expr $info(cii)+$info(cbo)+1] end]
				append nnl " "
			}
			set index [lwdaq nearest_neighbor $metrics $nnl]
		} {
			set index [lwdaq nearest_neighbor $metrics]
		}
	} error_result]} {
		Neuroarchiver_print "ERROR: $error_result"
		return ""
	}
	
	set closest [lindex $cl [expr $index-1]]

	set distance 0.0
	for {set m 0} {$m < [llength $metrics]} {incr m} {
		set z1 [lindex $metrics $m]
		if {![string is double -strict $z1]} {
			Neuroarchiver_print "ERROR: Invalid metrics provided by processor."
			return $closest
		}
		set z2 [lindex $closest [expr $m+$info(cii)+$info(cbo)+1]]
		if {![string is double -strict $z2]} {
			Neuroarchiver_print "ERROR: Invalid metrics provided by matching event."
			return $closest
		}
		set distance [expr $distance + ($z1-$z2)*($z1-$z2)]
	}
	set info(classifier_match) [format %.3f [expr sqrt($distance)]]
	

	return $closest
}

#
# Neuroclassifier_processing accepts a characteristics line as
# input. If there are mutliple channels recorded in this line, 
# the routine separates the characteristics of each channel and
# forms a list of events, one for each channel. It searches the 
# event library for each event, in case the event is a repeat of
# one that already exists in the library. If so, it hilites
# the event in the library and makes it visible in the text
# window. Otherwise, the routine checks to see if the event
# qualifies as unusual. The first metric should be greater than
# the classifier threshold. If the event is unusual, the
# routine finds the closest match to the event in the library
# and classifies the event as being of the same type. In either
# case, the routine plots the characteristics of the event
# upon the map. In the special case where we are re-processing
# the event libarary to obtain new metrics, the routine replaces
# the existing baseline power and metrics for each library event
# with the newly-calculated values from the processor.
#
proc Neuroclassifier_processing {characteristics} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	if {![winfo exists $info(classifier_window)]} {return 0}

	# We extract from the characteristics line the file name
	# and play time, then we make a list of separate intervals,
	# one for each channel. To do this, we assume that only the
	# channel numbers will be integers.
	scan $characteristics %s%f fn pt
	set idcs ""
	set idc ""
	foreach a [lrange $characteristics $info(cii) end] {
		if {[string is integer $a]} {
			if {$idc != ""} {lappend idcs $idc}
			set idc $a
		} {
			lappend idc $a
		}
	}
	lappend idcs $idc
	
	# We define the text and map widgets and delete all displayed
	# points in the map.
	set t $info(classifier_text)
	set c $info(classifier_map)	
	$c delete displayed
	$t tag delete hilite

	# We search for each interval in turn, looking through the text window.
	# Thus we have idc as the characteristics of each particular interval 
	# taken from the list idcs that we constructed above.
	foreach idc $idcs {

		# Extract the channel id and look for the event in the library.
		set id [lindex $idc 0]
		set index [$t search "$fn $pt $id" 1.0]

		if {$index != ""} {
			# Get the library event from the text window.
			set event [$t get "$index" "$index lineend"]
			
			# If we are re-processing the library, we will replace the
			# old baseline power and metrics with the displayed values.
			if {[info exists info(reprocessing_event_list)]} {
				set event "[lrange $event 0 [expr $info(cii)+$info(cto)]]\
					[lrange $idc $info(cbo) end]"
				$t delete "$index" "$index lineend"
				$t insert $index $event
			}
			
			# If the event type is "Add" we assume we have just added it to
			# the library. We insert the displayed baseline power and metrics, 
			# and switch the type of the event to Unknown.
			if {[lindex $event [expr $info(cii)+$info(cto)]] == "Added"} {
				set event "[lrange $event 0 [expr $info(cii)+$info(cto)-1]]\
					Unknown\
					[lrange $idc $info(cbo) end]"
				$t delete "$index" "$index lineend"
				$t insert $index $event
			}

			# We have found the interval in the library, so we hilite
			# it and show it.
			$t tag add hilite "$index" "$index lineend"
			$t tag configure hilite -background lightgreen
			$t see $index
			
			# Because we have already identified the type of this event
			# by eye, and stored it as such in the event list, we can be
			# certain of its type.
			set type [lindex $event [expr $info(cii) + $info(cto)]]

			# And the match distance is of course zero, and the closest
			# event it itself.
			set info(classifier_match) 0.0
			set closest $event
			
			# Plot the event as a white square.
			Neuroclassifier_plot displayed $event
		} {
			# We did not find the interval, so we check its threshold metric,
			# which is the one that marks the occurance of an event, to see
			# if the interval is normal or an event. If it's an event, we
			# classify it by finding the closest match in the event list. 
			if {[lindex $idc [expr $info(cbo)+1]] >= $config(classifier_threshold)} {
				set classifier_library [Neuroclassifier_event_list]
				set closest [Neuroclassifier_classify \
					[lrange $idc [expr $info(cbo)+1] end] 1]
				# A non-empty string for closest means a nearest match
				# was found. Otherwise the matching failed, perhaps because
				# the library itself is empty. We call the event Unknown if
				# the distance is greater than the match threshold. Otherwise
				# the event takes the same type as the closest match.
				if {$closest != ""} {
					if {$info(classifier_match) <= $config(classifier_match_limit)} {
						set type [lindex $closest [expr $info(cii)+$info(cto)]]
					} {
						set type "Unknown"
					}
					set index [$t search $closest 1.0]
					$t tag add hilite "$index" "$index lineend"
					$t tag configure hilite -background lightblue
					$t see $index
				} {
					set type "Unknown"
				}
			} {
				# An event is Normal only if there is sufficient signal reception
				# to be sure of this. Otherwise it's a Loss event.
				set closest ""
				if {[lindex $idc [expr $info(cbo)+1]] > 0.0} {
					set type "Normal"
				} {
					set type "Loss"
				}
			}

			# We plot the interval on the screen as a displayed point.
			Neuroclassifier_plot displayed \
				"$fn $pt $id $type [lrange $idc $info(cbo) end]"
		}
		
		# If we have defined an event handler script, we execute it now
		# at the local scope, so that the script has access to the variables
		# type, id, fn, pt, closest, event, and of course the info and config
		# arrays of the Neuroarchiver. We also provide support for a TCPIP
		# socket whose name will be stored in sock. In the event of an error
		# we close this socket, so that the handler script does not have to
		# worry about sockets being left open.
		set sock "sock0"
		if {$config(enable_handler) && ($info(handler_script) != "")} {
			if {[catch {eval $info(handler_script)} error_result]} {
				Neuroarchiver_print "ERROR: $error_result"
				LWDAQ_socket_close $sock
			}
		}

		# If we are continuing only to the next unusual event, rather than
		# playing indefinitely, we check to see if this event was unsusual,
		# and if so we stop playback.
		if {$info(classifier_continue) \
			&& ($type != "Normal") \
			&& ($type != "Loss")} {
			Neuroarchiver_command "play" "Stop"
			set info(classifier_continue) 0
		}
	}
}

#
# Neuroclassifier_reprocess goes through the events in the text window and
# re-processes each of them so as to replace the old characteristics with 
# those generated by the Neuroarchiver's current processor script.
#
proc Neuroclassifier_reprocess {{index 0}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	if {![winfo exists $info(classifier_window)]} {
		catch {unset info(reprocessing_event_list)}
		return 0
	}
	if {$index == 0} {
		if {[info exists info(reprocessing_event_list)]} {return 0}
		set info(reprocessing_event_list) [Neuroclassifier_event_list]
	} 
	if {($index > 0) && ![info exists info(reprocessing_event_list)]} {
		return 0
	}
	if {$index >= [llength $info(reprocessing_event_list)]} {
		catch {unset info(reprocessing_event_list)}
		return 0
	}
	if {![info exists info(reprocessing_event_list)]} {return 0}
	Neuroclassifier_jump [lindex $info(reprocessing_event_list) $index]
	if {$index < [llength $info(reprocessing_event_list)]} {
		LWDAQ_post [list Neuroclassifier_reprocess [incr index]]
	}
	return 1
}

#
# Neuroclassifier_compare goes through the event list and measures the
# distance between every pair of events of differing types, and compares
# this distance to the match limit. If the distance is less, the Classifier
# prints the pair of events to the Neuroarchiver text window as a pair of
# potentially-contradictory events.
#
proc Neuroclassifier_compare {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	Neuroarchiver_print "\nComparison of Library Events" purple
	set events [Neuroclassifier_event_list]
	if {[llength $events] == 0} {
		Neuroarchiver_print "WARNING: No events in library to compare."
	}
	while {[llength $events] > 1} {
		set event1 [lindex $events 0]
		set e1 $event1
		foreach v {fn pt id et bp} {
			set $v\_1 [lindex $e1 0]
			set e1 [lrange $e1 1 end]
		}
		set events [lrange $events 1 end]
		foreach event2 $events {
			set e2 $event2
			foreach v {fn pt id et bp} {
				set $v\_2 [lindex $e2 0]
				set e2 [lrange $e2 1 end]
			}
			if {($fn_1 == $fn_2) && ($pt_1 == $pt_2) && ($id_1 == $id_2)} {
				if {$et_1 == $et_2} {
					Neuroarchiver_print "Duplicates:\n$event1\n$event2"
				} {
					Neuroarchiver_print "Contradiction:\n$event1\n$event2"
				}
			} {
				if {$et_1 != $et_2} {
					if {([llength $e1] == [llength $e2]) || ([llength $e1 == 0])} {
						set s 0
						for {set i 0} {$i < [llength $e1]} {incr i} {
							set s [expr $s + \
								pow([lindex $e1 $i]-[lindex $e2 $i],2)]
						}
						set s [expr sqrt(1.0*$s/[llength $e1])]
						if {$s < $config(classifier_match_limit)} {
							Neuroarchiver_print \
								"Overlap (Separation = [format %.3f $s]):\ \n$event1\n$event2"
						}
					} {
						Neuroarchiver_print "Mismatch:\n$event1\n$event2"
					}
				}
			}
			LWDAQ_support
		}
	}
	Neuroarchiver_print "Done.\n" purple
}

#
# Neuroclassifier_stop puts a stop to all reprocessing events by unsetting
# the event list, and stops playback as well.
#
proc Neuroclassifier_stop {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	catch {unset info(reprocessing_event_list)}
	set info(classifier_display_control) "Stop"
	Neuroarchiver_command play "Stop"
}

proc Neuroclassifier_play {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	if {!$config(enable_processing)} {
		Neuroarchiver_print "ERROR: Processing is disabled."
		return
	}
	set info(classifier_continue) 0
	Neuroarchiver_command "play" "Play"
}

proc Neuroclassifier_continue {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	if {!$config(enable_processing)} {
		Neuroarchiver_print "ERROR: Processing is disabled."
		return
	}
	set info(classifier_continue) 1
	Neuroarchiver_command "play" "Play"
}

#
# Neuroclassifier_batch_classification selects one or more characteristics 
# files and goes through them comparing each interval to the classifier
# events. It does this for the channels specified in the channel select
# string in the main Neuroarchiver window. The result is a text window
# containing a list of events that we can cut and paste into a file.
#
proc Neuroclassifier_batch_classification {{state "Start"}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	global nbc

	set w $info(classifier_window)\.nbc

	if {$state == "Start"} {
		if {[winfo exists $w]} {
			raise $w
			return 0
		}
		toplevel $w
		wm title $w "Batch Classification for Neuroarchiver $info(version)"
		catch {unset nbc}
		
		set f [frame $w.f1]
		pack $f -side top -fill x
		
		label $f.fl -text "Input:" -fg blue
		button $f.scf -text "Pick Files" -command {
			set fn [LWDAQ_get_file_name 1]
			if {$fn != ""} {
				set nbc(fnl) $fn
				LWDAQ_print $nbc(t) "Picked [llength $nbc(fnl)] input files."
			}
		}
		button $f.scd -text "Apply Pattern to Directory" -command {
			set dn [LWDAQ_get_dir_name]
			if {$dn != ""} {
				set nbc(fnl) [LWDAQ_find_files $dn $nbc(dmp)]
				LWDAQ_print $nbc(t) "Found [llength $nbc(fnl)] input files\
					matching \"$nbc(dmp)\" in \"[file tail $dn]\"."
			}
		}
		set nbc(dmp) "*.txt"
		label $f.lmatch -text "Pattern:"
		entry $f.ematch -textvariable nbc(dmp)
		pack $f.fl $f.scf $f.scd $f.lmatch $f.ematch -side left -expand yes

		label $f.ofl -text "Output:" -fg blue
		set nbc(ofn) [file join $config(play_dir) "Events.txt"]
		button $f.sof -text "Specify File" -command {
			set fn [LWDAQ_put_file_name [file tail $nbc(ofn)]]
			if {$fn != ""} {set nbc(ofn) $fn}
		}
		pack $f.ofl $f.sof -side left -expand yes
		label $f.tl -text "Threshold:" -fg blue
		entry $f.te -textvariable Neuroarchiver_config(classifier_threshold) \
			-width 6
		pack $f.te $f.tl -side right	
		
		set f [frame $w.f2]
		pack $f -side top -fill x
		label $f.cl -text "Controls:" -fg blue
		set nbc(run) 0
		button $f.go -text "Batch Classify" -command {
			LWDAQ_post [list Neuroclassifier_batch_classification "Classify"]
		}
		button $f.stop -text "Stop" -command {
			set nbc(run) 0
		}
		button $f.allc -text "All Channels" -command {
			for {set id 1} {$id < $Neuroarchiver_info(max_id)} {incr id} {
				set nbc(en_$id) 1
			}
		}
		button $f.noc -text "No Channels" -command {
			for {set id 1} {$id < $Neuroarchiver_info(max_id)} {incr id} {
				set nbc(en_$id) 0
			}
		}
		button $f.allt -text "All Types" -command {
			foreach {type color} "$Neuroarchiver_config(classifier_types) Unknown black" {
				set b [string tolower $type]
				set nbc($type) 1
			}
		}
		button $f.not -text "No Types" -command {
			foreach {type color} "$Neuroarchiver_config(classifier_types) Unknown black" {
				set b [string tolower $type]
				set nbc($type) 0
			}
		}
		pack $f.cl $f.go $f.stop $f.allc $f.noc $f.allt $f.not -side left -expand yes
		label $f.ll -text "Limit:" -fg blue
		entry $f.le -textvariable Neuroarchiver_config(classifier_match_limit) \
			-width 6
		pack $f.le $f.ll -side right
		
		set f [frame $w.channels]
		pack $f -side top -fill x
		label $f.cl -text "Channels:" -fg blue
		pack $f.cl -side left
		for {set id 1} {$id < $info(max_id)} {incr id} {
			set nbc(en_$id) 0
			checkbutton $f.b$id -variable nbc(en_$id) -text $id
			pack $f.b$id -side left -expand yes
		}
		
		set f [frame $w.types]
		pack $f -side top -fill x
		label $f.tl -text "Types:" -fg blue
		pack $f.tl -side left
		foreach {type color} "$config(classifier_types) Unknown black" {
			set b [string tolower $type]
			set nbc($type) 0
			checkbutton $f.$b -variable nbc($type) -text $type
			pack $f.$b -side left
		}
		
		set nbc(t) [LWDAQ_text_widget $w 100 20 1 1]
		LWDAQ_enable_text_undo $nbc(t)
	}
	
	if {$state == "Classify"} {
		if {$nbc(run)} {return 0}
		
		if {![info exists nbc(fnl)]} {
			LWDAQ_print $nbc(t) "ERROR: Select input files."
			return 0
		}
		if {![info exists nbc(ofn)]} {
			LWDAQ_print $nbc(t) "ERROR: Specify output files."
			return 0
		}
		set classifier_library [Neuroclassifier_event_list]
		if {[llength $classifier_library] < 1} {
			LWDAQ_print $nbc(t) "ERROR: Empty classifier list."
			return 0
		}
		
		set nbc(run) 1
		set nbc(setup) 1

		LWDAQ_print $nbc(t) "Start Classification" purple
		set metrics_start [expr $info(cbo)+1]
		set metrics_end [expr $info(cbo)+[llength $config(classifier_metrics)]]
		set event_counter 0
		set interval_counter 0

		if {[catch {set of [open $nbc(ofn) w]} error_result]} {
			LWDAQ_print $nbc(t) "ERROR: Cannot open file \"$nbc(ofn)\"."
			return 0
		}
		LWDAQ_print $nbc(t) "Opened \"$nbc(ofn)\" for output."
		
		foreach fn [lsort -dictionary $nbc(fnl)] {
			# Read in the characteristics of the first file.
			LWDAQ_print -nonewline $nbc(t) "[file tail $fn] "
			LWDAQ_update
			set f [open $fn r]
			set characteristics [string trim [read $f]]
			close $f

			# Check to see if the output file has the correct form for 
			# automatic output file naming. This form is M, a ten-digit 
			# unsigned integer, an underscore, a string, and finally the
			# extension .txt. If the event file has this format, we check 
			# if the characteristics file also has this format. If so, we 
			# construct the new event file name by replacing the old event 
			# file's timestamp with the new characteristics file timestamp.
			# We close the old event file and open a new one.
			if {[regexp {M[0-9]{10}_(.*?)\.txt} $nbc(ofn) match efs]} {
				if {[regexp {M([0-9]{10})_.*?\.txt} $fn match ts]} {
					set nbc(ofn) [file join [file dirname $nbc(ofn)] M$ts\_$efs\.txt]
					close $of
					set of [open $nbc(ofn) w]
				}
			}
			
			# We are going to count events of each selected type for each selected
			# channel id in this file, so we define variables for these counts.
			for {set id 1} {$id < $info(max_id)} {incr id} {
				if {$nbc(en_$id)} {
					foreach {type color} "$config(classifier_types) Unknown black" {
						if {[info exists nbc($type)] && $nbc($type)} {
							set event_counter_$id\_$type 0
						}
					}
				}
			}

			# For each characteristics line, we check to see if the interval
			# is an event, and if so, what kind of event. We check for loss
			# and new events.
			foreach c [split $characteristics \n] { 
				if {!$nbc(run) || ![winfo exists $w]} {
					LWDAQ_print $nbc(t) "Aborted\n" purple
					close $of
					return 0
				}
				set archive [lindex $c 0]
				set play_time [lindex $c 1]
				set c [lrange $c 2 end]
				while {[llength $c] > 0} {
					incr interval_counter
					set id [lindex $c 0]
					if {![string is integer -strict $id]} {
						LWDAQ_print $nbc(t) ""
						LWDAQ_print $nbc(t) "ERROR: Invalid characteristics in \"[file tail $fn]\"."
						close $of
						set nbc(run) 0
						return 0
					}
					if {($id > 0) && ($id < $info(max_id)) && $nbc(en_$id) && \
						([lindex $c $metrics_start] > $config(classifier_threshold))} {
						set baseline_pwr [lindex $c $info(cbo)]
						set metrics [lrange $c $metrics_start $metrics_end]
						set closest [Neuroclassifier_classify $metrics $nbc(setup)]
						set nbc(setup) 0
						if {$info(classifier_match) <= $config(classifier_match_limit)} {						
							set type [lindex $closest [expr $info(cii)+$info(cto)]]
						} {
							set type "Unknown"
						}
						set event "$archive $play_time $id $type $baseline_pwr $metrics"
						if {[info exists nbc($type)] && $nbc($type)} {
							puts $of $event
							incr event_counter
							incr event_counter_$id\_$type
						}
					}
					set c [lrange $c [expr $metrics_end+1] end]
				}
				LWDAQ_support
			}
			
			# We complete the single line we began with the file name above, and record
			# the event counts for each selected channel and selected event type.
			for {set id 1} {$id < $info(max_id)} {incr id} {
				if {$nbc(en_$id)} {
					LWDAQ_print -nonewline $nbc(t) "$id " purple
					foreach {type color} "$config(classifier_types) Unknown black" {
						if {[info exists nbc($type)] && $nbc($type)} {
							LWDAQ_print -nonewline $nbc(t) "[set event_counter_$id\_$type] "
						}
					}
				}
			}
			LWDAQ_print $nbc(t)
		}
		close $of

		LWDAQ_print $nbc(t) "Examined $interval_counter intervals, found $event_counter events."		
		LWDAQ_print $nbc(t) "Done." purple
		set nbc(run) 0
	}
}

#
# Neuroclassifier_save saves the events listed in the Classifier test
# window to a file, and refreshes the text window and map. If no file
# is passed to the routine, it opens a file browser.
#
proc Neuroclassifier_save {{name ""}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	if {$name == ""} {set name [LWDAQ_put_file_name "Event_Library.txt"]}
	if {$name == ""} {return ""}
	
	set event_list [Neuroclassifier_event_list] 
	set f [open $name w]
	foreach event $event_list {puts $f "$event"}
	close $f
}

#
# Neuroclassifier_load reads an event list from a text file into the
# Classifier's text window. If no file is passed to the routine, it opens a file
# browser.
#
proc Neuroclassifier_load {{name ""}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	if {$name == ""} {set name [LWDAQ_get_file_name]}
	if {$name == ""} {return ""}
	if {![file exists $name]} {
		Neuroarchiver_print "ERROR: Cannot find \"[file tail $name]\"."
		return ""
	}

	set f [open $name r]
	set event_list [split [string trim [read $f]] \n]
	close $f
	
	Neuroclassifier_display $event_list
}

#
# Neuroarchiver_calibration allows us to view and edit the global baseline
# power values used by some processors to produce interval characteristics
# that are independent of the sensitivity of the sensor. The processor can
# use these global variables to keep track of a "baseline" power value by
# which other power measurements may be divided to obtain a normalised
# power measurement. We can save the baseline power values to the metadata
# of an NDF file, or load them from the metadata. The Calibration Panel also
# displays the frequencies used for reconstruction, which may have been
# specified by the user, or may have been picked from a list of possible
# frequencies in the default frequency parameter.
#
proc Neuroarchiver_calibration {{name ""}} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	set w $info(window)\.baselines
	if {[winfo exists $w]} {
		raise $w
		return 0
	}
	toplevel $w
	wm title $w "Calibration Panel"

	set f [frame $w.calibration -relief groove -border 4]
	pack $f -side left -fill y
	
	label $f.tid -text "ID" -fg purple
	label $f.tbp -text "Baseline Power" -fg purple
	label $f.trst -text "Reset" -fg purple
	label $f.tsps -text "SPS" -fg purple
	grid $f.tid $f.tbp $f.trst $f.tsps -sticky news
	
	for {set id 1} {$id < $info(max_id)} {incr id} {
		label $f.l$id -text $id -anchor w 
		entry $f.e$id -textvariable Neuroarchiver_info(bp_$id) \
			-relief sunken -bd 1 -width 20
		button $f.b$id -text "Reset" \
			-command "set Neuroarchiver_info(bp_$id) $info(bp_reset)"
		label $f.f$id -textvariable Neuroarchiver_info(f_$id) -width 4
		grid $f.l$id $f.e$id $f.b$id $f.f$id -sticky news
	}
	
	set f [frame $w.controls]
	pack $f -side left -fill y

	set f [frame $w.controls.f1 -relief groove -border 4]
	pack $f -side top -fill x

	button $f.rb -text "Reset Baselines" -command {Neuroarchiver_baselines_reset}
	pack $f.rb -side top

	button $f.nb -text "Normalize Baselines" -command {Neuroarchiver_baselines_normalize}
	pack $f.nb -side top

	set f [frame $w.controls.f2 -relief groove -border 4]
	pack $f -side top -fill x

	button $f.read -text "Read Baselines from Metadata" \
		-command {Neuroarchiver_baselines_read $Neuroarchiver_config(bp_name)}
	pack $f.read -side top
	button $f.save -text "Write Baselines to Metadata" \
		-command {Neuroarchiver_baselines_write $Neuroarchiver_config(bp_name)}
	pack $f.save -side top

	set f [frame $w.controls.f3 -relief groove -border 4]
	pack $f -side top -fill x

	label $f.lname -text "Name for All Metadata Reads and Writes:" -fg blue
	pack $f.lname -side top
	entry $f.name -textvariable Neuroarchiver_config(bp_name)
	pack $f.name -side top	
	
	set f [frame $w.controls.f4 -relief groove -border 4]
	pack $f -side top -fill x
	
	label $f.lplayback -text "Playback Strategy:" -fg blue
	pack $f.lplayback -side top
	checkbutton $f.autoreset -variable Neuroarchiver_config(bp_autoreset) \
		-text "Reset Baselines on Playback Start"
	pack $f.autoreset -side top
	checkbutton $f.autoread -variable Neuroarchiver_config(bp_autoread) \
		-text "Read Baselines from Metadata on Playback Start"
	pack $f.autoread -side top
	checkbutton $f.autowrite -variable Neuroarchiver_config(bp_autowrite) \
		-text "Write Baselines to Metadata on Playback Finish"
	pack $f.autowrite -side top

	set f [frame $w.controls.f5 -relief groove -border 4]
	pack $f -side top -fill x
	
	label $f.ljump -text "Event Jumping Strategy:" -fg blue
	pack $f.ljump -side top
	radiobutton $f.jumpread -variable Neuroarchiver_config(jump_strategy) \
		-text "Read Baselines from Metadata" -value "read"
	radiobutton $f.jumplocal -variable Neuroarchiver_config(jump_strategy) \
		-text "Use Current Baseline Power" -value "local"
	radiobutton $f.jumpevent -variable Neuroarchiver_config(jump_strategy) \
		-text "Use Baseline Power in Event Description" -value "event"
	pack $f.jumpread $f.jumplocal $f.jumpevent -side top
}

#
# Neuroarchiver_baselines_reset sets all the baseline power values to the
# reset value, which is supposed to be so high that no channel will have a
# baseline power exceeding it.
#
proc Neuroarchiver_baselines_reset {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info	

	for {set i 1} {$i < $info(max_id)} {incr i} {
		set info(bp_$i) $info(bp_reset)
	}
}

#
# Neuroarchiver_baselines_normalize sets all the baseline power values
# to 1.0.
#
proc Neuroarchiver_baselines_normalize {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info	

	for {set i 1} {$i < $info(max_id)} {incr i} {
		set info(bp_$i) 1.0
	}
}

#
# Neuroarchiver_baselines_write takes the existing baseline power values
# and saves them as baseline power string in the metadata of the current
# playback file, with the name specified in the config(bp_name) parameter.
# The routine does not write baseline powers that meet or exceed the reset 
# value, because these are not valid.
#
proc Neuroarchiver_baselines_write {name} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info	

	if {[regexp {[^a-zA-Z0-9_\-\.]} $name]} {
		Neuroarchiver_print "ERROR: Name \"$name\" invalid contains illegal characters."
		return 0
	}

	if {[catch {set metadata [LWDAQ_ndf_string_read $config(play_file)]} error_string]} {
		Neuroarchiver_print "ERROR: $error_string"
		return 0
	}
	
	if {$name == $info(no_name)} {
		set pattern "<baseline>\[^<\]*</baseline>"
	} {
		set pattern "<baseline id=\"$name\">\[^<\]*</baseline>"
	}
	set metadata [string trim [regsub -all $pattern $metadata ""]]
	
	if {$name == $info(no_name)} {
		append metadata "\n<baseline>\n"
	} {
		append metadata "\n<baseline id=\"$name\">\n"	
	}
	
	for {set id 1} {$id < $info(max_id)} {incr id} {
		if {$info(bp_$id) < $info(bp_reset)} {
			append metadata "$id $info(bp_$id)\n"
		}
	}
	
	append metadata "</baseline>\n"
	
	LWDAQ_ndf_string_write $config(play_file) [string trim $metadata]\n

	Neuroarchiver_print "Wrote baselines \"$name\" to [file tail $config(play_file)]." verbose

	return 1
}

#
# Neuroarchiver_baselines_read looks at the metadata of the current playback
# archive and looks for a baseline power string with the name given by the
# config(bp_name) string. It reads any such baseline powers it finds into
# the baseline power array.
#
proc Neuroarchiver_baselines_read {name} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info

	if {[regexp {[^a-zA-Z0-9_\-\.]} $name]} {
		Neuroarchiver_print "ERROR: Baseline name \"$name\" contains illegal characters."
		return 0
	}

	if {[catch {set metadata [LWDAQ_ndf_string_read $config(play_file)]} error_string]} {
		Neuroarchiver_print "ERROR: $error_string"
		return 0
	}

	if {$name == $info(no_name)} {
		set pattern "<baseline>(\[^<\]*)</baseline>"
	} {
		set pattern "<baseline id=\"$name\">(\[^<\]*)</baseline>"
	}

	if {[regexp $pattern $metadata match baselines]} {
		foreach {id bp} [string trim $baselines] {
			if {$bp < $info(bp_reset)} {
				set info(bp_$id) $bp
			}
		}		
	} {
		Neuroarchiver_print "ERROR: No baselines \"$name\" in [file tail $config(play_file)]."
		return 0
	}
	Neuroarchiver_print "Read baselines \"$name\" from [file tail $config(play_file)]." verbose
	return 1
}

#
# Neuroarchiver_magnified_view opens a new window with a larger, or at lease separate, plot of
# the voltage-time or amplitude-frequency graph. The size of the window is set by the
# vt_view_zoom and af_view_zoom parameters.
#
proc Neuroarchiver_magnified_view {figure} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	if {$figure == "vt"} {
		if {[winfo exists $info(vt_view)]} {
			raise $info(vt_view)
			return 0
		}
		toplevel $info(vt_view)
		wm title $info(vt_view) "Voltage vs. Time Magnified View"
   		set info(vt_view_photo) [image create photo "_neuroarchiver_vt_view_photo_"]
   		set l $info(vt_view)\.plot
   		label $l -image $info(vt_view_photo)
		pack $l -side top
		Neuroarchiver_draw_graphs
	}
	if {$figure == "af"} {
		if {[winfo exists $info(af_view)]} {
			raise $info(af_view)
			return 0
		}
		toplevel $info(af_view)
		wm title $info(af_view) "Amplitude vs. Frequency Magnified View"
   		set info(af_view_photo) [image create photo "_neuroarchiver_af_view_photo_"]
   		set l $info(af_view)\.plot
   		label $l -image $info(af_view_photo)
		pack $l -side top
		Neuroarchiver_draw_graphs
	}
	
	return $figure
}

#
# Neuroarchiver_draw_graphs draws the vt and af graphs in the two view
# windows in the Neuroarchiver, and in the separate view windows, if they
# exist.
#
proc Neuroarchiver_draw_graphs {} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	lwdaq_draw $info(vt_image) $info(vt_photo)
	if {[winfo exists $info(vt_view)]} {
		lwdaq_draw $info(vt_image) $info(vt_view_photo) -zoom $config(vt_view_zoom)
	}
	lwdaq_draw $info(af_image) $info(af_photo)
	if {[winfo exists $info(af_view)]} {
		lwdaq_draw $info(af_image) $info(af_view_photo) -zoom $config(af_view_zoom)
	}
}

#
# Neuroarchiver_fresh_graphs clears the graph images in memory, and if you pass it
# a "1" as a parameter, it will clear the graphs from the screen as well.
# It calls lwdaq_graph to create an empty graph in the overlay area of the
# graph images, and lwdaq_draw to draw the empty graph on the screen.
#
proc Neuroarchiver_fresh_graphs {{clear_screen 0}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	global LWDAQ_Info
	
	if {!$LWDAQ_Info(gui_enabled)} {return 1}
	
	lwdaq_graph "0 0" $info(vt_image) -fill 1 \
		-x_min 0 -x_max 1 -x_div $config(t_div) \
		-y_min 0 -y_max 1 -y_div $config(v_div) \
		-color 1  

	if {$config(log_frequency)} {
		if {$config(f_min) < [lindex $info(log_frequency_lines) 0]} {
			set config(f_min) [lindex $info(log_frequency_lines) 0]
		}
		lwdaq_graph "0 0" $info(af_image) -fill 1 \
			-x_min 0 -x_max 1 -y_min 0 -y_max 1 \
			-y_div $config(a_div) -color 10
		foreach f $info(log_frequency_lines) {
			if {$f < $config(f_min)} {continue}
			if {$f > $config(f_max)} {break}
			lwdaq_graph "[expr log($f)] 0 [expr log($f)] 1" $info(af_image) -fill 0 \
				-x_min [expr log($config(f_min))] -x_max [expr log($config(f_max))] \
				-y_min 0 -y_max 1 -color 10
		}
	} {	
		lwdaq_graph "0 0" $info(af_image) -fill 1 \
			-x_min 0 -x_max 1 -x_div $config(f_div) \
			-y_min 0 -y_max 1 -y_div $config(a_div) \
			-color 1
	}
	
	if {$clear_screen} {
		Neuroarchiver_draw_graphs
	}
	
	set info(signal) "0 0"
	set info(values) "0"
	set info(spectrum) "0 0"
	
	LWDAQ_support
	return 1
}

#
# Neuroarchiver_plot_signal plots the a signal on the screen. It uses 
# lwdaq_graph to plot data in the vt_image overlay. The procedure does not 
# draw the graph on the screen. We leave the drawing until all the signals have 
# been plotted in the vt_image overlay by successive calls to this procedure.
# For more information about lwdaw_graph, see the LWDAQ Command Reference.
# If we don't pass a signal to the routine, it uses $info(signal). The signal
# string must be a list of time and sample values "t v ". If we don't specify
# a color, the routine uses the info(channel_num) as the color code. If we don't 
# specify a signal, the routine uses the $info(signal).
#
proc Neuroarchiver_plot_signal {{color ""} {signal ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	upvar result result
	global LWDAQ_Info
	
	if {!$LWDAQ_Info(gui_enabled)} {return 1}
	
	if {$color == ""} {set color [lindex $config(color_table) $info(channel_num)]}
	if {$signal == ""} {set signal $info(signal)}
	
	foreach a {v_range v_offset} {
		if {![string is double -strict $config($a)]} {
			set result "ERROR: Invalid value, \"$config($a)\" for $a."
			return 0
		}
	}

	if {$config(ac_couple)} {
		set v_min [expr $config(v_offset) - $config(v_range) / 2 ]
		set v_max [expr $config(v_offset) + $config(v_range) / 2]
	} {
		set v_min $config(v_offset)
		set v_max [expr $config(v_offset) + $config(v_range)]
	}
	
	lwdaq_graph $signal $info(vt_image) -y_min $v_min \
		-y_max $v_max -color $color -ac_couple $config(ac_couple)
	
	set info(t_min) $config(play_time)
	
	LWDAQ_support
	return 1
}

#
# Neuroarchiver_plot_spectrum plots a spectrum in the af_image overlay, but 
# does not display the plot on the screen. The actual display will take
# place later, for all channels at once, to save time. If you don't
# pass a spectrum to the routine, it will plot $info(spectrum). Each
# spectrum point must be in the format "f a ", where f is frequency
# in Hertz and a is amplitude in ADC counts. If we don't specify a color for
# the plot, the routine uses the $info(channel_num). If we don't specify a spectrum,
# it uses $info(spectrum).
#
proc Neuroarchiver_plot_spectrum {{color ""} {spectrum ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	upvar result result
	global LWDAQ_Info
	
	if {!$LWDAQ_Info(gui_enabled)} {return 1}
	
	if {$color == ""} {set color [lindex $config(color_table) $info(channel_num)]}
	if {$spectrum == ""} {set spectrum $info(spectrum)}

	foreach a {a_range f_min f_max} {
		if {![string is double -strict $config($a)]} {
			set result "ERROR: Invalid value, \"$config($a)\" for $a."
			return 0
		}
	}
	
	set amplitudes ""
	set frequency 0
	foreach {a p} $spectrum {
		if {($frequency >= $config(f_min)) || ($frequency <= $config(f_max))} {
			if {$config(log_frequency)} {
				if {$frequency > [lindex $info(log_frequency_lines) 0]} {
					append amplitudes "[format %.3f [expr log($frequency)]] $a "
				}
			} {
				append amplitudes "$frequency $a "
			}
		}
		set frequency [expr $frequency + $info(f_step)]
	}
	
	if {$config(log_frequency)} {
		set x_min [expr log($config(f_min))]
		set x_max [expr log($config(f_max))]
	} {
		set x_min $config(f_min)
		set x_max $config(f_max)
	}
	lwdaq_graph $amplitudes $info(af_image) \
		-x_min $x_min -x_max $x_max \
		-y_min 0 -y_max $config(a_range) \
		-color $color
		
	LWDAQ_support
	return 1
}

#
# Neuroarchiver_record manages the recording of data to archive files. It is the
# recorder's execution procedure. It calls the Recorder Instrument to produce
# a block of data with a fixed number of clock messages. It stores these
# messages to disk. If the control variable, config(record_control), is "Record",
# the procedure posts itself again to the event queue. The recorder calculates
# the number of clock messages from the recorder_interval time, which is in 
# seconds, and is available in the Neuroarchiver panel.
#
proc Neuroarchiver_record {} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	upvar #0 LWDAQ_config_Recorder iconfig
	upvar #0 LWDAQ_info_Recorder iinfo
	global LWDAQ_Info
	
	if {![array exists info]} {return 0}

	if {$LWDAQ_Info(reset)} {
		set info(record_control) "Idle"
		return 1
	}
	
	if {$LWDAQ_Info(gui_enabled) && ![winfo exists $info(window)]} {
		array unset info
		array unset config
		return 0
	}
	
	if {$info(record_control) == "Stop"} {
		set info(record_control) "Idle"
		return 1
	}
	
	if {$info(record_control) == "Pick"} {
		catch {$info(record_control_label) configure -bg orange}
		LWDAQ_update
		Neuroarchiver_pick record_file
		catch {$info(record_control_label) configure -bg white}
		LWDAQ_update
	}

	if {$info(record_control) == "PickDir"} {
		catch {$info(record_control_label) configure -bg orange}
		LWDAQ_update
		Neuroarchiver_pick record_dir
		catch {$info(record_control_label) configure -bg white}
		LWDAQ_update
	}

	if {$info(record_control) == "Reset"} {
		catch {$info(record_control_label) configure -bg red}
		if {$iinfo(control) != "Idle"} {
			set iinfo(control) "Stop"
			LWDAQ_post Neuroarchiver_record
			return 0
		}
		if {$iconfig(image_source) == "daq"} {
			set result [LWDAQ_reset_Recorder]
			if {[LWDAQ_is_error_result $result]} {
				Neuroarchiver_print $result
				set info(record_control) "Idle"
				return 0
			}
		}
		catch {$info(record_control_label) configure -bg white}
	}

	if {($info(record_control) == "Reset") \
			|| (($config(record_end_time) >= $config(autocreate)) \
				&& ($config(autocreate) > 0))} {
		if {![file exists $config(record_dir)]} {
			Neuroarchiver_print "ERROR: Directory $dirname does not exist."
			set info(record_control) "Idle"
			return 0
		}
		set config(record_file) [file join $config(record_dir) "M[clock seconds]\.ndf"]
		set info(record_file_tail) [file tail $config(record_file)]
		LWDAQ_ndf_create $config(record_file) $config(ndf_metadata_size)	
		LWDAQ_ndf_string_write $config(record_file) \
			"<c>\
			\nDate Created: [clock format [clock seconds] -format {%c}].\
			\nCreator: Neuroarchiver $info(version), LWDAQ_$LWDAQ_Info(program_patchlevel).\
			\nHost: [info hostname]\
			\n</c>\n"
		Neuroarchiver_print "Created NDF file $config(record_file)."
		set config(record_end_time) 0
	}

	if {$info(record_control) == "Record"} {
		# Check the archive file name and type.
		if {[catch {LWDAQ_ndf_data_check $config(record_file)} message]} {
			Neuroarchiver_print "ERROR: $message\."
			set info(record_control) "Idle"
			return 0
		}

		catch {$info(record_control_label) configure -bg yellow}
		
		if {$iinfo(control) == "Loop"} {
			set iinfo(control) "Acquire"
		}

		set saved_analysis_enable $iconfig(analysis_enable)
		set iconfig(analysis_enable) $config(recorder_plot_enable)
		set record_num_clocks [expr round($config(record_interval) * $info(clocks_per_second))]
		set iconfig(daq_num_clocks) $record_num_clocks
		set saved_max_daq_attempts $LWDAQ_Info(max_daq_attempts)
		set LWDAQ_Info(max_daq_attempts) 1	
		
		set daq_result [LWDAQ_acquire Recorder]
		
		set LWDAQ_Info(max_daq_attempts) $saved_max_daq_attempts
		set iconfig(analysis_enable) $saved_analysis_enable
		catch {$info(record_control_label) configure -bg white}
	
		if {[LWDAQ_is_error_result $daq_result]} {
			Neuroarchiver_print $daq_result
			LWDAQ_post Neuroarchiver_record
			return 0
		}
		
		# Append the new data to our NDF file.		
		LWDAQ_ndf_data_append $config(record_file) \
			[lwdaq_image_contents $iconfig(memory_name) -truncate 1 \
				-data_only 1 -record_size $info(message_length)]

		# Increment the record time. If there has been interruption in the
		# data acquisition, this end time will be too low when compared to
		# the end time we would obtain by examining the clock messages.
		set config(record_end_time) [expr $config(record_end_time) + $config(record_interval)]
		
		LWDAQ_post Neuroarchiver_record
		return 1
	}

	set info(record_control) "Idle"
	return 0
}

#
# Neuroarchiver_play manages the play-back and processing of signals
# from archive files. We start by checking the block of messages in 
# the buffer_image. We read messages out of the play-back archive until
# it has enough clock messages to span play_interval seconds. Sometimes,
# the block of messages we read will be many times larger than necessary.
# We extract from the buffer_image exactly the correct number of messages
# to span the play_interval and put these in the data_image. We go through
# the channels string and make a list of channels we want to process. For
# each of these channels, in the order they appear in the channels string,
# we apply extraction, reconstruction, transformation, and processing to the 
# data image. If requested by the user, we read their processor_file off
# disk and apply it in turn to the signal and spectrum we obtained for
# each channel. We store the results of processing to disk in a text file
# and print them to the text window also.
#
proc Neuroarchiver_play {} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config
	upvar #0 LWDAQ_config_Recorder iconfig
	upvar #0 LWDAQ_info_Recorder iinfo
	global LWDAQ_Info

	if {![array exists info]} {return 0}

	if {$LWDAQ_Info(reset)} {
		set info(play_control) "Idle"
		return 1
	}
	
	if {$LWDAQ_Info(gui_enabled) && ![winfo exists $info(window)]} {
		array unset info
		array unset config
		return 0
	}
	
	if {$info(play_control) == "Stop"} {
		catch {$info(play_control_label) configure -bg white}
		set info(play_control) "Idle"
		return 1
	}
	
	# If the play control label background is not yellow, we set
	# the background to green for Play and orange otherwise.
	catch {
		if {[$info(play_control_label) cget -bg] != "yellow"} {
			if {$info(play_control) == "Play"} {
				catch {$info(play_control_label) configure -bg green}
			} {
				catch {$info(play_control_label) configure -bg orange}			
			}
		}
		LWDAQ_update
	}
	
	# Format the play time variable before we proceed.
	set config(play_time) [Neuroarchiver_play_time_format $config(play_time)]
	
	if {$info(play_control) == "Pick"} {
		Neuroarchiver_pick play_file
		set config(play_time) 0.0
		set config(saved_play_time) $config(play_time)
		Neuroarchiver_fresh_graphs 1
		if {![string match $config(play_dir)* $config(play_file)]} {
			Neuroarchiver_print "WARNING: Directory tree changed to include new play file."
			set config(play_dir) [file dirname $config(play_file)]
		}
	}

	if {$info(play_control) == "PickDir"} {
		Neuroarchiver_pick play_dir
		Neuroarchiver_fresh_graphs 1
		if {[string match $config(play_dir)* $config(play_file)]} {
			catch {$info(play_control_label) configure -bg white}
			set info(play_control) "Idle"
			return 1
		} {
			set info(play_control) "First"
		}
	}

	if {$info(play_control) == "First"} {
		set play_list [LWDAQ_find_files $config(play_dir) *.ndf]
		if {[llength $play_list] < 1} {
			Neuroarchiver_print "ERROR: There are no NDF files in the\
				playback directory tree."
			catch {$info(play_control_label) configure -bg white}
			set info(play_control) "Idle"
			return 0
		}
		set config(play_file) [lindex $play_list 0]
		set config(play_time) 0.0
		set config(saved_play_time) $config(play_time)
		Neuroarchiver_fresh_graphs 1
	}

	if {[catch {LWDAQ_ndf_data_check $config(play_file)} message]} {
		Neuroarchiver_print "ERROR: $message."
		catch {$info(play_control_label) configure -bg white}
		set info(play_control) "Idle"
		return 0
	}	
	
	if {$config(play_file) != $info(saved_play_file)} {
		set config(play_index) 0
		set info(play_file_tail) [file tail $config(play_file)]
		set info(saved_play_file) $config(play_file)
		set info(play_end_time) [Neuroarchiver_end_time $config(play_file)]
		set info(play_previous_clock) -1
		if {$config(play_time) < 0.0} {
			set config(play_time) 0.0
		}
		if {$config(play_time) > [expr $info(play_end_time) - $config(play_interval)]} {
			set config(play_time) [Neuroarchiver_play_time_format \
				[expr $info(play_end_time) - \
				$config(play_interval) - \
				fmod($info(play_end_time),$config(play_interval))] ]
		}
		set info(saved_play_time) 0.0
		lwdaq_data_manipulate $info(buffer_image) clear
		set config(unaccepted_values) $info(default_unaccepted_values)
	}

	if {($info(play_control) == "Pick") || ($info(play_control) == "First")} {
		catch {$info(play_control_label) configure -bg white}
		set info(play_control) "Idle"
		return 1
	}
	
	if {$info(play_control) == "Back"} {
		# Set the play time back by two intervals.
		set config(play_time) [Neuroarchiver_play_time_format \
			[expr $config(play_time) - 2.0 * $config(play_interval)]]

		# If we are going back before the start of this archive, we try
		# to find an previous archive to play its final interval. We get
		# a list of all NDF files in the play_dir directory tree.
		if {$config(play_time) < 0.0} {
			set fl [LWDAQ_find_files $config(play_dir) *.ndf]
			set i [lsearch $fl $config(play_file)]
			if {$i < 0} {
				Neuroarchiver_print "ERROR: Cannot move to previous file,\
					\"$info(play_file_tail)\" not in playback directory tree."
				catch {$info(play_control_label) configure -bg white}
				set info(play_control) "Idle"
				return 0
			}
			set file_name [lindex $fl [expr $i - 1]]
			if {$file_name != ""} {
				Neuroarchiver_print "Playback switching to previous file\
					\"[file tail $file_name]\"."
				set config(play_file) $file_name
				set info(play_file_tail) [file tail $file_name]
				set config(play_time) $info(max_play_time)
			} {
				Neuroarchiver_print "ERROR: No previous file in\
					playback directory tree."
				set config(play_time) 0.0
				catch {$info(play_control_label) configure -bg white}
				set info(play_control) "Idle"
				return 0
			}
		} 
		
		set info(play_control) "Step"
		LWDAQ_post Neuroarchiver_play
		return 1
	}
	
	if {$info(play_control) == "Repeat"} {
		set config(play_time) [Neuroarchiver_play_time_format \
			[expr $config(play_time) - $config(play_interval)]]
		if {$config(play_time) < 0.0} {
			set config(play_time) 0.0
		}
		set info(play_control) "Step"
		LWDAQ_post Neuroarchiver_play
		return 1
	}
	
	if {[winfo exists $info(text)]} {
		$info(text) delete 1.0 "end [expr 0 - $config(num_lines_keep)] lines"
	}
	
	if {$config(play_time) != $info(saved_play_time)} {
		# Because we are jumping to a new location, we set the previous clock
		# variable to the undefined code.
		set info(play_previous_clock) -1

		# Our target play time is play_time. We seek through the archive and
		# find the last clock message that occurs in the data before or exactly
		# at the target time.
		scan [Neuroarchiver_seek_time $config(play_file) $config(play_time)] \
			%f%u new_play_time new_play_index

		# If the new play time is less than our target, we either asked for
		# a time that does not correspond to a clock message, or there are 
		# clock messages missing from the data. In either case, we move to
		# the interval boundary just before the new play time.
		if {$new_play_time < $config(play_time)} {
			set new_play_time [Neuroarchiver_play_time_format \
				[expr $new_play_time - fmod($new_play_time,$config(play_interval))]]
			scan [Neuroarchiver_seek_time $config(play_file) $new_play_time] \
				%f%u new_play_time new_play_index
		}
		
		# If our new play time is greater than our target, something has gone
		# wrong in the seek operation.
		if {$new_play_time > $config(play_time)} {
			Neuroarchiver_print "WARNING: No clock message preceding\
				time $config(play_time) s,\
				moving to $new_play_time s."
		}

		# Report the move to the text window when verbose is set.
		Neuroarchiver_print "Moving to clock at $new_play_time s,\
			index $new_play_index,\
			closest to target $config(play_time) s." verbose
			
		# Set the play time and index.
		set config(play_time) $new_play_time
		set config(play_index) $new_play_index

		# Set the saved play time and clear the data buffer and reset the
		# unaccepted value list.
		set info(saved_play_time) $config(play_time)
		lwdaq_data_manipulate $info(buffer_image) clear
		set config(unaccepted_values) $info(default_unaccepted_values)
	}

	if {$config(play_time) == 0.0} {
		if {$config(bp_autoreset)} {Neuroarchiver_baselines_reset}
		if {$config(bp_autoread)} {Neuroarchiver_baselines_read $config(bp_name)}
	}
	
	set play_num_clocks [expr round($config(play_interval) * $info(clocks_per_second))]
	set clocks [lwdaq_recorder $info(buffer_image) "clocks 0 $play_num_clocks"]
	scan $clocks %d%d%d%d%d num_errors num_clocks num_messages start_index end_index

	set end_of_file 0
	while {($num_clocks < $play_num_clocks) && !$end_of_file} {
		set data [LWDAQ_ndf_data_read \
			$config(play_file) \
			[expr $info(message_length) * ($config(play_index) + $num_messages) ] \
			$info(block_size)]
		set num_messages_read [expr [string length $data] / $info(message_length) ]
		if {$num_messages_read > 0} {
			Neuroarchiver_print "Read $num_messages_read messages from\
				[file tail $config(play_file)]\." verbose
			if {[catch {
				lwdaq_data_manipulate $info(buffer_image) write \
					[expr $num_messages * $info(message_length)] $data
				set clocks [lwdaq_recorder $info(buffer_image) "clocks 0 $play_num_clocks"]
				set saved_num_messages $num_messages
				scan $clocks %d%d%d%d%d num_errors num_clocks num_messages start_index end_index
				if {$saved_num_messages == $num_messages} {
					error "One or more blank messages in recording."
				}
			} error_result]} {
				# The only way to get to here, so far as we know, is for there to
				# be blank messages in the data, but there may be other corruptions
				# that lead to this point. We call the seek routine to find the next
				# available clock message in the file, then jump to the first whole
				# interval after that.
				Neuroarchiver_print $error_result verbose
				scan [Neuroarchiver_seek_time $config(play_file) $config(play_time)] \
					%f%u%f%u lo_time lo_index hi_time hi_index
				if {$lo_time < $hi_time} {
					if {fmod($hi_time,$config(play_interval)) == 0} {
						set config(play_time) $hi_time
					} {
						set config(play_time) [Neuroarchiver_play_time_format \
							[expr $hi_time - \
							fmod($hi_time,$config(play_interval)) + \
							$config(play_interval)]]
					}
					Neuroarchiver_print "WARNING: Archive [file tail $config(play_file)]\
						corrupted from [format %.2f $lo_time] s\
						to [format %.2f $hi_time] s,\
						skipping to $config(play_time) s."
				
					LWDAQ_post Neuroarchiver_play
					return 0
				} {
					Neuroarchiver_print "WARNING: Archive [file tail $config(play_file)]\
						corrupted from [format %.2f $lo_time] s\
						to [format %.2f $info(play_end_time)] s,\
						moving to next archive."
					set end_of_file 1
				}
			}
		} {
			set end_of_file 1
		}
	}
	
	if {$end_of_file} {
		# We are at the end of the file, so write baselines to metadata if
		# instructed by the user.
		if {$config(bp_autowrite)} {
			Neuroarchiver_baselines_write $config(bp_name)
		}	
		
		# Stop now if play_stop_at_end is set. We don't have enough data
		# to display a full interval.
		if {$config(play_stop_at_end)} {
			catch {$info(play_control_label) configure -bg white}
			set info(play_control) "Idle"
			return 1
		}
		
		# We obtain a list of all NDF files in the play_dir directory tree. If
		# can't find the current file in the directory tree, we abort.
		set fl [LWDAQ_find_files $config(play_dir) *.ndf]
		set i [lsearch $fl $config(play_file)]
		if {$i < 0} {
			Neuroarchiver_print "ERROR: Cannot continue to a later file,\
				\"$info(play_file_tail)\" not in playback directory tree."
			catch {$info(play_control_label) configure -bg white}
			set info(play_control) "Idle"
			return 0
		}
		
		# We see if there is later file in the directory tree. If so, we switch to
		# the later file. Otherwise, we wait for a new file or new data, by calling
		# the Neuroarchiver play routine again and turning the control label yellow.
		set file_name [lindex $fl [expr $i + 1]]
		if {$file_name != ""} {
			Neuroarchiver_print "Playback switching to next file [file tail $file_name]."
			set config(play_file) $file_name
			set info(play_file_tail) [file tail $file_name]
			set config(play_time) 0.0
			catch {$info(play_control_label) configure -bg white}
			LWDAQ_post Neuroarchiver_play
			return 1
		} {
			# This is the case where we have $num_clocks but need $play_num_clocks
			# and we have no later file to switch to. This case arises during live 
			# play-back, when the player is trying to read more data out of the file 
			# that is being written to by the recorder. The screen will show you when 
			# the Player is waiting. By checking the state of the play_control_label, 
			# we make sure that we issue the following print statement only once. While
			# the Player is waiting, the label remains yellow.
			catch {
				if {[$info(play_control_label) cget -bg] != "yellow"} {
					Neuroarchiver_print "Have $num_clocks clocks, need $play_num_clocks.\
						Waiting for next archive to be recorded." verbose
					$info(play_control_label) configure -bg yellow
				}
			}
			LWDAQ_post Neuroarchiver_play
			return 1
		}
	}
	
	if {$num_clocks == $play_num_clocks} {
		set end_index $num_messages
	}
	
	set start_addr [expr $start_index * $info(message_length)]
	set end_addr [expr $end_index * $info(message_length)]
	set data [lwdaq_data_manipulate $info(buffer_image) read \
		$start_addr [expr $end_addr - $start_addr]]
	lwdaq_data_manipulate $info(data_image) clear
	lwdaq_data_manipulate $info(data_image) write 0 $data 
	lwdaq_data_manipulate $info(buffer_image) shift $end_addr

	set clocks [lwdaq_recorder $info(data_image) "clocks 0 -1"]
	scan $clocks %d%d%d%d%d num_errors num_clocks num_messages first_index last_index
	set clocks [lwdaq_recorder $info(data_image) "get $first_index $last_index"]
	set first_clock [lindex $clocks 1]
	set last_clock [lindex $clocks 4]
	if {$last_clock > $first_clock} {
		set time_span [expr 1.0 * \
			($last_clock - $first_clock + 1) / \
			$info(clocks_per_second)]
	} {
		set time_span [expr 1.0 * \
			($last_clock + $info(max_sample) + 1 - $first_clock + 1) / \
			$info(clocks_per_second)]
	}
	if {$time_span != $config(play_interval)} {
		if {fmod($time_span,$config(play_interval)) > 0} {
			set time_skip [expr ($time_span - \
				fmod($time_span,$config(play_interval)) + \
				$config(play_interval))]
		} {
			set time_skip $time_span
		}
		Neuroarchiver_print "WARNING: Missing data after $config(play_time) s,\
			display spans [format %.2f $time_span] s,\
			will skip to [expr $config(play_time) + $time_skip] s."
		set time_span $time_skip
	} {
		if {$num_errors > 0} {
			Neuroarchiver_print "WARNING: Encountered $num_errors errors\
				in [file tail $config(play_file)] between $config(play_time) s and\
				[expr $config(play_time) + $config(play_interval)] s."
		}	
	}
	if {([expr $first_clock - $info(play_previous_clock)] != 1) \
			&& (($info(play_previous_clock) != $info(max_sample)) \
					|| ($first_clock != 0)) \
			&& ($info(play_previous_clock) != -1)} {
		Neuroarchiver_print "WARNING: Clock jumps from\
			$info(play_previous_clock) to $first_clock in\
			[file tail $config(play_file)] at $config(play_time) s."
	}
	if {$config(show_messages) || (($num_errors > 0) && $config(verbose))} {
		set report [lwdaq_recorder $info(data_image) "print 0 1"]
		if {[regexp {index=([0-9]*) } $report match index]} {
			Neuroarchiver_print [lwdaq_recorder $info(data_image) \
				"print [expr $index - $config(show_num)/2] \
					[expr $index + $config(show_num)/2]"]
		} {
			Neuroarchiver_print [lwdaq_recorder $info(data_image) \
				"print 0 $config(show_num)"]
		}
	}
	set info(play_previous_clock) $last_clock
	Neuroarchiver_print "Using $num_messages messages,\
		including $num_clocks clocks." verbose

	Neuroarchiver_fresh_graphs		

	set channel_list [lwdaq_recorder $info(data_image) "list"]	

	if {![LWDAQ_is_error_result $channel_list]} {
		set ca ""
		foreach {id qty} $channel_list {
			if {$qty > $config(activity_threshold)} {
				lappend ca "$id\:$qty"
			}
		}
		set info(channel_activity) $ca
	} {
		set info(channel_activity) $channel_list
	}

	if {$config(channel_select) == "*"} {
		set channels ""
		foreach {id qty} $channel_list {
			if {($qty > $config(activity_threshold)) \
				&& ($id != 0) \
				&& ($id != $info(max_id))} {
				lappend channels "$id"
			}
		}
	} {
		set channels $config(channel_select)
	}
	
	set result ""
	set en_proc $config(enable_processing)
	if {$en_proc} {
		if {![file exists $config(processor_file)]} {
			set result "ERROR: Processor script $config(processor_file) does not exist."
		} {
			set f [open $config(processor_file) r]
			set info(processor_script) [read $f]
			close $f
		}
	}
	
	foreach channel_code $channels {
		set info(channel_code) $channel_code
		set info(channel_num) [lindex [split $channel_code :] 0]
		set info(signal) [Neuroarchiver_signal]
		set info(values) [Neuroarchiver_values]
		set info(spectrum) [Neuroarchiver_spectrum]
		if {$config(enable_vt)} {Neuroarchiver_plot_signal}
		if {$config(enable_af)} {Neuroarchiver_plot_spectrum}
		if {![LWDAQ_is_error_result $result] && $en_proc} {
			if {[catch {eval $info(processor_script)} error_result]} {
				set result "ERROR: $error_result"
			}
		}
		LWDAQ_support
	}
	
	if {$result != ""} {
		if {![LWDAQ_is_error_result $result]} {
			set result "[file tail $config(play_file)] $config(play_time) $result"
		}
		Neuroarchiver_print $result
		if {$config(save_processing)} {
			set afn [file root [file tail $config(play_file)]]_[\
				regsub {\.tcl} [file tail $config(processor_file)] .txt]
			LWDAQ_print [file join [file dirname $config(processor_file)] $afn] $result
		}
		if {![LWDAQ_is_error_result $result] \
				&& [winfo exists $info(classifier_window)]} {
			Neuroclassifier_processing $result
		}

	} {
		if {$config(save_processing) && !$config(enable_processing)} {
			Neuroarchiver_print "WARNING: Processing is disabled, so will not be saved."
		}
	}
	
	# Turn the label back to white before we plot the graphs. This gives the
	# label a better flash behavior during rapid playback.
	catch {$info(play_control_label) configure -bg white}
	LWDAQ_update

	if {$LWDAQ_Info(gui_enabled)} {Neuroarchiver_draw_graphs}
	
	if {$time_span == $config(play_interval)} {
		set config(play_time) [Neuroarchiver_play_time_format \
			[expr $config(play_time) + $config(play_interval)]]
		set info(saved_play_time) $config(play_time)
		set config(play_index) [expr $config(play_index) + $end_index]
	} {
		set config(play_time) [Neuroarchiver_play_time_format \
			[expr $config(play_time) + $time_span]]
		set info(saved_play_time) $info(max_play_time)
		set config(play_index) 0
	}
		
	if {$info(play_control) == "Play"} {
		LWDAQ_post Neuroarchiver_play
	} {
		set info(play_control) "Idle"
	}

	return 1
}

#
# Neuroarchiver_jump displays an event. We can either pass the event directly to
# the routine, or we can pass one of three keywords that direct the routine to
# select an event from those listed in a file. The event passed to the routine or
# read from a file by the routine must be a list in which the first element names
# an archive in the current play directory tree, the second gives the time at
# which the event takes place in seconds from the start of this archive, and the
# third element gives the channel or channels in which the event occurs. If we
# pass one of the keywords "Back", "Go", or "Step" to the routine it will
# decrement, leave unaltered, or increment the event_index respectively, read a
# list of events from the current event file, and jump to the one pointed to by
# the event_index. Event one is the first in the list. When the routine reads in
# the file, it sets num_events. The file must contain text lines, each line
# containing a single event in the above-described format. The jump routine will
# set the baseline powers in preparation for display and processing, according
# to the jump_strategy parameter. If this is "local" we use the current baseline
# powers, if "read" we read them from the archive metadata using the baseline 
# power name in the Baselines Panel. If it is "event" we assume the fourth element
# in the event list is a keyword describing the event and the fifth element is
# the baseline power we should apply to the selected channels.
#
proc Neuroarchiver_jump {{event ""}} {
	upvar #0 Neuroarchiver_info info
	upvar #0 Neuroarchiver_config config

	# If the event is a keyword, we read in the event file
	# adjust the event index and pick the event_index'th event 
	# in the file, with event one being the first.
	if {($event == "Back") || ($event == "Go") || ($event == "Step")} {
		if {![file exists $config(event_file)]} {
			Neuroarchiver_print "ERROR: Cannot find \"[file tail $config(event_file)]\"."
			return ""
		}
	
		set f [open $config(event_file) r]
		set event_list [split [string trim [read $f]] \n]
		close $f
		
		if {[llength $event_list] < 1} {
			Neuroarchiver_print "ERROR: Empty event list."
			return ""
		}
	
		set info(num_events) [llength $event_list]

		switch $event {
			"Back" {incr config(event_index) -1}
			"Step" {incr config(event_index) +1}
		}

		if {$config(event_index) < 1} {
			set config(event_index) 1
		}
		if {$config(event_index) >= $info(num_events)} {
			set config(event_index) $info(num_events)
		}

		set event [lindex $event_list [expr $config(event_index)-1]]
	}
	
	# Check that the event contains an archive name and a play time.
	if {(![string match -nocase *.ndf [lindex $event 0]]) \
			|| (![string is double [lindex $event 1]])} {
		Neuroarchiver_print "ERROR: Invalid event \"[string range $event 0 60]\"."
		return ""
	}

	# Try to find the event NDF file in the playback directory tree.
	set fl [LWDAQ_find_files $config(play_dir) *.ndf]
	set pft [lindex $event 0]
	set pf ""
	foreach fn $fl {
		if {[regexp $pft $fn]} {
			set pf $fn
			break
		}
	}
	if {$pf == ""} {
		Neuroarchiver_print "ERROR: Cannot find $pft in $config(play_dir)."
		return ""
	}
	if {[catch {LWDAQ_ndf_data_check $pf} message]} {
		Neuroarchiver_print "ERROR: $message."
		return ""
	}
	
	# Set the play file and play time to match this event.
	set config(play_file) $pf
	set info(play_file_tail) [file tail $pf]
	set config(play_time) [Neuroarchiver_play_time_format [lindex $event 1]]
	
	# If event isolation is turned on, we set the channel select
	# to the event channel list.
	if {$config(isolate_events)} {
		set config(channel_select) [lindex $event 2]
	}
	
	# Display the event in purple in the text window.
	Neuroarchiver_print $event purple
	
	# Set up the baseline powers according to the jump configuration in the
	# Baselines Panel.
	switch $config(jump_strategy) {
		"read" {
			Neuroarchiver_baselines_read $config(bp_name)
		}
		"event" {
			foreach id [lindex $event 2] {
				set info(bp_$id) [lindex $event 4]
			}
		}
		default {
		# In all other cases we do nothing, and use the current baseline power.
		}
	}
	
	# We execute the jump in the command routine.
	Neuroarchiver_command play Jump
	
	# We return the event.
	return $event
}

#
# Neuroarchiver_open creates the Neuroarchiver window, with all its buttons, boxes,
# and displays. It uses routines from the TK library to make the frames and widgets.
# To make sense of what the procedure is doing, look at the features in the 
# Neuroarchiver from top-left to bottom right. That's the order in which we 
# create them in the code. Frames enclose rows of buttons, labels, and entry 
# boxes. The images are TK "photos" associated with label widgets. The last thing
# to go into the Neuroarchiver panel is its text window.
#
proc Neuroarchiver_open {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	
	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.record
	frame $f
	pack $f -side top -fill x
	
	set f $w.record.a
	frame $f
	pack $f -side top -fill x

	label $f.control -textvariable Neuroarchiver_info(record_control) \
		-fg blue -width 8
	set info(record_control_label) $f.control
	pack $f.control -side left -expand 1

	foreach a {Record Stop Reset} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Neuroarchiver_command record $a"
		pack $f.$b -side left -expand 1
	}

	label $f.lrs -text "Interval (s):" 
	tk_optionMenu $f.mrs Neuroarchiver_config(record_interval) 0.25 0.5 1 2 4
	pack $f.lrs $f.mrs -side left -expand 1

	button $f.conf -text "Configure" -command "Neuroarchiver_configure"
	button $f.help -text "Help" -command "LWDAQ_tool_help Neuroarchiver"
	checkbutton $f.d -variable Neuroarchiver_config(verbose) -text "Verbose"
	pack $f.conf $f.help $f.d -side left -expand 1
	
	set f $w.record.b
	frame $f
	pack $f -side top -fill x
	
	label $f.a -text "Archive:" -anchor w
	label $f.b -textvariable Neuroarchiver_info(record_file_tail) -width 20 -bg gray
	button $f.pick -text "Pick" -command "Neuroarchiver_command record Pick"
	button $f.pick_dir -text "PickDir" -command "Neuroarchiver_command record PickDir"
	button $f.metadata -text "Metadata" -command  {
		LWDAQ_post [list Neuroarchiver_metadata_view record]
	}
	label $f.lac -text "End (s):"
	label $f.eac -textvariable Neuroarchiver_config(record_end_time) -width 6
	label $f.le -text "Create (s):"
	entry $f.ee -textvariable Neuroarchiver_config(autocreate) -width 6
	pack $f.a $f.b $f.pick $f.pick_dir $f.metadata $f.lac $f.eac $f.le $f.ee -side left -expand 1

	set f $w.displays
	frame $f -border 2
	pack $f -side top -fill x
	
	set f $w.displays.signal
	frame $f -relief groove -border 2
	pack $f -side left -fill y
	
	set f $w.displays.signal.title
	frame $f
	pack $f -side top -fill x
	
	checkbutton $f.ac -variable Neuroarchiver_config(ac_couple) -text "AC" 
	label $f.title -text "Value vs. Time" -fg green
	checkbutton $f.enable -variable Neuroarchiver_config(enable_vt) -text "Enable" 
	pack $f.ac $f.title $f.enable -side left -expand 1

	set f $w.displays.signal
   	set info(vt_photo) [image create photo "_neuroarchiver_vt_photo_" \
   		-width $info(plot_width) \
   		-height $info(plot_height)]
	label $f.graph -image $info(vt_photo) 
	bind $f.graph <Button-1> {Neuroarchiver_magnified_view vt}
	pack $f.graph -side top
	
	set f $w.displays.signal.controls
	frame $f
	pack $f -side top -fill x
	label $f.lv_offset -text "v_offset:"
	entry $f.ev_offset -textvariable Neuroarchiver_config(v_offset) -width 5
	pack $f.lv_offset $f.ev_offset -side left -expand 1
	label $f.lv_range -text "v_range:"
	entry $f.ev_range -textvariable Neuroarchiver_config(v_range) -width 5
	pack $f.lv_range $f.ev_range -side left -expand 1
	label $f.lt_left -text "t_min:"
	label $f.et_left -textvariable Neuroarchiver_info(t_min) -width 5
	pack $f.lt_left $f.et_left -side left -expand 1
	
	set f $w.displays.spectrum
	frame $f -relief groove -border 2
	pack $f -side right -fill y
	
	set f $w.displays.spectrum.title
	frame $f 
	pack $f -side top -fill x
	
	label $f.title -text "Amplitude vs. Frequency" -fg green
	checkbutton $f.lf -variable Neuroarchiver_config(log_frequency) -text "Log"
	checkbutton $f.enable -variable Neuroarchiver_config(enable_af) -text "Enable"
	pack $f.enable $f.title $f.lf -side left -expand 1
	
	set f $w.displays.spectrum
   	set info(af_photo) [image create photo "_neuroarchiver_af_photo_" \
   		-width $info(plot_width) \
   		-height $info(plot_height)]
	label $f.graph -image $info(af_photo) 
	bind $f.graph <Button-1> {Neuroarchiver_magnified_view af}
	pack $f.graph -side top
	
	set f $w.displays.spectrum.controls
	frame $f
	pack $f -side top -fill x
	foreach a {a_range f_min f_max} {
		label $f.l$a -text $a\:
		entry $f.e$a -textvariable Neuroarchiver_config($a) \
			-relief sunken -bd 1 -width 5
		pack $f.l$a $f.e$a -side left -expand 1
	}

	foreach a {f_step} {
		label $f.l$a -text $a\:
		label $f.e$a -textvariable Neuroarchiver_info($a) -width 5
		pack $f.l$a $f.e$a -side left -expand 1
	}

	set f $w.play
	frame $f
	pack $f -side top -fill x

	set f $w.play.a
	frame $f
	pack $f -side top -fill x

	label $f.control -textvariable Neuroarchiver_info(play_control) -fg blue -width 8
	set info(play_control_label) $f.control
	pack $f.control -side left -expand 1

	foreach a {Play Step Stop Repeat Back} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Neuroarchiver_command play $a"
		pack $f.$b -side left -expand 1
	}

	label $f.lrs -text "Interval (s):" 
	tk_optionMenu $f.mrs Neuroarchiver_config(play_interval) \
		0.0625 0.125 0.25 0.5 1.0 2.0 4.0 8.0 16.0 32.0
	label $f.li -text "Time (s):"
	entry $f.ei -textvariable Neuroarchiver_config(play_time) -width 6
	pack $f.lrs $f.mrs $f.li $f.ei -side left -expand 1
	label $f.le -text "End (s):"
	label $f.ee -textvariable Neuroarchiver_info(play_end_time) -width 6
	pack $f.le $f.ee -side left -expand 1
	
	set f $w.play.ac
	frame $f 
	pack $f -side top -fill x

	label $f.al -text "Activity:" -anchor w
	label $f.ae -textvariable Neuroarchiver_info(channel_activity) \
		-anchor w -width 80 -bg gray
	pack $f.al $f.ae -side left -expand 1

	set f $w.play.b
	frame $f
	pack $f -side top -fill x

	label $f.a -text "Archive:" -anchor w
	label $f.b -textvariable Neuroarchiver_info(play_file_tail) -width 20 -bg gray
	button $f.pick -text "Pick" -command "Neuroarchiver_command play Pick"
	button $f.pickd -text "PickDir" -command "Neuroarchiver_command play PickDir"
	button $f.first -text "First" -command "Neuroarchiver_command play First"
	button $f.clist -text "List" -command {
		LWDAQ_post [list Neuroarchiver_comment_list ""]
	}
	pack $f.a $f.b $f.pick $f.pickd $f.first $f.clist -side left -expand 1
	button $f.metadata -text "Metadata" -command {
		LWDAQ_post [list Neuroarchiver_metadata_view play]
	}
	pack $f.metadata -side left -expand 1
	button $f.overview -text "Overview" -command {
		LWDAQ_post [list LWDAQ_post Neuroarchiver_overview]
	}
	pack $f.overview -side left -expand 1
	
	set f $w.play.c
	frame $f
	pack $f -side top -fill x
		
	label $f.e -text "Processor:" -anchor w
	label $f.f -textvariable Neuroarchiver_info(processor_file_tail) -width 16 -bg gray
	button $f.g -text "Pick" -command "Neuroarchiver_pick processor_file 1"
	checkbutton $f.enable -variable Neuroarchiver_config(enable_processing) -text "Enable"
	checkbutton $f.record -variable Neuroarchiver_config(save_processing) -text "Save"
	pack $f.e $f.f $f.g $f.enable $f.record -side left -expand 1
	label $f.lchannels -text "Select:" -anchor e
	entry $f.echannels -textvariable Neuroarchiver_config(channel_select) -width 30
	pack $f.lchannels $f.echannels -side left -expand 1
	button $f.baselines -text "Calibration" -command "Neuroarchiver_calibration"
	pack $f.baselines -side left -expand 1
	
	set f $w.play.d
	frame $f
	pack $f -side top -fill x
		
	label $f.e -text "Events:" -anchor w
	label $f.f -textvariable Neuroarchiver_info(event_file_tail) -width 16 -bg gray
	button $f.g -text "Pick" -command "Neuroarchiver_pick event_file 1"
	pack $f.e $f.f $f.g -side left -expand 1
	foreach a {Back Go Step} {
		set b [string tolower $a]
		button $f.$b -text $a -command [list LWDAQ_post "Neuroarchiver_jump $a"]
		pack $f.$b -side left -expand 1
	}
	label $f.il -text "Index:" 
	entry $f.ie -textvariable Neuroarchiver_config(event_index) -width 4
	label $f.ll -text "Length:" 
	label $f.le -textvariable Neuroarchiver_info(num_events) -width 4
	pack $f.il $f.ie $f.ll $f.le -side left -expand 1
	button $f.cb -text "Classifier" -command "LWDAQ_post Neuroclassifier_open"
	pack $f.cb -side left -expand 1

	set info(text) [LWDAQ_text_widget $w 100 10 1 1]

	return 1
}

#
# Neuroarchiver_close closes the Neuroarchiver and deletes its configuration and
# info arrays.
#
proc Neuroarchiver_close {} {
	upvar #0 Neuroarchiver_config config
	upvar #0 Neuroarchiver_info info
	
	if {[winfo exists $info(window)]} {
		destroy $info(window)
	}
	array unset config
	array unset info
	return 1
}

Neuroarchiver_init
Neuroarchiver_open
Neuroarchiver_fresh_graphs 1
	
return 1

----------Begin Help----------


INTRODUCTION
------------

For detailed help on the Neuroarchiver, see:

http://www.opensourceinstruments.com/Electronics/A3018/Neuroarchiver.html

For help on the Recorder Instrument, see:

http://www.opensourceinstruments.com/Electronics/A3018/Recorder.html

Here is a list of the plot colors and how they correspond to channel numbers.

Code 	Color
0		red 
1		green
2		blue
3		orange
4		yellow
5		magenta
6		brown
7		salmon
8		sky blue
9		black
10		gray
11		light gray
12		dark red
13		dark green
14		dark blue
15		dark brown

Note that channel 0 is reserved for timestamp in receiver, and channel 15 is reserved for slow communications. Neither will appear in the Neuroarchiver plots. By default, we plot each channel in the color whose code is the channel number, so channel 1 is green and channel 2 is blue. You can change the color codes for the channels by editing the color_table configuration parameter, which contains an ordered list of the color codes that correspond to channel numbers 0 to 15. 

Here are some example processor scripts that you cut and paste into a new file, or which you can use to over-write the contents of an existing processor script. Save the file as a simple text file, not a rich text file. We recommend you give it extension ".tcl", because this enables Tcl language hiliting in many editors. Select this new file with the Processor Pick Button. Check the Processing Enable Box. The Neuroarchiver will apply the script to each playback interval. Each application generates a result string. Indeed, this result string is referred to as the "result" variable in processor scripts. Most processor scripts will generate a non-empty result string, and if so, this this string will appear in the Neuroarchiver text window and will also be appended to a text file we call the "characteristics file". The characteristics file has a name composed of the archive and processor files, with extension ".txt". When we apply P.tcl to M1234567890.ndf the characteristics are stored in M1234567890_P.txt. This file will appear in the same directory as the processor file, not the archive.

# Record reception from each active channel to a line in a characteristics 
# file.
append result "$info(channel_num) [format %.2f [expr 100.0 - $info(loss)]] "

# Export signal values to text file. Each active channel receives a file
# En.txt, where n is the channel number. All values from the reconstructed 
# signal are appended as sixteen-bit integers to separate lines in the file. 
# The script also produces a simple processing result, giving the channel number
# and the number of values exported.
set fn [file join [file dirname $config(play_file)] "E$info(channel_num)\.txt"]
set export_string ""
foreach {timestamp value} $info(signal) {
  append export_string "$value\n"
}
set f [open $fn a]
puts -nonewline $f $export_string
close $f
append result "$info(channel_num) [llength $export_string] "

# Export signal values to text file after filtering. Otherwise like the previous
# processor.
set pwr [Neuroarchiver_band_power 60 160 1 1]
set fn [file join [file dirname $config(play_file)] \
   "E$info(channel_num)\.txt"]
set export_string ""
foreach value $info(values) {
   append export_string "$value\n"
}
set f [open $fn a]
puts -nonewline $f $export_string
close $f
append result "$info(channel_num) [llength $export_string] "

# Export signal spectrum so a file called Sn.txt where n is the channel
# number. The script does not use the result string, and so produces no
# characteristics file. Instead of appending the spectrum to its output
# file, each run through this script re-writes the spectrum file.
set fn [file join [file dirname $config(processor_file)] "S$info(channel_num)\.txt"]
set export_string ""
set frequency 0
foreach {amplitude phase} $info(spectrum) {
  append export_string "$frequency $amplitude\n"
  set frequency [expr $frequency + $info(f_step)]
}
set f [open $fn w]
puts -nonewline $f $export_string
close $f

# Calculate signal reception and power in three bands for each active
# channel. The transient band is 0.1-1 Hz. The seizure band is 2-20 Hz.
# The burst power band is 40-160 Hz. The Player saves these numbers to a
# characteristics file. Each line in the file will have the play file
# name and play time followed by channel number, reception, and power in
# each of the three bands. If the voltage versus time plot is enabled,
# we plot the mid-power band signal underneath the original channel
# signal.
append result "$info(channel_num) [format %.2f [expr 100.0 - $info(loss)]] "
set tp [expr 0.001 * [Neuroarchiver_band_power 0.1 1 0]]
set sp [expr 0.001 * [Neuroarchiver_band_power 2 20 $config(enable_vt)]]
set bp [expr 0.001 * [Neuroarchiver_band_power 40 160 0]]
append result "[format %.2f $tp] [format %.2f $sp] [format %.2f $bp] "

# Calculate and record the power in each of a sequence of contiguous
# bands, with the first band beginning just above 0 Hz. We specify the
# remaining bands with the frequency of the boundaries between the
# bands. The final frequency is the top end of the final band.
append result "$info(channel_num) "
set f_lo 0
foreach f_hi {1 20 40 160} {
  set power [Neuroarchiver_band_power [expr $f_lo + 0.01] $f_hi 0]
  append result "[format %.2f [expr 0.001 * $power]] "
  set f_lo $f_hi
}

# Here's another way to obtain power in various bands. We specify the
# lower and upper frequency of each band.
append result "$info(channel_num) [format %.2f [expr 100.0 - $info(loss)]] "
foreach {lo hi} {1 3.99 4 7.99 8 11.99 12 29.99 30 49.99 50 69.99 70 119.99 120 160} {
  set bp [expr 0.001 * [Neuroarchiver_band_power $lo $hi 0]]
  append result "[format %.2f $bp] "
}

# Here we obtain the coastline length of the voltage samples.
append result "$info(channel_num) [format %.1f [lwdaq x_length $info(values)]] "


Kevan Hashemi hashemi@opensourceinstruments.com
----------End Help----------
