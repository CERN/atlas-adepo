# PXC_Calibrator, a LWDAQ Tool
# Copyright 2004, Paul Keselman, Brandeis University
# Copyright 2009, Kevan Hashemi, Brandeis University
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
# The PXC Calibrator determines the optical properties of ATLAS Proximity 
# Cameras. This program was formerly known as the Camera Calibrator.
#
# Version 3: Kevan takes over management of the code. Move to LWDAQ 7.2, so 
# use new tool init routine.
#
# Version 4: Incorporate Camera Table into the data section of this script. The
# User selects a Camera Calibration directory, in which there should be a file
# called apparatus_database.txt, containing the CMM measurements of various masks
# and stands used to calibrate cameras. The PXC Calibrator will append its
# calibration constants and calibration parameters to two files called 
# calibration_database.txt and parameter_database.txt. We add a help section
# that attempts to explain how to use the program, how to provide its input files,
# and how to interpret its output files.
# 
# Version 5: Change name to PXC Calibrator. Add re-calculation button and remove
# the previous calibration look-up code. Correct use of lappend in the calculation
# routines. Add calculation of residual to axis fit and apply a limit to this
# residual above which the calibration fails. Add verbose button for long and short
# output.
#
# Version 6: Fix bug in auto-store where Tool would report an error.
#
# Version 7: Correct bug in calibration time, whereby time is set only when 
# tool opens. Temperature measurement now detects over-large standard
# deviation associated with non-thermometer device, and sets the measurement
# time to 17 ms per division to give a while number of 60-Hz cycles.
#
# Version 8: Abbreviate some names, so as to make sure that new default thermometer
# settings will apply. Removed all the read-only restrictions on menus.
#
# Version 9: Fix bug in temperature measurement and clear improve menu selects.
#
# Version 10: When we select calibration file, we can specify a new file or
# choose an existing file. Add Forward button.
#
# Version 11: Add device id and time stamp selector fields for the recalculate
# all function.
#
# Version 12: Use random boundary analysis for Rasnik images so that we can analyze
# out-of-focus images and obtain an error estimate. The calibrator will now attempt
# to calibrate any camera on any stage, but will issue a warning if the stage is 
# not perfect for the camera.
#
# Version 13: Add EES cameras. Correct error in extraction of camera type from 
# camera information data.
#
# Version 14: Add option to show residuals to find out why fits are failing with
# the show_residuals parameter.

proc PXC_Calibrator_init {} {
    upvar #0 PXC_Calibrator_info info
    upvar #0 PXC_Calibrator_config config
    global LWDAQ_Info LWDAQ_Driver
	
    LWDAQ_tool_init "PXC_Calibrator" "14"
    if {[winfo exists $info(window)]} {return 0}
    
    # Set file names and database directory.
    set config(apparatus_file) "apparatus_database.txt"
	set config(calibration_file) [clock format [clock seconds] -format PXC_calib_%d_%b_%y.txt]
      
    # Set config array variables
    set config(rasnik_analysis_reference_code) 2
    set config(rasnik_analysis_square_size_um) 340
    set config(Rasnik_ip_addr) 129.64.37.90
    set config(Rasnik_flash_seconds) 0.01
    set config(Rasnik_adjust_flash) 1
    set config(Rasnik_analysis_enable) 1
    set config(Rasnik_max_tries) 20
    set config(Rasnik_driver_socket) 6
    set config(Rasnik_mux_socket) 1
    set config(Rasnik_source_driver_socket) 7
    set config(Rasnik_source_mux_socket) 8
    set config(Thermometer_ip_addr) 129.64.37.87
    set config(Thermometer_driver_socket) 8
    set config(Thermometer_device_element) 1
    set config(Thermometer_mux_socket) 1
    set config(Thermometer_max_stdev) 1
	set config(Thermometer_timebase) 0.017
	set config(max_initial_mag_error) 0.02
    set config(max_pos_sigma) 1.0
    set config(max_mag_error) 0.002
    set config(max_remount_change_um) 3
    set config(max_resolution_um) 1.0
    set config(max_axis_resid_um) 5
    set config(min_stage_range) 2
    set config(show_residuals) 0
    set config(verbose) 1
    set config(auto_store) 0
    set config(device_id_select) "*"
    set config(calibration_time_select) "*"
    set config(calibration_time_last) 0
    set config(operator_select) "*"
    
    # Set info-array variables
    set info(calib_stage_id) none
    set info(master_mask_id) none
    set info(operator_name) none
    set info(device_id) none
    set info(short_device_id) ""
    set info(apparatus_database) ""
 	set info(title) "No State Established"
 	set info(control) "Null"

    # Set retain checkboxes for info-array variables
    set info(retain_calib_stage_id) 1
    set info(retain_master_mask_id) 1
    set info(retain_operator_name) 1
    set info(retain_device_id) 0

    # Set other info-array variables used in the script.
    set info(temperature) ""
    set info(state_history) [list]
    set info(stored) 0
    set info(calculation_status_label) ""
    set info(device_id_text_field) ""
    set info(device_calibration_data) ""
    set info(camera_parameters) ""

    set info(stage_z_coords) "100"
    set info(nom_mpin_dist) "100"
    set info(set_mpin_dist) "100"
    set info(meas_mag) "1"
    set info(center_stage_pos) "100"
    set info(min_stage_pos) "98"
    set info(max_stage_pos) "102"
    set info(data_$info(center_stage_pos)) [list]
    set info(positions) "98 99 100 101 102"

	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 
    set info(control) "Idle"
    set info(state) "Start"

    return ""
}

# Executed when the stop button is pressed.
proc PXC_Calibrator_stop {} {
    upvar #0 PXC_Calibrator_info info
    upvar #0 LWDAQ_info_Rasnik iinfo
    if {$info(control) != "Idle"} {
		set info(control) "Stop"
    }
    if {$iinfo(control) != "Idle"} {
		set iinfo(control) "Stop"
    }
}

# Generates a configuration window from entries in the config array when the 
# configure button is pressed.
proc PXC_Calibrator_configure {} {
    upvar #0 PXC_Calibrator_info info
    upvar #0 PXC_Calibrator_config config
	set w [LWDAQ_tool_configure $info(name)]
	button $w.app_file_get -text "Choose Apparatus Database" -command {
		set f [LWDAQ_get_file_name]
		if {$f != ""} {set PXC_Calibrator_config(apparatus_file) $f}
	}
	pack $w.app_file_get -side top -expand 1
	button $w.calib_file_put -text "Specify New Calibration Database" -command {
		set f [LWDAQ_put_file_name $PXC_Calibrator_config(calibration_file)]
		if {$f != ""} {set PXC_Calibrator_config(calibration_file) $f}
	}
	pack $w.calib_file_put -side top -expand 1
	button $w.calib_file_get -text "Choose Existing Calibration Database" -command {
		set f [LWDAQ_get_file_name]
		if {$f != ""} {set PXC_Calibrator_config(calibration_file) $f}
	}
	pack $w.calib_file_get -side top -expand 1
    return 1
}

# Puts calibration files into appropriate files when the store button is pressed.
proc PXC_Calibrator_store {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

    if {$info(state) != "Finish"} {
		LWDAQ_print $info(text) "ERROR: You are not at the end-point of a calibration."
		return
    }
    if {$info(stored)} {
		LWDAQ_print $info(text) "ERROR: You already stored that calibration."
		LWDAQ_print $info(text) "SUGGESTION: If you want to save it again, uncheck the stored box."
		return
    }

	set data ""
	foreach p $info(positions) {
		append data "$info(data_$p)\n"
	}
	append data "$info(temperature)\n"

    set entry_str ""
    append entry_str "device_calibration:\n"
    append entry_str "device_id: $info(device_id)\n"
    append entry_str "calibration_type: proximity_camera\n"
    append entry_str "apparatus_version: \"$info(calib_stage_id) $info(master_mask_id)\"\n"
    append entry_str "calibration_time: $info(calibration_time)\n"
    append entry_str "operator_name: $info(operator_name)\n"
    append entry_str "data:\n"
    append entry_str $data
    append entry_str "end.\n"

	# Check that the calibration file exists.
	if {![file exists [file dirname $config(calibration_file)]]} {
		LWDAQ_print $info(text) "ERROR: Can't find calibration database file."
		LWDAQ_print $info(text) "SUGGESTION: Press Configure and Choose Calibration Database."
		return 0
	}	
	
	set f [open $config(calibration_file) a]
	puts $f $entry_str
	close $f
    
    set info(stored) 1
    return $entry_str
}

proc PXC_Calibrator_acquire {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info
    upvar #0 LWDAQ_config_Rasnik iconfig
    upvar #0 LWDAQ_info_Rasnik iinfo
	
    if {![winfo exists $info(window)]} {return}
	
    # Set config array variables
    set iconfig(daq_ip_addr) $config(Rasnik_ip_addr)
    set iconfig(daq_driver_socket) $config(Rasnik_driver_socket)
    set iconfig(daq_mux_socket) $config(Rasnik_mux_socket)
    set iconfig(daq_source_driver_socket) $config(Rasnik_source_driver_socket)
    set iconfig(daq_source_mux_socket) $config(Rasnik_source_mux_socket)
    set iconfig(daq_flash_seconds) $config(Rasnik_flash_seconds)
    set iconfig(daq_adjust_flash) $config(Rasnik_adjust_flash)
    set iconfig(analysis_enable) $config(Rasnik_analysis_enable)
    set iinfo(analysis_max_tries) $config(Rasnik_max_tries)
    set iconfig(analysis_reference_code) $config(rasnik_analysis_reference_code)
    set iconfig(analysis_square_size_um) $config(rasnik_analysis_square_size_um)
    set iconfig(verbose_result) 0	
	
    set result [LWDAQ_acquire Rasnik]
    set config(Rasnik_flash_seconds) $iconfig(daq_flash_seconds)
	
	if {[LWDAQ_is_error_result $result]} {
		return $result
    }
	
   	lwdaq_draw $iconfig(memory_name) $info(photo) -intensify exact
	
    if {$info(control) == "Stop"} {
		set result "ERROR: Acquisition stopped."
    }

    return $result
}

# Reads the temperatures sensor.
proc PXC_Calibrator_temperature_acquire {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info
    upvar #0 LWDAQ_config_Thermometer iconfig
    upvar #0 LWDAQ_info_Thermometer iinfo

    # Set config array variables
    set iconfig(daq_ip_addr) $config(Thermometer_ip_addr)
    set iconfig(daq_driver_socket) $config(Thermometer_driver_socket)
    set iconfig(daq_device_element) $config(Thermometer_device_element)
    set iconfig(daq_mux_socket) $config(Thermometer_mux_socket)
    set iconfig(analysis_enable) 2
    set iconfig(verbose_result) 0
    set iinfo(display_s_per_div) $config(Thermometer_timebase) 

    set result [LWDAQ_acquire Thermometer]
	if {[LWDAQ_is_error_result $result]} {
		return $result
    }
    
    if {[lindex $result 2] > $config(Thermometer_max_stdev)} {
	    return "ERROR: Noisy temperature measurement."
	}
	
    return [format "%.1f" [lindex $result 1]]
}

