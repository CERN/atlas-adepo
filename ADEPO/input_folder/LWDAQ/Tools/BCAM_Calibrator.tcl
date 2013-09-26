# BCAM Calibrator, a Standard and Polite LWDAQ Tool
# Copyright (C) 2004-2012 Kevan Hashemi
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
# Version 16: Added support for JK plates. Changed many of the names of info
# elements.
#
# Version 17: Added support for TC237 image sensor.
#
# Version 18: Corrected some bugs that arose from modifications of Version 17.
#
# Version 19: Add support for the H-BCAM.
#
# Version 20: Correct bug in HBCAM source calibration, no such image error.

proc BCAM_Calibrator_init {} {
	upvar #0 BCAM_Calibrator_info info
	upvar #0 BCAM_Calibrator_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "BCAM_Calibrator" "20"
	if {[winfo exists $info(window)]} {return 0}

	set config(daq_timeout_ms) 5000
	set config(apparatus_file) "apparatus_database.txt"
	set config(calibration_file) [clock format [clock seconds] -format BCAM_calib_%d_%b_%y.txt]
	set config(daq_ip_addr) 129.64.37.87
	set config(bcam_driver_socket) 7
	set config(apparatus_driver_socket) 4
	set config(daq_near_flash_seconds) 0.000005
	set config(daq_far_flash_seconds) 0.000020
	set config(daq_viewer_flash_seconds) 0.000000
	set config(daq_adjust_flash) 1
	set config(daq_subtract_background) 0
	set config(analysis_threshold) "10 #"
	set config(verbose_calculation) 1
	set config(ambient_exposure_seconds) 0.1
	set config(auto_store) 0
	set config(calculation_status) "NONE"
	set config(jk_plate_device_type) 2
	set config(sources_device_type) 2
	set config(fibers_device_type) 1
	set config(source_block_device_type) 2
	
	set info(camera_sources) "4 3 2 1"
	set info(camera_front_element) "2"
	set info(camera_rear_element) "1"
	set info(sources_front_elements) "3 4"
	set info(sources_rear_elements) "1 2"
	set info(state_history) [list]
	set info(calibration_type) none
	set info(apparatus_version) none
	set info(device_id) none
	set info(operator_name) none
	set info(retain_calibration_type) 1
	set info(retain_apparatus_version) 1
	set info(retain_device_id) 1
	set info(retain_operator_name) 1
	foreach range {near far} {
		foreach orientation {0 90 180 270} {
			set info(camera_$range\_$orientation\_valid) 0
		}
	}
	foreach orientation {0 90 180 270} {
		set info(sources_$orientation\_valid) 0
	}
	set info(stored) 0
	set info(apparatus_database) ""
	set info(device_calibration) ""
	
	set info(calibration_class) "camera"
	set info(calibration_end) "front"
	set info(calibration_color) "black"
	set info(calibration_ccd_rotation) "0"
	set info(calibration_ccd_type) "TC255"
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	set info(control) "Idle"
	set info(state) "Start"
	set info(display_image) "bcam_calibrator_image"
	
	return 1	
}

proc BCAM_Calibrator_configure {} {
	upvar #0 BCAM_Calibrator_info info
	upvar #0 BCAM_Calibrator_config config
	set f [LWDAQ_tool_configure $info(name)]
	button $f.app_file_get -text "Choose Apparatus Database" -command {
		set fn [LWDAQ_get_file_name]
		if {$fn != ""} {set BCAM_Calibrator_config(apparatus_file) $fn}
	}
	pack $f.app_file_get -side top -expand 1
	button $f.calib_file_put -text "Specify New Calibration Database" -command {
		set fn [LWDAQ_put_file_name $BCAM_Calibrator_config(calibration_file)]
		if {$fn != ""} {set BCAM_Calibrator_config(calibration_file) $fn}
	}
	pack $f.calib_file_put -side top -expand 1
	button $f.calib_file_get -text "Choose Existing Calibration Database" -command {
		set fn [LWDAQ_get_file_name]
		if {$fn != ""} {set BCAM_Calibrator_config(calibration_file) $fn}
	}
	pack $f.calib_file_get -side top -expand 1
	return 1
}

proc BCAM_Calibrator_store {} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info
	if {$info(state) != "Finish"} {
		LWDAQ_print $info(text) \
			"ERROR: You are not at the end-point of a calibration."
		return
	}
	if {$info(stored)} {
		LWDAQ_print $info(text) \
			"ERROR: You already stored that calibration."
		LWDAQ_print $info(text) \
			"SUGGESTION: If you want to save it again, uncheck the stored box."
		return
	}
	set f [open $config(calibration_file) a]
	puts $f $info(device_calibration)
	close $f
	set info(stored) 1
	return 1
}

