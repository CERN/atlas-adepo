# Long-Wire Data Acquisition Software (LWDAQ)
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

#
# BCAM.tcl defines the BCAM instrument.
#

#
# LWDAQ_init_BCAM creates all elements of the BCAM instrument's
# config and info arrays.
#
proc LWDAQ_init_BCAM {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_BCAM info
	upvar #0 LWDAQ_config_BCAM config
	array unset config

	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "BCAM"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(analysis_show_timing) 0
	set info(analysis_show_pixels) 0
	set info(analysis_return_bounds) 0
	set info(analysis_return_intensity) 0
	set info(daq_extended) 0
	set info(extended_parameters) "0.6 0.9 0 1"
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 344
	set info(daq_image_height) 244
	set info(daq_image_left) 20
	set info(daq_image_right) [expr $info(daq_image_width) - 1]
	set info(daq_image_top) 1
	set info(daq_image_bottom) [expr $info(daq_image_height) - 1]
	set info(flash_seconds_max) 0.1
	set info(flash_seconds_step) 0.000002
	set info(flash_seconds_reduce) 0.1
	set info(flash_seconds_transition) 0.000030
	set info(flash_max_tries) 30
	set info(flash_num_tries) 0
	set info(ambient_exposure_seconds) 0
	set info(peak_max) 180
	set info(peak_min) 100
	set info(file_try_header) 1
	set info(analysis_pixel_size_um) 10
	set info(daq_device_type) 2
	set info(daq_source_device_type) 2
	set info(daq_password) "no_password"
	set info(daq_source_ip_addr) "*"
	set info(delete_old_images) 1
	set info(verbose_description) " \
			{Spot Position X (um)} \
			{Spot Position Y (um) or Line Rotation Anticlockwise (mrad)} \
			{Number of Pixels Above Threshold in Spot} \
			{Peak Intensity in Spot} \
			{Accuracy (um)} \
			{Threshold (counts)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./images/$info(name)\*
	set config(memory_name) $info(name)\_0
	set config(daq_ip_addr) 129.64.37.79
	set config(daq_source_driver_socket) 8
	set config(daq_source_mux_socket) 1
	set config(daq_source_device_element) "3 4"
	set config(daq_driver_socket) 5
	set config(daq_mux_socket) 1
	set config(daq_device_element) 2
	set config(daq_subtract_background) 0
	set config(daq_adjust_flash) 0
	set config(daq_flash_seconds) 0.000010
	set config(intensify) exact
	set config(analysis_threshold) "10 #"
	set config(analysis_num_spots) 2
	set config(analysis_enable) 1
	set config(verbose_result) 0

	return 1
}		

#
# LWDAQ_analysis_BCAM applies BCAM analysis to an image 
# in the lwdaq image list. By default, the routine uses the
# image $config(memory_name).
proc LWDAQ_analysis_BCAM {{image_name ""}} {
	upvar #0 LWDAQ_config_BCAM config
	upvar #0 LWDAQ_info_BCAM info
	if {$image_name == ""} {set image_name $config(memory_name)}
	set l [LWDAQ_split $config(analysis_num_spots)]
	set num_spots [lindex $l 0]
	if {$num_spots == ""} {set num_spots 1}
	set sort_code [lindex $l 1]
	if {$sort_code == ""} {set sort_code 1}
	set result [lwdaq_bcam $image_name \
		-show_timing $info(analysis_show_timing) \
		-show_pixels $info(analysis_show_pixels) \
		-num_spots $num_spots \
		-pixel_size_um $info(analysis_pixel_size_um) \
		-threshold $config(analysis_threshold) \
		-analysis_type $config(analysis_enable) \
		-sort_code $sort_code \
		-return_bounds $info(analysis_return_bounds) \
		-return_intensity $info(analysis_return_intensity)] 
	if {$result == ""} {set result "ERROR: $info(name) analysis failed."}
	return $result
}