# Check if the two succsesive data acquisitions from repositioning the instruments are 
# within specified constraints.
proc PXC_Calibrator_check_positioning {result1 result2} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

    set result $result2

    if {![string is double -strict $config(max_remount_change_um)]} {
		set result "ERROR: max_remount_change_um must be a number."
		LWDAQ_print $info(text) $result
		LWDAQ_print $info(text) "SUGGESTION: Correct max_remount_change_um in Configuration panel."
		return $result
    }

    set con $config(max_remount_change_um)

    # Get x and y addresses for each input
    set x1 [lindex [split $result1] 1]
    set y1 [lindex [split $result1] 2]
    set x2 [lindex [split $result2] 1]
    set y2 [lindex [split $result2] 2]

    if {[expr abs($x1 - $x2) > $con] || [expr abs ($y1 - $y2) > $con]} {
		set result "ERROR: Measurements not consistent, go back a step and start again."
    }
    return $result
}

# Check if the magnification returned by the RASNIK Analysis is within the set constraints.
proc PXC_Calibrator_check_magnification {p result} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

    if {![string is double -strict $config(max_mag_error)]} {
		set result "ERROR: max_mag_error must be floating point number."
		LWDAQ_print $info(text) $result
		LWDAQ_print $info(text) "SUGGESTION: Correct max_mag_error in Configuration panel."
		return $result
    }

    set err $config(max_mag_error)

    # Get magnification and mpin dist for the current positions.
    set curr_mag [lindex [split $result] 4]
    set curr_z [lindex [lindex $info(stage_z_coords) [lsearch $info(stage_z_coords) "$p*"]] 1]
    
    # Get magnification and mpin dist for the previously measured position.    
    if { $p < $info(center_stage_pos) } {
	set prev_p [expr $p + 1]
    } {
	set prev_p [expr $p - 1]
    }
    set prev_mag [lindex [split $info(data_$prev_p)] 4]
    set prev_z  [lindex [lindex $info(stage_z_coords) [lsearch $info(stage_z_coords) "$prev_p*"]] 1]

    # Calculate expected magnification at the current position.
    set exp_mag [expr $prev_z / $curr_z * $prev_mag]
           
    if {[expr abs ($curr_mag - $exp_mag) > $err]} {
		set l_b [format "%1.3f" [expr $exp_mag - $err]]
		set u_b [format "%1.3f" [expr $exp_mag + $err]]
		set result "ERROR: Image magnification M = $curr_mag out of bounds: $l_b < M < $u_b."
		LWDAQ_print $info(text) $result
		LWDAQ_print $info(text) "SUGGESTION: Check stage position or change max_mag_error\
			in Configuration panel."
    }
    return $result
}

# Build a list of the camera mount z-coordinates of the mask positions available on 
# the stage.
proc PXC_Calibrator_get_stage_z_coords {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

	#Get data for the stage and the master mask.
	set e $info(calib_stage_id)
	append e {[^~]*?data:[ \n]*([^~]*?)[ \n]*end\.}
	if {![regexp $e $info(apparatus_database) match stage_data]} {
		return "ERROR: Cannot find entry for \"$info(calib_stage_id)\" in apparatus database."
	}

	#Extract the data for the camera mount from the stage measurement.	    
	set cam_mnt_data [lrange $stage_data  0 4]
	set pin1_cmm [split [lindex $cam_mnt_data 2] ","]
	set pin2_cmm [split [lindex $cam_mnt_data 3] ","]
	set cylPnt_cmm [lrange [split [lindex $cam_mnt_data 4] ","] 0 2]
	set cylDir_cmm [lrange [split [lindex $cam_mnt_data 4] ","] 3 5]
	set cylD [lindex [split [lindex $cam_mnt_data 4] ","] 6]

	#Find the intersection between the cylinder axis and the perpendiculars to pin1 & pin2.
	set pin1Int_cmm [Line_Pnt_Intersection $cylPnt_cmm $cylDir_cmm $pin1_cmm]
	set pin2Int_cmm [Line_Pnt_Intersection $cylPnt_cmm $cylDir_cmm $pin2_cmm]
	
	#Define the camera mount coordinate system in cmm coordinates.
	set jVec [Vec_Unit [Vec_Subtract $pin2Int_cmm $pin2_cmm]]
	set kVec [Vec_Unit $cylDir_cmm]
	set iVec [Vec_Cross $jVec $kVec]
	set camMntCoordVec_cmm [list $iVec $jVec $kVec]
	set camMntCoordOrigin_cmm $pin1Int_cmm

	#Extract the data for the mask mount from the stage measurement.
	set msk_mnt_data [lrange $stage_data 5 end]
	set stgPosLabels ""
	set mskMntSph_cmm ""
	foreach pos $msk_mnt_data {
		set mskMntStr [split $pos ","]
		lappend stgPosLabels [lindex $mskMntStr 0]
		lappend mskMntSph_cmm [list \
			[lrange $mskMntStr 1 3] \
			[lrange $mskMntStr 5 7] \
			[lrange $mskMntStr 9 11]]
	}
	
	#Convert the sphere coordinates from cmm to camera mount coordinate system.
	set mskMntSph_camMnt ""
	foreach pos $mskMntSph_cmm {
		set mskMntSph_camMnt_pos ""
		foreach sph $pos {
			set new_sph_coord [Matrix_Mult \
				[list [Vec_Subtract $sph $camMntCoordOrigin_cmm]] \
					[Transpose $camMntCoordVec_cmm]]
			lappend mskMntSph_camMnt_pos [lindex $new_sph_coord 0]
		}
		lappend mskMntSph_camMnt $mskMntSph_camMnt_pos
		LWDAQ_support
	}

    #Get the z coordinate for each position
    set z_coords ""
    for {set i 0} {$i < [llength $stgPosLabels]} {incr i} {
		lappend z_coords "[lindex $stgPosLabels $i] [lindex $mskMntSph_camMnt $i 0 2]"
    }
    
    return $z_coords
}