proc BCAM_Calibrator_stop {} {
	upvar #0 BCAM_Calibrator_info info
	upvar #0 LWDAQ_info_BCAM iinfo
	if {$info(control) != "Idle"} {
		set info(control) "Stop"
		set iinfo(control) "Stop"
	}
}

proc BCAM_Calibrator_timeout {} {
	BCAM_Calibrator_stop
	LWDAQ_print $info(text) "ERROR: Timeout waiting for BCAM measurement."
}

proc BCAM_Calibrator_get_param {entry name} {
	set index [expr [lsearch $entry "$name\:"] + 1]
	if {$index == 0} {return ""}
	return [lindex $entry $index]
}

proc BCAM_Calibrator_check {} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info
	upvar #0 LWDAQ_config_BCAM iconfig
	upvar #0 LWDAQ_info_BCAM iinfo

	if {![winfo exists $info(window)]} {return}

	LWDAQ_set_image_sensor $info(calibration_ccd_type) BCAM	
	set iconfig(daq_ip_addr) $config(daq_ip_addr)
	if {$info(calibration_class) == "camera"} {
		set iconfig(daq_driver_socket) $config(bcam_driver_socket)
		set iconfig(daq_source_driver_socket) $config(apparatus_driver_socket)
		set iinfo(daq_source_device_type) $config(source_block_device_type)
		set iconfig(daq_flash_seconds) $config(daq_near_flash_seconds)
		set iconfig(daq_source_device_element) $info(camera_sources)
		if {$info(calibration_end) == "front"} {
			set iconfig(daq_device_element) $info(camera_front_element)
		} {
			set iconfig(daq_device_element) $info(camera_rear_element)
		}
	} 
	if {$info(calibration_class) == "sources"} {
		set iconfig(daq_driver_socket) $config(apparatus_driver_socket)
		set iconfig(daq_source_driver_socket) $config(bcam_driver_socket)
		set iinfo(daq_source_device_type) $config(sources_device_type)
		set iconfig(daq_flash_seconds) $config(daq_viewer_flash_seconds)
		if {$info(calibration_end) == "front"} {
			set iconfig(daq_source_device_element) $info(sources_front_elements)
		} {
			set iconfig(daq_source_device_element) $info(sources_rear_elements)
		}
		set iconfig(daq_device_element) $info(camera_front_element)
	}
	if {$info(calibration_class) == "jk_plate"} {
		set iconfig(daq_driver_socket) $config(bcam_driver_socket)
		set iconfig(daq_source_driver_socket) $config(apparatus_driver_socket)
		set iinfo(daq_source_device_type) $config(jk_plate_device_type)
		set iconfig(daq_flash_seconds) $config(daq_near_flash_seconds)
		set iconfig(daq_source_device_element) $info(sources_front_elements)
		set iconfig(daq_device_element) $info(camera_front_element)
	}
	if {$info(calibration_class) == "fibers"} {
		set iconfig(daq_driver_socket) $config(apparatus_driver_socket)
		set iconfig(daq_source_driver_socket) $config(bcam_driver_socket)
		set iinfo(daq_source_device_type) $config(fibers_device_type)
		set iconfig(daq_flash_seconds) $config(daq_viewer_flash_seconds)
		if {$info(calibration_end) == "front"} {
			set iconfig(daq_source_device_element) $info(sources_front_elements)
		} {
			set iconfig(daq_source_device_element) $info(sources_rear_elements)
		}
		set iconfig(daq_device_element) $info(camera_front_element)
	}

	set iconfig(daq_adjust_flash) 0
	set icongif(daq_subtract_background) 0
	set iconfig(analysis_enable) 0
	set iinfo(ambient_exposure_seconds) $config(ambient_exposure_seconds)

	set result [LWDAQ_acquire BCAM]	
	if {[LWDAQ_is_error_result $result]} {
		LWDAQ_print $info(text) $result
		return 0
	}

	lwdaq_image_manipulate $iconfig(memory_name) copy -name $info(display_image)
	if {$info(calibration_ccd_type) == "ICX424"} {
		lwdaq_image_manipulate $info(display_image) shrink_2 -replace 1
	}
	lwdaq_draw $info(display_image) $info(photo) -intensify strong
	
	return $result
}

