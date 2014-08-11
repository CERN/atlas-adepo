# Sudoku.tcl, Solves Sudoku Puzzles
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

# The Sudoku logic is in the procedures at the bottom of the file. The
# initial code just opens a window and sets up the user interface. You
# can define non-standard size Sudoku's by changing box_side to 2 or 4
# instead of 3.

# You enter the puzzel in the window by entering numbers and skipping
# blank. As soon as the solver starts working on a blank cell, it will
# substitute a full list of symbols for the blank, meaning that the
# value of the cell is undefined.

# Each cell is a list of symbols that the solver has not yet eliminated
# as possible values for the cell. The symbols are separated by spaces.
# At the beginning, you enter single symbols for the initial clues, and
# blanks for undefined cells. The solver fills in the blanks for you with
# the symbol list.

# The solving logic works by expressing the Sudoku rules with six
# simple logical actions, and applying each action to every cell in 
# the puzzle, starting at the top-left, and working down to the bottom-
# right. The application of the six rules to all cells is one Step
# in the solving process. 

# After the step, you will see each cell has a new list of possible
# values. You can edit these as you see fit.

# You press the Step button to apply the rules again, and eventually 
# the process will converge or arrive at a contradiction. The solver
# notifies you of a contradiction in its text window. The contradiction
# means that the starting values for the Step are not consistent with
# any pattern that satisfies the Sudoku rules.

# If, instead of a contradiction, you have a unique solution to the 
# puzzle, you are done. But if there are some cells with two symbols,
# you must pick one such cell and delete one of the symbols. By doing 
# this, you instruct the solver to proceed on the assumption that your 
# choice of symbol is correct. Now you press Step again, and you will
# either get convergance or a contradiction. If it converges, the
# solution will either be unique (in which case you are finished), or
# you will have to pick one of two again. If you get a contradictio, you
# use the Back button to go back to the place where you picked one of
# two values, and you pick the other value.

# The six Sudoku rules are as follows, where a "symbol" is any of the
# numbers 1 to 9 in a 3x3 Sudoku, a "box" is one of the nine 3x3 boxes,
# a "column" is one of the nine columns, and a "row" is one of the
# nine rows.

# There may be no more than one instance of a symbol in any box.
# There may be no less than one instance of a symbol in any box.
# There may be no more than one instance of a symbol in any column.
# There may be no less than one instance of a symbol in any column.
# There may be no more than one instance of a symbol in any row.
# There may be no less than one instance of a symbol in any row.

# make window
set w .s
destroy $w
toplevel $w
wm title $w Sudoku

# define symbol set
set box_side 3
set puzzle_side [expr $box_side * $box_side]
set symbols ""
for {set i 1} {$i <= $puzzle_side} {incr i} {
	append symbols "$i "
}


# define blank puzzle made up of rows and columns of cells.
# each cell is a list of possible values.
foreach i $symbols {
	foreach j $symbols {
		set cell_$i\_$j ""
	}
}

# procedure to get puzzle contents as a list
proc extract_sudoku {} {
	global symbols
	set sudoku [list]
	foreach j $symbols {
		foreach i $symbols {
			upvar #0 cell_$j\_$i cell
			lappend sudoku $cell
		}
	}
	return $sudoku
}

# Clear the progress list, which saves the results
# of Step and Back.
set sudoku_progress [list]

# display puzzle
set f $w.puzzle
frame $f
pack $f -side top -fill x
foreach j $symbols {
	set bl ""
	foreach i $symbols {
		entry $f.e$j\_$i -textvariable cell_$j\_$i -width 10
		append bl "$f.e$j\_$i "
		if {[expr $i % $box_side] == 0} {
			label $f.b$j\_$i
			append bl "$f.b$j\_$i "
		}
	}
	eval "grid $bl -sticky news"
	if {[expr $j % $box_side] == 0} {
		label $f.b$j -bd 0 -relief sunken
		grid $f.b$j -sticky news
	}
}

# make buttons
set f $w.buttons
frame $f
pack $f -side top -fill x
foreach a {step back save load} {
	button $f.$a -text $a -command sudoku_$a
	pack $f.$a -side left -expand 1
}

