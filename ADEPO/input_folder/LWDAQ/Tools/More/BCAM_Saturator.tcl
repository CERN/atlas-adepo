# BCAM_Saturator, a Standard and Polite LWDAQ Tool
# Copyright (C) 2004, Kevan Hashemi, Brandeis University
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
# Version 8: Brought up to date with LWDAQ 7.2. 

proc BCAM_Saturator_init {} {
	upvar #0 BCAM_Saturator_info info
	upvar #0 BCAM_Saturator_config config
	global LWDAQ_Info LWDAQ_Driver
	
	LWDAQ_tool_init "BCAM_Saturator" "8"
	if {[winfo exists $info(window)]} {return 0}

	set config(flash_factors) "0.0 0.1 0.3 0.5 0.6 \
		0.7 0.8 0.9 1.0 \
		1.1 1.2 1.3 1.4 \
		1.6 1.8 2.0"
	set config(num_flash_divisions) 10
	set config(size_intensity_divisions) 25
	set config(color) 1
	
	if {[file exists $info(settings_file_name)]} {
		uplevel #0 [list source $info(settings_file_name)]
	} 

	set info(control) "Idle"

	return 1	
}

proc BCAM_Saturator_bcam {} {
	LWDAQ_open BCAM
}

proc BCAM_Saturator_saturate {} {
	upvar #0 BCAM_Saturator_info info
	upvar #0 BCAM_Saturator_config config
	upvar #0 LWDAQ_config_BCAM iconfig
	upvar #0 LWDAQ_info_BCAM iinfo
	global LWDAQ_Driver

	if {$info(control) != "Idle"} {return 0}
	set info(control) "Acquire"
	set w $info(window)
	
	if {$iconfig(daq_adjust_flash)} {
		LWDAQ_print $info(text) "WARNING: BCAM is set to adjust exposure time."
	}
	if {$iconfig(daq_subtract_background)} {
		LWDAQ_print $info(text) "WARNING: BCAM is set to subtract background."
	}
	
	set saved_f $iconfig(daq_flash_seconds)

	set result ""
	foreach ff $config(flash_factors) {
		set f [expr $saved_f * $ff]
		set iconfig(daq_flash_seconds) $f
		set daq_result [LWDAQ_acquire BCAM]
		LWDAQ_update
		if {[LWDAQ_is_error_result $daq_result]} {
			LWDAQ_print $info(text) $daq_result
			set info(control) "Abort"
		}
		if {$info(control) == "Abort"} {
			set info(control) "Idle"
			set iconfig(daq_flash_seconds) $saved_f
			return 0
		}
		lwdaq_draw $iconfig(memory_name) $info(photo)
		set characteristics [lwdaq_image_characteristics $iconfig(memory_name)]
		set max [lindex $characteristics 6]
		append results " $f $max"
		LWDAQ_print $info(text) "Exposure time (s) [format %.1e $f],\
			Flash Fraction [format %.2f $ff],\
			Peak Intensity (counts) [format %.1f $max]"	
	}
	lwdaq_graph $results $info(graph_image_name)  \
		-x_min 0 -x_max $f -y_min 0 -y_max 255 -color $config(color) \
		-x_div [expr $f / $config(num_flash_divisions)] \
		-y_div $config(size_intensity_divisions)		
	set ave [lindex $characteristics 4]
	set background "0 $ave $f $ave"
	lwdaq_graph $background $info(graph_image_name)  \
		-x_min 0 -x_max $f -y_min 0 -y_max 255 \
		-color $config(color)
	lwdaq_draw $info(graph_image_name) $info(graph)
	incr config(color)
	
	set iconfig(daq_flash_seconds) $saved_f
	
	set info(control) "Idle"
	return $result
}

proc BCAM_Saturator_abort {} {
	upvar #0 BCAM_Saturator_info info
	if {$info(control) != "Idle"} {
		set info(control) "Abort"
	}
}

proc BCAM_Saturator_clear {} {
	upvar #0 BCAM_Saturator_info info
	if {$info(control) != "Idle"} {return 0}
	lwdaq_graph "0 0" $info(graph_image_name) -fill 1
	lwdaq_draw $info(graph_image_name) $info(graph)
}

