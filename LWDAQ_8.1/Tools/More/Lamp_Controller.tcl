# Lamp_Controller, a Standard and Polite LWDAQ Tool
# Copyright (C) 2012 Kevan Hashemi, Open Source Instruments
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


proc Lamp_Controller_init {} {
	upvar #0 Lamp_Controller_info info
	upvar #0 Lamp_Controller_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "Lamp_Controller" "2"
	if {[winfo exists $info(window)]} {return 0}

	set config(ip_addr) "10.0.0.37"
	set config(driver_socket) 1
	set config(pulse_height) 10
	set config(pulse_length) 10
	set config(interval_length) 200
	set config(stimulus_length) 10
	set config(randomize) 0
	set config(polarity) 0
	set config(max_height) 11.5

	set info(stimulus_script) ""
	set info(state) "Idle"
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	return 1   
}

proc Lamp_Controller_commands {} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	set commands "0080 "
	
	if {$config(polarity)} {
		append commands "0182 "
	}
	
	set x [expr round(255.0 * $config(pulse_height) / $config(max_height))]
	if {$x > 255} {set x 255}
	binary scan [binary format c* $x] H2 h
	append commands "$h\83 "
	
	set addr 4
	foreach a {pulse_length interval_length stimulus_length} {
		binary scan [binary format c* \
			[expr $config($a) / 256]] H2 h
		append commands "$h\8$addr "
		incr addr
		binary scan [binary format c* \
			[expr $config($a) % 256]] H2 h
		append commands "$h\8$addr "
		incr addr
	}

	if {$config(randomize)} {
		append commands "018a "
	}
	
	append commands "0181"

	return $commands
}

proc Lamp_Controller_transmit {commands} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	if {[catch {
		set sock [LWDAQ_socket_open $config(ip_addr)]
		LWDAQ_set_driver_mux $sock $config(driver_socket) 1
		foreach cmd $commands {
			LWDAQ_transmit_command_hex $sock $cmd
		}
		LWDAQ_wait_for_driver $sock
		LWDAQ_socket_close $sock
	} error_result]} {
		LWDAQ_print $info(text) "ERROR: $error_result"
		if {[info exists sock]} {LWDAQ_socket_close $sock}
	}
	LWDAQ_print $info(text) $commands green
	
	return $commands
}

proc Lamp_Controller_stimulate {} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	if {$info(state) != "Idle"} {return}
	set info(state) "Stimulate"
	set commands [Lamp_Controller_commands]
	Lamp_Controller_transmit $commands
	set info(state) "Idle"
}

proc Lamp_Controller_stop {} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	if {$info(state) != "Idle"} {return}
	set info(state) "Stop"
	set commands "0081"
	Lamp_Controller_transmit $commands
	set info(state) "Idle"
}

proc Lamp_Controller_repeat {} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	if {$info(state) != "Idle"} {return}
	set info(state) "Repeat"
	set commands "0181"
	Lamp_Controller_transmit $commands
	set info(state) "Idle"
}

proc Lamp_Controller_print {} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	set script {
set sock [LWDAQ_socket_open %1]
LWDAQ_set_driver_mux $sock %2
foreach c {%3} {
	LWDAQ_transmit_command_hex $sock $c
}
LWDAQ_wait_for_driver $sock
LWDAQ_socket_close $sock
	}
	set commands [Lamp_Controller_commands]
	set script [regsub %1 $script $config(ip_addr)]
	set script [regsub %2 $script $config(driver_socket)]
	set script [regsub %3 $script $commands]	
	LWDAQ_print $info(text) $script
}

proc Lamp_Controller_open {} {
	upvar #0 Lamp_Controller_config config
	upvar #0 Lamp_Controller_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
	
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	label $f.state -textvariable Lamp_Controller_info(state) \
		-width 12 -fg blue
	pack $f.state -side left -expand 1
	foreach a {Stimulate Stop Repeat Print} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_post Lamp_Controller_$b"
		pack $f.$b -side left -expand 1
	}
	foreach a {Configure Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b $info(name)"
		pack $f.$b -side left -expand 1
	}
	
	set f $w.values
	frame $f
	pack $f -side top -fill x
	
	foreach {a b} {ip_addr "(x.x.x.x)" \
		driver_socket "(1-8)" \
		pulse_length "(ms)" \
		interval_length "(ms)" \
		stimulus_length "(pulses)" \
		pulse_height "(V)" } {
		label $f.l$a -text "$a $b" -fg blue
		entry $f.e$a -textvariable Lamp_Controller_config($a) 
		grid $f.l$a $f.e$a -sticky nsew
	}
	checkbutton $f.polarity -text "Invert Logic Output" \
		-variable Lamp_Controller_config(polarity)
	checkbutton $f.randomize -text "Randomize Pulse Interval" \
		-variable Lamp_Controller_config(randomize)
	grid $f.polarity $f.randomize -sticky nsew

	set info(text) [LWDAQ_text_widget $w 50 15]

	LWDAQ_print $info(text) "$info(name) Version $info(version) \n"
	
	return 1
}

Lamp_Controller_init
Lamp_Controller_open
	
return 1

----------Begin Help----------

The Lamp Controller tool allows us to compose and transmit stimulation instructions to a Lamp Controller (A2060L). It prints the hexadecimal codes required to invoke the stimulus, or repeat the stimulus, in its text window. When you press the Print button, the tool prints a TCL script that will perform the stimulus defined in the entry boxes.

If you want to compose your own lists of instructions, you can use the following code in the Toolmaker, and enter your hexadecimal instructions in the commands entry box.

# Send a sequence of LWDAQ commands to a device
# upon button press. List the commands in the
# entry box in hexadecimal format.
set p(commands) "0080 FF83 2087 0185 0181"
set p(text) $t
set p(ip_addr) "129.64.37.88"
set p(driver_socket) 5
set p(mux_socket) 1
button $f.transmit -text Transmit -command Transmit
entry $f.commands -textvariable p(commands) -width 60
pack $f.transmit $f.commands -side left -expand yes
proc Transmit {} {
  global p
  set sock [LWDAQ_socket_open $p(ip_addr)]
  LWDAQ_set_driver_mux $sock $p(driver_socket) $p(mux_socket)
  foreach c $p(commands) {
    LWDAQ_transmit_command_hex $sock $c
  }
  LWDAQ_socket_close $sock
  LWDAQ_print $p(text) $p(commands)
}

Kevan Hashemi hashemi@opensourceinstruments.com
----------End Help----------

----------Begin Data----------

----------End Data----------