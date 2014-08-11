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
# Rasnik.tcl defines the Rasnik instrument.
#

#
# LWDAQ_init_Rasnik creates all elements of the Rasnik instrument's
# config and info arrays.
#
proc LWDAQ_init_Rasnik {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Rasnik info
	upvar #0 LWDAQ_config_Rasnik config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Rasnik"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(daq_extended) 0
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 344
	set info(daq_image_height) 244
	set info(daq_image_left) 20
	set info(daq_image_right) [expr $info(daq_image_width) - 1]
	set info(daq_image_top) 1
	set info(daq_image_bottom) [expr $info(daq_image_height) - 1]
	set info(flash_seconds_max) 0.5
	set info(flash_seconds_step) 0.000001
	set info(flash_seconds_reduce) 0.1
	set info(flash_seconds_transition) 0.000010
	set info(flash_max_tries) 30
	set info(flash_num_tries) 0
	set info(peak_max) 180
	set info(peak_min) 150
	set info(extended_parameters) "0.6 0.9"
	set info(daq_password) "no_password"
	set info(daq_source_ip_addr) "*"
	set info(analysis_show_fitting) 0
	set info(analysis_show_timing) 0
	set info(analysis_reference_x_um) 0
	set info(analysis_reference_y_um) 0
	set info(analysis_max_tries) 20 
	set info(analysis_min_width) 50
	set info(analysis_max_mag_ratio) "none"
	set info(analysis_max_pos_um) "none"
	set info(analysis_pixel_size_um) 10
	set info(analysis_pattern_only) 0
	set info(daq_device_type) 2
	set info(daq_source_device_type) 1
	set info(delete_old_images) 1
	set info(verbose_description) " \
			{Mask Position X (um in mask coordinates)} \
			{Mask Position Y (um in mask coordinates)} \
			{Image Magnification X (mm/mm)} \
			{Image Magnification Y (mm/mm)} \
			{Image Rotation (mrad anticlockwise)} \
			{Measurement Precision (um in mask)} \
			{Mask Square Size (um)} {Pixel Size (um)} \
			{Orientation Code (the code chosen by analysis)} \
			{Reference Code (the code used by analysis)} \
			{Reference Point X (um from left edge of CCD)} \
			{Reference Point Y (um from top edge of CCD)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 129.64.37.79
	set config(daq_source_driver_socket) 7
	set config(daq_source_mux_socket) 1
	set config(daq_source_device_element) 1
	set config(daq_driver_socket) 6
	set config(daq_mux_socket) 1
	set config(daq_device_element) 2
	set config(daq_subtract_background) 0
	set config(daq_adjust_flash) 0
	set config(daq_flash_seconds) 0.01
	set config(intensify) exact
	set config(analysis_reference_code) 2
	set config(analysis_orientation_code) 0
	set config(analysis_square_size_um) 120
	set config(analysis_enable) 1
	set config(verbose_result) 0

	return 1
}		