proc BCAM_Calibrator_camera_acquire {range orientation} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info
	upvar #0 LWDAQ_config_BCAM iconfig
	upvar #0 LWDAQ_info_BCAM iinfo
	
	if {![winfo exists $info(window)]} {return}
	
	LWDAQ_set_image_sensor $info(calibration_ccd_type) BCAM	
	set iconfig(daq_ip_addr) $config(daq_ip_addr)
	set iconfig(daq_driver_socket) $config(bcam_driver_socket)
	set iconfig(daq_source_driver_socket) $config(apparatus_driver_socket)
	if {$range == "near"} {
		set iconfig(daq_flash_seconds) $config(daq_near_flash_seconds)
	} {
		set iconfig(daq_flash_seconds) $config(daq_far_flash_seconds)
	}
	if {$info(calibration_end) == "front"} {
		set iconfig(daq_device_element) $info(camera_front_element)
	} {
		set iconfig(daq_device_element) $info(camera_rear_element)
	}		
	set iconfig(daq_adjust_flash) $config(daq_adjust_flash)
	set icongif(daq_subtract_background) $config(daq_subtract_background)
	set iconfig(daq_source_device_element) $info(camera_sources)
	set iinfo(daq_source_device_type) $config(source_block_device_type)
	set iconfig(analysis_enable) 1
	set iconfig(analysis_num_spots) 4
	set iconfig(analysis_threshold) $config(analysis_threshold)
	set iinfo(ambient_exposure_seconds) 0	
	
	set result [LWDAQ_acquire BCAM]
	if {[LWDAQ_is_error_result $result]} {
		LWDAQ_print $info(text) $result
		return 0
	}
	
	lwdaq_image_manipulate $iconfig(memory_name) copy -name $info(display_image)
	if {$info(calibration_ccd_type) == "ICX424"} {
		lwdaq_image_manipulate $info(display_image) shrink_2 -replace 1
	}
	LWDAQ_analysis_BCAM $info(display_image)
	lwdaq_draw $info(display_image) $info(photo) -intensify exact
	
	if {$info(control) == "Stop"} {
		set result "ERROR: Acquisition aborted"
	}
	
	if {![LWDAQ_is_error_result $result]} {
		if {$config(daq_adjust_flash)} {
			if {$range == "near"} \
				{set config(daq_near_flash_seconds) $iconfig(daq_flash_seconds)} \
				{set config(daq_far_flash_seconds) $iconfig(daq_flash_seconds)}
		}

		if {[llength $result] < 8} {
			set result "-1 -1 -1 -1 -1 -1 -1 -1"
		} {
			set s [list]
			foreach i {1 7 13 19} {
				lappend s [list [lindex $result $i] [lindex $result [expr $i + 1]]]
			}
			set s [lsort -real -index 1 -increasing $s]
			set st [list [lindex $s 0] [lindex $s 1]]
			set sb [list [lindex $s 2] [lindex $s 3]]
			set st [lsort -real -index 0 -increasing $st]
			set sb [lsort -real -index 0 -decreasing $sb]
			set s [concat $st $sb]
			for {set r 0} \
				{$r < [expr $orientation + $info(calibration_ccd_rotation)]} \
				{set r [expr $r + 90]} {
				set s [concat [lrange $s 3 3] [lrange $s 0 2]]
			}
			set result [join $s]
		}

		set info(camera_$range\_$orientation) $result
		set info(camera_$range\_$orientation\_valid) 1
	}
	LWDAQ_print $info(text) $result
	return $result
}