#
# LWDAQ_infobuttons_BCAM creates buttons that allow us to configure
# the BCAM for any of the available image sensors.
#
proc LWDAQ_infobuttons_BCAM {f} {
	global LWDAQ_Driver

	foreach a "TC255 TC237 KAF0400 ICX424 ICX424Q" {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_set_image_sensor $a BCAM"
		pack $f.$b -side left -expand yes
	}
}

#
# LWDAQ_daq_BCAM captures an image from the LWDAQ electronics and places
# the image in the lwdaq image list. It provides background subtraction by
# taking a second image while flashing non-existent lasers. It provides
# automatic exposure adjustment by calling itself until the maximum image
# intensity lies within peak_min and peak_max. For detailed comments upon
# the readout of the image sensors, see the LWDAQ_daq_Camera routine.
#
proc LWDAQ_daq_BCAM {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_BCAM info
	upvar #0 LWDAQ_config_BCAM config

	set image_size [expr $info(daq_image_width) * $info(daq_image_height)]
	if {$config(daq_flash_seconds) > $info(flash_seconds_max)} {
		set config(daq_flash_seconds) $info(flash_seconds_max)
	}
	if {$config(daq_flash_seconds) < 0} {
		set config(daq_flash_seconds) 0
	}

	if {[catch {
		# We open one or two sockets for the camera and the sources.
		set sock_1 [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock_1 $info(daq_password)
		if {![LWDAQ_ip_addr_match $info(daq_source_ip_addr) $config(daq_ip_addr)]} {
			set sock_2 [LWDAQ_socket_open $info(daq_source_ip_addr)]
			LWDAQ_login $sock_2 $info(daq_password)
		} {
			set sock_2 $sock_1
		}

		# Select the device and set the device type.
		LWDAQ_set_driver_mux $sock_1 $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock_1 $info(daq_device_type)
		LWDAQ_set_device_element $sock_1 $config(daq_device_element)
		
		# Clear the image sensor of charge.
		if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
			LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
			LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
			LWDAQ_wake $sock_1
		}
		if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
			LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
			LWDAQ_transmit_command_hex $sock_1 0098
			LWDAQ_transmit_command_hex $sock_1 00B8
			LWDAQ_transmit_command_hex $sock_1 0098
		}	
		if {($info(daq_device_type) == $LWDAQ_Driver(KAF0400_device))} {
			for {set i 1} {$i < 10} {incr i} {
				LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
			}
			LWDAQ_wake $sock_1
		}
	
		# If two drivers, wait for the first to finish.	
		if {$sock_1 != $sock_2} {LWDAQ_wait_for_driver $sock_1}
		
		# Select the sources one by one and flash them.
		LWDAQ_set_driver_mux $sock_2 $config(daq_source_driver_socket) $config(daq_source_mux_socket)
		LWDAQ_set_device_type $sock_2 $info(daq_source_device_type)
		set total_flash_time 0
		foreach e $config(daq_source_device_element) {
			set en [lindex [split $e *] 0]
			set ff [lindex [split $e *] 1]
			if {![string is integer -strict $en]} {
				error "invalid source element number \"$en\""
			}
			if {![string is double -strict $ff]} {set ff 1}
			LWDAQ_set_device_element $sock_2 $en
			set ft [expr $config(daq_flash_seconds) * $ff]
			if {$ft > $info(flash_seconds_max)} {
				set ft $info(flash_seconds_max)
			}
			set total_flash_time [expr $total_flash_time + $ft]
			LWDAQ_flash_seconds $sock_2 $ft
		}
		
		# Add the ambient exposure if it's non-zero.
		if {$info(ambient_exposure_seconds) > 0.0} {
			LWDAQ_delay_seconds $sock_2 $info(ambient_exposure_seconds)
		}
		
		# If two drivers, wait for the second one to finish.
		if {$sock_1 != $sock_2} {LWDAQ_wait_for_driver $sock_2}
		
		# Select the camera again.
		LWDAQ_set_driver_mux $sock_1 $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock_1 $info(daq_device_type)
		LWDAQ_set_device_element $sock_1 $config(daq_device_element)
		
		# Transfer the image into the readout array.
		if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
			LWDAQ_execute_job $sock_1 $LWDAQ_Driver(alt_move_job)
		}
		if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
			LWDAQ_transmit_command_hex $sock_1 0099
			LWDAQ_transmit_command_hex $sock_1 0098
			LWDAQ_transmit_command_hex $sock_1 0088
		}

		# Read the image out of the sensor and into driver memory.
		LWDAQ_set_data_addr $sock_1 0
		LWDAQ_execute_job $sock_1 $LWDAQ_Driver(read_job)
		
		# Put camera and source to sleep.
		LWDAQ_sleep $sock_1		
		if {$sock_1 != $sock_2} {LWDAQ_sleep $sock_2}

		# Download the image from the driver.
		set image_contents [LWDAQ_ram_read $sock_1 0 $image_size]

		# Now we do it all again for background subtraction.
		if {$config(daq_subtract_background)} {
			if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
				LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
				LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
				LWDAQ_wake $sock_1
			}
			if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
				LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
				LWDAQ_transmit_command_hex $sock_1 0098
				LWDAQ_transmit_command_hex $sock_1 00B8
				LWDAQ_transmit_command_hex $sock_1 0098
			}	
			LWDAQ_wake $sock_1			
			if {$sock_1 != $sock_2} {LWDAQ_wait_for_driver $sock_1}
			LWDAQ_set_driver_mux $sock_2 $config(daq_source_driver_socket) $config(daq_source_mux_socket)
			LWDAQ_set_device_type $sock_2 $info(daq_source_device_type)
			LWDAQ_delay_seconds $sock_2 $total_flash_time
			if {$sock_1 != $sock_2} {LWDAQ_wait_for_driver $sock_2}
			LWDAQ_set_driver_mux $sock_1 $config(daq_driver_socket) $config(daq_mux_socket)
			LWDAQ_set_device_type $sock_1 $info(daq_device_type)
			LWDAQ_set_device_element $sock_1 $config(daq_device_element)
			if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
				LWDAQ_execute_job $sock_1 $LWDAQ_Driver(alt_move_job)
			}
			if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
				LWDAQ_transmit_command_hex $sock_1 0099
				LWDAQ_transmit_command_hex $sock_1 0098
				LWDAQ_transmit_command_hex $sock_1 0088
			}
			LWDAQ_set_data_addr $sock_1 0
			LWDAQ_execute_job $sock_1 $LWDAQ_Driver(read_job)
			LWDAQ_sleep $sock_1		
			if {$sock_1 != $sock_2} {LWDAQ_sleep $sock_2}
			set background_image_contents [LWDAQ_ram_read $sock_1 0 $image_size]
		}
		
		LWDAQ_socket_close $sock_1
		if {$sock_2 != $sock_1} {LWDAQ_socket_close $sock_2}
	} error_result]} { 
		if {[info exists sock_1]} {LWDAQ_socket_close $sock_1}
		if {[info exists sock_2]} {LWDAQ_socket_close $sock_2}
		return "ERROR: $error_result"
	}
		
	set config(memory_name) [lwdaq_image_create \
		-width $info(daq_image_width) \
		-height $info(daq_image_height) \
		-left $info(daq_image_left) \
		-right $info(daq_image_right) \
		-top $info(daq_image_top) \
		-bottom $info(daq_image_bottom) \
		-data $image_contents \
		-name "$info(name)\_$info(counter)"]
		
	if {$config(daq_subtract_background)} {
		set background_image_name [lwdaq_image_create \
			-width $info(daq_image_width) \
			-height $info(daq_image_height) \
			-left $info(daq_image_left) \
			-right $info(daq_image_right) \
			-top $info(daq_image_top) \
			-bottom $info(daq_image_bottom) \
			-data $background_image_contents]
		lwdaq_image_manipulate $config(memory_name) \
			subtract $background_image_name -replace 1
		lwdaq_image_destroy $background_image_name
	}
	
	if {!$config(daq_adjust_flash)} {return $config(memory_name)} 

	set max [lindex [lwdaq_image_characteristics $config(memory_name)] 6]
	set t $config(daq_flash_seconds)
	if {$max < 1} {set max 1}
	if {$max < $info(peak_min)} {
		if {$t < $info(flash_seconds_max)} {
			if {$t < $info(flash_seconds_transition)} {
				set t [expr $t + $info(flash_seconds_step) ]
				set call_self 1
			} {
				set t [expr ($info(peak_min) + $info(peak_max)) * 0.5 * $t / $max ]
				if {$t > $info(flash_seconds_max)} {
					set t $info(flash_seconds_max)
					set call_self 1
				} {
					set call_self 1
				}
			}
		} {
			set call_self 0
		}
	} {
		if {$max > $info(peak_max)} {
			if {$t > 0} {
				if {$t <= $info(flash_seconds_transition)} {
					set t [expr $t - $info(flash_seconds_step) ]
					set call_self 1
				} {
					set t  [expr $t * $info(flash_seconds_reduce) ]
					set call_self 1
				}
			} {
				set call_self 0
			}
		} {
			set call_self 0
		}
	}

	if {$call_self \
		&& ($info(control) != "Stop") \
		&& ($info(flash_num_tries)<$info(flash_max_tries))} {
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

#
# LWDAQ_extended_BCAM tries to assign optimal values to peak_max and 
# peak_min, and adjust the analysis boundaries to enclose the spots within
# a number of pixels of their centers. You direct the configuration calculations
# with the extended_parameters string, which contains parameters
# as a list. The string "0.6 0.9 20 1" sets peak_min to 60% of saturation, 
# peak_max to 90% of saturation, shrinks the image bounds to 20 pixels around
# the spot center, and adjusts individual source exposure times. If you don't
# want a border, specify bounds to be 0 (instead of 20). If you don't want to
# adjust multiple sources individually, specify 0 for individual_sources.
#
proc LWDAQ_extended_BCAM {} {
   	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_BCAM info
	upvar #0 LWDAQ_config_BCAM config

	# Check extended parameter string to make sure that its elements
	# are correct, and insert default values if they are absent.
	LWDAQ_print $info(text) "\nExtended Acquisition" green
	LWDAQ_print $info(text) "parameters \"$info(extended_parameters)\""
	set min_frac [lindex $info(extended_parameters) 0]
	LWDAQ_print $info(text) "min_frac = $min_frac"
	if {![string is double -strict $min_frac]} {
		return "ERROR: value \"$min_frac\" is not valid for min_frac."
	}
	if {($min_frac<0) || ($min_frac>=1)} {
		return "ERROR: value \"$min_frac\" is not valid for min_frac."
	}
	set max_frac [lindex $info(extended_parameters) 1]
	LWDAQ_print $info(text) "max_frac = $max_frac"
	if {![string is double -strict $max_frac]} {
		return "ERROR: value \"$max_frac\" is not valid for max_frac."
	}
	if {($max_frac<=$min_frac) || ($max_frac>1)} {
		return "ERROR: value \"$max_frac\" is not valid for max_frac."
	}
	set border [lindex $info(extended_parameters) 2]
	if {$border == ""} {set border 0}
	LWDAQ_print $info(text) "border = $border"
	if {![string is integer $border]} {
		return "ERROR: value \"$border\" is not valid for border."
	}
	if {$border < 0} {
		return "ERROR: value \"$border\" is not valid for border."
	}
	set individual_sources [lindex $info(extended_parameters) 3]
	if {$individual_sources == ""} {set individual_sources 1}
	LWDAQ_print $info(text) "individual_sources = $individual_sources"
	if {![string is integer -strict $border]} {
		return "ERROR: value \"$individual_sources\" is not valid for individual_sources."
	}

	# Save the data acquisition parameters we will be altering during
	# extended acquisition. We used the saved values to make sure that
	# we restore the BCAM Instrument to its former condition at the end
	# of extended data acquisition, even if we abort with an error.
	set saved_daf $config(daq_adjust_flash)
	set saved_dfs $config(daq_flash_seconds)
	set saved_dsds $config(daq_source_driver_socket)
	set saved_apsu $info(analysis_pixel_size_um)
	set saved_dsde $config(daq_source_device_element) 
	
	# Obtain an image with zero flash time. This image serves
	# as a background or black-level reference.
	set config(daq_adjust_flash) 0
	set config(daq_source_driver_socket) 0
	set config(daq_flash_seconds) 0
	set image_name [LWDAQ_daq_BCAM]
	set config(daq_flash_seconds) $saved_dfs
	set config(daq_source_driver_socket) $saved_dsds
	set config(daq_adjust_flash) $saved_daf
	
	# Display the background image and determine its average intensity.
	if {[LWDAQ_is_error_result $image_name]} {return $image_name}	
	if {[winfo exists $info(window)]} {
		lwdaq_draw $image_name $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	} 
	set bg [lindex [lwdaq_image_characteristics $image_name] 4]
	LWDAQ_print $info(text) "background = $bg"
	
	# Obtain an image with the lasers flashing for the 
	# maximum possible time. We assume this image contains
	# saturated pixels.
	set config(daq_adjust_flash) 0
	set config(daq_flash_seconds) $info(flash_seconds_max)
	set image_name [LWDAQ_daq_BCAM]
	set config(daq_flash_seconds) $saved_dfs
	set config(daq_adjust_flash) $saved_daf
	
	# Display the saturated image and determine its maximum intensity.
	if {[LWDAQ_is_error_result $image_name]} {return $image_name}	
	if {[winfo exists $info(window)]} {
		lwdaq_draw $image_name $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	} 
	set sat [lindex [lwdaq_image_characteristics $image_name] 6]
	LWDAQ_print $info(text) "saturation = $sat"

	# Calculate the maximum and minimum acceptable peak spot
	# intensities for the BCAM, based upon the background
	# and saturated image intensities.
	set info(peak_max) [expr round(($sat - $bg) * $max_frac + $bg)]
	LWDAQ_print $info(text) "peak_max = $info(peak_max)"
	set info(peak_min) [expr round(($sat - $bg) * $min_frac + $bg)]
	LWDAQ_print $info(text) "peak_min = $info(peak_min)"
	
	# We now go through all the source elements in daq_source_element
	# and determine their optimal exposure times separately.
	if {([llength $config(daq_source_device_element)] > 1) && $individual_sources} {

		# Make a list of element numbers and their optimal flash times.
        set exposures [list]
        foreach element $config(daq_source_device_element) {
        	set element_num [lindex [split $element *] 0]
			set config(daq_source_device_element) $element_num
			set config(daq_flash_seconds) $info(flash_seconds_max)
			set config(daq_adjust_flash) 1
			set image_name [LWDAQ_daq_BCAM]
			set flash_seconds $config(daq_flash_seconds)
			set config(daq_adjust_flash) $saved_daf
			set config(daq_flash_seconds) $saved_dfs
			set config(daq_source_device_element) $saved_dsde

			if {[LWDAQ_is_error_result $image_name]} {return $image_name}	
			if {[winfo exists $info(window)]} {
				lwdaq_draw $image_name $info(photo) \
					-intensify $config(intensify) -zoom $info(zoom)
			} 
			lappend exposures "$element_num $flash_seconds"
			LWDAQ_print $info(text) "Element $element_num flash time = $flash_seconds"
        }
        
        # Sort this list in order of increasing exposure time, and determine
        # the minimum exposure time.
        set exposures [lsort -increasing -index 1 $exposures]
        set min_exposure [lindex $exposures 0 1]
        
        # We will use the minimum exposure time as daq_flash_seconds unless
        # the minimum exposure time is less than flash_seconds_step, in 
        # which case we use flash_seconds_step instead.
		if {$min_exposure < $info(flash_seconds_step)} {
			set config(daq_flash_seconds) $info(flash_seconds_step)
		} {
			set config(daq_flash_seconds) $min_exposure
		}
        LWDAQ_print $info(text) "Reference flash time = $config(daq_flash_seconds)"
        
        # Create a new device list in which we list the device elements in
        # order of increasing exposure time, with each element number followed
        # by "*" and the multiple of daq_flash_seconds required to 
        # obtain the element's exposure time.
        set new_device_list ""
		foreach element $exposures {
			set exposure [lindex $element 1]
			set element_num [lindex $element 0]
			set ratio [expr $exposure / $config(daq_flash_seconds)]
			append new_device_list "$element_num\*[format %1.2f $ratio] "
		}
		
		# Replace the old device list.
		set config(daq_source_device_element) $new_device_list
		LWDAQ_print $info(text) "New device list = \"$new_device_list\""
	}
	
	# Try out the new parameter with an acquisition with automatic
	# flash adjustement.
	set config(daq_adjust_flash) 1
	set image_name [LWDAQ_daq_BCAM]
	set config(daq_adjust_flash) $saved_daf
	if {[LWDAQ_is_error_result $image_name]} {return $image_name}	

	# If the border parameter is greater than zero, we adjust the
	# analysis boundaries so they enclose the spots with $border
	# pixels on all sides of the spot centers.
	if {$border > 0} {
	
		# Find the coordinates of the spots in units of
		# image pixels.
		set info(analysis_pixel_size_um) 1
		set result [LWDAQ_analysis_BCAM $image_name]
		set info(analysis_pixel_size_um) $saved_apsu
		if {[LWDAQ_is_error_result $result]} {return $image_name}	

		# Find the range of columns and rows spanned by
		# the spot centers.
		set max_i 1
		set max_j 1
		set min_i $info(daq_image_width)
		set min_j $info(daq_image_height)
		foreach {i j n p s t} $result {
			if {$i == -1} {continue}
			if {$i > $max_i} {set max_i $i}
			if {$i < $min_i} {set min_i $i}
			if {$j > $max_j} {set max_j $j}
			if {$j < $min_j} {set min_j $j}			
		}
		
		# Calculate the analysis boundaries to enclose the spot centers.
		set info(daq_image_left) [expr round($min_i - $border)]
		if {$info(daq_image_left) < 1} {
			set info(daq_image_left) 1
		}
		set info(daq_image_right) [expr round($max_i + $border)]
		if {$info(daq_image_right) >= [expr $info(daq_image_width) -1]} {
			set info(daq_image_right) [expr $info(daq_image_width) -1]
		}
		set info(daq_image_top) [expr round($min_j - $border)]
		if {$info(daq_image_top) < 1} {
			set info(daq_image_top) 1
		}
		set info(daq_image_bottom) [expr round($max_j + $border)]
		if {$info(daq_image_bottom) >= [expr $info(daq_image_height) - 1]} {
			set info(daq_image_bottom) [expr $info(daq_image_height) -1]
		}
		
		# Inform the user of the new boundaries.
		LWDAQ_print $info(text) "daq_image_left = $info(daq_image_left)"
		LWDAQ_print $info(text) "daq_image_top = $info(daq_image_top)"
		LWDAQ_print $info(text) "daq_image_right = $info(daq_image_right)"
		LWDAQ_print $info(text) "daq_image_bottom = $info(daq_image_bottom)"

		# Set the analysis boundaries of the existing image.
		lwdaq_image_manipulate $image_name none \
			-left $info(daq_image_left) \
			-right $info(daq_image_right) \
			-top $info(daq_image_top) \
			-bottom $info(daq_image_bottom)
	}

	# Display the final image.
	if {[winfo exists $info(window)]} {
		lwdaq_draw $image_name $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	} 
	
	# Return the name of the final image.
	return $image_name
}

