# Copyright (C) 2003 Ed Diehl, University of Michigan
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
# Special version of chamber_checker for testing UM chambers.
# Differences with regular chamber_checker denoted with
# comment labelled "UM_SPECIAL"
#
#
proc Chamber_Checker_init {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
  upvar #0 Chamber_Checker_data ccdata
  global LWDAQ_Info
	
  array unset info
  array unset config
  array unset ccdata

#  This is a flag to indicate if the granite ref. file has been read.
  set ccdata(exists) 0

# UM_SPECIAL - Call this version Chamber_Checker_UM
  set info(name) "Chamber_Checker"
  set info(version) 2.7
	
  LWDAQ_tool_startup $info(name)

  set info(state) "Idle"
  set info(description) "No Image"
  set info(text) ""
	
  foreach a {1} {
    set info(diagnostic_ok_$a) 0
    set info(diagnostic_result_$a) "ERROR: No image captured yet"
  }
  foreach a {1 2 3 4} {
    set info(rasnik_ok_$a) 0
    set info(rasnik_result_$a) "ERROR: No image captured yet"
  }
  foreach a {1 2 3 4} {
    set info(camera_ok_$a) 0 
    set info(camera_result_$a) "ERROR: No image captured yet"
  }
	
  set config(camera_min_threshold) 60
  set config(camera_max_threshold) 140
  set config(persistence_abort_ms) 3000
  set config(persistence_pause_ms) 1000
  set config(driver_addr) 141.211.101.63
#  set config(driver_addr) 129.64.37.79
  set config(driver_socket) 1
  set config(rasnik_intensify) exact
  set config(camera_intensify) exact
  set config(camera_image_left) 1

  set config(diagnostic_1_sensor_mux_socket) 1
  set config(diagnostic_1_source_mux_socket) 0
  set config(diagnostic_1_description) "Diagnostic: LWDAQ Power Supplies"

  set config(rasnik_1_sensor_mux_socket) 7
  set config(rasnik_1_source_mux_socket) 2
  set config(rasnik_1_flash_seconds) 0.02
  set config(rasnik_1_description) "Rasnik: Short-Side Camera, Short-Side Mask"       

  set config(rasnik_2_sensor_mux_socket) 7
  set config(rasnik_2_source_mux_socket) 1
  set config(rasnik_2_flash_seconds) 0.02
  set config(rasnik_2_description) "Rasnik: Short-Side Camera, Long-Side Mask"

  set config(rasnik_3_sensor_mux_socket) 8
  set config(rasnik_3_source_mux_socket) 1
  set config(rasnik_3_flash_seconds) 0.02
  set config(rasnik_3_description) "Rasnik: Long-Side Camera, Long-Side Mask"

  set config(rasnik_4_sensor_mux_socket) 8
  set config(rasnik_4_source_mux_socket) 2
  set config(rasnik_4_flash_seconds) 0.02
  set config(rasnik_4_description) "Rasnik: Long-Side Camera, Short-Side Mask"

  set config(camera_1_sensor_mux_socket) 3
  set config(camera_1_source_mux_socket) 3
  set config(camera_1_exposure_seconds) 0.01
  set config(camera_1_description) "Camera: Long Side, Readout End"

  set config(camera_2_sensor_mux_socket) 4
  set config(camera_2_source_mux_socket) 4
  set config(camera_2_exposure_seconds) 0.1
  set config(camera_2_description) "Camera: Short Side, Readout End"       

  set config(camera_3_sensor_mux_socket) 5
  set config(camera_3_source_mux_socket) 5
  set config(camera_3_exposure_seconds) 0.01
  set config(camera_3_description) "Camera: Long Side, High-Voltage End"       

  set config(camera_4_sensor_mux_socket) 6
  set config(camera_4_source_mux_socket) 6
  set config(camera_4_exposure_seconds) 0.01
  set config(camera_4_description) "Camera: Short Side, High-Voltage End"   
 
  if {[file exists $info(settings_file_name)]} {
    after 1 [list source $info(settings_file_name)]
  } 

  return ""    
}

proc Chamber_Checker_save {} {
  upvar #0 Chamber_Checker_info info
  LWDAQ_tool_save $info(name)
}

proc Chamber_Checker_help {} {
  upvar #0 Chamber_Checker_info info
  LWDAQ_tool_help $info(name)
}

proc Chamber_Checker_print {s} {
  upvar #0 Chamber_Checker_info info
  LWDAQ_print $info(text) $s
}

proc Chamber_Checker_configure {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
  set w $info(window)\.info
  if {[winfo exists $w]} {return ""}
  toplevel $w
  wm title $w "$info(name) Configuration Array"
  button $w.save -text "Save" -command Chamber_Checker_save
  pack $w.save
  frame $w.f1
  frame $w.f2
  pack $w.f1 $w.f2 -side left -fill y
  set config_list [array names config]
  set config_list [lsort -dictionary $config_list]
  set count 0
  set half [expr [llength $config_list] / 2]
  foreach i $config_list {
    incr count
    if {$count > $half} {set f f2} {set f f1}
    label $w.$f.l$i -text $i -anchor w
    entry $w.$f.e$i -textvariable Chamber_Checker_config($i) \
      -relief sunken -width 35
    grid $w.$f.l$i $w.$f.e$i -sticky news
  }
  return ""
}