# Calculate the camera calibration parameters from the existing measurements
# and using the existing apparatus selections.
proc PXC_Calibrator_calculate {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

	#--- Establish the Camera Mount and Mask Mount coordinate systems. ---#

	# Get data for the stage and the master mask.
	set e $info(calib_stage_id)
	append e {[^~]*?data:[ \n]*([^~]*?)[ \n]*end\.}
	if {![regexp $e $info(apparatus_database) match stage_data]} {
		return "ERROR: Cannot find data for $info(calib_stage_id) in apparatus database."
	}
	set e $info(master_mask_id)
	append e {[^~]*?data:[ \n]*([^~]*?)[ \n]*end\.}
	if {![regexp $e $info(apparatus_database) match master_mask_data]} {
		return "ERROR: Cannot find data for $info(calib_stage_id) in apparatus database."
	}
	
	# Extract the data for the camera mount from the stage measurement.	    
	set cam_mnt_data [lrange $stage_data  0 4]
	set pin1_cmm [split [lindex $cam_mnt_data 2] ","]
	set pin2_cmm [split [lindex $cam_mnt_data 3] ","]
	set cylPnt_cmm [lrange [split [lindex $cam_mnt_data 4] ","] 0 2]
	set cylDir_cmm [lrange [split [lindex $cam_mnt_data 4] ","] 3 5]
	set cylD [lindex [split [lindex $cam_mnt_data 4] ","] 6]

	# Find the intersection between the cylinder axis and the perpendiculars to pin1 & pin2.
	set pin1Int_cmm [Line_Pnt_Intersection $cylPnt_cmm $cylDir_cmm $pin1_cmm]
	set pin2Int_cmm [Line_Pnt_Intersection $cylPnt_cmm $cylDir_cmm $pin2_cmm]
	
	# Define the camera mount coordinate system in cmm coordinates.
	set jVec [Vec_Unit [Vec_Subtract $pin2Int_cmm $pin2_cmm]]
	set kVec [Vec_Unit $cylDir_cmm]
	set iVec [Vec_Cross $jVec $kVec]
	set camMntCoordVec_cmm [list $iVec $jVec $kVec]
	set camMntCoordOrigin_cmm $pin1Int_cmm

	# Extract the data for the mask mount from the stage measurement.
	set msk_mnt_data [lrange $stage_data 5 end]
	set stgPosLabels ""
	set mskMntSph_cmm ""
	foreach pos $msk_mnt_data {
		set mskMntStr [split $pos ","]
		lappend stgPosLabels [lindex $mskMntStr 0]
		lappend mskMntSph_cmm [list \
			[lrange $mskMntStr 1 3] \
			[lrange $mskMntStr 5 7] \
			[lrange $mskMntStr 9 11]]
	}
	
	# Convert the sphere coordinates from cmm to camera mount coordinate system.
	set mskMntSph_camMnt ""
	foreach pos $mskMntSph_cmm {
		set mskMntSph_camMnt_pos ""
		foreach sph $pos {
			set new_sph_coord [Matrix_Mult \
				[list [Vec_Subtract $sph $camMntCoordOrigin_cmm]] \
					[Transpose $camMntCoordVec_cmm]]
			lappend mskMntSph_camMnt_pos [lindex $new_sph_coord 0]
		}
		lappend mskMntSph_camMnt $mskMntSph_camMnt_pos
		LWDAQ_support
	}
	
	# Define the mask mount coordinate system in camera mount coordinates.
	set mskMntCoordVec_camMnt ""
	set mskMntCoordOrigin_camMnt ""
	foreach pos $mskMntSph_camMnt {
		set iVec [Vec_Unit [Vec_Subtract [lindex $pos 0] [lindex $pos 1]]]
		set jVec [lindex [Fit_Plane_3pt $pos] 0]
		set kVec [Vec_Cross $iVec $jVec]
		lappend mskMntCoordVec_camMnt [list $iVec $jVec $kVec]
		lappend mskMntCoordOrigin_camMnt [lindex $pos 0]
		LWDAQ_support
	}

	#--- Reconstruct Master-Mask coordinate system. ---#

	# Extract the master mask calibration parameters from the database.
	set masterMsk_address [lrange $master_mask_data 0 1]
	set masterMsk_point [lrange $master_mask_data 2 4]
	set ij_dirCos [Vec_Mult [lrange $master_mask_data 5 6] [expr 1.0 / 1000]]
	set masterMsk_angle [expr [lindex $master_mask_data 7] / 1000]
	
	# Establish the master mask coordinate system in mask mount coordinates.
	set k_dirCos [expr sqrt(1 - pow([lindex $ij_dirCos 0],2) -  pow([lindex $ij_dirCos 1],2))]
	set kVec "$ij_dirCos $k_dirCos"
	set iVec [Vec_Rot [Vec_Unit "[lindex $kVec 2] 0 -[lindex $kVec 0]"] $kVec $masterMsk_angle];
	set jVec [Vec_Cross $kVec $iVec]
	set masterMsk_addressOrigin "$masterMsk_address 0.0"
	set masterMskCoordVec_mskMnt [list $iVec $jVec $kVec]
	set masterMskCoordOrigin_mskMnt $masterMsk_point
	
	#--- Calculate the device parameters for the current measurement. ---#

	# For each mask position, find the point on the mask that falls onto the center of 
	# the CCD and calculate its camera mount coordinates.
	set dataPos ""
	set mskPoint_camMnt ""
	set msk_magn ""
	set msk_tilt ""
	foreach p $info(positions) {
		set pos [expr $p - [lindex [lsort -increasing -integer $stgPosLabels] 0]]
		lappend dataPos $pos
		set msk_address [Vec_Mult "[lrange $info(data_$p) 1 2] 0.0" [expr {1.0 / 1000}]]
		lappend msk_magn [lrange $info(data_$p) 3 4]
		lappend msk_tilt [lindex $info(data_$p) 5]
		
		set mskPoint_1 [list [Vec_Subtract $msk_address $masterMsk_addressOrigin]]
		set mskPoint_2 [Matrix_Mult $mskPoint_1 $masterMskCoordVec_mskMnt]
		set mskPoint_3 [Vec_Add [lindex $mskPoint_2 0] $masterMskCoordOrigin_mskMnt]
		set mskPoint_4 [Matrix_Mult [list $mskPoint_3] [lindex $mskMntCoordVec_camMnt $pos]]
		set mskPoint_5 [Vec_Add [lindex $mskPoint_4 0] [lindex $mskMntCoordOrigin_camMnt $pos]]
		lappend mskPoint_camMnt $mskPoint_5
		LWDAQ_support
	}
	
	# Calculate master mask coordinate vectors (in camera mount coordinates) 
	# at each position on the stage.
	foreach vec $mskMntCoordVec_camMnt {
		set masterMskCoordVec_camMnt [lappend masterMskCoordVec_camMnt \
			[Matrix_Mult $masterMskCoordVec_mskMnt $vec]]
	}

	# Calculates the tilt of the mask in each stage position (relative to the 
	# camera mount coordinate system).
	set masaterMskTilt_camMnt ""
	foreach p $dataPos {
		set tiltX [expr -1000 * [lindex $masterMskCoordVec_camMnt $p 0 1]]
		set tiltY [expr -1000 * [lindex $masterMskCoordVec_camMnt $p 1 0]]
		set masterMskTilt_camMnt [lappend masterMskTilt_camMnt [expr ($tiltX + $tiltY) / 2]]
	}

	# Calculate z-coordinate and mask magnification for each mask position.
	set z_dist ""
	foreach e $mskPoint_camMnt {lappend z_dist [lindex $e 2]}
	set magn_inv ""
	foreach e $msk_magn {lappend magn_inv [expr 1.0 / [Vec_Mean $e]]}
	set z_magn_pair ""
	for {set i 0} {$i < [llength $z_dist]} {incr i} {
		lappend z_magn_pair "[lindex $z_dist $i] [lindex $magn_inv $i]"
	}
	
	# Fit a straight line to 1/M vs z.
	set magn_fit [Fit_Line $z_magn_pair]
	
	# Calculate the z-coordinage of the center of the lens. (z such that 1/M(z) = 0).
	set lens_z [expr -[lindex $magn_fit 0] / [lindex $magn_fit 1]]

	# Calculate the camera tilt from the mask tilt and the measured ccd-to-mask tilt.
	set cam_tilt ""
	for {set i 0} {$i < [llength $msk_tilt]} {incr i} {
		lappend cam_tilt [expr [lindex $msk_tilt $i] + [lindex $masterMskTilt_camMnt $i]]
	}
	set cam_tilt [Vec_Mean $cam_tilt]
	
	# Calculate the z-coordinate of the ceter of the ccd.
	set ccd_z ""
	foreach elem $z_magn_pair {
		set ccd_z [lappend ccd_z [expr $lens_z - (1 / [lindex $elem 1]) \
			* ([lindex $elem 0] - $lens_z)]]
	}
	set ccd_z [Vec_Mean $ccd_z]

	# Fit a line through the mask points and calculate where it intersects the 
	# z-plane of the lens and the ccd.
	set cam_axis_eq [Fit_Line_3d $mskPoint_camMnt]
	set t1 [expr {($lens_z - [lindex $cam_axis_eq 1 2]) * [lindex $cam_axis_eq 0 2]}]
	set t2 [expr {($ccd_z - [lindex $cam_axis_eq 1 2]) * [lindex $cam_axis_eq 0 2]}]
	set lens [Vec_Add [Vec_Mult [lindex $cam_axis_eq 0] $t1] [lindex $cam_axis_eq 1]]
	set ccd [Vec_Add [Vec_Mult [lindex $cam_axis_eq 0] $t2] [lindex $cam_axis_eq 1]]

	# Direction cosines of the camera axis relative to the calibration cylinder.
	set dir_cosines [Vec_Unit [lindex [Matrix_Mult \
		[list [Vec_Subtract $lens $ccd]] \
		[list "1 0 0" "0 1 0" "0 0 1"]] 0]]

	# Correction due to the calibration cylinder not being exactly 30.000mm. *)
	set y_offset [expr ($cylD - 30.000) / 2 / cos([Pi] / 4)];

	#The final parameters
	set pivot [Vec_Add $lens "0 $y_offset 0"]
	set axis [Vec_Mult 1000 [lrange $dir_cosines 0 1]]
	set pivot_ccd [expr [lindex $lens 2] - [lindex $ccd 2]]
	set rotation $cam_tilt
	set curr_params "$pivot $axis $pivot_ccd $rotation"

	# Calculate the rms residual from the axis fit. We display the residuals
	# when show_residuals is set.
	if {$config(show_residuals)} {
		LWDAQ_print $info(text) "\nResiduals x, y, z (um, um, mm):" green
	}
	set rms 0
	foreach p $mskPoint_camMnt {
		set v [Line_Pnt_Intersection \
			[lindex $cam_axis_eq 1] \
			[lindex $cam_axis_eq 0] \
			$p]
		set vd [Vec_Subtract $v $p]
		if {$config(show_residuals)} {
			LWDAQ_print $info(text) "\
				[format %.1f [expr 1000 * [lindex $vd 0]]]\
				[format %.1f [expr 1000 * [lindex $vd 1]]]\
				[format %.1f [lindex $p 2]]" green
		}
		set rms [expr $rms + [lindex $vd 0]*[lindex $vd 0] + [lindex $vd 1]*[lindex $vd 1]]
	}
	set rms [expr 1000 * sqrt($rms/[llength $mskPoint_camMnt])]
	
	# Prepare the single-line or verbose calibration result string.
	if {$config(verbose)} {
		set result "\nDevice: $info(device_id)\n"
		append result "Apparatus: \"$info(calib_stage_id) $info(master_mask_id)\"\n"
		append result "Time: $info(calibration_time)\n"
		append result "Accuracy: [format %.1f $rms] um\n"
		append result "pivot.x [format %.3f [lindex $curr_params 0]] mm\n"
		append result "pivot.y [format %.3f [lindex $curr_params 1]] mm\n"
		append result "pivot.z [format %.3f [lindex $curr_params 2]] mm\n"
		append result "axis.x [format %.3f [lindex $curr_params 3]] mrad\n"
		append result "axis.y [format %.3f [lindex $curr_params 4]] mrad\n"
		append result "pivot-ccd [format %.3f [lindex $curr_params 5]] mm\n"
		append result "rotation [format %.3f [lindex $curr_params 6]] mrad"
	} {
		set result "$info(device_id) $info(calibration_time) "
		append result [format "%.3f %.3f %.3f %.3f %.3f %.3f %.3f" \
			[lindex $curr_params 0] [lindex $curr_params 1] [lindex $curr_params 2] \
			[lindex $curr_params 3] [lindex $curr_params 4] \
			[lindex $curr_params 5] [lindex $curr_params 6]]
	}
	
	# Add a warning to the result string if the residual is too large.
	if {$rms > $config(max_axis_resid_um)} {
		append result "\nWARNING: Axis residual exceeds limit of $config(max_axis_resid_um) um."
	}	
	
	return $result
}

# PXC_Calibrator_sort_dc sorts two device calibration measurements in
# order of increasing device id. If the device ids are the same, we sort
# in order of most recent calibration first.
proc PXC_Calibrator_sort_dc {dc1 dc2} {
	if {[regexp {device_id:[ ]*([^\n ]+)} $dc1 match id1] \
		&& [regexp {calibration_time:[ ]*([^\n ]+)} $dc1 match time1] \
		&& [regexp {device_id:[ ]*([^\n ]+)} $dc2 match id2] \
		&& [regexp {calibration_time:[ ]*([^\n ]+)} $dc2 match time2]} {
		set sort [string compare -nocase $id1 $id2]
		if {$sort == 0} {
			set sort [string compare -nocase $time2 $time1]
		}
	} {
		set sort 0	
	}
	return $sort
}

# Go through the entries in the calibration database and re-calculate
# the source positions for each entry using the apparatus database and
# the measurements in each entry.
proc PXC_Calibrator_recalculate_all {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

	# Check if the apparatus database file exists.
	if {![file exists $config(apparatus_file)]} {
		LWDAQ_print $info(text) "ERROR: Can't find apparatus database file."
		LWDAQ_print $info(text) "SUGGESTION: Press Configure and Choose Apparatus Database."
		return 0
	}

	# Read in the apparatus database and remove tildas and comments
	set f [open $config(apparatus_file) r]
	set contents [read $f]
	set contents [regsub -all "~" $contents " "]
	set info(apparatus_database) [regsub -all {\{[^~]*?\}} $contents ""]
	close $f

	# Check that the calibration file exists.
	if {![file exists $config(calibration_file)]} {
		LWDAQ_print $info(text) "ERROR: Can't find calibration database file."
		LWDAQ_print $info(text) "SUGGESTION: Press Configure and Choose Calibration Database."
		return 0
	}	
	
	# Read in the file contents and remove tildas and comments.
	set f [open $config(calibration_file) r]
	set contents [read $f]
	close $f
	set contents [regsub -all "~" $contents " "]
	set contents [regsub -all {\{[^~]*?\}} $contents ""]
	
	# Parse file contents using the device_calibration key phrase and the
	# tilda character.
	set measurements \
		[split \
			[regsub -all "device_calibration:" \
				$contents "~device_calibration:"] ~]
	set measurements [lreplace $measurements 0 0]
	set sorted [lsort -command PXC_Calibrator_sort_dc $measurements]
	set measurements $sorted
		
	LWDAQ_print $info(text) "Found total [llength $measurements] entries in calibration database."
	LWDAQ_print $info(text) "Recalculating parameters for all matching entries..." purple
	set info(control) "Calculate"
	set previous_id "none"
	foreach m $measurements {
		if {[regexp {device_id:[ ]*([^\n ]+)} $m match id] \
				&& [regexp {calibration_type:[ ]*([^\n ]+)} $m match type] \
				&& [regexp {apparatus_version:[ ]*"([^"]*)} $m match version] \
				&& [regexp {calibration_time:[ ]*([^\n ]+)} $m match time] \
				&& [regexp {operator_name:[ ]*([^\n ]+)} $m match operator] \
				&& [regexp {data:[ \n]*([^~]*?)[ \n]*end.} $m match data]} {
			if {![string match $config(device_id_select) $id]} {continue}
			if {![string match $config(operator_select) $operator]} {continue}
			if {![string match -nocase $config(calibration_time_select) $time]} {continue}
			if {$config(calibration_time_last)} {
				if {[string match -nocase $previous_id $id]} {continue}
			}
			set info(device_id) $id
			set info(calibration_time) $time
			set info(operator_name) $operator
			set data [split $data \n]
			set data [lreplace $data end end]
			set info(positions) ""
			foreach d $data {
				lappend info(positions) [lindex $d 0]
				set info(data_[lindex $d 0]) $d
			}			
			set info(calib_stage_id) [lindex $version 0]
			set info(master_mask_id) [lindex $version 1]

			set result [PXC_Calibrator_calculate]

			if {[regexp "WARNING: " $result]} {
				if {$config(verbose)} {
					LWDAQ_print $info(text) $result blue
				} {
					LWDAQ_print $info(text) \
						[regsub {\nWARNING: [^\n]*} $result ""] \
						blue
				}
			} {
				LWDAQ_print $info(text) $result black
			}
			if {($info(control) == "Stop") || ![winfo exists $info(window)]} {break}
			set previous_id $id
		} {
			LWDAQ_print $info(text) "ERROR: Invalid entry:\n$m."
			break
		}
		LWDAQ_update
	}
	if {$info(control) == "Stop"} {
		LWDAQ_print $info(text) "Stopped.\n" purple
	} {
		LWDAQ_print $info(text) "Done.\n" purple
	}
	set info(control) "Idle"
}

