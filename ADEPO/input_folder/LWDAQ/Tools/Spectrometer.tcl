# Spectrometer.tcl, Plots results from the RFPM Instrument.
# Copyright (C) 2006 Kevan Hashemi, Open Source Instruments Inc.
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

# Version 20: Add calibration constant entries in the panel and now
# convert frequency lines into dac counts automatically. Control buttons
# are Scan and Repeat so we can scan a fequency band or monitor a
# particular frequency. We provide calibration constants in the Help
# screen, but direct the user to the A3008 manual for instructions.

proc Spectrometer_init {} {
	upvar #0 Spectrometer_info info
	upvar #0 Spectrometer_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Spectrometer" "20"
	if {[winfo exists $info(window)]} {return 0}

	set info(control) "Idle"
	set info(instrument) "RFPM"
	set info(graph_width) 700
	set info(graph_height) 200
	set info(graph_names) "A B C D E F G"
	set info(active_graph) "A"
	set info(cursor_y) "0"
	set info(image_name) spectrometer
	lwdaq_image_destroy $info(image_name)
	set info(photo_name) spectrometer
	set info(data) [list]
	set info(peak_to_rms_dB) 9
  		
	set config(count_max) 100
	set config(count_min) 0
	set config(peak_power) 1
	set config(power_min) -100
	set config(power_max) -20
	set config(power_div) 10
	set config(gain_c0) 0
	set config(gain_c1) 121
	set config(gain_c2) 11
	set config(gain_c3) 1
	set config(peak_v_limit) 0.8
	set config(ave_v_limit) 0.3
	set config(step_div) 255
	set config(cursor_enable) 1
	set config(cursor_color) 8
	set config(f_color) 2
	set config(step_increment) 1
	set config(f_lines) "900 910 920 930"
	set config(f_ref) "910"
	set config(dac_ref) "48"
	set config(f_slope) "0.81"
	set config(p_ref) "1600"
	set config(step) 0
	
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 
	
	return 1	
}

proc Spectrometer_print {s {color black}} {
	upvar #0 Spectrometer_info info
	LWDAQ_print $info(text) $s $color
}

proc Spectrometer_refresh {} {
	upvar #0 Spectrometer_info info
	upvar #0 Spectrometer_config config
	
	set x_max $config(count_max)
	set x_min $config(count_min)
	
	lwdaq_graph "0 0" $info(image_name) -fill 1 \
		-x_min $x_min -x_max $x_max \
		-y_min $config(power_min) -y_max $config(power_max) \
		-y_div $config(power_div) -x_div $config(step_div) \
		-color 1
		
	foreach {l} $config(f_lines) {
		set x [expr ($l - $config(f_ref)) / $config(f_slope) + $config(dac_ref)]
		set graph "$x $config(power_min) $x $config(power_max)"
		lwdaq_graph $graph $info(image_name) \
			-x_min $x_min -x_max $x_max \
			-y_min $config(power_min) -y_max $config(power_max) \
			-color $config(f_color)
	}
	foreach graph_name $info(graph_names) {
		set graph [list]
		foreach p $info(data) {
			foreach {step power gn} $p {
				if {$graph_name == $gn} {
					lappend graph "$step $power "
				}
			}
		}
		if {[llength $graph] < 2} {continue}
		set graph [join [lsort -increasing -integer -index 0 $graph]]
		set color [lsearch $info(graph_names) $graph_name]
		lwdaq_graph $graph $info(image_name) \
			-x_min $x_min -x_max $x_max \
			-y_min $config(power_min) -y_max $config(power_max) \
			-color $color
	}
	if {$config(cursor_enable)} {
		set graph "$config(step) $config(power_min) $config(step) $config(power_max)"
		lwdaq_graph $graph $info(image_name) \
			-x_min $x_min -x_max $x_max \
			-y_min $config(power_min) -y_max $config(power_max) \
			-color $config(cursor_color) 
		set graph "$x_min $info(cursor_y) $x_max $info(cursor_y)"
		lwdaq_graph $graph $info(image_name) \
			-x_min $x_min -x_max $x_max \
			-y_min $config(power_min) -y_max $config(power_max) \
			-color $config(cursor_color)
	}
	lwdaq_draw $info(image_name) $info(photo_name)
}