proc Chamber_Checker_abort {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
	
  foreach i {Diagnostic Rasnik Camera} {
    global LWDAQ_info_$i
    set LWDAQ_info_$i\(control) "Stop"
  }
	
  set info(state) "Abort"
  after $config(persistence_abort_ms) \
  [list set Chamber_Checker_info(state) "Idle"]
}

proc Chamber_Checker_acquire {instrument n} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
  upvar #0 LWDAQ_config_$instrument iconfig
  upvar #0 LWDAQ_info_$instrument iinfo

  if {$info(state) == "Abort"} {return}
  set info(state) "Acquiring"
  set name [string tolower $instrument]\_$n

  set iconfig(daq_ip_addr) $config(driver_addr)
  set iconfig(daq_driver_socket) $config(driver_socket)
  set iconfig(daq_source_driver_socket) $config(driver_socket) 
  set iconfig(daq_mux_socket) $config($name\_sensor_mux_socket)
  set iconfig(daq_source_mux_socket) $config($name\_source_mux_socket)

  if {$instrument == "Rasnik"} {
    set iconfig(daq_flash_seconds) $config($name\_flash_seconds)
  }
  if {$instrument == "Camera"} {
    set iconfig(daq_exposure_seconds) $config($name\_exposure_seconds)
    set saved_left $iinfo(daq_image_left)
    set iinfo(daq_image_left) $config(camera_image_left)
  }

  set saved_lwdaq_config [lwdaq_config]
  lwdaq_config -text_name $info(text) 
  lwdaq_config -photo_name $info(photo)

  set result [LWDAQ_acquire $instrument]
  set result [lreplace [split $result] 0 0 "$instrument\_$n"]

  if {$info(state) != "Abort"} {
    if {$instrument == "Rasnik"} {
      lwdaq_draw $iconfig(memory_name) $info(photo) \
      -intensify $config(rasnik_intensify)
    }
    if {$instrument == "Camera"} {
      lwdaq_draw $iconfig(memory_name) $info(photo) \
      -intensify $config(camera_intensify)
    }
    if {$instrument == "Diagnostic"} {
      lwdaq_draw $iconfig(memory_name) $info(photo) -intensify none
    }
  }

  if {$instrument == "Camera"} {
    set iinfo(daq_image_left) $saved_left
  }
  eval "lwdaq_config $saved_lwdaq_config"
  set info(description) $config($name\_description)

  if {$info(state) == "Abort"} {return}
  set info(state) "Idle"
	
  return $result
}

proc Chamber_Checker_rasnik {n} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_data ccdata

  set result [Chamber_Checker_acquire Rasnik $n]
  set info(rasnik_result_$n) $result
  if {![LWDAQ_is_error_result $result]} {
    set info(rasnik_ok_$n) 1
#  Print results in format boxes
    set w $info(window)
    set ccdata(rasnik_x_$n) [lindex $result 1]
    set ccdata(rasnik_y_$n) [lindex $result 2]
    set magx [lindex $result 3]
    set magy [lindex $result 4]
    set mag  [expr { sqrt( ($magx*$magx + $magy*$magy)/2 ) } ]
    set ccdata(rasnik_mag_$n) [format "%.4f" $mag] 
    set ccdata(rasnik_tilt_$n) [lindex $result 5]
#  Print deviations from granite if granite data exists
    if { $ccdata(exists) == 1 } {
      foreach a { x y mag tilt } {
        set xd $ccdata([format "rasnik_%s_%s" $a $n])  
        set xg $ccdata([format "grasnik_%s_%s" $a $n])
        set var [format "rasnik_d%s_%s" $a $n]
        if { ($a=="x") || ($a=="y" ) } { 
          set gr $ccdata([format "grasnik_grad%s_%s" $a $n])
          set ccdata($var) [format "%8.1f" [expr { $gr*($xd - $xg) } ] ]
        } elseif { $a=="mag" } {
          set ccdata($var) [format "%8.4f" [expr { $xd - $xg } ] ]
        } else {
          set ccdata($var) [format "%8.3f" [expr { $xd - $xg } ] ]
        }
      }
    }
  } {
    set info(rasnik_ok_$n) 0
    Chamber_Checker_print $result	
  }

  return ""
}	

proc Chamber_Checker_camera {n} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
  set result [Chamber_Checker_acquire Camera $n]
  set info(camera_result_$n) $result
  if {![LWDAQ_is_error_result $result]} {
    set max [lindex $result 7]
    set min [lindex $result 8]
    if {($min < $config(camera_min_threshold)) && \
    ($max > $config(camera_max_threshold))} {
      set info(camera_ok_$n) 1
    } {
      append result " (ERROR: Inadequate intensity variation.)"
      set info(camera_ok_$n) 0
    }
  } {
    set info(camera_ok_$n) 0
  } 
  Chamber_Checker_print $result	
  return ""
}	