#
# LWDAQ_analysis_Rasnik applies rasnik analysis to an image in the lwdaq
# image list. By default, the routine uses image $config(memory_name).
#
proc LWDAQ_analysis_Rasnik {{image_name ""}} {
	upvar #0 LWDAQ_config_Rasnik config
	upvar #0 LWDAQ_info_Rasnik info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {$info(analysis_show_fitting) != 0} {
		lwdaq_config -wait_ms $info(analysis_show_fitting)
		if {$info(analysis_show_fitting) == -1} {
			set info(control) "Acquire"
		}
	}
	
	set analysis_type [expr $config(analysis_enable) % 10]
	if {$analysis_type == 0} {return ""}

	set img $image_name	
	set shrink [expr $config(analysis_enable) / 10]
	if {$shrink >= 1} {
		set img [lwdaq_image_manipulate $img smooth -replace 0]
	}
	if {$shrink == 1} {
		lwdaq_image_manipulate $img smooth -replace 1
	}
	if {$shrink > 1} {
		lwdaq_image_manipulate $img shrink_$shrink -replace 1
		set pixel_size [expr $shrink * $info(analysis_pixel_size_um)]
		set zoom [expr $shrink * $info(zoom)]
	} {
		set pixel_size $info(analysis_pixel_size_um)
		set zoom $info(zoom)
	}
	lwdaq_config -zoom $zoom -intensify $config(intensify)
	
	scan [lwdaq_image_characteristics $img] "%d %d %d %d" left top right bottom
	set done 0
	set index 0
	while {!$done && ($analysis_type != 0)} {
		incr index
		set result [lwdaq_rasnik $img \
			-show_fitting $info(analysis_show_fitting) \
			-show_timing $info(analysis_show_timing) \
			-reference_code $config(analysis_reference_code) \
			-orientation_code $config(analysis_orientation_code) \
			-pixel_size_um $pixel_size \
			-reference_x_um $info(analysis_reference_x_um) \
			-reference_y_um $info(analysis_reference_y_um) \
			-square_size_um $config(analysis_square_size_um) \
			-pattern_only $info(analysis_pattern_only)]
		if {![LWDAQ_is_error_result $result]} {
			scan $result "%f %f %f %f" x y mag_x mag_y
			set error_message ""
			if {[string is integer -strict $info(analysis_max_pos_um)]} {
				if {$x > $info(analysis_max_pos_um)} {
					append error_message "x>$info(analysis_max_pos_um) "
				}
				if {$y > $info(analysis_max_pos_um)} {
					append error_message "y>$info(analysis_max_pos_um) "
				}
			}
			if {[string is double -strict $info(analysis_max_mag_ratio)]} {
				if {$mag_y == 0} {
					append error_message "mag_y=0 "
				} {
					set mag_ratio [expr $mag_x / $mag_y]
					if {$mag_ratio > $info(analysis_max_mag_ratio)} {
						append error_message "mag_x/mag_y>$info(analysis_max_mag_ratio) "
					}
					if {$mag_ratio < [expr 1 / $info(analysis_max_mag_ratio)]} {
						append error_message "mag_y/mag_x>$info(analysis_max_mag_ratio) "
					}
				}
			}
			if {$error_message != ""} {
				set result "ERROR: $error_message"
			}
		}
		if {![LWDAQ_is_error_result $result]} {
			set done 1
		} {
			if {($index < $info(analysis_max_tries)) \
					&& ($analysis_type >= 2)
					&& ($info(control) != "Stop")} {
				if {[winfo exists $info(window)] && ($analysis_type == 3)} {
					lwdaq_draw $img $info(photo) -intensify $config(intensify) -zoom $zoom
				}
				LWDAQ_update
				set min $info(analysis_min_width)
				if {[expr $right-$left]>$min} {
					set width [expr $min+round(rand()*($right-$left-$min))]
				} {
					set width [expr $right-$left]
				}
				if {[expr $bottom-$top]>$min} {
					set height [expr $min+round(rand()*($bottom-$top-$min))]
				} {
					set height [expr $bottom-$top]
				}
				set new_left [expr $left+round(rand()*($right-$left-$width))]
				set new_right [expr $new_left+$width]
				set new_top [expr $top+round(rand()*($bottom-$top-$height))]
				set new_bottom [expr $new_top+$height]
				lwdaq_image_manipulate $img none \
					-left $new_left -top $new_top -right $new_right -bottom $new_bottom
			} {
				set done 1
			}
		}
	}
	
	if {[LWDAQ_is_error_result $result]} {
		lwdaq_image_manipulate $img none -left $left -top $top -right $right -bottom $bottom
		if {[winfo exists $info(window)] && ($analysis_type == 3)} {
			lwdaq_draw $img $info(photo) -intensify $config(intensify) -zoom $zoom
			LWDAQ_update
		}
	}
	
	if {$img != $image_name} {
		lwdaq_image_manipulate $image_name transfer_overlay $img
		lwdaq_image_destroy $img
	}
	
	return $result
}

#
# LWDAQ_infobuttons_BCAM creates buttons that allow us to configure
# the BCAM for any of the available image sensors.
#
proc LWDAQ_infobuttons_Rasnik {f} {
	global LWDAQ_Driver
	foreach a "TC255 TC237 KAF0400 ICX424 ICX424Q" {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_set_image_sensor $a Rasnik"
		pack $f.$b -side left -expand yes
	}
}