proc BCAM_Calibrator_sources_acquire {orientation} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info
	upvar #0 LWDAQ_config_BCAM iconfig
	upvar #0 LWDAQ_info_BCAM iinfo
	
	if {![winfo exists $info(window)]} {return}
	
	LWDAQ_set_image_sensor $info(calibration_ccd_type) BCAM	
	set iconfig(daq_ip_addr) $config(daq_ip_addr)
	set iconfig(daq_flash_seconds) $config(daq_viewer_flash_seconds)
	if {$info(calibration_class) == "sources"} {
		set iconfig(daq_source_driver_socket) $config(bcam_driver_socket)
		set iconfig(daq_driver_socket) $config(apparatus_driver_socket)
		set iinfo(daq_source_device_type) $config(sources_device_type)
	} 
	if {$info(calibration_class) == "fibers"} {
		set iconfig(daq_source_driver_socket) $config(bcam_driver_socket)
		set iconfig(daq_driver_socket) $config(apparatus_driver_socket)
		set iinfo(daq_source_device_type) $config(fibers_device_type)
	} 
	if {$info(calibration_class) == "jk_plate"} {
		set iconfig(daq_driver_socket) $config(bcam_driver_socket)
		set iconfig(daq_source_driver_socket) $config(apparatus_driver_socket)
		set iinfo(daq_source_device_type) $config(jk_plate_device_type)
	}
	if {$info(calibration_end) == "front"} {
		set iconfig(daq_source_device_element) $info(sources_front_elements)
	} {
		set iconfig(daq_source_device_element) $info(sources_rear_elements)
	}
	set iconfig(daq_device_element) $info(camera_front_element)	
	set iconfig(daq_adjust_flash) $config(daq_adjust_flash)
	set icongif(daq_subtract_background) $config(daq_subtract_background)
	set iconfig(analysis_enable) 1
	set iconfig(analysis_num_spots) 2
	set iconfig(analysis_threshold) $config(analysis_threshold)
	set iinfo(ambient_exposure_seconds) 0	
	
	set result [LWDAQ_acquire BCAM]
	if {[LWDAQ_is_error_result $result]} {
		LWDAQ_print $info(text) $result
		return 0
	}
	
	lwdaq_image_manipulate $iconfig(memory_name) copy -name $info(display_image)
	if {$info(calibration_ccd_type) == "ICX424"} {
		lwdaq_image_manipulate $info(display_image) shrink_2 -replace 1
	}
	LWDAQ_analysis_BCAM $info(display_image)
	lwdaq_draw $info(display_image) $info(photo) -intensify exact
	
	if {![LWDAQ_is_error_result $result]} {
		if {$config(daq_adjust_flash)} {
			set config(daq_viewer_flash_seconds) $iconfig(daq_flash_seconds)
		}

		if {[llength $result] < 4} {
			set result "-1 -1 -1 -1"
		} {
			set s [list]
			foreach i {1 7} {
				lappend s [list [lindex $result $i] [lindex $result [expr $i + 1]]]
			}
			if {$orientation == 0} {set s [lsort -real -index 0 -increasing $s]}
			if {$orientation == 90} {set s [lsort -real -index 1 -decreasing $s]}
			if {$orientation == 180} {set s [lsort -real -index 0 -decreasing $s]}
			if {$orientation == 270} {set s [lsort -real -index 1 -increasing $s]}
			if {$info(calibration_color) == "blue"} {
				lappend s [lindex $s 0]
				set s [lreplace $s 0 0]
			} 
			set result [join $s]
		}
	
		set info(sources_$orientation) $result
		set info(sources_$orientation\_valid) 1
	}
	LWDAQ_print $info(text) $result
	return $result
}

