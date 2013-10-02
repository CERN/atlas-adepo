# Long-Wire Data Acquisition Software (LWDAQ)
# Copyright (C) 2009-2012 Kevan Hashemi, Brandeis University
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
# Dosimeter.tcl defines the Dosimeter instrument.
#

#
# LWDAQ_init_Dosimeter creates all elements of the Dosimeter instrument's
# config and info arrays.
#
proc LWDAQ_init_Dosimeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Dosimeter info
	upvar #0 LWDAQ_config_Dosimeter config
	array unset config

	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Dosimeter"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(analysis_show_timing) 0
	set info(analysis_show_pixels) 0
	set info(daq_extended) 0
	set info(daq_device_type) 2
	set info(daq_source_device_type) 1
	set info(file_use_daq_bounds) 0
	set info(daq_image_width) 344
	set info(daq_image_height) 244
	set info(daq_image_left) 30
	set info(daq_image_right) [expr $info(daq_image_width) - 10]
	set info(daq_image_top) 11
	set info(daq_image_bottom) [expr $info(daq_image_height) - 10]
	set info(file_try_header) 1
	set info(use_image_area) 0
	set info(analysis_pixel_size_um) 10
	set info(daq_password) "no_password"
	set info(delete_old_images) 1
	set info(verbose_description) " \
			{Charge Density (counts/pixel)} \
			{Dark Current (counts/row)} \
			{Average Intensity (counts)} \
			{Threshold Intesnity (counts)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)} \
			{Hit Intensity (total net intensity)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./images/$info(name)\*
	set config(memory_name) $info(name)\_0
	set config(daq_ip_addr) 129.64.37.88
	set config(daq_driver_socket) 2
	set config(daq_mux_socket) 1
	set config(daq_device_element) 2
	set config(daq_source_driver_socket) 1
	set config(daq_source_mux_socket) 1
	set config(daq_source_device_element) 1
	set config(daq_flash_seconds) 0.0
	set config(daq_activate_hex) "0000"
	set config(daq_exposure_seconds) 0.1
	set config(daq_subtract_background) 0
	set config(intensify) exact
	set config(analysis_threshold) "2 $"
	set config(analysis_num_spots) 4
	set config(analysis_enable) 1
	set config(verbose_result) 0

	return 1
}		

#
# LWDAQ_analysis_Dosimeter applies Dosimeter analysis to an image 
# in the lwdaq image list. By default, the routine uses the
# image $config(memory_name). It calculates the average and standard
# deviation of intensity. It calculates the vertical slope of intensity,
# which will be zero if we obtained the image with background 
# subtraction. It calcualtes the sum of intensity using the threshold,
# and then looks for the most prominent spots in the image for a list
# of hits.
proc LWDAQ_analysis_Dosimeter {{image_name ""}} {
	upvar #0 LWDAQ_config_Dosimeter config
	upvar #0 LWDAQ_info_Dosimeter info
	if {$image_name == ""} {set image_name $config(memory_name)}

	# Obtain the vertical slope of intensity, which is proportional
	# to the dark current, provided that we have not performed a 
	# background subtraction.
	set profile [lwdaq_image_profile $image_name -row 0]
	set row_num 0
	foreach row $profile {
		append graph "$row_num [format %.2f $row] "
		incr row_num
	}
	set slope [format %.4f [lindex [lwdaq straight_line_fit $graph] 0]]

	# Obtain the sum intensity above threshold for the entire image.
	# we must first convert the threshold string into an absolute
	# threshold, and to do this we call lwdaq_bcam.
	set threshold_string [lwdaq_bcam $image_name \
		-num_spots 1 \
		-threshold $config(analysis_threshold) \
		-analysis_type 1]
	set threshold [lindex $threshold_string 5]
	set histogram [lwdaq_image_histogram $image_name]
	set sum 0
	foreach {i f} $histogram {
		if {$i > $threshold} {set sum [expr $sum + ($i-$threshold) * $f]}
	}
	
	# Divide the sum intensity by the number of pixels in the analysis
	# boundaries to obtain the charge density in counts/pixel.
	set bounds_string [lwdaq_image_characteristics $image_name]
	scan $bounds_string %u%u%u%u%f left top right bottom ave
	set density [format %.3f [expr 1.0 * $sum / ($right-$left) / ($bottom-$top)]]
	
	# Obtain a list of hits with intensity above threshold, giving
	# the total intensity of each such hit.
	set hits [lwdaq_bcam $image_name \
		-show_timing $info(analysis_show_timing) \
		-show_pixels $info(analysis_show_pixels) \
		-num_spots $config(analysis_num_spots) \
		-pixel_size_um $info(analysis_pixel_size_um) \
		-threshold $config(analysis_threshold) \
		-analysis_type 1 \
		-return_intensity 1 \
		-sort_code 1]

	return "$density $slope $ave $threshold $hits"
}