proc Chamber_Checker_diagnostic {n} {
  upvar #0 Chamber_Checker_info info
  set result [Chamber_Checker_acquire Diagnostic $n]
  set info(diagnostic_result_$n) $result
  if {![LWDAQ_is_error_result $result]} {
    set info(diagnostic_ok_$n) 1
  } {
    set info(diagnostic_ok_$n) 0
  } 
  Chamber_Checker_print $result	
  return ""
}	

proc Chamber_Checker_all {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config

# Disable diagnostic and PMO 
if { 0 } {
  foreach n {1} {
    Chamber_Checker_diagnostic $n
    if {$info(state) == "Abort"} {return}
    set info(state) "Pause"
    LWDAQ_wait_ms $config(persistence_pause_ms)
    if {$info(state) == "Abort"} {return}
  }
}
  foreach n {1 2 3 4} {
    Chamber_Checker_rasnik $n
    if {$info(state) == "Abort"} {return}
    set info(state) "Pause"
    LWDAQ_wait_ms $config(persistence_pause_ms)
    if {$info(state) == "Abort"} {return}
  }
if { 0 } {
  foreach n {1 2 3 4} {
    Chamber_Checker_camera $n
    if {$info(state) == "Abort"} {return}
    set info(state) "Pause"
    LWDAQ_wait_ms $config(persistence_pause_ms)
    if {$info(state) == "Abort"} {return}
  }
}
  set info(state) "Idle"
  return ""
}

proc Chamber_Checker_prolog {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
	
  set q $info(window)

  if {$q != ""} {
    if {[winfo exists $q]} {return ""}
    toplevel $q
    wm title $q "Prolog for $info(name) Version $info(version)"
  } {
    wm title . "Prolog for $info(name) Version $info(version)"
    destroy .frame
  }
	
  set w $q.prolog_frame
  frame $w
  pack $w -side top -fill x

  frame $w.f1 -borderwidth 9 -bg #54caea
  pack  $w.f1 -fill x
  frame $w.f2 -borderwidth 9  -bg #54caea
  pack  $w.f2 -fill x
  frame $w.f3 -borderwidth 9  -bg #54caea
  pack  $w.f3 -fill x
  frame $w.f4 -borderwidth 9  -bg #54caea
  pack  $w.f4 -fill x
	
# Create command buttons
  label $w.f1.lab -text "MDT Chamber RASNIK Readout\nEnter Chamber and Operator"   
  label $w.f2.lab -text "Chamber:"   
#  UM_SPECIAL Set chamber to EML5C15
# set default chamber_number
  set info(chamber_type) EML5
  set info(chamber_end)     C
  set info(chamber_number) 15
  tk_optionMenu $w.f2.chamber Chamber_Checker_info(chamber_type) EMS4 \
    EMS5 EML3 EML4 EML5
  tk_optionMenu $w.f2.end Chamber_Checker_info(chamber_end) A C
  tk_optionMenu $w.f2.number Chamber_Checker_info(chamber_number) \
    01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16
  label  $w.f3.lab  -text "Operator:"
#  UM_SPECIAL Set operator to Diehl   
  tk_optionMenu $w.f3.operator Chamber_Checker_info(chamber_operator) "Edward Diehl" "none" \
    "Alan Wilson" "Reza Farsian" "Zhengguo Zhou" "Li Zhou" "Helmut Schick"
  button $w.f4.ok -text OK -command [list set Chamber_Checker_info(prolog) 1] 
  label  $w.f4.lab -text ""  
	
#  Make garish colors
  $w.f1.lab      config -bg #54caea
  $w.f2.lab      config -bg #54caea
  $w.f3.lab      config -bg #54caea
  $w.f4.lab      config -bg #54caea
  $w.f2.chamber  config -bg #ef770e
  $w.f2.end      config -bg #ef770e
  $w.f2.number   config -bg #ef770e
  $w.f3.operator config -bg #ef770e
  $w.f4.ok       config -bg #26f713
	
#  Display the buttons
  pack $w.f1.lab
  pack $w.f2.lab $w.f2.chamber $w.f2.end $w.f2.number -side left
  pack $w.f3.lab $w.f3.operator -side left
  pack $w.f4.lab  -side left
  pack $w.f4.ok -side right 
	
# Wait until we get a valid operator name & valid chamber name: odd numbers for EML, even for EMS
  set done 0
  while {!$done} {
    set info(prolog) 0
    vwait Chamber_Checker_info(prolog)
# Deal with the fact that TCL treats 0X numbers as octal so 08 and 09 fail even/odd check
    if { $info(chamber_number) == "08" } { 
      set icheck 8 
    } elseif { $info(chamber_number) == "09" } { 
      set icheck 9 
    } else { 
      set icheck $info(chamber_number) 
    }
    set i [expr ($icheck/2)*2 ]
    if { ($info(chamber_type) == "EMS4")||($info(chamber_type) == "EMS5") } {
      if { $i != $icheck } {
        $w.f4.lab config -text "Invalid chamber number!" 
        continue
      }
    }
    if { ($info(chamber_type) == "EML3")||($info(chamber_type) == "EML4")\
      || ($info(chamber_type) == "EML5") } {
      if { $i == $icheck } {
        $w.f4.lab config  -text "Invalid chamber number!" 
        continue
      }
    }
    if { $info(chamber_operator) == "none" } {
      $w.f4.lab config  -text "Invalid operator name!" 
      continue
    }
    set done 1
  }

#  Format chamber name
  set info(chamber) [format "%s%s%s" $info(chamber_type) \
  $info(chamber_end) $info(chamber_number) ]

  if {$info(window) != ""} {destroy $info(window)} {destroy $w}
  return ""
}