# make text window
set t [text $w.t -relief sunken -bd 1 \
	-border 2 -yscrollcommand "$w.scroll set" \
	-setgrid 1 -height 10 -width 100]
if {[info tclversion] >= 8.4} {$t configure -undo 1 -autosep 1}
scrollbar $w.scroll -command "$t yview"
pack $w.scroll -side right -fill y
pack $t -expand yes -fill both
foreach c {black red green blue orange yellow brown purple} {
	$t tag configure $c -foreground $c
}
$t configure -tabs "0.25i left"

# define routine to write in text window
proc sudoku_print {args} {
	set option "-newline"
	if {[string match "-nonewline" [lindex $args 0]]} {
		set option "-nonewline"
		set args [lreplace $args 0 0]
	}
	if {[string match "-newline" [lindex $args 0]]} {
		set args [lreplace $args 0 0]
	}
	set text_win [lindex $args 0]
	set print_str [lindex $args 1]
	if {$option == "-newline"} {append print_str \n}
	if {![winfo exists $text_win]} {
		return 0
	}
	set color [lindex $args 2]
	$text_win insert end "$print_str" $color
	$text_win yview moveto 1
	return 1
}

# welcome message.
sudoku_print .s.t "Welcome to Sudoku Version II" blue
sudoku_print .s.t "For help, see Sudoku.tcl source code comments.\n"

# routine to read a saved sudoku.
proc sudoku_load {} {
	global sudoku_progress
	set fn [tk_getOpenFile]
	if {$fn == ""} {return}
	set f [open $fn r]
	set sudoku_progress [list [read $f]]
	close $f
	sudoku_back
}

# routine to save a sudoku to disk.
proc sudoku_save {} {
	global sudoku_progress
	set fn [tk_getSaveFile]
	if {$fn == ""} {return}
	set f [open $fn w]
	puts $f [extract_sudoku]
	close $f
}

# step procedure
proc sudoku_step {} {
	global symbols sudoku_progress
	sudoku_print .s.t "\nStep..." purple
	update
	lappend sudoku_progress [extract_sudoku]
	foreach j $symbols {
		foreach i $symbols {
			upvar #0 cell_$j\_$i cell
			if {[string trim $cell] == ""} {
				set cell $symbols
			}
		}
	}
	foreach j $symbols {
		foreach i $symbols {
			eliminate_box $j $i
			eliminate_column $j $i
			eliminate_row $j $i
			force_box $j $i
			force_column $j $i
			force_row $j $i
		}
	}
	sudoku_print .s.t "Done." purple
}

# back procedure
proc sudoku_back {} {
	global sudoku_progress symbols
	if {[llength $sudoku_progress] >= 1} {
		set s [lindex $sudoku_progress end]
		set sudoku_progress [lreplace $sudoku_progress end end]
		set index 0
		foreach j $symbols {
			foreach i $symbols {
				upvar #0 cell_$j\_$i cell
				set cell [lindex $s $index]
				incr index
			}
		}
	} {
		sudoku_print .s.t  "Sudoku: cannot go back farther"
	}
}

# The eliminate_box procedure looks through a cell's box for other
# cells that have single symbols, and eliminates these symbols from
# the cell's list of possible symbols. This procedure implements
# the Sudoku rule that there may be no more than one instance of
# any symbol in a box.
proc eliminate_box {j i} {
	upvar #0 cell_$j\_$i cell
	global box_side puzzle_side symbols
	set left [expr round(($i-1) - fmod(($i-1),$box_side)) + 1]
	set top [expr round(($j-1) - fmod(($j-1),$box_side)) + 1]
	foreach s $symbols {
		for {set ib $left} {$ib < [expr $left + $box_side]} {incr ib} {
			for {set jb $top} {$jb < [expr $top + $box_side]} {incr jb} {
				if {($i == $ib) && ($j == $jb)} {continue}
				upvar #0 cell_$jb\_$ib c
				if {([lsearch $c $s] >= 0) && ([llength $c] == 1)} {
					set index [lsearch $cell $s]
					if {$index >= 0} {
						if {[llength $cell] == 1} {
							sudoku_print .s.t  "Sudoku: contradiction eliminating box in cell $j $i"
						} {
							set cell [lreplace $cell $index $index]
						}
					}
				}
			}
		}
	}
}