proc Spectrometer_clear {} {
	upvar #0 Spectrometer_info info
	set new_data [list]
	foreach e $info(data) {
		if {[lindex $e 2] != $info(active_graph)} {
			lappend new_data $e			
		}
	}
	set info(data) $new_data
	Spectrometer_refresh
}

proc Spectrometer_clear_all {} {
	upvar #0 Spectrometer_info info
	set info(data) [list]
	Spectrometer_refresh
}

proc Spectrometer_save_graphs {} {
	upvar #0 Spectrometer_info info
	set fn [LWDAQ_put_file_name "RF_Spectrum.txt"]
	if {$fn == ""} {return}
	set f [open $fn w]
	foreach e $info(data) {
		puts $f $e
	}
	close $f
}

proc Spectrometer_load_graphs {} {
	upvar #0 Spectrometer_info info
	set fn [LWDAQ_get_file_name]
	if {$fn == ""} {return}
	set f [open $fn r]
	while {[gets $f line] > 0} {
		lappend info(data) $line
	}
	close $f
	Spectrometer_refresh
}

proc Spectrometer_command {command} {
	upvar #0 Spectrometer_info info
	global LWDAQ_Info
	if {$command == $info(control)} {
		return 1
	}
	if {$command == "Stop"} {
		if {$info(control) != "Idle"} {set info(control) "Stop"}
		return 1
	}
	if {$info(control) == "Idle"} {
		set info(control) $command
		LWDAQ_post Spectrometer_execute
		return 1
	} {
		set info(control) $command
		return 1
	}
	return 0
}


proc Spectrometer_execute {} {
	upvar #0 Spectrometer_info info
	upvar #0 Spectrometer_config config

	global LWDAQ_Info
	
	if {![array exists info]} {return}

	if {$info(window) != ""} {
		if {![winfo exists $info(window)]} {return}
	}
	if {($info(control) == "Stop") || $LWDAQ_Info(reset)} {
		set info(control) "Idle"
		return 0
	}
		
	if {($info(control) == "Scan")} {
		set config(step) [expr $config(step) + $config(step_increment)]
		if {$config(step) > $config(count_max)} {set config(step) $config(count_min)}
		if {$config(step) < $config(count_min)} {set config(step) $config(count_max)}
	}

	upvar #0 LWDAQ_config_$info(instrument) iconfig
	set iconfig(daq_dac_value) $config(step)
	if {$config(peak_power)} {
		set iconfig(analysis_enable) 1
	} {
		set iconfig(analysis_enable) 2
	}
	set result [LWDAQ_acquire $info(instrument)]
	if {$result == ""} {
		set result "ERROR: $info(instrument) returned empty result."
	} 
	
	if {![LWDAQ_is_error_result $result]} {
		scan $result %s%f%f%f%f name c0 c1 c2 c3
		
		if {$config(peak_power)} {
			set limit $config(peak_v_limit)
		} {
			set limit $config(ave_v_limit)
		}
		if {$c3 < $limit} {
			set amplitude [expr $c3 * $config(gain_c3)]
		} elseif {$c2 < $limit} {
			set amplitude [expr $c2 * $config(gain_c2)]
		} else {
			set amplitude [expr $c1 * $config(gain_c1)]
		}
		if {$amplitude > 0} { 
			set dbm [format {%.0f} [expr 20 * log10( $amplitude / $config(p_ref) ) ]]
			if {!$config(peak_power)} {
				set dbm [expr $dbm + $info(peak_to_rms_dB)]
			}
		} {
			set dbm $config(power_min)
		}
		set i [lsearch $info(data) "$config(step) * $info(active_graph)"]
		if {$i > 0} {set info(data) [lreplace $info(data) $i $i]}
		lappend info(data) "$config(step) $dbm $info(active_graph)"
		if {!$config(peak_power)} {
			set s "Average"
		} {
			set s "Peak"
		}
		set f [expr ($config(step) - $config(dac_ref)) * $config(f_slope) + $config(f_ref)]
		LWDAQ_print $info(text) "Step: $config(step)\
			Frequency: [format %.1f $f] MHz\
			$s Power: $dbm dBm\
			Graph: $info(active_graph)"
		set info(cursor_x) $config(step)
		set info(cursor_y) $dbm
		Spectrometer_refresh
	} {
		LWDAQ_print $info(text) $result
		set config(step) [expr $config(step) - $config(step_increment)]
		set info(control) "Idle"
		return 0
	}


	if {($info(control) == "Scan") || ($info(control) == "Repeat")} {
		LWDAQ_post Spectrometer_execute
		return 1
	} 
	
	set info(control) "Idle"
	return 1
}