proc BCAM_Calibrator_ct_change {ct} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info

	set info(calibration_type) $ct

	switch $ct {
		"black_h_fc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "ICX424"
		}
		"black_h_rc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "rear"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "ICX424"
		}
		"black_h_fs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_h_rs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "rear"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_h_fc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "front"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "ICX424"
		}
		"blue_h_rc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "rear"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "ICX424"
		}
		"blue_h_fs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "front"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_h_rs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "rear"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_polar_fc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_polar_rc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "rear"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_polar_fs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_polar_rs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "rear"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_polar_fc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "front"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_polar_rc" {
			set info(calibration_class) "camera"
			set info(calibration_end) "rear"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_polar_fs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "front"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_polar_rs" {
			set info(calibration_class) "sources"
			set info(calibration_end) "rear"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_azimuthal_c" {
			set info(calibration_class) "camera"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "180"
			set info(calibration_ccd_type) "TC255"
		}
		"black_azimuthal_s" {
			set info(calibration_class) "sources"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "180"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_azimuthal_c" {
			set info(calibration_class) "camera"
			set info(calibration_end) "front"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "180"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_azimuthal_s" {
			set info(calibration_class) "sources"
			set info(calibration_end) "front"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "180"
			set info(calibration_ccd_type) "TC255"
		}
		"j_plate" {
			set info(calibration_class) "jk_plate"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"k_plate" {
			set info(calibration_class) "jk_plate"
			set info(calibration_end) "front"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"black_fiber_rs" {
			set info(calibration_class) "fibers"
			set info(calibration_end) "rear"
			set info(calibration_color) "black"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
		"blue_fiber_rs" {
			set info(calibration_class) "fibers"
			set info(calibration_end) "rear"
			set info(calibration_color) "blue"
			set info(calibration_ccd_rotation) "0"
			set info(calibration_ccd_type) "TC255"
		}
	}

	if {$info(calibration_class) == "camera"} {
		$info(cc_label) configure -bg $info(calibration_color) -fg white
		$info(sc_label) configure -bg white -fg black
	} {
		$info(cc_label) configure -bg white -fg black
		$info(sc_label) configure -bg $info(calibration_color) -fg white
	} 
	
	if {$info(calibration_class) == "jk_plate"} {
		$info(sc_label) configure -text "JK Plate Calibration"
	}

	if {$info(apparatus_database) == ""} {return}
	
	set available [list]
	foreach b $info(apparatus_database) {
		if {[BCAM_Calibrator_get_param $b calibration_type] == $ct} {
			lappend available [BCAM_Calibrator_get_param $b apparatus_version]
		}
	}	
	$info(apparatus_version_menu) delete 0 end
	foreach b $available {
		$info(apparatus_version_menu) add command \
			-label $b \
			-command [list set BCAM_Calibrator_info(apparatus_version) $b]
	}	
	set info(apparatus_version) $b
}

proc BCAM_Calibrator_do {step} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info
	upvar #0 LWDAQ_config_BCAM iconfig
	global LWDAQ_Driver LWDAQ_Info
	
	if {$step == "Execute"} {
		if {$info(control) != "Idle"} {
			LWDAQ_print $info(text) "ERROR: Cannot execute until \"Idle\"."
			LWDAQ_print $info(text) "SUGGESTION: Wait a second, or try \"Stop\""
			return 1
		}
		focus $info(execute_button)
	}
	
	if {$step == "Backward"} {
		if {$info(control) != "Idle"} {
			LWDAQ_print $info(text) "ERROR: Cannot go backwards until \"Idle\"."
			LWDAQ_print $info(text) "SUGGESTION: Wait a second, or try \"Stop\"."
			return 1
		}
		set info(state) [lindex $info(state_history) end]
		set info(state_history) [lreplace $info(state_history) end end]
		BCAM_Calibrator_do Establish
		return 1
	}
	
	if {$step == "Forward"} {
		if {$info(control) != "Idle"} {
			LWDAQ_print $info(text) "ERROR: Cannot go forwards until \"Idle\"."
			LWDAQ_print $info(text) "SUGGESTION: Wait a second, or try \"Stop\"."
			return 1
		}
		lappend info(state_history) $info(state)
		if {[llength $info(state_history)] > 30} {
			set info(state_history) [lreplace $info(state_history) 0 0]
		}
	}

	if {$info(state) == "Start"} {
		if {$step == "Establish"} {
			set info(state_history) [list "Start"]
			set info(title)	"Press Execute to load apparatus file and create calibration file."
			LWDAQ_print $info(text) \
				"Press \"Configure\" and \"Choose Apparatus File\" to select an apparatus file."
			LWDAQ_print $info(text) \
				"Press \"Configure\" and \"Choose Calibration File\" to specify a calibration file."
			LWDAQ_print $info(text) \
				"NOTE: Your new measurements will be appended to the calibration file."
			return 1
		}
		if {$step == "Execute"} {
			foreach a {calibration_type apparatus_version operator_name device_id} {
				set info($a) none
			}
			set info(control) "Reading"
			$info(ct_menu) delete 0 end
			$info(apparatus_version_menu) delete 0 end
			if {![file exists $config(apparatus_file)]} {
				LWDAQ_print $info(text) \
					"ERROR: Cannot find apparatus file \"$config(apparatus_file)\"."
				set info(control) "Idle"
				return 1
			}
			set f [open $config(apparatus_file) r]
			set am [read $f]
			close $f
			while {1} {
				set i_start [string first "\{" $am]
				set i_end [string first "\}" $am]
				if {$i_start <	0} {break}
				if {$i_end < 0} {set i_end end}
				set am [string replace $am $i_start $i_end ""]
			}
			set index 0
			set info(apparatus_database) ""
			while {1} {
				set i_start [string first "\nend.\n" $am $index]
				if {$i_start <	0} {break}
				lappend info(apparatus_database) \
					[string range $am $index [expr $i_start + [string length "\nend.\n"] - 1]]
				set index [expr $i_start + [string length "\nend.\n"]]
				if {$i_start <= 0} {break}
			}
			set available ""
			foreach b $info(apparatus_database) {
				set ct [BCAM_Calibrator_get_param $b calibration_type]
				if {($ct != "") && ([lsearch $available $ct] < 0)} {
					lappend available $ct
				}
			}
			if {[llength $available] == 0} {
				LWDAQ_print $info(text) \
					"ERROR: No valid entries in apparatus database."
				LWDAQ_print $info(text) \
					"SUGGESTION: Check apparatus database file with a text editor."
				set info(control) "Idle"
				return 1
			}
			$info(ct_menu) delete 0 end
			foreach b $available {
				$info(ct_menu) add command -label $b -command "BCAM_Calibrator_ct_change $b" 
			}
			set info(control) "Idle"
			BCAM_Calibrator_do Forward
			return 1
		}
		if {$step == "Forward"} {
			set info(state) "Define_Calibration"
			BCAM_Calibrator_do Establish
			return 1
		}
	}
	
	if {$info(state) == "Define_Calibration"} {
		if {$step == "Establish"} {
			set info(title)	"Select calibration, apparatus, operator, and id."
			return 1
		}
		if {$step == "Execute"} {
			if {$info(calibration_type) == "none"} {
				LWDAQ_print $info(text) "ERROR: No calibration type selected."
				return 1
			}			
			if {$info(apparatus_version) == "none"} {
				LWDAQ_print $info(text) "ERROR: No apparatus version selected."
				return 1
			}			
			if {$info(operator_name) == "none"} {
				LWDAQ_print $info(text) "WARNING: No operator name entered."
			}			
			if {$info(device_id) == "none"} {
				LWDAQ_print $info(text) "WARNING: No device id entered."
			}	
			if {[file exists $config(calibration_file)]} {
				set f [open $config(calibration_file) r]
				set calibrations [read $f]
				close $f
				set index 0
				set pre_existing [list]
				set pattern "device_id:\[ \]+$info(device_id)\[ \n\]+"
				append pattern "calibration_type:\[ \]+$info(calibration_type)"
				while {[regexp -indices -start $index $pattern $calibrations match]} {
					set index [expr [lindex $match 1] + 1]
					regexp -start $index {calibration_time:[ ]+([^\n]*)} $calibrations match timestamp
					regexp -start $index {operator_name:[ ]+([^\n]*)} $calibrations match operator
					lappend pre_existing "$info(device_id) $info(calibration_type)\
						$timestamp $operator"
				}
				if {[llength $pre_existing] > 0} {
					LWDAQ_print $info(text) "WARNING: The following matching measurements\
						exists in your mesurement file:"
					foreach c $pre_existing {
						LWDAQ_print $info(text) $c blue
					}
				}
			}
						
			BCAM_Calibrator_do Forward
			return 1
		}
		if {$step == "Forward"} {
			set info(state) "Test"
			BCAM_Calibrator_do Establish
			return 1
		}
	}

	if {$info(state) == "Test"} {
		if {$step == "Establish"} {
			set info(title)	"Press Execute for Test Image, Forward When Satisfied."
			return 1
		}
		if {$step == "Execute"} {
			set info(control) "Acquire"
			BCAM_Calibrator_check
			set info(control) "Idle"
			return 1
		}
		if {$step == "Forward"} {
			if {$info(calibration_class) == "camera"} {
				set info(state) "Camera_Calib_N_0"
			} {
				set info(state) "Source_Calib_0"
			}
			BCAM_Calibrator_do Establish
			focus $info(execute_button)
			return 1
		}
	}
	
	if {[string match "Camera_Calib_?_*" $info(state)]} {
		if {[string index $info(state) 13] == "N"} {set range "near"} {set range "far"}
		set orientation [string replace $info(state) 0 14]
		
		if {$step == "Establish"} {
			set info(title) "Capture Image, \
				Source Block [string toupper $range] Range,\
				Roll Cage $orientation\-DEGREE Orientation."
			return 1
		}
		if {$step == "Execute"} {
			set info(control) "Acquire"
			set result [BCAM_Calibrator_camera_acquire $range $orientation]
			set info(control) "Idle"
			if {![LWDAQ_is_error_result $result]} {BCAM_Calibrator_do Forward}
			return 1
		}
		if {$step == "Forward"} {
			set orientation [expr $orientation + 90]
			if {($orientation == 360) && ($range == "far")} {
				set info(state) "Calculate"
			} {
				if {$orientation == 360} {
					set orientation 0
					set range "far"
				}
				if {$range == "near"} {
					set info(state) "Camera_Calib_N_$orientation"
				} {
					set info(state) "Camera_Calib_F_$orientation"
				}
			}
			BCAM_Calibrator_do Establish
			return 1
		}
	}
	
	if {[string match "Source_Calib_*" $info(state)]} {
		set orientation [string replace $info(state) 0 12]
		
		if {$step == "Establish"} {
			set info(title) "Capture Image With\
				Roll Cage in $orientation\-DEGREE Orientation."
			return 1
		}
		if {$step == "Execute"} {
			set info(control) "Acquire"
			set result [BCAM_Calibrator_sources_acquire $orientation]
			set info(control) "Idle"
			if {![LWDAQ_is_error_result $result]} {BCAM_Calibrator_do Forward}
			return 1
		}
		if {$step == "Forward"} {
			set orientation [expr $orientation + 90]
			if {$orientation == 360} {
				set info(state) "Calculate"
			} {
				set info(state) "Source_Calib_$orientation"
			}
			BCAM_Calibrator_do Establish
			return 1
		}
	}
	
	if {$info(state) == "Calculate"} {
		if {$step == "Establish"} {
			set info(title) "Calculate Calibration Constants."
			return 1
		}
		if {$step == "Execute"} {
			set dc ""
			append dc "device_calibration:\n"
			append dc "device_id: $info(device_id)\n"
			append dc "calibration_type: $info(calibration_type)\n"
			append dc "apparatus_version: $info(apparatus_version)\n"
			append dc "calibration_time: [LWDAQ_time_stamp]\n"
			append dc "operator_name: $info(operator_name)\n"
			append dc "data:\n"		
			if {$info(calibration_class) == "camera"} {	
				foreach range {near far} {
					foreach orientation {0 90 180 270} {
						append dc "$info(camera_$range\_$orientation) \n"
					}
				}
			} {
				foreach orientation {0 90 180 270} {
					append dc "$info(sources_$orientation) \n"
				}
			}
			append dc "end.\n"
			set info(device_calibration) $dc
			
			set am ""
			foreach b $info(apparatus_database) {
				if {([BCAM_Calibrator_get_param $b calibration_type] \
							== $info(calibration_type)) \
					&& ([BCAM_Calibrator_get_param $b apparatus_version] \
							== $info(apparatus_version))} {
					set am $b
				}
			}	

			$info(calculation_status_label) configure -text "CALCULATE" -fg blue
			set result [lwdaq_calibration $dc $am \
				-verbose $config(verbose_calculation) \
				-check 1]
			if {[regexp "WARNING:" $result] || [regexp "NaN" $result]} {
				set config(calculation_status) "FAIL"
				$info(calculation_status_label) configure -fg red
				LWDAQ_print $info(text) $result blue	
			} {
				set config(calculation_status) "PASS"
				$info(calculation_status_label) configure -fg green
				LWDAQ_print $info(text) $result	black
			}
			set info(control) "Idle"
			BCAM_Calibrator_do Forward	
			return 1
		}
		if {$step == "Forward"} {
			set info(state) "Finish"
			BCAM_Calibrator_do Establish
			return 1
		}
	}
		
	if {$info(state) == "Finish"} {
		if {$step == "Establish"} {
			if {$config(auto_store) && ($config(calculation_status) == "PASS")} {
				BCAM_Calibrator_store
				set info(title) "Press Execute to move on."
			} {
				set info(title) "Press Store to save constants, Execute to move on."
			}
			return 1
		}
		if {$step == "Execute"} {
			if {!$info(stored)} {
				LWDAQ_print $info(text) "WARNING: You did not store your measurements."
			}
			set info(stored) 0
			foreach range {near far} {
				foreach orientation {0 90 180 270} {
					set info(camera_$range\_$orientation\_valid) 0
				}
			}
			foreach orientation {0 90 180 270} {
				set info(sources_$orientation\_valid) 0
			}
			$info(calculation_status_label) configure -text "NONE" -fg black
			foreach p {calibration_type apparatus_version operator_name device_id} {
				if {!$info(retain_$p)} {set info($p) "none"}
			}
			BCAM_Calibrator_do Forward
			return 1
		}	
		if {$step == "Forward"} {
			set info(state) "Define_Calibration"
			BCAM_Calibrator_do Establish
			return 1
		}
	}
}