# The force_box procedure looks through the other cells in a box for
# each of the subject cell's possible symbols. If it finds that 
# no other cell in the box has this symbol in its list of possible 
# symbols, force_box forces the value of the subject cell to this
# symbol. This procedure implements the rule that there may be no
# less than one instance of any symbol in a box.
proc force_box {j i} {
	upvar #0 cell_$j\_$i cell
	global box_side puzzle_side symbols
	set left [expr round(($i-1) - fmod(($i-1),$box_side)) + 1]
	set top [expr round(($j-1) - fmod(($j-1),$box_side)) + 1]
	foreach s $symbols {
		set other_place 0
		for {set ib $left} {$ib < [expr $left + $box_side]} {incr ib} {
			for {set jb $top} {$jb < [expr $top + $box_side]} {incr jb} {
				if {($i == $ib) && ($j == $jb)} {continue}
				upvar #0 cell_$jb\_$ib c
				if {([lsearch $c $s] >= 0)} {
					set other_place 1
				}
			}
		}
		if {$other_place == 0} {
			set index [lsearch $cell $s]
			if {$index < 0} {
				sudoku_print .s.t  "Sudoku: contradiction forcing box in cell $j $i"
			} {
				set cell $s
			}
			break
		}
	}
}

# As eliminate_box, but for columns.
proc eliminate_column {j i} {
	upvar #0 cell_$j\_$i cell
	global box_side puzzle_side symbols
	foreach s $symbols {
		for {set jc 1} {$jc <= $puzzle_side} {incr jc} {
			if {($j == $jc)} {continue}
			upvar #0 cell_$jc\_$i c
			if {([lsearch $c $s] >= 0) && ([llength $c] == 1)} {
				set index [lsearch $cell $s]
				if {$index >= 0} {
					if {[llength $cell] == 1} {
						sudoku_print .s.t  "Sudoku: contradiction eliminating column in cell $j $i"
					} {
						set cell [lreplace $cell $index $index]
					}
				}
			}
		}
	}
}

# As force_box, but for columns.
proc force_column {j i} {
	upvar #0 cell_$j\_$i cell
	global box_side puzzle_side symbols
	foreach s $symbols {
		set other_place 0
		for {set jc 1} {$jc <= $puzzle_side} {incr jc} {
			if {($j == $jc)} {continue}
			upvar #0 cell_$jc\_$i c
			if {([lsearch $c $s] >= 0)} {
				set other_place 1
			}
		}
		if {$other_place == 0} {
			set index [lsearch $cell $s]
			if {$index < 0} {
				sudoku_print .s.t  "Sudoku: contradiction forcing column in cell $j $i"
			} {
				set cell $s
			}
			break
		}
	}
}

# As eliminate_box, but for rows.
proc eliminate_row {j i} {
	upvar #0 cell_$j\_$i cell
	global box_side puzzle_side symbols
	foreach s $symbols {
		for {set ir 1} {$ir <= $puzzle_side} {incr ir} {
			if {($i == $ir)} {continue}
			upvar #0 cell_$j\_$ir c
			if {([lsearch $c $s] >= 0) && ([llength $c] == 1)} {
				set index [lsearch $cell $s]
				if {$index >= 0} {
					if {[llength $cell] == 1} {
						sudoku_print .s.t  "Sudoku: contradiction eliminating row in cell $j $i"
					} {
						set cell [lreplace $cell $index $index]
					}
				}
			}
		}
	}
}

# As force_box, but for rows.
proc force_row {j i} {
	upvar #0 cell_$j\_$i cell
	global box_side puzzle_side symbols
	foreach s $symbols {
		set other_place 0
		for {set ir 1} {$ir <= $puzzle_side} {incr ir} {
			if {($i == $ir)} {continue}
			upvar #0 cell_$j\_$ir c
			if {([lsearch $c $s] >= 0)} {
				set other_place 1
			}
		}
		if {$other_place == 0} {
			set index [lsearch $cell $s]
			if {$index < 0} {
				sudoku_print .s.t  "Sudoku: contradiction forcing row in cell $j $i"
			} {
				set cell $s
			}
			break
		}
	}
}

