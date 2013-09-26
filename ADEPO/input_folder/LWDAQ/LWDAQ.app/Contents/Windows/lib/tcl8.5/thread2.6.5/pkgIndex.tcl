#
# Tcl package index file, version 1.1
#
if {[package vsatisfies [package provide Tcl] 8.4]} {
    package ifneeded Thread 2.6.5 [list thread_load $dir]
    package ifneeded Ttrace 2.6.5 [list thread_source $dir]
    proc thread_load {dir} {
        load [file join $dir thread265.dll]
        rename thread_load {}
    }
    proc thread_source {dir} {
        if {[info exists ::env(TCL_THREAD_LIBRARY)] &&
            [file readable $::env(TCL_THREAD_LIBRARY)/ttrace.tcl]} {
            source $::env(TCL_THREAD_LIBRARY)/ttrace.tcl
        } elseif {[file readable [file join $dir .. lib ttrace.tcl]]} {
            source [file join $dir .. lib ttrace.tcl]
        } elseif {[file readable [file join $dir ttrace.tcl]]} {
            source [file join $dir ttrace.tcl]
        }
        if {[info commands ttrace::update] ne ""} {
            ttrace::update
        }
        rename thread_source {}
    }
}