proc BCAM_Calibrator_open {} {
	upvar #0 BCAM_Calibrator_config config
	upvar #0 BCAM_Calibrator_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
	
	set f $w.status
	frame $f
	pack $f -side top -fill x
	
	label $f.title \
		-textvariable BCAM_Calibrator_info(title) \
		-width 70
	pack $f.title -side left
	
	label $f.control -textvariable BCAM_Calibrator_info(control) \
		-width 10
	pack $f.control -side right
	
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	foreach a {Execute Backward Forward} {
		set b [string tolower $a]
		button $f.$b -text $a -command [list LWDAQ_post "BCAM_Calibrator_do $a" front]
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	focus $info(execute_button)
	foreach a {Stop Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command BCAM_Calibrator_$b
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	foreach a {Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b BCAM_Calibrator"
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	
	set f $w.type_ver_id
	frame $f 
	pack $f -side top -fill x
	
	label $f.ptitle -text "Parameter:" 	
	label $f.lct -text "calibration_type" 
	label $f.lav -text "apparatus_version" 
	label $f.lon -text "operator_name"
	label $f.ldi -text "device_id"

	label $f.stitle -text "Select:"
	set info(ct_menu) \
		[tk_optionMenu $f.sct BCAM_Calibrator_info(calibration_type) none]
	set info(apparatus_version_menu) \
		[tk_optionMenu $f.sav BCAM_Calibrator_info(apparatus_version) none]
	entry $f.son -textvariable BCAM_Calibrator_info(operator_name) -width 10
	entry $f.sdi -textvariable BCAM_Calibrator_info(device_id) -width 20
	
	label $f.rtitle -text "Retain:"
	checkbutton $f.rct -variable BCAM_Calibrator_info(retain_calibration_type) 
	checkbutton $f.rav -variable BCAM_Calibrator_info(retain_apparatus_version) 
	checkbutton $f.ron -variable BCAM_Calibrator_info(retain_operator_name) 
	checkbutton $f.rdi -variable BCAM_Calibrator_info(retain_device_id) 

	grid $f.ptitle $f.lct $f.lav $f.lon $f.ldi -padx 5 -sticky news
	grid $f.stitle $f.sct $f.sav $f.son $f.sdi -padx 5 -sticky news
	grid $f.rtitle $f.rct $f.rav $f.ron $f.rdi -padx 5 -sticky news

	set f $w.panel
	frame $f 
	pack $f -side top -fill x
	
	set f1 $f.image_frame
	frame $f1 -relief sunken -border 2
	pack $f1 -side left -fill y
	set info(photo) [image create photo]
	label $f1.image -image $info(photo) 
	pack $f1.image -side left

	set f2 $f.status_frame 
	frame $f2
	pack $f2 -side right -fill y
	
	set f $f2.c
	frame $f -relief flat -border 4
	pack $f -side top -fill x
	set info(cc_label) $f.description
	label $f.description -text "Camera Calibration:" -bg white
	pack $f.description -side top 
	foreach range {near far} {
		frame $f.$range
		pack $f.$range -side top -fill x
		label $f.$range.l -text $range -width 10
		pack $f.$range.l -side left -expand 1
		foreach orientation {0 90 180 270} {
			checkbutton $f.$range.$orientation \
				-variable BCAM_Calibrator_info(camera_$range\_$orientation\_valid) \
				-text $orientation
			pack $f.$range.$orientation -side left -expand 1
		}
	}	
	
	set f $f2.s
	frame $f -relief flat -border 4
	pack $f -side top -fill x
	set info(sc_label) $f.description
	label $f.description -text "Source Calibration:" -bg white
	pack $f.description -side top 
	foreach orientation {0 90 180 270} {
		checkbutton $f.$orientation \
			-variable BCAM_Calibrator_info(sources_$orientation\_valid) \
			-text $orientation
		pack $f.$orientation -side left -expand 1
	}


	set f $f2.store
	frame $f
	pack $f -side top -fill x
	label $f.description -text "Calibration Database:" 
	pack $f.description -side top
	frame $f.controls
	pack $f.controls -side top
	button $f.controls.sb -text "Store" -command "BCAM_Calibrator_store"
	pack $f.controls.sb -side left
	checkbutton $f.controls.as -variable BCAM_Calibrator_config(auto_store) \
		-text "Auto-Store" 
	pack $f.controls.as -side left
	checkbutton $f.controls.ss -variable BCAM_Calibrator_info(stored) \
		-text "Stored"
	pack $f.controls.ss -side left
	
	set f $f2.calc
	frame $f 
	pack $f -side top -fill x
	label $f.description -text "Calculation Status: " 
	pack $f.description -side top
	label $f.cs -textvariable BCAM_Calibrator_config(calculation_status) \
		-font {helvetica 40 bold}
	pack $f.cs -side top
	set info(calculation_status_label) $f.cs

	set info(text) [LWDAQ_text_widget $w 80 10]
	
	BCAM_Calibrator_do Establish
	
	return 1
}

BCAM_Calibrator_init
BCAM_Calibrator_open

return 1

----------Begin Help----------
The BCAM_Calibrator calibrates BCAM cameras and sources.

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