proc Chamber_Checker_open {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_config config
	
  set w $info(window)

  if {$w != ""} {
    if {[winfo exists $w]} {return ""}
    toplevel $w
    wm title $w "$info(name) Version $info(version)"
  } {
    wm title . "$info(name) Version $info(version)"
  }
	
  set f1 $w.title_line
  frame $f1 -bg #54caea
  pack $f1 -side top -fill x
    
  label $f1.description -textvariable Chamber_Checker_info(description) -width 40 -bg #54caea
  pack $f1.description -side left
	
  label $f1.chamber -textvariable Chamber_Checker_info(chamber) -width 14 -relief ridge -bg #f4c73f
  pack $f1.chamber -side left
	
  label $f1.state -textvariable Chamber_Checker_info(state) -width 10 -bg #54caea
  pack $f1.state -side right
    
  set f2 $w.image_line
  frame $f2 -bg #54caea
  pack $f2 -side top -fill x
    
  set f2_i $f2.image_frame
  frame $f2_i -bg #54caea
#  pack $f2_i -side left -fill y
  pack $f2_i -side top 
  set info(photo) [image create photo -width 344 -height 244]
  label $f2_i.image -image $info(photo) -bg #54caea
  pack $f2_i.image -side top

#  The results frame is not used (?)
#  set f2_c $f2.results_frame
#  frame $f2_c -bg #54caea
#  pack $f2_c -fill y
	
  set f $w.f_raslab 
  frame $f -bg #54caea
  pack  $f -side top -fill x
  label $f.rasnik      -text "    Inplane"  -bg #54caea
  label $f.rasnik_x    -text "X (um)"  -width 9 -anchor c -bg #54caea
  label $f.rasnik_y    -text "Y (um)"  -width 9 -anchor c -bg #54caea
  label $f.rasnik_mag  -text "Mag"     -width 9 -anchor c -bg #54caea
  label $f.rasnik_tilt -text "Tilt"    -width 9 -anchor c -bg #54caea
  label $f.rasnik_delx -text "dX (um)" -width 9 -anchor c -bg #54caea
  label $f.rasnik_dely -text "dY (um)" -width 9 -anchor c -bg #54caea
  label $f.rasnik_delm -text "dMag"    -width 9 -anchor c -bg #54caea
  label $f.rasnik_delt -text "dTilt"   -width 9 -anchor c -bg #54caea
  pack $f.rasnik -side left 
  pack $f.rasnik_delt $f.rasnik_delm $f.rasnik_dely $f.rasnik_delx $f.rasnik_tilt \
       $f.rasnik_mag $f.rasnik_y $f.rasnik_x -side right
  
#  Make frames for inplane RASNIK buttons & data
#  Also init ccdata() array
  define_rasnik_labels 1 SS
  define_rasnik_labels 2 SD
  define_rasnik_labels 3 LS
  define_rasnik_labels 4 LD
	
# Frame for diagnostic & PMO buttons
  set   f3  $w.controls_line
  frame $f3 -bg #54caea
  pack  $f3 -side top -fill x
    
# Diagnostic button
  label $f3.dl -text "Diagnostic:" -bg #54caea
  pack $f3.dl -side left 
  checkbutton $f3.diagnostic_cb -variable Chamber_Checker_info(diagnostic_ok_1) -bg #54caea
  pack $f3.diagnostic_cb  -side left 
  button $f3.diagnostic_b -command [list Chamber_Checker_diagnostic 1] -bg #f2ef3c
  pack $f3.diagnostic_b  -side left 
	
# PMO buttons
  define_pmo_labels 4 HVS
  define_pmo_labels 3 HVL
  define_pmo_labels 2 ROS
  define_pmo_labels 1 ROL
  label $f3.cl -text "PMO:" -width 8 -bg #54caea
  pack $f3.cl -side right

# Comment line
  set f4 $w.comment_line
  frame $f4  -bg #54caea
  pack $f4 -side top -fill x
  label $f4.label -text "Comment:" -bg #54caea
  pack $f4.label -side left 
  entry $f4.comment -width 75 -relief sunken -textvariable Chamber_Checker_info(comment)
  pack $f4.comment -side left 

# Master Control Line
  set f5 $w.master_controls_line
  frame $f5  -bg #54caea
  pack $f5 -side top -fill x
    
  foreach a {All Abort Configure Save_Data Help} {
    set b [string tolower $a]
    button $f5.$b -text "$a" -command [list Chamber_Checker_$b]  -bg #0eef3b
    pack $f5.$b -side left -expand 1
  }

# Periodic data taking
  set info(periodic_on) 0
  set info(periodic_num) 0
  set info(pending_periodic_event) 0
  set info(period) 15
  set f $w.periodic
  frame $f -bg #f70909 -relief ridge -bd 5
  pack  $f -side top -fill x
  set f $w.periodic.in
  frame $f -bg #54caea
  pack  $f -side top -fill x

  label $f.label -text "Periodic Data Taking  "  -bg #54caea
  pack  $f.label -side left
  button $f.start -text "Start" -command [list Chamber_Checker_periodic] -bg #0eef3b -bd 5
  label $f.plabel -text "  Period (s):"  -bg #54caea
  entry $f.period -textvariable Chamber_Checker_info(period) -width 5 -relief sunken 
  pack  $f.start -side left
  pack  $f.plabel $f.period -side left
  label $f.nlabel -text "Events taken:"  -bg #54caea
  label $f.number -textvariable Chamber_Checker_info(periodic_num) -width 5 -relief sunken 
  pack  $f.number $f.nlabel -side right

# Scroll box	
  set info(text) [text $w.text -relief sunken \
    -border 2 -yscrollcommand "$w.scroll set" \
    -setgrid 1 -height 15 -width 80]
  if {[info tclversion] >= 8.4} {$info(text) configure -undo 1 -autosep 1}
  scrollbar $w.scroll -command "$info(text) yview"  -bg #00ff00
  pack $w.scroll -side right -fill y
  pack $info(text) -expand yes -fill both
  $info(text) tag configure red -foreground red
  LWDAQ_bind_command_key $info(text) b [list $info(text) delete 1.0 end]

  Chamber_Checker_print "$info(name) Version $info(version) \n"

# Read granite file
  Chamber_Checker_read_granite
  return ""
} 