# Defines calibration steps.
proc PXC_Calibrator_do {step} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info
    upvar #0 LWDAQ_config_Rasnik iconfig
    global LWDAQ_Driver LWDAQ_Info

    if {$step == "Execute"} {
		if {$info(control) != "Idle"} {
			LWDAQ_print $info(text) "ERROR: Cannot execute until Idle."
			LWDAQ_print $info(text) "SUGGESTION: Wait a second, or try Stop"
			return 0
		}
		focus $info(execute_button)
    }
	
    if {$step == "Backward"} {
		if {$info(control) != "Idle"} {
			LWDAQ_print $info(text) "ERROR: Cannot go backwards until Idle."
			LWDAQ_print $info(text) "SUGGESTION: Wait a second, or try Stop."
			return 0
		}
		set info(state) [lindex $info(state_history) end]
		set info(state_history) [lreplace $info(state_history) end end]
		PXC_Calibrator_do Establish
		return 1
    }
	
    if {$step == "Forward"} {
		if {$info(control) != "Idle"} {
			LWDAQ_print $info(text) "ERROR: Cannot go forwards until Idle."
			LWDAQ_print $info(text) "SUGGESTION: Wait a second, or try Stop."
			return 0
		}
		lappend info(state_history) $info(state)
		if {[llength $info(state_history)] > 30} {
			set info(state_history) [lreplace $info(state_history) 0 0]
		}
    }

    if {$info(state) == "Start"} {
		if {$step == "Establish"} {
			set info(state_history) [list "Start"]
			set info(title) "Press Execute to load apparatus database."
			return
		}
		if {$step == "Execute"} {
			foreach a {calib_stage_id  master_mask_id operator_name device_id} {
				set info($a) none
			}
	
			set info(control) "Reading"

			# Check if the apparatus database file exists.
			if {![file exists $config(apparatus_file)]} {
				LWDAQ_print $info(text) "ERROR: Can't find apparatus database file."
				LWDAQ_print $info(text) "SUGGESTION: Press Configure and Choose Apparatus Database."
				set info(control) "Idle"
				return 0
			}
	
			# Read in the apparatus database and replace tildas and comments.
			set f [open $config(apparatus_file) r]
			set contents [read $f]
			set contents [regsub -all "~" $contents " "]
			set info(apparatus_database) [regsub -all {\{[^~]*?\}} $contents ""]
			close $f
	
			# Parse the measurement file into its entries.
			set measurements \
				[split \
					[regsub -all "apparatus_measurement:" \
						$info(apparatus_database) "~apparatus_measurement:"] ~]
			set measurements [lreplace $measurements 0 0]
		
			# Extract unique apparatus versions from the apparatus database, and 
			# include them in the apparatus menus.
			set count_mm 0
			set count_cs 0
			$info(master_mask_menu) delete 0 end
			$info(calib_stage_menu) delete 0 end
			foreach m $measurements {
				if {[regexp {apparatus_version:[ ]*([^\n ]+)} $m match version] \
					&& [regexp {calibration_type:[ ]*([^\n ]+)} $m match type]} {
					if {$type == "proximity_camera"} {
						if {[regexp {^[A-Z][0-9]{4}} $version]} {
							$info(master_mask_menu) add command -label $version \
								-command "set PXC_Calibrator_info(master_mask_id) $version"
							incr count_mm
						} {
							$info(calib_stage_menu) add command -label $version \
								-command "set PXC_Calibrator_info(calib_stage_id) $version"
							incr count_cs
						}
						
					}
				}
			}
    
			set info(control) "Idle"

			if {$count_cs == 0} {
				LWDAQ_print $info(text) "ERROR: No calibration stage entries in apparatus database."
				return 0
			}
		
			if {$count_mm == 0} {
				LWDAQ_print $info(text) "ERROR: No master mask entries in apparatus database."
				return 0
			}
		
			PXC_Calibrator_do Forward
			return 1
		}

		if {$step == "Forward"} {
			set info(state) "Enter_Device_ID"
			PXC_Calibrator_do Establish
			return 1
		}
    }

    if {$info(state) == "Enter_Device_ID"} {
		if {$step == "Establish"} {
			set info(title) "Install the camera on the mount and scan in the device id."
			focus $info(device_id_text_field)
			$info(device_id_text_field) selection range 0 end
			return 1
		}

		if {$step == "Execute"} {
			# Check if the device_id has been entered.
			if {$info(device_id) == "none" || $info(device_id) == ""} {
				LWDAQ_print $info(text) "ERROR: No device_id entered."
				return 0
			}
			if {![regexp {^20MABND([A-Z])00([0-9][0-9][0-9][0-9])$} $info(device_id) match let num]} {
				LWDAQ_print $info(text) "ERROR: Invalid device id, must be of the form 20MABNDG00xxxx."
				return 0
			}
			set info(short_device_id) "$let$num"
	
			# Read in camera parameters from the lookup table and find the nominal mask_to_pin distance 
			# and magnification for the current camera.
			set cam_type "unknown"
			set nom_cam_params [split [LWDAQ_tool_data PXC_Calibrator] \n]
			set nom_cam_params [lreplace $nom_cam_params 0 0]
			if {[string match "ERROR:*" $nom_cam_params]} {return}
			for {set i 1} {$i < [llength $nom_cam_params]} {incr i 1} {
				regexp {^G([0-9]{4})$} [lindex [lindex $nom_cam_params $i] 0] match l_num
				regexp {^G([0-9]{4})$} [lindex [lindex $nom_cam_params $i] 1] match u_num
				regexp {^20MABNDG00([0-9]{4})$} $info(device_id) match num
				if {($l_num <= $num) && ($num <= $u_num)} {
					set cam_type [lindex [lindex $nom_cam_params $i] 2]
					set info(nom_mpin_dist) [lindex [lindex $nom_cam_params $i] 5]
					set info(set_mpin_dist) [lindex [lindex $nom_cam_params $i] 6]
					set info(meas_mag) [lindex [lindex $nom_cam_params $i] 7]
				}
			}   
			if {$info(set_mpin_dist) == "N/A" || $info(meas_mag) == "N/A"} {
				LWDAQ_print $info(text) "ERROR: No entry found for $info(device_id) in the lookup table."
				LWDAQ_print $info(text) "SUGGESTION: Create an entry in PXC_Calibrator.tcl data section."
				return 0
			}
			if {$cam_type == "unknown"} {
				LWDAQ_print $info(text) "ERROR: Unknown device_id"
				LWDAQ_print $info(text) "SUGGESTION: Create an entry in PXC_Calibrator.tcl data section."
				return 0
			}
			LWDAQ_print $info(text) "Camera Type: $cam_type ($info(device_id))"
			
			PXC_Calibrator_do Forward
			return
		}
	
		if {$step == "Forward"} {
			set info(state) "Define_Calibration"
			PXC_Calibrator_do Establish
			return
		}
    }

    if {$info(state) == "Define_Calibration"} {
		if {$step == "Establish"} {
			set info(title) "Select calibration stage and master mask."
			return 1
		}

		if {$step == "Execute"} {
			set num_errors 0
		   
			foreach a {calib_stage_id master_mask_id} {
				if {$info($a) == "none"} {
					LWDAQ_print $info(text) "ERROR: No $a selected."
					incr num_errors 1
				}
			}
			# Check if calib_stage_id has been selected and is valid.
			if {$info(calib_stage_id) == "none"} {
				LWDAQ_print $info(text) "ERROR: No calib_stage_id selected."
				incr num_errors 1
			}
	
			# Check if master_mask_id has been selected
			if {$info(master_mask_id) == "none"} {
				LWDAQ_print $info(text) "ERROR: No $a selected."
				incr num_errors 1
			}
	
			# Check if operator_name has been entered
			if {$info(operator_name) == "none" || $info(operator_name) == ""} {
				LWDAQ_print $info(text) "ERROR: No operator_name entered."
				incr num_errors 1
			}
		   
			if {$num_errors > 0} {return 0}
			
			#Determine mask_to_pin distances for the current stage.
			set info(stage_z_coords) [PXC_Calibrator_get_stage_z_coords]
	
			# Find the stage position closest to the nominal mask_to_pin distance.
			set min_dist 1000
			foreach pos $info(stage_z_coords) {
				set dist [expr abs ([lindex $pos 1] - $info(nom_mpin_dist))]
				if { $dist < $min_dist } {
					set min_dist $dist
					set info(center_stage_pos) [lindex $pos 0]    
				}
			}
			set info(min_stage_pos) [lindex [lindex $info(stage_z_coords) 0] 0]
			set info(max_stage_pos) [lindex [lindex $info(stage_z_coords) end] 0]
	
			LWDAQ_print $info(text) "Available positions are $info(min_stage_pos) to $info(max_stage_pos),\
				position is $info(center_stage_pos) is the best one to start with."
			if {$info(center_stage_pos) == [expr $info(min_stage_pos)]} {
				LWDAQ_print $info(text) "WARNING: Stage may be too long for accurate calibration." blue
			}
			if {$info(center_stage_pos) == [expr $info(max_stage_pos)]} {
				LWDAQ_print $info(text) "WARNING: Stage may be too short for accurate calibration." blue
			}
			
			PXC_Calibrator_do Forward
			return 1
		}

		if {$step == "Forward"} {
			set info(state) "Position_Instrument_1"
			LWDAQ_print $info(text) "Starting a fresh calibration."
			set namelist [array names info]
			foreach name $namelist {
				if {[regexp {data_[0-9]+} $name]} {
					unset info($name)
				}
			}
			PXC_Calibrator_do Establish
			return 1
		}
    }

    if {[regexp {Position_Instrument_([0-9]+)} $info(state) match position]} {		
		if {$step == "Establish"} {
			$info(calculation_status_label) configure -text "$info(center_stage_pos)" -fg darkblue
			if {$position == 1} {
				set info(title) "Place master mask in position $info(center_stage_pos)."
			} {
				set info(title) "Re-position camera in the camera mount."
			}
			return 1
		}
		
		if {$step == "Execute"} {
			set info(control) "Acquire"
			if {$position == 1} {
				set info(calibration_time) [LWDAQ_time_stamp]
				set temp_result [PXC_Calibrator_temperature_acquire]
				if {![LWDAQ_is_error_result $temp_result]} {
					set info(temperature) $temp_result
				} {
					LWDAQ_print $info(text) "WARNING: Invalid temperature measurement."
					set info(temperature) "none"
				}
			}
			set result [PXC_Calibrator_acquire]
			set info(control) "Idle"
			if {[LWDAQ_is_error_result $result]} {
				LWDAQ_print $info(text) $result
				return 0
			}

			set result "$info(center_stage_pos) [lrange $result 1 end]"
			LWDAQ_print $info(text) $result

			# Check magnification.
			set curr_mag [lindex [split $result] 4]
			set curr_z [lindex [lindex $info(stage_z_coords) \
				[lsearch $info(stage_z_coords) "$info(center_stage_pos)*"]] 1]
			set exp_mag [expr $info(set_mpin_dist) / $curr_z * $info(meas_mag)]
			if {[expr abs($curr_mag - $exp_mag)] > $config(max_initial_mag_error)} {
				LWDAQ_print $info(text) "WARNING: Initial image magnification is out of bounds."
				LWDAQ_print $info(text) "SUGGESTION: Check the mask position."
			}
			
			set info(inst_positioning_$position) $result

			# Check if repositioning the camera affected the result.
			if {$position == 2} {
				set result [PXC_Calibrator_check_positioning $info(inst_positioning_1) \
					$info(inst_positioning_2)]
			}
		
			if {[LWDAQ_is_error_result $result]} {
				LWDAQ_print $info(text) $result
				return 0
			}
			set info(data_$info(center_stage_pos)) $result
			set info(positions) $info(center_stage_pos)
			PXC_Calibrator_do Forward
			return 1
		}
		
		if {$step == "Forward"} {
			if {$position == 2} {
				set info(state) "Collect_Data_$info(center_stage_pos)"
				PXC_Calibrator_do Forward
			} {
				set info(state) "Position_Instrument_2"
				PXC_Calibrator_do Establish
			}
			return 1
		}
    }

    if {[regexp {Collect_Data_([0-9]+)} $info(state) match position]} {
	
		if {$step == "Establish"} {
			$info(calculation_status_label) configure -text "$position" -fg darkblue
			set info(data_$position) "R 0 0 0 0 0 0 0 0 0 0 0 0"
			set info(title) "Place master mask in position $position."
			return 1
		}

		if {$step == "Execute"} {
			set info(control) "Acquire"
			set result [PXC_Calibrator_acquire]
			set info(control) "Idle"
			if {([LWDAQ_is_error_result $result])
				|| ([lindex $result 6] > $config(max_pos_sigma))} {
				LWDAQ_print $info(text) "NOTE: Poor image quality at position $position,\
					assuming mask is out of focus."
				if {($position <= $info(center_stage_pos)) 
					&& ($info(center_stage_pos) < $info(max_stage_pos))} {
					set info(state) "Collect_Data_[expr $info(center_stage_pos) + 1]"
				} {
					set info(state) "Calculate"
				}
				PXC_Calibrator_do Establish
				return 1
			} 
			
			set result "$position [lrange $result 1 end]"
			LWDAQ_print $info(text) $result
	
			set result [PXC_Calibrator_check_magnification $position $result]
			if {[LWDAQ_is_error_result $result]} {return 0}
			set info(data_$position) $result
			if {[lsearch $info(positions) $position] == -1} {
				lappend info(positions) $position
				set info(positions) [lsort -integer $info(positions)]
			}

			PXC_Calibrator_do Forward
			return 1
		}
	
		if {$step == "Forward"} {
			if {$position <= $info(center_stage_pos)} {
				if {$position > $info(min_stage_pos)} {
					set info(state) "Collect_Data_[expr $position - 1]"
				} {
					if {$info(center_stage_pos) < $info(max_stage_pos)} {
						set info(state) "Collect_Data_[expr $info(center_stage_pos) + 1]"
					} {
						set info(state) "Calculate"
					}
				}
			} {
				if {$position < $info(max_stage_pos)} {
					set info(state) "Collect_Data_[expr $position + 1]"
				} {
					set info(state) "Calculate"
				}
			}

			PXC_Calibrator_do Establish
			return 1
		}
    }

    if {$info(state) == "Calculate"} {
		if {$step == "Establish"} {
			$info(calculation_status_label) configure -text "$info(short_device_id)" -fg darkblue
			set info(title) "Press Execute to calculate calibration constants."
			return 1
		}
		
		if {$step == "Execute"} {
			set result [PXC_Calibrator_calculate]
			if {[regexp "WARNING: " $result]} {
				set config(calculation_status) "FAIL"
				$info(calculation_status_label) configure -fg red
				LWDAQ_print $info(text) $result blue	
			} {
				set config(calculation_status) "PASS"
				$info(calculation_status_label) configure -fg green
				LWDAQ_print $info(text) $result	black
			}
			
			PXC_Calibrator_do Forward
			return 1
		}
		
		if {$step == "Forward"} {
			set info(state) "Finish"
			PXC_Calibrator_do Establish
			return 1
		}
    }

    if {$info(state) == "Finish"} {
		if {$step == "Establish"} {
			if {$config(auto_store) && ($config(calculation_status) == "PASS")} {
				PXC_Calibrator_store
				set info(title) "Press Execute to move on."
			} {
				set info(title) "Press Store to save constants, Execute to move on."
			}
			return 1
		}

		if {$step == "Execute"} {
			if {!$info(stored)} {
				LWDAQ_print $info(text) "WARNING: Measurements have not been stored."
			}
			set info(stored) 0
	
			foreach p $info(positions) {
				set info(data_$p) 0
			}
			set info(positions) ""
			set info(camera_parameters) ""
			set info(device_calibration_data) ""
	
			$info(calculation_status_label) configure -text "NONE" -fg black
	
			foreach p {calib_stage_id master_mask_id} {
				if {!$info(retain_$p)} {set info($p) "none"}
			}
			foreach p {operator_name device_id} {
				if {!$info(retain_$p)} {set info($p) "none"}
			}
		
			PXC_Calibrator_do Forward
			return 1
		}	

		if {$step == "Forward"} {
			set info(state) "Enter_Device_ID"
			PXC_Calibrator_do Establish
			return 1
		}
    }
}