#
# LWDAQ_infobuttons_Dosimeter creates buttons that allow us to configure
# the Dosimeter for any of the available image sensors.
#
proc LWDAQ_infobuttons_Dosimeter {f} {
	global LWDAQ_Driver

	foreach a "TC255 TC237 KAF0400 ICX424 ICX424Q" {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_set_image_sensor $a Dosimeter"
		pack $f.$b -side left -expand yes
	}
}


#
# LWDAQ_daq_Dosimeter captures an image from the LWDAQ electronics and places
# the image in the lwdaq image list. 
#
proc LWDAQ_daq_Dosimeter {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Dosimeter info
	upvar #0 LWDAQ_config_Dosimeter config

	set image_size [expr $info(daq_image_width) * $info(daq_image_height)]

	if {($config(daq_flash_seconds) > 0) && ($config(daq_activate_hex) != "0000")} {
		LWDAQ_print $info(text) "WARNING: Flashing and activation are both enabled."
	}

	if {[catch {
		# Connect to the driver. We assume the dosimeter and radiation source are
		# connected to the same driver.
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)
		
		# Select the Dosimeter sensor, clear the charge out of it, and place it
		# in its exposure state.
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_device_element $sock $config(daq_device_element)

		# Clear the image sensor of stored charge.
		if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
			# In the TC255 and TC237 image sensors, we can use the sensor's storage
			# area to detect radiation. The storage area is covered with an 
			# aluminum mask to keep out light. We clear charge out of this area
			# and the image area using the move job.
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			
			# Set the horizontal and vertical clock control bits lo so that
			# the sensor accumulates charge in its image and storage areas.
			LWDAQ_wake $sock
		}
		if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
			# In the ICX424 and ICX424Q image sensors, we can use the sensor's vertical
			# transfer array to detect radiation. This array is masked from light
			# by the image pixel array.
			
			# Clear the transfer array with move jobs.
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)

			# Clear the image area with a substrate pulse. We set
			# V2 and V3 hi and V1 lo to keep charge constrained in the
			# vertical transfer columns.
			LWDAQ_transmit_command_hex $sock 0098
			LWDAQ_transmit_command_hex $sock 00B8
			LWDAQ_transmit_command_hex $sock 0098

			# If we are using the transfer array, clear it again. We don't
			# do this when we are using the image area, because operating
			# the vertical clock phases to clear the transfer array corrupts
			# the image in the image area.
			if {!$info(use_image_area)} {
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			}
		}
		if {($info(daq_device_type) == $LWDAQ_Driver(KAF0400_device))} {
			# Execute multiple move jobs to clear the image area.
			for {set i 1} {$i < 10} {incr i} {
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			}
			
			# Return the device to is exposure state.
			LWDAQ_wake $sock
		}

		# If we have a source of radiation that can be flashed quickly by
		# the driver with a flash job, daq_flash_seconds will be greater than
		# zero, and will indicate the time for which the source must be turned
		# on.
		if {$config(daq_flash_seconds) > 0} {
			LWDAQ_set_driver_mux $sock $config(daq_source_driver_socket) \
				$config(daq_source_mux_socket)
			LWDAQ_set_device_type $sock $info(daq_source_device_type)
			LWDAQ_set_device_element $sock $config(daq_source_device_element)
			LWDAQ_set_delay_seconds $sock $config(daq_flash_seconds)
			LWDAQ_execute_job $sock $LWDAQ_Driver(flash_job)
		}
		
		# If we have a source of radiation that can be turned on with a single
		# device command, we send that command now. The subsequent delay introduced
		# by daq_exposure_seconds should be adequate to include the length of 
		# the radiation burst.
		if {$config(daq_activate_hex) != "0000"} {
			LWDAQ_set_driver_mux $sock $config(daq_source_driver_socket) \
				$config(daq_source_mux_socket)
			LWDAQ_transmit_command_hex $sock $config(daq_activate_hex)		
		}
		
		# Expose the sensor for the exposure time.
		LWDAQ_delay_seconds $sock $config(daq_exposure_seconds)
		
		# Select the image sensor.
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) \
			$config(daq_mux_socket)
		LWDAQ_set_device_type $sock $info(daq_device_type)
		LWDAQ_set_device_element $sock $config(daq_device_element)

		# Prepare image sensor for readout.
		if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
			if {$info(use_image_area)} {
				# Transfer the image area charge into the storage area.
				LWDAQ_execute_job $sock $LWDAQ_Driver(alt_move_job)
			}
		}
		if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
			|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
			if {$info(use_image_area)} {
				# Transfer the image out of the image area and into the
				# transfer columns by applying read pulse to V2 and V3.
				# We keep V1 lo to maintain pixel charge separation in 
				# the vertical transfer columns.
				LWDAQ_transmit_command_hex $sock 0099
				LWDAQ_transmit_command_hex $sock 0098
			}

			# Drive V2 hi, V1 and V3 lo so as to collect all pixel
			# charges under the V2 clock.
			LWDAQ_transmit_command_hex $sock 0088	
		}

		# Read out the pixels and store in driver memory.
		LWDAQ_set_data_addr $sock 0
		LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)
		
		# Transfer the image from the driver to the data acquisition computer.
		set image_contents [LWDAQ_ram_read $sock 0 $image_size]

		# If we want to subtract a background, we obtain the 
		# background image and subtract it.
		if {$config(daq_subtract_background)} {
			if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
				LWDAQ_wake $sock
			}
			if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
				LWDAQ_transmit_command_hex $sock 0098
				LWDAQ_transmit_command_hex $sock 00B8
				LWDAQ_transmit_command_hex $sock 0098
				if {!$info(use_image_area)} {
					LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
				}
			}
			if {$config(daq_flash_seconds) > 0} {
				LWDAQ_set_delay_seconds $sock $config(daq_flash_seconds)
				LWDAQ_execute_job $sock $LWDAQ_Driver(delay_job)
			}
			LWDAQ_delay_seconds $sock $config(daq_exposure_seconds)
			if {($info(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
				if {$info(use_image_area)} {
					LWDAQ_execute_job $sock $LWDAQ_Driver(alt_move_job)
				}
			}
			if {($info(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
				|| ($info(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
				if {$info(use_image_area)} {
					LWDAQ_transmit_command_hex $sock 0099
					LWDAQ_transmit_command_hex $sock 0098
				}
				LWDAQ_transmit_command_hex $sock 0088	
			}
			LWDAQ_set_data_addr $sock 0
			LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)
			set background_image_contents [LWDAQ_ram_read $sock 0 $image_size]
		}

		# Send the sensor to sleep.
		LWDAQ_sleep $sock

		# Close the socket. We are done with data acquisition.
		LWDAQ_socket_close $sock
	} error_result]} { 
		if {[info exists sock]} {LWDAQ_socket_close $sock}
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

	lwdaq_image_manipulate $config(memory_name) none \
		-results "$config(daq_exposure_seconds)"

	return $config(memory_name) 
} 

