set fn [LWDAQ_get_file_name]
if {$fn == ""} {exit}
set f [open $fn]
set contents [read $f]
close $f

regsub -all {\n} $contents " " a
regsub -all {\[} $a  "\n\[" b
regsub -all {\(} $b "\n\(" c

set fn [file join [file root $fn]_Compact[file extension $fn]]
set f [open $fn w]
puts $f $c
close $f