proc PXC_Calibrator_open {} {
    upvar #0 PXC_Calibrator_config config
    upvar #0 PXC_Calibrator_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
    set f $w.status
    frame $f
    pack $f -side top -fill x
	
	label $f.title -textvariable PXC_Calibrator_info(title) -width 60
	pack $f.title -side left	
	label $f.control -textvariable PXC_Calibrator_info(control) -width 10
	pack $f.control -side right
			
    set f $w.controls
    frame $f
    pack $f -side top -fill x
	
    foreach a {Execute Backward Forward} {
		set b [string tolower $a]
		button $f.$b -text $a -command "PXC_Calibrator_do $a"
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
    }
    focus $info(execute_button)

    foreach a {Stop Configure} {
		set b [string tolower $a]
		button $f.$b -text $a -command PXC_Calibrator_$b
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
    }
	foreach a {Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b PXC_Calibrator"
		pack $f.$b -side left -expand 1
		set info($b\_button) $f.$b
	}
	
    set f $w.type_ver_id
    frame $f 
    pack $f -side top -fill x

    label $f.ptitle -text "Parameter:"
    label $f.lsi -text "calib_stage_id"
    label $f.lmi -text "master_mask_id"
    label $f.lon -text "operator_name"
    label $f.ldi -text "device_id"
	
    label $f.stitle -text "Select:"
    tk_optionMenu $f.ssi PXC_Calibrator_info(calib_stage_id) none
    set info(calib_stage_menu) $f.ssi.menu
    tk_optionMenu $f.smi PXC_Calibrator_info(master_mask_id) none
    set info(master_mask_menu) $f.smi.menu
    entry $f.son -textvariable PXC_Calibrator_info(operator_name) -width 10 
    entry $f.sdi -textvariable PXC_Calibrator_info(device_id) -width 16 
    set info(device_id_text_field) $f.sdi
	
    label $f.rtitle -text "Retain:"
    checkbutton $f.rsi -variable PXC_Calibrator_info(retain_calib_stage_id) 
    checkbutton $f.rmi -variable PXC_Calibrator_info(retain_master_mask_id)
    checkbutton $f.ron -variable PXC_Calibrator_info(retain_operator_name) 
    checkbutton $f.rdi -variable PXC_Calibrator_info(retain_device_id) 

    grid $f.ptitle $f.lsi $f.lmi $f.lon $f.ldi -padx 7 -sticky news
    grid $f.stitle $f.ssi $f.smi $f.son $f.sdi -padx 7 -sticky ew
    grid $f.rtitle $f.rsi $f.rmi $f.ron $f.rdi -padx 7 -sticky news

    set f $w.image_line
    frame $f 
    pack $f -side top -fill x
    
    set f1 $f.image_frame
    frame $f1 -bd 3 -relief sunken
    pack $f1 -side left -fill y
    set info(photo) [image create photo -width 344 -height 244]
    label $f1.image -image $info(photo) 
    pack $f1.image -side left

    set f2 $f.status_frame
    frame $f2 -bd 3 -relief sunken
    pack $f2 -side right -fill both -expand 1

	set f $f2.store
	frame $f
	pack $f -side top -fill x
	label $f.description -text "Calibration Database:" 
	pack $f.description -side top
	frame $f.controls
	pack $f.controls -side top
	button $f.controls.sb -text "Store" -command "PXC_Calibrator_store"
	pack $f.controls.sb -side left
	checkbutton $f.controls.as -variable PXC_Calibrator_config(auto_store) \
		-text "Auto-Store" 
	pack $f.controls.as -side left
	checkbutton $f.controls.ss -variable PXC_Calibrator_info(stored) \
		-text "Stored"
	pack $f.controls.ss -side left
		
    set f $f2.calc
    frame $f 
    pack $f -side top -fill x
    label $f.description -text "Calculation Status: "
    pack $f.description -side top
    label $f.cs -text "NONE" -font {helvetica 40 bold}
    pack $f.cs -side top
    set info(calculation_status_label) $f.cs
    frame $f.controls
    pack $f.controls -side top
    button $f.controls.rc -text "Recalculate All" -command "PXC_Calibrator_recalculate_all"
    pack $f.controls.rc -side left
	checkbutton $f.controls.v -variable PXC_Calibrator_config(verbose) -text "Verbose"
	checkbutton $f.controls.l -variable PXC_Calibrator_config(calibration_time_last) -text "Last"
	pack $f.controls.v $f.controls.l -side left

	set g $f.select
	frame $g 
	pack $g -side top -fill x
	
	label $g.ldi -text "device_id_select"
	entry $g.rdi -textvariable PXC_Calibrator_config(device_id_select) -width 14
	label $g.lts -text "calibration_time_select"
	entry $g.rts -textvariable PXC_Calibrator_config(calibration_time_select) -width 14
	label $g.lo -text "operator_select"
	entry $g.ro -textvariable PXC_Calibrator_config(operator_select) -width 14

	grid $g.ldi $g.rdi -padx 5 -sticky ne
	grid $g.lts $g.rts -padx 5 -sticky ne
	grid $g.lo $g.ro -padx 5 -sticky ne
	
    set info(text) [LWDAQ_text_widget $w 90 15]
	
    PXC_Calibrator_do Establish
	
    return 1
}