proc BCAM_Saturator_open {} {
	upvar #0 BCAM_Saturator_config config
	upvar #0 BCAM_Saturator_info info

	set w [LWDAQ_tool_open $info(name)]
	if {$w == ""} {return 0}
		
	set f $w.controls
	frame $f
	pack $f -side top -fill x
	
	foreach a {Saturate Abort Clear} {
		set b [string tolower $a]
		button $f.$b -text $a -command BCAM_Saturator_$b
		pack $f.$b -side left -expand 1
	}
	label $f.state -textvariable BCAM_Saturator_info(control) -width 20 -fg blue
	pack $f.state

	set f $w.image_line
	frame $f 
	pack $f -side top -fill x
	
	set f1 $f.image_frame
	frame $f1 
	pack $f1 -side left -fill y
	set info(photo) [image create photo -width 344 -height 244]
	label $f1.image -image $info(photo) 
	pack $f1.image -side left

	set f2 $f.graph_frame
	frame $f2 
	pack $f2 -side left -fill y
	set info(graph) [image create photo -width 344 -height 244]
	label $f2.image -image $info(graph) 
	pack $f2.image -side left

	set info(graph_image_name) [lwdaq_image_create -width 344 -height 244 \
		-left 0 -right 343 -top 2 -bottom 243]
	BCAM_Saturator_clear
	
	set f $w.more
	frame $f
	pack $f -side top -fill x
	
	foreach a {BCAM} {
		set b [string tolower $a]
		button $f.$b -text $a -command BCAM_Saturator_$b
		pack $f.$b -side left -expand 1
	}
	foreach a {Configure Help} {
		set b [string tolower $a]
		button $f.$b -text $a -command "LWDAQ_tool_$b BCAM_Saturator"
		pack $f.$b -side left -expand 1
	}

	set info(text) [LWDAQ_text_widget $w 80 15]

	LWDAQ_print $info(text) "$info(name) Version $info(version) \n"
	
	return 1
}

BCAM_Saturator_init
BCAM_Saturator_open

return 1

----------Begin Help----------
The BCAM_Saturator will show you the saturation intensity of a camera,
the linearity of the laser-camera combination with flash time, and the
intensity of the laser image at zero exposure time, which can be
significant when the camera is less than a couple of meters from the
laser.

Before you press the "Saturate" button, set up your BCAM instrument so
that it captures images of your laser (or lasers) that appear to be near
to saturation, or just into saturation. Be sure to turn off the BCAM
Instruments automatic flash time adjustment, by setting the BCAM
daq_adjust_flash option to zero.

We recommend that you do not subtract a background image. Not only does
the subtraction slow down the data acquisition process, because it
requires the BCAM to capture a second image, but it also distorts the
intensity scale by subtracting an unknown offset from the intensity of
all pixels. The BCAM Saturator will plot the background intensity in a
graph for you as a horizontal line, so you can see the net laser
intensity with respect to the background in the graph of image intensity
versus exposure time.

The graph we plot of image intensity is linear in both axese, with the
vertical axis extending from intensity 0 to 255, and the horizontal axis
extending from flash time 0 s to the maximum flash time used by the
BCAM_Saturator.

The BCAM_Saturator obtains the flash times from the flash time in your
BCAM instrument. It multiplies the pre-existing flash time by each of
the numbers in the config(flash_factors) list and captures an image with
the resulting flash time value. After the last flash, the BCAM_Saturator
restores you BCAM instrument's flash time to its pre-existing value.

If you would like the BCAM_Saturator to take fewer, or more,
measurements, by trying fewer, or more, flash times, press the Configure
button, and you will see the list of flash fractions, which you can edit
as you like. Press the Save button and the BCAM_Saturator will save your
configuration to disk, and open it automatically next time.

Linearity of Plot: The linearity of the graph of image intensity versus
flash time depends both upon the linearity of the CCD pixels, and upon
the linearity of the light output of the laser versus flash time. The
light output of the laser depends almost entirely upon the dynamic
properties of the laser driver. The laser driver in our BCAM Side Head
circuits (A2049 and A2040) takes roughly four microseconds to turn the
laser on to full power. After that, the laser power changes slightly as
the transistor junctions in the laser driver heat up, changing the gain
and offset in the power-monitoring control loop. In short: the linearity
of the BCAM_Saturator graph tells you about the laser driver.

Slope of Plot: We choose the flash times by multiplying a nominal flash
time in the BCAM instrument, so the slope of the line on the screen will
vary hardly at all from one measurement to the next. But the slope in
units of counts/second is mainly a function of laser output power and
laser-camera range. The slope is proportional to laser power and
inversely proportional to the square of the range. Laser output powers
vary from one BCAM to the next because the sensitivity of their internal
monitoring photodiodes vary. The laser driver circuit controls the
current in this photodiode. The sensitivity of the photodiodes in laser
diodes are poorly constrained by the manufacturer's data sheets. The
DL3147 from Sanyo give a factor of five range in sensitivity, while the
LDP65001E from Lumex allows for a factor of twenty range in sensitivity.
In practice, the lasers in a single batch do not vary nearly this much
between one laser and the next, but the possibility of such variation
remains.

Saturation of Plot: The saturation level of the graph, which is the
intensity at which the plot becomes horizontal, is a function of the CCD
only. The pixels saturate when they are full of electrons. The inensity
count corresponding to saturated pixels is a function of the CCD output
amplifier and the LWDAQ device amplifier. The saturation level for BCAM
Heads (A2048 and A2051) is usually about 220 counts.

Background Level of Plot: (straight horizontal line) The background
level is a combination of background light in the room, and a mosfet
charge injection in the CCD's output amplifier (the CCD is the TC255P in
the BCAM Head A2048 and A2051). With minimal background light, the
backgroud level of the image is usually about 40 counts.

Kevan Hashemi hashemi@brandeis.edu
----------End Help----------
