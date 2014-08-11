# Long-Wire Data Acquisition Software (LWDAQ)
# Copyright (C) 2004, 2005, 2006 Kevan Hashemi, Brandeis University
# Copyright (C) 2006, Rapha‘l Tieulent, Institut de Physique NuclŽaire de Lyon 
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
# WPS.tcl defines the WPS instrument.
#

#
# LWDAQ_init_WPS creates all elements of the WPS instrument's
# config and info arrays.
#
proc LWDAQ_init_WPS {} {
	global LWDAQ_Info LWDAQ_Driver
	upvar #0 LWDAQ_info_WPS info
	upvar #0 LWDAQ_config_WPS config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "WPS"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(analysis_show_timing) 0
	set info(analysis_show_edges) 0
	set info(analysis_pixel_size_um) 10
	set info(analysis_reference_um) 1220
	set info(daq_extended) 0
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 344
	set info(daq_image_height) 488
	set info(daq_image_left) 21
	set info(daq_image_right) [expr $info(daq_image_width) - 2]
	set info(daq_image_top) 2
	set info(daq_image_bottom) [expr $info(daq_image_height) - 2]
	set info(flash_seconds_max) 1.0
	set info(flash_seconds_reduce) 0.2
	set info(flash_max_tries) 30
	set info(flash_num_tries) 0
	set info(peak_max) 160
	set info(peak_min) 120
	set info(file_try_header) 1
	set info(daq_device_type) 2
	set info(daq_password) "no_password"
	set info(delete_old_images) 1
	set info(verbose_description) "\
		{Camera One Left Edge Position (um)}\
		{Camera One Left Edge Rotation (mrad)}\
		{Camera One Right Edge Position (um)}\
		{Camera One Right Edge Rotation (mrad)}\
		{Camera Two Left Edge Position (um)}\
		{Camera Two Left Edge Rotation (mrad)}\
		{Camera Two Right Edge Position (um)}\
		{Camera Two Right Edge Rotation (mrad)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./images/$info(name)\*
	set config(memory_name) $info(name)\_0
	set config(daq_ip_addr) 10.0.0.37
	set config(daq_source_device_element) 1
	set config(daq_driver_socket) 1
	set config(daq_mux_socket) 7
	set config(daq_subtract_background) 0
	set config(daq_adjust_flash) 0
	set config(daq_flash_seconds) 0.01
	set config(daq_simultaneous) 1
	set config(intensify) exact
	set config(analysis_enable) 3
	set config(analysis_threshold) "30 # 10"
	set config(verbose_result) 0

	return 1
}		

#
# LWDAQ_analysis_WPS applies WPS analysis to an image 
# in the lwdaq image list. By default, the routine uses the
# image $config(memory_name).
proc LWDAQ_analysis_WPS {{image_name ""}} {
	upvar #0 LWDAQ_config_WPS config
	upvar #0 LWDAQ_info_WPS info
	if {$image_name == ""} {set image_name $config(memory_name)}

	set characteristics [lwdaq_image_characteristics $image_name]
	set h [lindex $characteristics 8]
	set w [lindex $characteristics 9]

	set pre_smooth 0
	set merge 0
	if {$config(analysis_enable) >= 2} {set pre_smooth 1}
	if {$config(analysis_enable) >= 3} {set merge 1}
	
	lwdaq_image_manipulate $image_name none \
		-bottom [expr $h/2-2] -top 2
	set wps_top [lwdaq_wps $image_name \
		-show_timing $info(analysis_show_timing) \
		-show_edges $info(analysis_show_edges) \
		-num_wires 1 \
		-pixel_size_um $info(analysis_pixel_size_um) \
		-threshold $config(analysis_threshold) \
		-reference_um $info(analysis_reference_um) \
		-pre_smooth $pre_smooth \
		-merge $merge] 
		
	lwdaq_image_manipulate $image_name none \
		-bottom [expr $h-2] -top [expr $h/2+2]
	set wps_bottom [lwdaq_wps $image_name \
		-show_timing $info(analysis_show_timing) \
		-show_edges $info(analysis_show_edges) \
		-num_wires 1 \
		-pixel_size_um $info(analysis_pixel_size_um) \
		-threshold $config(analysis_threshold) \
		-reference_um [expr $info(analysis_reference_um) \
			+ $h/2.0*$info(analysis_pixel_size_um)] \
		-pre_smooth $pre_smooth \
		-merge $merge] 
	lwdaq_image_manipulate $image_name none \
		-bottom [expr $h-2] -top 2

	set result ""
	if {$wps_top == ""} {
		set result "ERROR: $info(name) analysis failed on top image."
	}
	if {$wps_bottom == ""} {
		set result "ERROR: $info(name) analysis failed on bottom image."
	}
	if {[LWDAQ_is_error_result $wps_top]} {
		set result $wps_top
	}
	if {[LWDAQ_is_error_result $wps_bottom]} {
		set result $wps_bottom
	}
	if {![LWDAQ_is_error_result $result]} {
		foreach i {0 1 6 7} {append result "[lindex $wps_top $i] "}
		foreach i {0 1 6 7} {append result "[lindex $wps_bottom $i] "}
	}
	
	return $result
}