#
# LWDAQ_daq_Rasnik ccaptures an image from the LWDAQ electronics and places
# the image in the lwdaq image list. It provides background subtraction by
# taking a second image while flashing non-existent LEDs. It provides
# automatic exposure adjustment by calling itself until the maximum image
# intensity lies withint peak_min and peak_max.
#
proc LWDAQ_daq_Rasnik {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Rasnik info
	upvar #0 LWDAQ_config_Rasnik config

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
		
		# Flash the rasnik illumination.
		LWDAQ_set_driver_mux $sock_2 $config(daq_source_driver_socket) \
			$config(daq_source_mux_socket)
		LWDAQ_set_device_type $sock_2 $info(daq_source_device_type)
		LWDAQ_set_device_element $sock_2 $config(daq_source_device_element)
		LWDAQ_flash_seconds $sock_2 $config(daq_flash_seconds)

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

		# Now we do it all again for background subtraction, but without
		# flashing the rasnik illumination.
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
			if {($info(daq_device_type) == $LWDAQ_Driver(KAF0400_device))} {
				for {set i 1} {$i < 10} {incr i} {
					LWDAQ_execute_job $sock_1 $LWDAQ_Driver(move_job)
				}
				LWDAQ_wake $sock_1
			}
			LWDAQ_wake $sock_1			
			if {$sock_1 != $sock_2} {LWDAQ_wait_for_driver $sock_1}
			LWDAQ_set_driver_mux $sock_2 $config(daq_source_driver_socket) \
				$config(daq_source_mux_socket)
			LWDAQ_set_device_type $sock_2 $info(daq_source_device_type)
			LWDAQ_delay_seconds $sock_2 $config(daq_flash_seconds)
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

	if {!$config(daq_adjust_flash)} {return $config(memory_name) }
	
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
# LWDAQ_extended_Rasnik tries to assign optimal values to peak_max and 
# peak_min. You direct the configuration with info(extended_parameters), 
# which contains min_frac and max_frac. With the string "0.6 0.9", the
# configuration sets peak_min to 60% of saturation, peak_max to 90% of 
# saturation.
#
proc LWDAQ_extended_Rasnik {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Rasnik info
	upvar #0 LWDAQ_config_Rasnik config

	LWDAQ_print $info(text) "\nExtended Acquisition" green
	LWDAQ_print $info(text) "parameters \"$info(extended_parameters)\""
	set min_frac [lindex $info(extended_parameters) 0]
	LWDAQ_print $info(text) "min_frac = $min_frac"
	if {![string is double -strict $min_frac]} {
		return "ERROR: value \"$min_frac\" is not valid for min_frac."
	}
	set max_frac [lindex $info(extended_parameters) 1]
	LWDAQ_print $info(text) "max_frac = $max_frac"
	if {![string is double -strict $max_frac]} {
		return "ERROR: value \"$max_frac\" is not valid for max_frac."
	}

	# Save the data acquisition parameters we will be altering during
	# extended acquisition. We used the saved values to make sure that
	# we restore the Rasnik Instrument to its former condition at the end
	# of extended data acquisition, even if we abort with an error.
	set saved_daf $config(daq_adjust_flash)
	set saved_dfs $config(daq_flash_seconds)
	set saved_dsds $config(daq_source_driver_socket)

	# Obtain an image with zero flash time. This image serves
	# as a background or black-level reference.
	set config(daq_adjust_flash) 0
	set config(daq_source_driver_socket) 0
	set config(daq_flash_seconds) 0
	set image_name [LWDAQ_daq_Rasnik]
	set config(daq_source_driver_socket) $saved_dsds
	set config(daq_flash_seconds) $saved_dfs
	set config(daq_adjust_flash) $saved_daf

	# Display the background image and determine its average intensity.
	if {[LWDAQ_is_error_result $image_name]} {return $image_name}	
	set bg [lindex [lwdaq_image_characteristics $image_name] 4]
	if {[winfo exists $info(window)]} {
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	} 
	LWDAQ_print $info(text) "background = $bg"
	
	# Obtain an image with the mask flashing for the 
	# maximum possible time. We assume this image contains
	# saturated pixels.
	set config(daq_adjust_flash) 0
	set config(daq_flash_seconds) $info(flash_seconds_max)
	set image_name [LWDAQ_daq_Rasnik]
	set config(daq_flash_seconds) $saved_dfs
	set config(daq_adjust_flash) $saved_daf
	
	# Display the saturated image and determine its maximum intensity.	
	if {[LWDAQ_is_error_result $image_name]} {return $image_name}	
	set sat [lindex [lwdaq_image_characteristics $image_name] 6]
	if {[winfo exists $info(window)]} {
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
	LWDAQ_print $info(text) "saturation = $sat"

	# Calculate the maximum and minimum acceptable peak spot
	# intensities for the BCAM, based upon the background
	# and saturated image intensities.
	set info(peak_max) [expr round(($sat - $bg) * $max_frac + $bg)]
	LWDAQ_print $info(text) "peak_max = $info(peak_max)"
	set info(peak_min) [expr round(($sat - $bg) * $min_frac + $bg)]
	LWDAQ_print $info(text) "peak_min = $info(peak_min)"
	
	# Try out the new parameter with an acquisition with automatic
	# flash adjustement.
	set config(daq_adjust_flash) 1
	set config(daq_flash_seconds) $info(flash_seconds_max)
	set image_name [LWDAQ_daq_Rasnik]
	set config(daq_adjust_flash) $saved_daf
	
	# Display the final image.
	if {[LWDAQ_is_error_result $image_name]} {return $image_name}	
	LWDAQ_print $info(text) "daq_flash_seconds = $config(daq_flash_seconds)"
	if {[winfo exists $info(window)]} {
		lwdaq_draw $config(memory_name) $info(photo) \
			-intensify $config(intensify) -zoom $info(zoom)
	}
	
	# Return the name of the final image.
	return $image_name
}