proc Spectrometer_open {} {
	upvar #0 Spectrometer_config config
	upvar #0 Spectrometer_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.setup
	frame $f
	pack $f -side top -fill x
	
	label $f.lstate -textvariable $info(name)_info(control) -width 6 -fg blue
	pack $f.lstate -side left -expand 1

	label $f.lstep -text "Step"
	entry $f.estep -textvariable $info(name)_config(step) -width 4
	pack $f.lstep $f.estep -side left -expand 1

	label $f.lgraph -text "Active Graph:"
	tk_optionMenu $f.m Spectrometer_info(active_graph) none
	foreach gn $info(graph_names) {
		$f.m.menu add command -label $gn \
			-command "set Spectrometer_info(active_graph) $gn"
	}
	set info(active_graph) [lindex $info(graph_names) 0]
	pack $f.lgraph $f.m -side left -expand 1

	button $f.clear -text "Clear" -command Spectrometer_clear
	pack $f.clear -side left -expand 1

	button $f.clearall -text "Clear All" -command Spectrometer_clear_all
	pack $f.clearall -side left -expand 1

	button $f.save -text "Save" -command Spectrometer_save_graphs
	pack $f.save -side left -expand 1

	button $f.load -text "Load" -command Spectrometer_load_graphs
	pack $f.load -side left -expand 1
	
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	foreach a {Stop Sample Repeat Scan} {
		set b [string tolower $a]
		button $f.$b -text $a -command "Spectrometer_command $a"
		pack $f.$b -side left -expand 1
	}
	foreach a {Configure Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b Spectrometer"
		pack $f.$b -side left -expand 1
	}

	label $f.lcursor -text "Show Cursor"
	checkbutton $f.ccursor -variable Spectrometer_config(cursor_enable)	
	pack $f.lcursor $f.ccursor -side left -expand 1

	label $f.lpeak -text "Peak Power"
	checkbutton $f.cpeak -variable Spectrometer_config(peak_power)	
	pack $f.lpeak $f.cpeak -side left -expand 1

	set f $w.graph
	frame $f 
	pack $f -side top -fill x
	image create photo $info(photo_name) \
		-width $info(graph_width) -height $info(graph_height)
	label $f.image -image $info(photo_name) 
	pack $f.image
	lwdaq_image_create -width $info(graph_width) \
   		-height $info(graph_height) -name $info(image_name)

	set f $w.calib
	frame $f
	pack $f -side top -fill x
	
	foreach p {f_ref dac_ref f_slope p_ref} {
		label $f.l$p -text "$p\:"
		entry $f.e$p -textvariable $info(name)_config($p) -width 5
		bind $f.e$p <Return> Spectrometer_refresh
		pack $f.l$p $f.e$p -side left -expand 1
	}

	label $f.l4 -text "f_lines:"
	entry $f.e4 -textvariable $info(name)_config(f_lines) -width 20
	bind $f.e4 <Return> Spectrometer_refresh
	pack $f.l4 $f.e4 -side left -expand 1

	set info(text) [LWDAQ_text_widget $w 80 10]

	Spectrometer_refresh

	return 1
}

Spectrometer_init
Spectrometer_open

return 1

----------Begin Help----------

You will find help for the Spectrometer Tool at:

http://www.opensourceinstruments.com/Electronics/A3008/M3008.html

Here are calibration constants for some existing spectrometer circuits.

A3008B 001
f_ref	910	MHz
dac_ref	48	count
f_slope	0.81	MHz/count

A3008B 002
f_ref	910	MHz
dac_ref	51	count
f_slope	0.73	MHz/count

A3008B 003
f_ref	910	MHz
dac_ref	41	count
f_slope	0.71	MHz/count

A3008A 004
f_ref	910	MHz
dac_ref	45	count
f_slope	0.80	MHz/count

Kevan Hashemi hashemi@opensourceinstruments.com

----------End Help----------