#
# LWDAQ_daq_WPS captures an image from the LWDAQ electronics and places
# the image in the lwdaq image list. It provides background subtraction by
# taking a second image while flashing non-existent lasers. It provides
# automatic exposure adjustment by calling itself until the maximum image
# intensity lies within peak_min and peak_max.
#
proc LWDAQ_daq_WPS {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_WPS info
	upvar #0 LWDAQ_config_WPS config

	set image_size [expr $info(daq_image_width) * $info(daq_image_height)]
	if {$config(daq_flash_seconds) > $info(flash_seconds_max)} {
		set config(daq_flash_seconds) $info(flash_seconds_max)
	}
	if {$config(daq_flash_seconds) < 0} {
		set config(daq_flash_seconds) 0
	}

	if {[catch {
		# Connect to the driver and log in.
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		
		# Select the sensor and specify its type.
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		
		# Select camera two, which means the clock signals will be 
		# applied to both image sensors. Clear the image sensors and
		# put them into their exposing state.
		LWDAQ_set_device_element $sock 2
		LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
		LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
		
		# Flash the light source.
		LWDAQ_set_device_element $sock $config(daq_source_device_element)
		LWDAQ_flash_seconds $sock $config(daq_flash_seconds)

		# Select camera two and move the images of both sensors from
		# the exposure area to the storage area.
		LWDAQ_set_device_element $sock 2
		LWDAQ_execute_job $sock $LWDAQ_Driver(alt_move_job)

		# Select camera one, so that the storage area clock will be applied
		# only to the first image sensor. We execute a wake job, which 
		# transmits hex 0180 to select the CCD1 output. We must do this a
		# few microseconds before we start our read job, in order to allow
		# the analog circuits to settle down before we check the cable loop
		# time. The read job gets the image out of the storage area and
		# into the driver memory.
		LWDAQ_set_device_element $sock 1
		LWDAQ_wake $sock 
		LWDAQ_set_data_addr $sock 0
		LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)

		if {$config(daq_simultaneous)} {
			# In simultaneous acquisition, we don't create another
			# image, we set up the second image sensor so we can read
			# out the image that already exists in its storage area.
			LWDAQ_set_device_element $sock 2
			LWDAQ_wake $sock
		} {
			# If we don't want, or our hardware does not support, simultaneous
			# exposure, weclear the image sensors again, flash the light, and 
			# transfer the images into the storage areas. Later, we will read out 
			# the second sensor only.
			LWDAQ_set_device_element $sock 2
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			LWDAQ_set_device_element $sock $config(daq_source_device_element)
			LWDAQ_flash_seconds $sock $config(daq_flash_seconds)
			LWDAQ_set_device_element $sock 2
			LWDAQ_execute_job $sock $LWDAQ_Driver(alt_move_job)
		}

		# Read the image out of camera two.
		LWDAQ_set_data_addr $sock [expr $image_size/2]
		LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)

		# Put the device to sleep.
		LWDAQ_sleep $sock		

		# Download out both images.
		set image_contents [LWDAQ_ram_read $sock 0 $image_size]
		
		# Close the socket. Data acquisition is complete.
		LWDAQ_socket_close $sock
	} error_result]} { 
		if {[info exists sock]} {LWDAQ_socket_close $sock}
		return "ERROR: $error_result"
	}
	
	# Construct a LWDAQ image containing the two WPS images
	# one on top of the other. The camera one image is the
	# top one.
	set config(memory_name) [lwdaq_image_create \
		-width $info(daq_image_width) \
		-height $info(daq_image_height) \
		-left $info(daq_image_left) \
		-right $info(daq_image_right) \
		-top $info(daq_image_top) \
		-bottom $info(daq_image_bottom) \
		-data $image_contents \
		-name "$info(name)\_$info(counter)"]
		
	# There will be a black stripe across the center of the combined
	# image, this being the top row of the second image. In order for
	# image intensification to be effective upon the entire image, we
	# must over-write this black stripe.
	set w $info(daq_image_width)
	set h $info(daq_image_height)
	set line [lwdaq_data_manipulate $config(memory_name) \
		read [expr $w*$h/2-2*$w] [expr $w]]
	lwdaq_data_manipulate $config(memory_name) \
		write [expr $w*$h/2-$w] $line

	if {!$config(daq_adjust_flash)} {return $config(memory_name)} 

	set max [lindex [lwdaq_image_characteristics $config(memory_name)] 6]
	set t $config(daq_flash_seconds)
	set call_self 0
	if {$max < 1} {set max 1}
	if {($max < $info(peak_min)) && ($t < $info(flash_seconds_max))} {
		set t [expr ($info(peak_min) + $info(peak_max)) * 0.5 * $t / $max ]
		if {$t > $info(flash_seconds_max)} {set t $info(flash_seconds_max)}
		set call_self 1
	}
	if {($max > $info(peak_max)) && ($t > 0)} {
		set t [expr $t * $info(flash_seconds_reduce) ]
		set call_self 1
	}

	if {$call_self \
		&& ($info(control) != "Stop") \
		&& ($info(flash_num_tries) < $info(flash_max_tries))} {
		incr info(flash_num_tries)
		set config(daq_flash_seconds) [format "%.6f" $t]
		if {[winfo exists $info(window)]} {
			lwdaq_draw $config(memory_name) $info(photo) \
				-intensify $config(intensify) -zoom $info(zoom)
		} 
		return [LWDAQ_daq_$info(name)]
	} {
		set info(flash_num_tries) 0
		return $config(memory_name) 
	}
} 

