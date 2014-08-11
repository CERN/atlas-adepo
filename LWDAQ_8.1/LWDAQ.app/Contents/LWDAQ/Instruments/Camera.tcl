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
# Camera.tcl defines the Camera instrument.
#

#
# LWDAQ_init_Camera creates all elements of the Camera instrument's
# config and info arrays.
#
proc LWDAQ_init_Camera {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Camera info
	upvar #0 LWDAQ_config_Camera config
	array unset config
	
	# The info array elements will not be displayed in the 
	# instrument window. The only info variables set in the 
	# LWDAQ_open_Instrument procedure are those which are checked
	# only when the instrument window is open.
	set info(name) "Camera"
	set info(control) "Idle"
	set info(window) [string tolower .$info(name)]
	set info(text) $info(window).text
	set info(photo) [string tolower $info(name)\_photo]
	set info(counter) 0 
	set info(zoom) 1
	set info(daq_extended) 0
	set info(file_use_daq_bounds) 0
	set info(daq_anti_blooming) 1
	set info(daq_fast_move) 0
	set info(daq_image_width) 700
	set info(daq_image_height) 520
	set info(daq_image_left) 24
	set info(daq_image_right) 682
	set info(daq_image_top) 14
	set info(daq_image_bottom) 506
	set info(daq_password) "no_password"
	set info(delete_old_images) 1
	set info(verbose_description) " \
		{Analysis Bounds Left (column)} {Analysis Bounds Top (row)} \
		{Analysis Bounds Right (column)} {Analysis Bounds Bottom (row)} \
		{Average of Intensity (counts)} {Standard Deviation of Intensity (counts)} \
		{Maximum Intensity (counts)} {Minimum Intensity (counts)} \
		{Height (rows)} {Width (columns)}"
	
	# All elements of the config array will be displayed in the
	# instrument window. No config array variables can be set in the
	# LWDAQ_open_Instrument procedure
	set config(image_source) "daq"
	set config(file_name) ./Images/$info(name)\*
	set config(memory_name) lwdaq_image_1
	set config(daq_ip_addr) 129.64.37.79
	set config(daq_device_type) 6
	set config(daq_driver_socket) 1
	set config(daq_mux_socket) 1
	set config(daq_device_element) 2
	set config(daq_exposure_seconds) 0.04
	set config(intensify) "rggb"
	set config(analysis_enable) 1
	set config(analysis_manipulation) "none"
	set config(verbose_result) 0
	
	return 1
}

#
# LWDAQ_analysis_Camera applies Camera analysis to an image 
# in the lwdaq image list. By default, the routine uses the
# image $config(memory_name).
#
proc LWDAQ_analysis_Camera {{image_name ""}} {
	upvar #0 LWDAQ_config_Camera config
	upvar #0 LWDAQ_info_Camera info
	if {$image_name == ""} {set image_name $config(memory_name)}
	if {[catch {	
		foreach m $config(analysis_manipulation) {
			lwdaq_image_manipulate $image_name $m -replace 1
		}
		lwdaq_image_manipulate $image_name none -clear 1
		set result [lwdaq_image_characteristics $image_name]
	} error_result]} {
		set result "ERROR: $error_result"
	}
	return $result
}