####################################################################
#   Routine for defining RASNIK data text boxes
####################################################################
proc define_rasnik_labels { n l } {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_data ccdata
  
  set f $info(window).inplane_$n
  frame $f -bg #54caea
  pack  $f -side top -fill x

  checkbutton $f.check_ok -variable Chamber_Checker_info(rasnik_ok_$n) -bg #54caea
  pack $f.check_ok -side left 
  button $f.acq_button -text "$l" -width 3 -command [list Chamber_Checker_rasnik $n] -bg #e17d07
# Dark blue #1b0fc1
  pack $f.acq_button   -side left 
  label $f.rasnik_x     -textvariable Chamber_Checker_data(rasnik_x_$n)     -width 9 -anchor e -relief sunken
  label $f.rasnik_y     -textvariable Chamber_Checker_data(rasnik_y_$n)     -width 9 -anchor e -relief sunken
  label $f.rasnik_mag   -textvariable Chamber_Checker_data(rasnik_mag_$n)   -width 9 -anchor e -relief sunken
  label $f.rasnik_tilt  -textvariable Chamber_Checker_data(rasnik_tilt_$n)  -width 9 -anchor e -relief sunken
  label $f.rasnik_dx    -textvariable Chamber_Checker_data(rasnik_dx_$n)    -width 9 -anchor e -relief sunken -bg #fbff87
  label $f.rasnik_dy    -textvariable Chamber_Checker_data(rasnik_dy_$n)    -width 9 -anchor e -relief sunken -bg #fbff87
  label $f.rasnik_dmag  -textvariable Chamber_Checker_data(rasnik_dmag_$n)  -width 9 -anchor e -relief sunken -bg #fbff87
  label $f.rasnik_dtilt -textvariable Chamber_Checker_data(rasnik_dtilt_$n) -width 9 -anchor e -relief sunken -bg #fbff87
  pack $f.rasnik_dtilt $f.rasnik_dmag $f.rasnik_dy $f.rasnik_dx  $f.rasnik_tilt \
       $f.rasnik_mag $f.rasnik_y  $f.rasnik_x -side right

  set ccdata(rasnik_x_$n)     0
  set ccdata(rasnik_y_$n)     0
  set ccdata(rasnik_mag_$n)   0
  set ccdata(rasnik_tilt_$n)  0
  set ccdata(rasnik_dx_$n)    0
  set ccdata(rasnik_dy_$n)    0
  set ccdata(rasnik_dmag_$n)  0
  set ccdata(rasnik_dtilt_$n) 0

  return ""
}

# Define PMO buttons
proc define_pmo_labels { n l } {
  upvar #0 Chamber_Checker_info info

  set f $info(window).controls_line
  label $f.space_$n  -text "" -width 2 -bg #54caea
  pack  $f.space_$n -side right
  button $f.acq_button_$n -text "$l" -width 3 -command [list Chamber_Checker_camera $n] -bg #c10f89
  pack   $f.acq_button_$n -side right
  checkbutton $f.check_ok_$n -variable Chamber_Checker_info(camera_ok_$n) -bg #54caea
  pack        $f.check_ok_$n -side right 

  return ""
} 