PXC_Calibrator_init
PXC_Calibrator_open

#----------------------------------MATH ROUTINES------------------------------------------#
# Here are some math routines written by Paul Keselman. They work in the context of the 
# PXC Calibrator but we're not sure we understand how to use them ourselves, because we 
# sometimes get results from them that don't make sense when we test them. Kevan 27-MAY-09
proc Pi {} {
    return 3.1415926535897932385
}
proc Factorial {x} {
    if {$x <= 1} {
	return 1
    } else {
	return [expr {$x * [Factorial [expr {$x - 1}]]}]
    }
}
proc Bin_Coeff {n r} {
    return [expr [Factorial $n] / ([Factorial [expr $n - $r]] * [Factorial $r])]
}
proc Bin_Coeff_Sum {n m} {
    set i 0; set sum 0
    while {($i <= $m) && ($i <= $n)} {
	set sum [expr {$sum + [Bin_Coeff $n $i]}]
	incr i
    }
    return $sum
}
proc Vec_Add {v1 v2} {
    set s ""
    if {([llength $v1] == 1) && ([llength $v2] == 1)} {
        set s [expr $v1 + $v2]
    } elseif {([llength $v1] > 1) && ([llength $v2] == [llength $v1])} {
        for {set i 0} {$i < [llength $v1]} {incr i} {lappend s [expr [lindex $v1 $i] + [lindex $v2 $i]]}
    } else {set s -1}
    return $s
}
proc Vec_Mult {v1 v2} {
    set s ""
    if {([llength $v1] == 1) && ([llength $v2] == 1)} {
        set s [expr $v1 * $v2]
    } elseif {([llength $v1] == 1) && ([llength $v2] > 1)} {
        foreach i $v2 {lappend s [expr $v1 * $i]}
    } elseif {([llength $v1] > 1) && ([llength $v2] == 1)} {
        foreach i $v1 {lappend s [expr $v2 * $i]}
    } elseif {([llength $v1] > 1) && ([llength $v2] == [llength $v1])} {
        for {set i 0} {$i < [llength $v1]} {incr i} {set s [expr $s + [lindex $v1 $i] * [lindex $v2 $i]]}
    } else {set s -1}
    return $s
}
proc Vec_Subtract {v1 v2} {
    return [Vec_Add $v1 [Vec_Mult -1 $v2]]
}
proc Vec_Cross {v1 v2} {
    if {([llength $v1] == 3) && ([llength $v2] == 3)} {
	set x_vec [expr {[lindex $v1 1] * [lindex $v2 2] - [lindex $v1 2] * [lindex $v2 1]}]
	set y_vec [expr {[lindex $v1 2] * [lindex $v2 0] - [lindex $v1 0] * [lindex $v2 2]}]
	set z_vec [expr {[lindex $v1 0] * [lindex $v2 1] - [lindex $v1 1] * [lindex $v2 0]}]
	return "$x_vec $y_vec $z_vec"
    } else {
	return -1
    }
}
proc Vec_Sum {v} {
    set sum 0
    foreach elem $v {set sum [expr {$sum + $elem}]}
    return $sum
}
proc Vec_Mean {v} {
    set sum [lindex $v 0]
    for {set i 1} {$i < [llength $v]} {incr i} {set sum [Vec_Add $sum [lindex $v $i]]}
    set mean [Vec_Mult [expr 1.0 / [llength $v]] $sum]
    return $mean
}
proc Vec_Unit {v} {
    return [Vec_Mult [expr {1.0 / sqrt([Vec_Mult $v $v])}] $v]
}
proc Vec_Round {v} {
    set result ""
    foreach elem $v {lappend result [expr round($elem)]}
    return $result
}
proc Vec_Dist {v1 v2} {
    set dist 0
    if {([llength $v1] > 1) && ([llength $v2] == [llength $v1])} {
	set diff_sum 0
	for {set i 0} {$i < [llength $v1]} {incr i} {set diff_sum [expr $diff_sum + pow([lindex $v1 $i] - [lindex $v2 $i],2)]}
	set dist [expr sqrt($diff_sum)]
    } else {set dist -1}
    return $dist
}
proc Transpose {v} {
    set num_elem [llength $v]
    set vec_len [llength [lindex $v 0]]
    set s2 ""
    for {set i 0} {$i < $vec_len} {incr i} {
	set s1 ""
	for {set j 0} {$j < $num_elem} {incr j} {
	    lappend s1 [lindex $v $j $i]
	}
	lappend s2 $s1
    }
    return $s2
}
proc Matrix_Mult {m1 m2} {
    #check if the dimensions of m1 and m2 are compatible
    set m1_r_dim [llength $m1]
    set m1_c_dim [llength [lindex $m1 0]]
    set m2_r_dim [llength $m2]
    set m2_c_dim [llength [lindex $m2 0]]
    if {$m1_c_dim != $m2_r_dim} {return -1}
 
    set m2_t [Transpose $m2]
    set m ""
    foreach row $m1 {
	set m_row ""
	foreach column $m2_t {
	    set m_row [lappend m_row [Vec_Mult $row $column]]
	}
	set m [lappend m $m_row]
    }
    return $m
}
proc Vec_Rot {v u a} {
    if {([llength $v] != 3) || ([llength $u] != 3) || ([llength $a] != 1)} {return -1}

    set symm ""
    foreach i {0 1 2} {
	set symm_row ""
	foreach j {0 1 2} {
	    set symm_row [lappend symm_row [expr {[lindex $u $i] * [lindex $u $j]}]]
	}
	set symm [lappend symm $symm_row]
    }
    set skew "{0 -[lindex $u 2] [lindex $u 1]} {[lindex $u 2] 0 -[lindex $u 0]} {-[lindex $u 1] [lindex $u 0] 0}"
    set unit "{1 0 0} {0 1 0} {0 0 1}"

    set mat ""
    for {set i 0} {$i <= 2} {incr i} {
	set symm_row [Vec_Mult [expr {1 - cos($a)}] [lindex $symm $i]]
	set skew_row [Vec_Mult [expr {sin($a)}] [lindex $skew $i]]
	set unit_row [Vec_Mult [expr {cos($a)}] [lindex $unit $i]]
	set mat [lappend mat [Vec_Add [Vec_Add $symm_row $skew_row] $unit_row]]
    }

    return [Matrix_Mult $mat $v]
}
proc Subsets {v} {
    set len_sub [expr pow(2, [llength $v])]
    set sub ""
    for {set i 1} {$i < $len_sub} {incr i} {
        binary scan [binary format s $i] b16 bin_str
        set bin_str
        set a ""
        for {set j 0} {$j < [string length $bin_str]} {incr j} {
            if {[string index $bin_str $j] == "1"} {lappend a [lindex $v $j]}
        }
        #add the subset length so that the list can later be sorted by size.
        set len [llength $a]
        lappend sub "$len $a" 
    }
    set sub [lsort $sub]
    set s ""
    foreach elem $sub {lappend s [lrange $elem 1 end]}
    return $s
}
proc NSubsets {v n} {
    set s [Subsets $v]
    set len [llength $v]
    set i_start [expr [Bin_Coeff_Sum $len [expr $n - 1]] - 1]
    set i_end [expr [Bin_Coeff_Sum $len $n] - 2]
    return [lrange $s $i_start $i_end]
}
proc Line_Pnt_Intersection {lin_pnt lin_dir pnt} {
    return [Vec_Subtract $lin_pnt [Vec_Mult $lin_dir [Vec_Mult [Vec_Subtract $lin_pnt $pnt] $lin_dir]]]
}
proc Fit_Line {p} {
    set x ""; set y ""; set xy ""; set xx ""; set yy ""
    foreach elem $p {
		set x [lappend x [lindex $elem 0]]
		set y [lappend y [lindex $elem 1]]
		set xy [lappend xy [expr [lindex $elem 0] * [lindex $elem 1]]]
		set xx [lappend xx [expr [lindex $elem 0] * [lindex $elem 0]]]
		set yy [lappend yy [expr [lindex $elem 1] * [lindex $elem 1]]]
    }
    set n [llength $p]
    set a [expr ([Vec_Sum $y] * [Vec_Sum $xx] - [Vec_Sum $x] * [Vec_Sum $xy]) / ($n * [Vec_Sum $xx] - pow([Vec_Sum $x],2))]
    set b [expr ($n * [Vec_Sum $xy] - [Vec_Sum $x] * [Vec_Sum $y]) / ($n * [Vec_Sum $xx] - pow([Vec_Sum $x],2))]
    return "$a $b"
}
proc Fit_Line_3d {p} {
    set p_trans [Transpose $p]
    set coord_pnts ""
    foreach coord $p_trans {
		set coord_pnts_elem ""
		for {set i 0} {$i < [llength $coord]} {incr i} {
			set coord_pnts_elem [lappend coord_pnts_elem "[expr $i + 1] [lindex $coord $i]"]
		}
		set coord_pnts [lappend coord_pnts $coord_pnts_elem]
    }
    set vec ""
    foreach pnts $coord_pnts {
		set eq [Fit_Line $pnts]
		set vec [lappend vec [lindex $eq 1]]
    }
    set vec [Vec_Unit $vec]
    set origin [Vec_Mean $p]
    return [list $vec $origin]
}
proc Fit_Plane_3pt {p} {
    if {([llength $p] != 3) && ([llength [lindex $p 0]] != 3)} {return -1}

    set norm [Vec_Unit [Vec_Cross [Vec_Subtract [lindex $p 1] [lindex $p 0]] [Vec_Subtract [lindex $p 2] [lindex $p 0]]]]
    set orig [Vec_Mean $p]
    
    #make sure the maximum element of norm is always positive.
    foreach elem $norm {
	set abs_norm [lappend abs_norm [expr abs($elem)]]
    }
    set abs_max_elem [lindex [lsort -real $abs_norm] end]
    
    if {[lsearch $norm $abs_max_elem] == -1} {set norm [Vec_Mult -1 $norm]}
    
    return "{$norm} {$orig}"
}
proc Mean_No_Outliers {points lim} {
	# Find the mean for a given set (point) disregarding the outliers, 
	# where the outliers are points that are more than a certain distance
	# (lim) away from the calculated mean.  The mean is calculated for the
	# largest subseset that contains no outliers.
	
	# add an index to each measured point to keep track of the measurement 
	# {p1 p2 ...} -> {{ 1 p1} {2 p2} ...}.
    set indexed_points ""
    for {set i 1} {$i <= [llength $points]} {incr i} {
	set indexed_points [lappend indexed_points "$i {[lindex $points [expr $i - 1]]}"]
    }
    
    # create all possible subsets of the measured set and divide them into 
    # groups based on their size. 
    set point_mean ""
    for {set i 1} {$i <= [llength $points]} {incr i} {
	set indexed_point_subs [NSubsets $indexed_points $i]
	
	# After the subsets have been created separate the index and the measurement 
	# into two arrays. Example: for subsets of size 2 you will have 
	# {{1 p1} {2 p2} {3 p3} ...} -> ({{1 2} {1 3} {2 3}} & {{p1 p2} {p1 p3} {p2 p3} ...}
	set index_subs ""; set point_subs ""
	foreach i_1 $indexed_point_subs {
	    set index_subs_2 ""; set point_subs_2 ""
	    foreach i_2 $i_1 {
		set index_subs_2 [lappend index_subs_2 [lindex $i_2 0]]
		set point_subs_2 [lappend point_subs_2 [lindex $i_2 1]]
	    }
	    set index_subs [lappend index_subs $index_subs_2]
	    set point_subs [lappend point_subs $point_subs_2]
	}
	
	# for each subset of size i calculate the mean and the residuals for all the points
	set new_point_subs ""
	for {set j 0} {$j < [llength $point_subs]} {incr j} {
	    set mean [Vec_Mean [lindex $point_subs $j]]
	    set dist ""
	    foreach elem $points {
		set dist [lappend dist [expr 1000 * [Vec_Dist $elem $mean]]]
	    }
	    set mean_dist [Vec_Mean $dist]
	    set new_point_subs [lappend new_point_subs "$mean_dist {[lindex $index_subs $j]}"]
	}
	# sort the entries according to the average distance from the points to their average.
	set new_point_subs [lsort $new_point_subs]

	# for each group of subsets of length i find the one with the smallest mean residual.
	set best_index [lindex $new_point_subs 0 1]
	set best_subset ""
	foreach elem $best_index {
	    set best_subset [lappend best_subset [lindex $points [expr $elem - 1]]]
	}

	# in the best case determine whether the measurements are within the allowed 
	# range of the mean. 
	set best_mean [Vec_Mean $best_subset]
	set best_dist ""
	set best_pass_var ""
	foreach elem $best_subset {
	    set best_dist [lappend best_dist [expr 1000 * [Vec_Dist $elem $best_mean]]]
	    if {[lindex $best_dist end] > $lim} {
		set best_pass_var [lappend best_pass_var "fail"]
	    } else {
		set best_pass_var [lappend best_pass_var "pass"]
	    }
	}

	# the mean will be calculated from the largest subset that will not produce 
	# failed mesurements
	if {[lsearch $best_pass_var "fail"] == -1} {
	    set point_mean $best_mean
	}
    }

    return $point_mean
}
#------------------------------END MATH ROUTINES------------------------------------------#