#
# LWDAQ_daq_Camera captures an image from the LWDAQ electronics and places
# the image in the lwdaq image list. 
#
proc LWDAQ_daq_Camera {} {
	global LWDAQ_Info  LWDAQ_Driver
	upvar #0 LWDAQ_info_Camera info
	upvar #0 LWDAQ_config_Camera config

	# Determine the number of bytes in the image we will acquire.
	set image_size [expr $info(daq_image_width) * $info(daq_image_height)]

	# If we encounter any errors in the data acquisition process, we will
	# abort data acquisition, but we will not stop the operation of the 
	# data acquisition program. That's why we enclose the data acquisition
	# steps in a Tcl "catch" command.
	if {[catch {
		
		# Open a socket to the LWDAQ driver.
		set sock [LWDAQ_socket_open $config(daq_ip_addr)]
		LWDAQ_login $sock $info(daq_password)

		# Select the device and set the device type.
		LWDAQ_set_driver_mux $sock $config(daq_driver_socket) $config(daq_mux_socket)
		LWDAQ_set_device_type $sock $config(daq_device_type)
		LWDAQ_set_device_element $sock $config(daq_device_element)

		# The TC255 and TC237 sensors have frame stores. We transfer the
		# image into the frame store and read it out from there. This invites
		# blurring of the image as it is read out, if the read out is not
		# fast enough. Some devices support "fast move" and "anti-blooming".
		# The code here implements these features if directed to do so by the
		# fast_move and anti_blooming parameters. By default, these are set 
		# to 1 for the camera instrument. But note that the fast move will
		# corrupt an image taken with a device that does not support the
		# fast move.
		if {($config(daq_device_type) == $LWDAQ_Driver(TC255_device)) \
			|| ($config(daq_device_type) == $LWDAQ_Driver(TC237_device))} {
			# The way we clear the image area depends upon whether
			# or not we're using fast-move.
			if {$info(daq_fast_move)} {
				# Configure the target to toggle IAG, SAG, and SRG when the driver
				# toggles the transmit logic level.
				LWDAQ_transmit_command_hex $sock 008D
				# Execute a fast_toggle_job that will toggle the transmit logic
				# level many times more than necessary to clear charge out of
				# the image area. In this code, we switch the logic level 
				# roughly 5000 times, and each logic level persists for half
				# a microsecond. The entire clear operation takes only 2.5 ms.
				LWDAQ_set_repeat_counter $sock [expr 20 * $info(daq_image_height)]
				LWDAQ_set_delay_seconds $sock 0.0000005
				LWDAQ_execute_job $sock $LWDAQ_Driver(fast_toggle_job) 
			} {
				# Execute a couple of image-move jobs to clear the image
				# area. The clear operation takes 8 ms.
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			}
	
			# Return the device to is exposure state.
			LWDAQ_wake $sock
			
			# Expose the CCD for specified time.
			LWDAQ_set_delay_seconds $sock $config(daq_exposure_seconds)
			if {$info(daq_anti_blooming)} {
				# We implement anti-blooming with the toggle job.
				LWDAQ_execute_job $sock $LWDAQ_Driver(toggle_job)
			} {
				# Without anti-blooming, we just wait.
				LWDAQ_execute_job $sock $LWDAQ_Driver(delay_job)
			}
			
			# Transfer the image out of the image are and into the
			# storage area.
			if {$info(daq_fast_move)} {
				# We implement fast-move in the same way we implemented
				# the image clear with fast-move, but this time we toggle
				# the IAG, SAG, and SRG lines only as many times as we need
				# get the image into the storage area. The process takes
				# 250 us.
				LWDAQ_transmit_command_hex $sock 008D 
				LWDAQ_set_repeat_counter $sock [expr 2 * $info(daq_image_height)]
				LWDAQ_set_delay_seconds $sock 0.0000005
				LWDAQ_execute_job $sock $LWDAQ_Driver(fast_toggle_job) 
				LWDAQ_transmit_command_hex $sock 0080
			} {
				# Without fast-move, we proceed more slowly. The image transfer
				# takes 2 ms.
				LWDAQ_execute_job $sock $LWDAQ_Driver(alt_move_job)
			}
			
			# Leave the delay timer set to zero.
			LWDAQ_set_delay_seconds $sock 0.0
		} 
		
		# The data device is digital, and already has an image ready for us
		# to transfer, so we do nothing except wake it up.
		if {($config(daq_device_type) == $LWDAQ_Driver(data_device))} {
			LWDAQ_wake $sock
		}
		
		# The KAF0400 image sensor has no frame store and no readout pixels.
		# We move the charge down one row at a time into the output register.
		if {($config(daq_device_type) == $LWDAQ_Driver(KAF0400_device))} {
			# Execute multiple move jobs to clear the image area.
			for {set i 1} {$i < 10} {incr i} {
				LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
			}
			
			# Return the device to is exposure state.
			LWDAQ_wake $sock
			
			# Expose the CCD for specified time.
			LWDAQ_delay_seconds $sock $config(daq_exposure_seconds)
		}
		
		# The ICX424 image sensor has a separate array of readout pixels on the 
		# dark side of the chip, and a substrate clock with which we can clear
		# all charge out of the image pixels.
		if {($config(daq_device_type) == $LWDAQ_Driver(ICX424_device)) \
			|| ($config(daq_device_type) == $LWDAQ_Driver(ICX424Q_device))} {
			# Clear the vertical transfer columns with a move job.
			LWDAQ_execute_job $sock $LWDAQ_Driver(move_job)
	
			# Clear the image area with a substrate pulse. We set
			# V2 and V3 hi and V1 lo to keep charge constrained in the
			# vertical transfer columns.
			LWDAQ_transmit_command_hex $sock 0098
			LWDAQ_transmit_command_hex $sock 00B8
			LWDAQ_transmit_command_hex $sock 0098
	
			# Expose image area.
			LWDAQ_delay_seconds $sock $config(daq_exposure_seconds)
	
			# Transfer the image out of the image area and into the
			# transfer columns by applying read pulse to V2 and V3.
			# We keep V1 lo to maintain pixel charge separation in 
			# the vertical transfer columns.
			LWDAQ_transmit_command_hex $sock 0099
			LWDAQ_transmit_command_hex $sock 0098
	
			# Drive V2 hi, V1 and V3 lo so as to collect all pixel
			# charges under the V2 clock.
			LWDAQ_transmit_command_hex $sock 0088
		}
		
		# Transfer the image to driver memory with the read job.
		LWDAQ_set_data_addr $sock 0
		LWDAQ_execute_job $sock $LWDAQ_Driver(read_job)
		
		# Send the device to sleep, read the image out of the
		# driver, and close the socket.
		LWDAQ_sleep $sock
		set image_contents [LWDAQ_ram_read $sock 0 $image_size]
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
		-name "$info(name)\_$info(counter)" ]
		
	return $config(memory_name) 
} 

#
# LWDAQ_set_image_sensor takes a LWDAQ device type name and an 
# instrument name as parameters. It sets up the named instrument
# to use the named device type for image capture. The routin sets 
# the image height and width, the device type number, and the 
# analysis boundaries. Some instruments have the daq device type 
# in the config array, and other in the info array, so this
# routine handles both contingencies.
#
proc LWDAQ_set_image_sensor {{name "TC255"} {instrument "Camera"}} {
	global LWDAQ_Driver
	upvar #0 LWDAQ_config_$instrument config
	upvar #0 LWDAQ_info_$instrument info

	# Check that we support the sensor.
	if {[lsearch $LWDAQ_Driver(image_sensors) $name] < 0} {
		error "sensor \"$name\" unsupported"	
	}
	
	# Set the device type.
	if {[info exists config(daq_device_type)]} {
		set config(daq_device_type) $LWDAQ_Driver($name\_device)
	} {
		set info(daq_device_type) $LWDAQ_Driver($name\_device)
	}
	
	# Extract the image characteristics and device type.
	scan $LWDAQ_Driver($name\_details) %u%u%u%u%u%u%f h w l t r b p

	set info(daq_image_height) $h
	set info(daq_image_width) $w
	set info(daq_image_left) $l
	set info(daq_image_top) $t
	set info(daq_image_right) $r
	set info(daq_image_bottom) $b
	if {[lsearch [array names info] analysis_pixel_size_um]} {
		set info(analysis_pixel_size_um) $p
	}
}

#
# LWDAQ_controls_Camera creates buttons that configure the Camera 
# for various image sensors.
#
proc LWDAQ_controls_Camera {} {
	upvar #0 LWDAQ_config_Camera config
	upvar #0 LWDAQ_info_Camera info
	global LWDAQ_Driver

	set w $info(window)
	if {![winfo exists $w]} {return 0}

	set f $w.setbuttons
	frame $f
	pack $f -side top -fill x
	
	foreach a $LWDAQ_Driver(image_sensors) {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_set_image_sensor $a Camera"
		pack $f.$b -side left -expand yes
	}
}