#  Read Granite data file
proc Chamber_Checker_read_granite {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_data ccdata
  set missing_grad 1

  set w $info(window)

  set ufilename [format "../granite/%s_granite.txt" [string tolower $info(chamber)]]
  set filename [file join $ufilename]
  if [catch {open $filename r} fileID] {
    Chamber_Checker_print "ERROR: Cannot open $filename."
    return "-1"
  } 

  Chamber_Checker_print "Opened file $filename; data shown in yellow boxes"
  set ccdata(exists) 1
  while {[gets $fileID line] >= 0} {
#  Print comments to screen
     if { [lindex $line 0] == "COMMENT:" } {
       Chamber_Checker_print $line
     }
#  Find gradient data.  Note slick method with lsearch:  
#   if search for "+" fails use default value of -1
    if { ( [lindex $line 0] == "C"      ) && \
  	 ( [lindex $line 1] == "Spacer" ) } { 
      set n [lsearch { x SS SD LS LD } [lindex $line 2]]
      set ccdata(grasnik_gradx_$n) [lsearch { x + } [lindex $line 3]] 
      set ccdata(grasnik_grady_$n) [lsearch { x + } [lindex $line 4]] 
      set missing_grad 0
    }   
# Find RASNIK data by checking for a line of 12 words.
    if { [llength $line] == 12 } {
      set n [lsearch { x SS SD LS LD } [lindex $line 11]]
      if { $n < 5 } {
	set ccdata(grasnik_x_$n)    [lindex $line 1]
	set ccdata(grasnik_y_$n)    [lindex $line 2]
	set ccdata(grasnik_mag_$n)  [lindex $line 3]
	set ccdata(grasnik_tilt_$n) [lindex $line 4]
        set ccdata(rasnik_dx_$n)    $ccdata(grasnik_x_$n)
        set ccdata(rasnik_dy_$n)    $ccdata(grasnik_y_$n)
        set ccdata(rasnik_dmag_$n)  $ccdata(grasnik_mag_$n)
        set ccdata(rasnik_dtilt_$n) $ccdata(grasnik_tilt_$n)
      }  
    }
  }
  close $fileID
#  Print error if missing gradient info.
  if { $missing_grad } {
    Chamber_Checker_print "WARNING:  Missing inplane RASNIK gradient data in granite file."
    foreach n { 1 2 3 4 } {
      set ccdata(grasnik_gradx_$n) 1 
      set ccdata(grasnik_grady_$n) 1 
    }
  }
  return "0"
}   

#  Write data to a file
proc Chamber_Checker_save_data {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_data ccdata

# Check if have all the data we need.
  foreach n {1 2 3 4} {
    if { $ccdata(rasnik_x_$n) == 0 } {
      Chamber_Checker_print "ERROR: Missing data from inplane line [lindex {x SS SD LS LD} $n].  Please take the missing data"
      return "-1"
    }
#  UM_SPECIAL Disable checking of PMO data
if { 0 } { 
   if { $info(camera_ok_$n) == 0 } {
      Chamber_Checker_print "Missing data from PMO [lindex {x ROL ROS HVL HVS} $n].  Please take the missing data"
      return "-1" 
    }
} 
  }

  set w $info(window)

  set secs [clock seconds]
  set timestamp [clock format $secs -format "%Y_%m_%d_%H_%M_%S"]  
  set ufilename [format "../data/inplane_%s_%s.txt" $timestamp [string tolower $info(chamber)] ]
  set filename [file join $ufilename]
  if [catch {open $filename w } fileID] {
    Chamber_Checker_print "ERROR: Cannot open $filename."
    return "-1"
  } 

  Chamber_Checker_print "Wrote output file $filename\n"
  set timestamp [clock format $secs -format "%m/%d/%y %H:%M:%S"]  
  puts $fileID "C RASNIK LOG FILE $timestamp"
  puts $fileID "C Operator: $info(chamber_operator)"
  puts $fileID "C Chamber: $info(chamber)"
  if { [string length $info(comment) ] } {
    puts $fileID "COMMENT: $info(comment)"
  }
  puts $fileID "C Inplane data X Y mag tilt"
  foreach n {1 2 3 4} {
    puts -nonewline $fileID [lindex {x SS SD LS LD} $n]
    puts -nonewline $fileID "\t$ccdata(rasnik_x_$n)\t$ccdata(rasnik_y_$n)"
    puts            $fileID "\t$ccdata(rasnik_mag_$n)\t$ccdata(rasnik_tilt_$n)\t"
  }
  puts $fileID "C Deviations from granite"
  foreach n {1 2 3 4} {
    puts -nonewline $fileID [lindex {x SS SD LS LD} $n]
    puts -nonewline $fileID "\t$ccdata(rasnik_dx_$n)\t$ccdata(rasnik_dy_$n)"
    puts $fileID            "\t$ccdata(rasnik_dmag_$n)\t$ccdata(rasnik_dtilt_$n)"
  }
#  UM_SPECIAL do not print PMO info
#  puts $fileID "C PMO cameras ROL ROS HVL HVS 1=ok"
#  puts $fileID "\t$info(camera_ok_1)\t$info(camera_ok_2)\t$info(camera_ok_3)\t$info(camera_ok_4)"
  
  close $fileID
  return "0"
}