return 1

----------Begin Help----------

PXC Calibrator
=================

Copyright 2004-2012 Paul Keselman, Brandeis University
Copyright 2009 Kevan Hashemi, Brandeis University


Introduction
------------

The PXC Calibrator determines the optical properties of proximity cameras. A
"proximity camera" is a camera designed and built for use in the ATLAS end-cap
muon alignment system. The cameras are cylindrical and mount in a v-slot with a
pin to locate them along their axis. The v-slot and the pin define a local
coordinate system, and the PXC Calibrator determines the optical properties of
the camera in terms of this coordinate system. We describe the camera optics
with seven real-valued parameters. The values of these parameters are the
camera`s "calibration constants".

The PXC Calibrator takes images with the camera, analyzes them, and uses the
results of image analysis to calculate the calibration constants. It prints the
calibration constants to the screen, but does not save them to disk. Instead of
saving the calibration constants, the PXC Calibrator stores the results of image
analysis, and a description of the apparatus you used to obtain the images. Each
camera calibration appears as a separate entry in a "calibration database" file.
 The Recalculate button tells the PXC Calibrator to read all the entries in the
calibration database and re-calcualte the calibration constants that fit each
entry.

Each camera has seven calibration constants. Here they are printed on a single
line, along with the camera serial number and the date upon which the
calibration measurements took place.

20MABNDG000800 20060804110626 0.1008 -0.1638 9.719 2.2663 2.7856 94.1320 -30.3022

The first word is the device serial number, followed by a time stamp that gives
the year, month, and time. The next three parameters are the x, y, and z
coordinates of the camera "pivot point". In our optical models of the proximity
camera, all rays pass through the pivot point. The x and y coordinate origin of
the v-slot lies at the nominal center of the proximity camera tube. The lens is
centered on the tube also, so we see that the pivot point position in the
example above is within a fraction of a millimeter of the camera axis. The
z-coordinate is with respect to the pin against which we press the camera when
we mount it. The next two parameters are the x and y direction of the camera
axis, in milliradians. The optical axis is defined by the line between the
effective center of the image sensor and the pivot point. The sixth calibration
constant is the distance from the pivot point to the effective center of the
image sensor. The final parameter is the rotation of the sensor about the
z-axis. We would like to tell you for certain which direction is positive
rotation, but at the time or writing, we`d just be making it up so we won`t
bother.

If you would like to read more about proximity pameras and their calibration
constants, we invite you to try this document, which describes the entire ATLAS
end-cap Muon Alignment system in detail, including the proximity cameras and the
proximity masks they are designed to look at The Optical Alignment System of the
ATLAS Muon Spectrometer Endcaps, which you will find at the following location.

http://alignment.hep.brandeis.edu/ATLAS/ECA.pdf

To calibrate a proximity camare, we place it in a calibration stand. The
"calibration stand" provides many sets of balls upon which we can mount
proximity masks. Each set of balls is numbered. A "proximity mask" is a
chessboard pattern, also called a "rasnik mask", illuminated by diffuse infrared
light. You will find a discussion of rasnik masks and the analysis of chessboard
patterns in Rasnik Analysis, which you will find at the following location.

http://alignment.hep.brandeis.edu/Devices/RASNIK/Analysis.html

We measure the calibration stand with our CMM (computer measuring machine) so
that we know the location of the v-slot and its locating pin, and the locations
of all the balls upon which we will mount a master mask. A "master mask" is one
we have calbrated by a separate procedure, so that we know the location of its
rasnik pattern in the local coordinate system defined by its own three mounting
balls.

Procedure
---------

We place the master mask in various positions on the calibration stand, and take
images of the mask with the camera. The PXC Calibrator analyzes the rasnik
pattern in each image, combine the results of analysis with the known position
of the mask and camera on the stand, and so deduce the seven camera calibration
constants. In theory, we need only two mask positions to obtain our seven
parameters. Each position provides us with four measurements: x, y, rotation,
and magnification. But the PXC Calibrator asks us to place the mask in seven
or eight positions, so as to obtain redundant measurements. The redundancy
allows us to identify errors caused by bad mask mounting, and gives us better
accuracy.

An abundance of mask measurements does not, however, provide us with immunity to
bad camera mounting. Our experience has been that it takes a practice to mount a
camera in a v-slot reliably. The PXC Calibrator asks the user to mount the
camera twice with the mask in a fixed location. If the mask measurements agree
well enough, we assume the mounting is a good one, and proceed to moving the
mask.

The PXC Calibrator needs to know the positions of all the balls on the
calibration stand, the location of the v-slot, and the calibration constants of
the master mask in order to calculate the camera calibration constants. It
expects to find these positions in a file called apparatus_database.txt. The
first step in the calibration procedure is to choose for the PXC Calibrator a
"database directory". We choose the directory by pressing Config and Choose
Database Directory in the configuration panel. The PXC Calibrator will look
in this directory for apparatus_database.txt. Later, at the end of each camera
calibration, the PXC Calibrator will append its measurements to a file called
calibration_database.txt.

After we specify the database directory, press Execute, and the PXC
Calibrator will load the apparatus measurements. It lists the available
calibration stands and master masks in its menu buttons. The PXC Calibrator
needs to know which calibration stand it`s going to be working with, and which
master mask. At the time of writing, there are two stands. They are called
CSL1CMA3MMB1 and CSS1CMA3MMA1. There are two master masks called D0011 and
D0012. We specify the calibration stand and the master mask with the
corresponding menu buttons.

The PXC Calibrator`s job is complicated by the fact that proximity cameras
come in many different focal ranges. The mask is in sharpest focus when the
distance from the v-slot pin to the mask is at "MPIN_nom" (mask-to-pin nominal).
The value of MPIN_nom varies from 145 mm to 625 mm for the ATLAS proximity
cameras. The mask must be in focus for effective calibration, so the calibration
mask positions are best placed on either side of the MPIN_nom. The PXC
Calibrator must know the focal range of any camera it calibrates so that it can
choose the sets of balls upon which the master mask should be mounted. Each
camera has a fourteen-digit identity label of the form 20MABNDG00xxxx. The last
four digits are the "serial number" of the camera. The data section of the
PXC Calibrator script provides a "camera table" relating serial numbers to
the properties of various camera types. Each type of camera has its own range of
serial numbers.

So the next step in the calibration procedure is to enter the camera serial
number and an operator name. Press Execute and the PXC Calibrator looks up
the serial number in its camera table. It tells we what type of camera you are
using and instructs us to mount it on the stand by specifying the number of a
set of balls on the stand. We mount the camera in the v-slot and mount the mask
on the numbered set of balls.

The Camare Calibrator tells us to and press Execute to take an image. At this
point, the PXC Calibrator needs to be configured correctly to acquire an
image from the camera of the rasnik mask. The PXC Calibrator uses the Rasnik
Instrument to acquire the image, and you will find a description of the Rasnik
Instrument in the Rasnik section of our LWDAQ User Manual, at the following
location.

http://alignment.hep.brandeis.edu/Electronics/LWDAQ/Manual.html

The PXC Calibrator also records temperature in the lab using the Thermometer
Instrument, which you`ll find described in the Thermometer section of the same
manual. The PXC Calibrator uses the Rasnik and Thermometer parameters defined in
its "configuration array" to guide Rasnik and Thermometer acquisition. We press
the Configure button and we see all the configuration array elements displayed
with their values. These elements include the database directory, the apparatus
database file name (which we have assumed is apparatus_database.txt) and all the
data aquisition parameters. Our hope is that the element names are
self-explanatory.