proc Chamber_Checker_periodic {} {
  upvar #0 Chamber_Checker_info info
  set w $info(window)
  if { $info(periodic_on) } { 
    set info(periodic_on) 0
    after cancel $info(pending_periodic_event)
    $w.periodic.in.start config -text "Start" -bg #0eef3b
  } else {
    set info(periodic_on) 1
    set info(periodic_num) 0
    $w.periodic.in.start config -text "Stop" -bg #f70909
    Chamber_Checker_periodic_open_file 
    Chamber_Checker_periodic_start
  } 
}

proc Chamber_Checker_periodic_start {} {
  upvar #0 Chamber_Checker_info info
  if { $info(period) < 10 } { set info(period) 10 }
  set period_ms [expr { 1000*$info(period) }]
  set info(pending_periodic_event) [after $period_ms Chamber_Checker_periodic_start]
  Chamber_Checker_all
  incr info(periodic_num)
  Chamber_Checker_periodic_save
}

#  Open file to write periodic data 
proc Chamber_Checker_periodic_open_file {} {
  upvar #0 Chamber_Checker_info info

#  Close file if had been open before
  if { [info exists info(fileID)] } { close $info(fileID) }

  set secs [clock seconds]
  set timestamp [clock format $secs -format "%Y_%m_%d_%H_%M_%S"]  
  set ufilename [format "../data/periodic_%s_%s.txt" $timestamp [string tolower $info(chamber)] ]
  set filename [file join $ufilename]
  if [catch {open $filename w } info(fileID)] {
    Chamber_Checker_print "ERROR: Cannot open $filename."
    return "-1"
  } 

  Chamber_Checker_print "Opened output file $filename\n"
  puts $info(fileID) "C Periodic RASNIK Data"
  puts $info(fileID) "C Operator: $info(chamber_operator)"
  puts $info(fileID) "C Chamber: $info(chamber)"
  puts $info(fileID) "C Period: $info(period) sec"
  if { [string length $info(comment) ] } {
    puts $info(fileID) "COMMENT: $info(comment)"
  }
}

#  Write periodic data to a file
proc Chamber_Checker_periodic_save {} {
  upvar #0 Chamber_Checker_info info
  upvar #0 Chamber_Checker_data ccdata

  set secs [clock seconds]
  puts -nonewline $info(fileID) "$info(periodic_num) "
  puts -nonewline $info(fileID) [clock format $secs -format "%Y%m%d %H%M%S"]  
  foreach n {1 2 3 4} {
    puts -nonewline $info(fileID) [format " %.1f %.1f"  $ccdata(rasnik_dx_$n) $ccdata(rasnik_dy_$n)]
    puts -nonewline $info(fileID) [format " %.4f" $ccdata(rasnik_dmag_$n)]
    puts -nonewline $info(fileID) [format " %.3f" $ccdata(rasnik_dmag_$n)]
  } 
  puts $info(fileID) ""
}

##################################################################
# NEVER put a procedure after this
##################################################################

foreach a {init prolog open} {
  catch {Chamber_Checker_$a} error_result
  if {$error_result != ""} {
    error "$error_result in Chamber_Checker_$a"
  }
}

return

                      Chamber_Checker.tcl
                      ===================

I.  Introduction.

This script permits readout of MDT chamber inplane RASNIK and PMO
cameras for chamber certification.  It has a nice display of RASNIK
measurement values and calculates deviations from measurements taken
on the granite chamber assembly table.  PMO images can be taken but
are not analyzed since the PMO cameras have nothing to look at in
chamber certification.  The program also writes out data file of
measurements.

o The granite data files are assumed to be in a directory ../granite
relative to the directory of the LWDAQ.tcl script.  The granite 
RASNIK measurements are read, the RASNIK mask gradient (orientation)
measurements are read, and any comments recorded in the original
granite files are written to the screen.

o The output data files are written to a directory ../data relative to
the LWDAQ.tcl directory. 

o The script has been tested on Mac, Linux, and Windows (XP) and works
on all, except the Windows version crashes a lot.

II.  Hardware.

Chamber Check is for use with the Alignment Multiplexer Box (AMB) on
an ATLAS End-Cap Muon Chamber. Connect a LWDAQ Driver to the root
socket on the AMB. You can use an eight-conductor straight-through
ethernet cable, or an LWDAQ cable.  The LWDAQ cable provides better
performance for long cables, but if your cable is less than five
meters long, you will not be able to tell the difference. Make sure
that the socket you use on the driver is the one indicated by the
driver socket number parameter in the Chamber Check configuration
array. Socket number one is the socket closest to the indicator lights
on the LWDAQ Driver (A2037).

III. Configuration

You can look at the Chamber Check configuration array, change its
contents, and save the contents to disk by pressing the Configure
button. When you next open the Chamber Checker, your saved settings
will be loaded into the configuration array.

There are two ways you can run the Chamber Check program. One is to
open it with the Source option in the LWDAQ program's File menu. When
you run Chamber Check in this manner, it will save its configuration
array in a file called:   Chamber_Checker_settings.txt