We set up the data acquisition parameters and press Execute in the main PXC
Calibrator panel. We wait and see what happens. Eventually we will get an image
displayed or an error message. Maybe it`s a good image, maybe it`s not. We open
the Rasnik Instrument from the Instrument menu of LWDAQ. We press Loop. We
adjust the instrument until we see a mask. We put our hand in front of the mask
to see if the image shows our fingers. We transfer the correct instrument
parameters into the PXC Calibrator`s configuration array.

We press Save in the Configuration Panel. Now we have saved all the PXC
Calibrator parameters, including the database directory and all acquisition
parameters. Next time we open the PXC Calibrator, it will restore our values.

The PXC Calibrator asks us to re-mount the camera and press Execute again. We do
this. If the calibrator is satisfied with the second measurement, it tells us to
move the mask to another set of balls and press Execute again. This procedure
continues through a range of mask positions until the calibrator is satisfied.
It asks you to press Execute to calculate the calibration constants. You choose
to store the new measurements and parameters by pressing the Store button. The
calibrator stores the measurements to calibration_database.txt in the database
directory.

The Recalculate button allows you to re-calculate the calibration constants of
all the cameras whose calibration measurements are stored in your calibration
database.


Camera Table
------------

To examine or edit the Camera Table, which relates camera serial numbers to
camera properties, open the PXC_Calibrator.tcl file with a text editor and
scroll down to the Begin Data line. You will see a table with eight columns. The
first two columns give the low an high values of the serial number range
corresponding to a particular camera type. The third columns gives the camera
type`s name. The A_nom column gives the nominal distance from the camera lens to
the pin in the v-slot. The A_set column gives the actual distance between the
lens and the pin as determined after the first few cameras of this type have
been constructed. The A_set will differ from the A_nom because the lenses we buy
do not match their specification exactly, and we move the lens in the tube until
the camera is in sharp focus at its nominal focal range. This nominal focal
range is expressed in MPIN_nom, which is the nominal range from the v-slot pin
to the mask surface. The PXC Calibrator uses MPIN_nom to determine the center
of the range of mask positions over which it should perform its calibration.

The MPIN_set and M_meas columns give us a combination of mask-pin distance and
mask image magnification. This combination, together with A_set, allows the
PXC Calibrator to calculate the expected mask image magnification at all mask
ranges. The PXC Calibrator uses the mask magnification to check that we have
placed the mask on the correct set of balls, that the camera is of the correct
type, and that the mask has the correct square size.  The distinction between
MPIN_nom and MPIN_set is that we assume the camera will be used at ranges around
MPIN_nom, but we calculate magnifications using MPIN_set and M_meas.

You will find a drawing of the generic Proximity Camera pipe with lens holder,
image sensor, and circuit board, at the following location. This drawing is for
our EES and EEL camera types.

http://alignment.hep.brandeis.edu/Devices/Proximity/Drawings/EE_PROXY_CAMERA_ASSY.pdf

Some cameras have MPIN_nom too long for the existing calibration stands. In this
case, we cannot enter the correct value of MPIN_nom, but instead must enter a
value that lies within the range of the calibration stand. The PXC Calibrator
will then pick mask positions arount the false MPIN_nom, and proceed with the
calibration. Even though the calibration takes place at ranges outside the
designed operating range of the camera, such long-focal-range cameras have such
a large depth of field that the mask will still be in focus at ranges ten or
twenty percent shorter than its true focal range. The calibration will proceed
smoothly and produce a valid result.


Mouting the Camera
------------------

Mounting the camera in the v-slot reliably takes a little practice. Start by
attaching the camera to the mount so that it is secured to the mount but still
free to move. Tighten the hold-down screw just far enough so that the movment of
the camera is constrained only by the two positioning pins. Slide the camera
forward against the z-pin. Rotate it counter-clockwise against the y-pin. Apply
minimal pressure to the camera body and none to the screw except for the weight
of the screwdriver. Use a torque screwdriver set to twenty ounce-inches (14
mN/m). Do not tighten any more than twenty ounce-inces. Turn the torque
screwdriver until you hear it click three times. Remove the screwdriver.



----------End Help----------

----------Begin Data----------
Low		Hi			Camera				A_nom	A_set	MPIN_nom	MPIN_set	M_meas
G0020	G0039		EIL1_SS_CH_B		18.20	15.23	487.81		490.0		0.347
G0040	G0059		EIL1_LS_CH_B		18.21	15.23	487.89		490.0		0.347
G0060	G0079		EIL1_LS_CH_CH		36.00	33.75	278.87		274.9		0.342
G0080	G0099		EIS1_SS_CH_B		51.59	50.49	167.31		164.7		0.343
G0100	G0119		EIS1_LS_CH_B		38.59	37.22	180.33		184.71		0.339
G0140	G0159		EIL2_SS_CH_B		 7.63	4.56	472.01		469.9		0.323
G0120	G0139		EIL2_LS_CH_B		 7.63	4.56	472.02		469.9		0.323
G1400	G1419		EIL2_LS_CH_CH		65.85	64.17	242.30		244.7		0.361
G0180	G0199		EIS2_SS_CH_B		33.34	32.17	196.63		194.17		0.318
G0200	G0219		EIS2_LS_CH_B		33.33	32.17	196.59		194.17		0.318
G0220	G0229		EI4_1,9,11_SS_CH_B	40.07	37.65	361.98		364.2		0.342
G0230	G0239		EI4_1,9,11_LS_CH_B	28.42	26.11	339.45		344.2		0.331
G0240	G0249		EI4_3,5,13_SS_CH_B	39.05	36.72	354.51		354.2		0.357
G0250	G0259		EI4_3,5,13_LS_CH_B	38.74	36.20	352.35		354.2		0.359
G0260	G0279		EML1_SS_CH_B		25.75	23.20	436.95		435.7		0.339
G0280	G0299		EML1_LS_CH_B		24.80	23.29	438.40		439.9		0.332
G0300	G0319		EML1_SS_CH_CH		54.34	56.96	201.32		194.7		0.386
G0320	G0339		EMS1_SS_CH_B		33.38	32.65	197.05		194.7		0.315
G0340	G0359		EMS1_LS_CH_B		33.38	32.65	199.11		194.7		0.314
G0360	G0379		EML2_SS_CH_B		22.20	20.35	439.54		435.7		0.338
G1380	G1399		EML2_LS_CH_B		 8.58	6.75	500.00		495.8		0.291
G0380	G0399		EML2_LS_CH_B		 8.58	6.75	500.00		495.8		0.291
G0400	G0419		EML2_LS_CH_CH		50.33	49.02	260.79		264.8		0.273
G0420	G0439		EMS2_SS_CH_B		32.73	31.70	193.11		194.0		0.321
G0440	G0459		EMS2_LS_CH_B		32.74	31.70	192.21		194.0		0.321
G0460	G0479		EML3_SS_CH_B		28.01	25.70	500.94		505.9		0.333
G0480	G0499		EML3_LS_CH_B		23.97	21.88	504.65		505.9		0.335
G1360	G1379		EML3_LS_CH_CH		65.96	63.35	242.98		244.7		0.364
G0520	G0539		EMS3_SS_CH_B		32.78	31.35	192.54		194.0		0.322
G0540	G0559		EMS3_LS_CH_B		32.74	31.70	192.22		194.0		0.321
G0560	G0579		EML4_SS_CH_B		 7.53	4.65	538.18		535.9		0.335
G0580	G0599		EML4_LS_CH_B		 7.38	4.87	541.55		540.0		0.331
G0600	G0619		EML4_LS_CH_CH		64.48	62.00	262.20		264.0		0.335
G0620	G0639		EMS4_SS_CH_B		46.41	45.58	172.64		174.7		0.332
G0640	G0659		EMS4_LS_CH_B		42.38	40.89	176.40		174.0		0.345
G0660	G0679		EML5_SS_CH_B		 7.03	4.42	538.68		535.9		0.335
G0680	G0699		EML5_LS_CH_B		 7.03	4.95	541.48		545.9		0.325
G0700	G0719		EML5_LS_CH_CH		26.06	24.52	329.27		334.1		0.330
G0720	G0729		EMS5_SS_CH_B(A)		36.88	35.71	181.93		184.7		0.334
G0730	G0739		EMS5_SS_CH_B(C)		59.21	58.17	145.93		144.7		0.373
G0740	G0759		EMS5_LS_CH_B		32.75	30.77	186.70		184.7		0.343
G0760	G0779		EOL1_SS_CH_B		 7.14	4.00	470.16		470.0		0.326
G0780	G0799		EOL1_LS_CH_B		27.55	26.9	489.28		484.8		0.335
G0800	G0819		EOL1_SS_CH_CH		26.98	24.4	287.73		284.2		0.341
G0820	G0839		EOS1_SS_CH_B		65.65	63.5	240.98		243.9		0.364
G0840	G0859		EOS1_LS_CH_B		45.43	42.5	264.45		264.8		0.348
G0860	G0879		EOL2_SS_CH_B		14.86	14.0	446.42		450.0		0.335
G0880	G0899		EOL2_LS_CH_B		 7.05	4.60	466.91		464.6		0.322
G0900	G0919		EOL2_SS_CH_CH		32.02	29.8	283.04		283.9		0.334
G0920	G0939		EOS2_SS_CH_B		66.78	65.7	259.45		263.8		0.328
G0940	G0959		EOS2_LS_CH_B		46.09	44.7	223.51		223.8		0.338
G0960	G0979		EOL3_SS_CH_B		13.17	10.2	450.85		445.1		0.340
G0980	G0999		EOL3_LS_CH_B		 7.03	4.57	470.18		464.5		0.321
G1000	G1019		EOL3_LS_CH_CH		54.64	N/A		213.98		N/A			N/A
G1020	G1039		EOS3_SS_CH_B		46.04	42.7	207.56		204.8		0.392
G1040	G1059		EOS3_LS_CH_B		45.43	44.4	264.45		263.8		0.339
G1060	G1079		EOL4_SS_CH_B		11.97	8.72	516.63		514.8		0.337
G1080	G1099		EOL4_LS_CH_B		 8.63	6.50	532.62		535.9		0.331
G1100	G1119		EOL4_LS_CH_CH		45.15	41.3	262.30		263.8		0.353
G1120	G1139		EOS4_SS_CH_B		45.43	44.4	264.45		263.8		0.339
G1140	G1159		EOS4_LS_CH_B		45.43	44.4	264.45		263.8		0.339
G1160	G1179		EOL5_SS_CH_B		15.94	12.7	552.38		554.8		0.334
G1180	G1199		EOL5_LS_CH_B		 7.07	5.70	566.11		564.8		0.327
G1200	G1219		EOL5_SS_CH_CH		45.15	41.3	262.30		263.8		0.353
G1220	G1239		EOS5_SS_CH_B		45.43	43.0	264.45		263.8		0.345
G1240	G1259		EOS5_LS_CH_B		53.72	51.4	307.96		303.5		0.349
G1260	G1279		EOL6_SS_CH_B		 7.09	4.70	584.58		584.7		0.316
G1280	G1299		EOL6_LS_CH_B		 7.69	4.45	599.67		595.2		0.308
G1300	G1319		EOL6_LS_CH_CH		27.53	25.8	287.58		283.8		0.338
G1320	G1339		EOS6_SS_CH_B		53.72	51.4	307.96		303.5		0.349
G1340	G1359		EOS6_LS_CH_B		53.72	51.4	307.96		303.5		0.349
G1420	G1499		EEL					15.6	15.1	600.00		600.0		0.291
G1500	G1579		EES					46.7	44.3	190.00		190.0		0.320
----------End Data----------