in the Tools/Data/Scripts folder of the LWDAQ program
directory. Another way to run Chamber Check is to place the script in
the LWDAQ.app/Contents/LWDAQ/Startup folder. When you run LWDAQ, it
will open Chamber Check automatically. If Chamber Check is the only
script in the Startup folder, it will use the main LWDAQ window for
its graphical user interface, and when you close the window, the LWDAQ
program will quit. If there are two or more scripts in the Startup
folder, Chamber Check will open its own window, and when you close
this window, the LWDAQ program will not quit. On the other hand, if
you close the LWDAQ main window, the Chamber Checker will terminate as
LWDAQ quits. When Chamber Check opens from the Startup folder, it puts
its settings file in the Startup folder too.

To add/remove allowed operators open the script in a text editor and
edit the following 2 lines:

tk_optionMenu $w.f3.operator Chamber_Checker_info(chamber_operator) "none" \
"Alan Wilson" "Reza Farsian" "Zhengguo Zhou" "Li Zhou" "Edward Diehl"

IV.  Operation.

The program starts with a dialog box where the user needs to enter the
chamber and operator names.  After the "OK" button is clicked the main
panel opens.  

a. Granite Reference Values 
At this point the inplane data from the chamber assembly granite table
are read in and the data displayed in the text boxes dX, dY, dMag, and
dTilt to demonstrate that the data has been successfully read in.  The
granite data are assumed to be in the directory "../granite" (relative
to LWDAQ.tcl) in files named [chamber]_granite.txt, where [chamber] is
a chamber name like eml5c15.  The granite data will be subtracted from
the chamber data to show the chamber deviations relative to the
granite.  The granite data files also have the orientation of the
RASNIK masks, so the deviations are corrected to the proper sign.

Here is an example Granite Reference file:

C RASNIK LOG FILE 09/05/03 08:12:53
C Operator: Helmut Schick
C Chamber: EML5C15 MIC081
C Spacer SS    +   +
C Spacer SD    +   +
C Spacer LS    +   +
C Spacer LD    +   +
  2   67932.7   50494.5  0.9725  -11.730  0.15   4 240  22 340 Spacer SS
  4   89431.2   89066.5  0.9151   -9.635  0.22   4 240  22 340 Spacer SD
  3   88801.5   88111.8  0.9995  -18.388  0.14   4 240  22 340 Spacer LS
  1   69141.5   50577.8  1.0922  -19.852  0.18   4 240  22 340 Spacer LD

Copy these lines into a file called ../granite/eml5c15_granite.txt if you want
to run the Chamber Checker tool just to see how it works.

b.  Inplane RASNIK Buttons
Chamber Checker reads four inplane rasnik instruments, analyzes their
images, and prints the single-line rasnik results in its text windows
next to the "Inplane" buttons labelled:

   SS => Short side straight inplane RASNIK
   SD => Short side diagonal inplane RASNIK
   LS => Long side straight inplane RASNIK
   LD => Long diagonal inplane RASNIK

"Short" and "Long" refer to the side the CCD camera is on.     

If you want to know what the RASNIK numbers in the single line output
mean, open the Rasnik instrument from the Instrument menu, set
verbose_result to 1, and when you next capture and analyze a Rasnik
image using the Chamber Checker, you will see the results printed out
in the Rasnik instrument text window. The next rasnik result will
appear in Rasnik instrument window in verbose form with a description
of each number.

Chamber Check will capture images from individual Rasniks with the
labeled Rasnik buttons, or it will do the all 4 Inplane Rasniks with 
the All button.  The check box next to each inplane button will be 
activated if the inplane image is successfully taken.

c.  PMO cameras
You can use the PMO buttons to take PMO camera images.  For this
process cameras should temporarily be attached to the PMO cables.
Since there are no RASNIK masks to look at the images will only appear
blurry white.   These buttons are labelled as follows:

  ROL => Readout end long side PMO camera
  ROS => Readout end short side PMO camera
  HVL => HV end long side PMO camera
  HVS => HV end short side PMO camera

The check box next to each PMO button will be activated if the PMO
image is successfully taken.
  
d.  Diagnostic Button

The Diagnostic button checks the LWDAQ Driver power supplies. You will
see an oscilloscope plot of the three power supplies in the Chamber
Check image window, and the results of the Diagnostic instrument in a
line of text.  If you want to know what the numbers in the line of
results mean, open the Diagnostic instrument and set verbose_result to
1 and watch the instrument's text window for the verbose result.

e.  All
The All button takes all 4 inplane RASNIK images in series.

f.  Abort.
The Abort button aborts the current image/data taking process.

g.  Configure
This buttons allows  configuration of various parameters controlling
the image/data taking.
 
h.  Save_Data Button.  

After all images have been taken the data can be saved to a file by
clicking the Save_Data button.  The data will be written to directory
"../data" relative to the LWDAQ.tcl script directory.  The name of the
data file will be in the format
inplane_YYYY_MM_DD_HH_MM_SS_[chamber].txt where YYYY_MM_DD_HH_MM_SS is
a year-month-day-hour-minute_second time stamp, and [chamber] is the
chamber name (e.g. EML5C15).   If you write a comment in the comment
line it is put into this file.

i.  Help
Displays this text.

Kevan Hashemi, hashemi@brandeis.edu
Edward Diehl, diehl@umich.edu
