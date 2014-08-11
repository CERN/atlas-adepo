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
# Utils.tcl contains file input-output routines, the LWDAQ event queue,
# time and date routines, debug and diagnostic routines, and LWDAQ help
# routines. The LWDAQ Event Queue is an event scheduler that allows us
# to perform simultaneous live data acquisition from multiple instruments 
# by scheduling the acquision actions so they do not overlap with one another.
#

#
# LWDAQ_utils_init initializes the untils routines.
#
proc LWDAQ_utils_init {} {
	upvar #0 LWDAQ_Info info
	set info(queue_run) 0
	set info(queue_ms) 10
	set info(queue_events) [list]
	set info(current_event) "Stopped"

	set info(reset) 0

	set info(vwait_var_names) [list]
	set info(max_vwait_names) 100
	set info(update_ms) 5
	set info(support_ms) 500

	set info(tcp_timeout_ms) 10000 
	set info(close_delay_ms) 20
	set info(lazy_flush) 1
	set info(open_sockets) ""
	set info(blocking_sockets) 0
	set info(daq_wait_ms) 1000
	
	set info(basic_client_port) 1090
	set info(basic_server_port) 1090
	set info(default_basic_addr) "0.0.0.0"
	
	set info(lwdaq_client_port) 90
	set info(default_lwdaq_addr) "10.0.0.37"
	set info(lwdaq_close_string) "\x04"

	set info(ndf_prefix) " ndf"
	set info(ndf_header_size) 100
	set info(ndf_string_length_addr) 12
	set info(ndf_min_data_size) 100000
	set info(ndf_string_size) 10000
	set info(ndf_record_size) 4
	
	set info(lwdaq_long_string_capacity) 200000
}

#
# LWDAQ_socket_open opens a connection to a TCPIP server and returns the
# socket name. The target parameter is of the form a:b where a is an IP
# address in standard x.x.x.x format or a host name, b is an IP port
# number in decimal format. The port number can be omitted, in which case
# the routine assumes a default port number. The optional parameter is 
# the message protocol name. Supported protocols are "lwdaq" and "basic". 
# The default is "lwdaq". To get the basic protocol, specify basic when 
# you open the socket. The lwdaq protocol differs from basic in that it 
# transmits an end of transmission code when we close the socket. The 
# routines that exchange messages with lwdaq servers are in the Driver.tcl
# file, and there you will see the transmit and receive routines checking 
# the socket info determine the socket protocol.
# 
proc LWDAQ_socket_open {target {protocol ""}} {
	upvar #0 LWDAQ_Info info

	# Extract the address and port from the procedure parameters.
	regexp {([^:]+)?(:([0-9]+))?} $target match addr dummy port
	if {$protocol == ""} {set protocol "lwdaq"}
	if {[lsearch "basic lwdaq" $protocol] < 0} {
		error "unrecognised protocol \"$protocol\""
	}
	if {$port == ""} {
		if {$protocol == "lwdaq"} {set port $info(lwdaq_client_port)}
		if {$protocol == "basic"} {set port $info(basic_client_port)}
	}
	if {$addr == ""} {
		if {$protocol == "lwdaq"} {set addr $info(default_lwdaq_addr)}
		if {$protocol == "basic"} {set port $info(default_basic_addr)}
	}

	# Open an asynchronous socket, and wait for it to become writeable.
	# We do this on all platforms, regardless of whether or not they
	# can tolerate blocking sockets during data transfer.
	set sock [socket -async $addr $port]
	set vwait_var_name [LWDAQ_vwait_var_name]
	upvar #0 $vwait_var_name vwait_var
	set vwait_var \
		"Waiting for connection to $addr\:$port\."
	set cmd_id [after $info(tcp_timeout_ms) [list set $vwait_var_name \
		"Timeout waiting for $sock connection to $addr\:$port\."]]
	fileevent $sock writable [list set $vwait_var_name \
		"Received connection $sock to $addr\:$port\."]
	LWDAQ_vwait $vwait_var_name
	fileevent $sock writable {}
	after cancel $cmd_id
	set vwait_var_copy $vwait_var
	unset vwait_var
	
	# If the socket did not become writeable before the timeout,
	# or if the waiting was aborted by some other routine, close
	# the socket and report an error.
	if {![string match "Received*" $vwait_var_copy]} {
		set status [fconfigure $sock -error]
		catch {close $sock}
		error "$vwait_var_copy $status"
	}
	
	# A socket error other than a timeout causes the socket to 
	# become writeable, so we now check to see if the socket
	# has become writeable as a result of an error, or whether
	# it is indeed ready to receive data.
	set status [fconfigure $sock -error]
	if {$status != ""} {
		catch {close $sock}
		error "failed to connect to $addr\:$port, $status"
	}
	
	# If this platform and tcl version requires blocking sockets
	# to avoid crashing or freezing, set the socket to block
	# program activity during reads and writes. We configure
	# the socket as a conduit for binary data, rather than eol-
	# delimited text lines using "-translation binary".
	fconfigure $sock \
		-translation binary \
		-blocking $info(blocking_sockets) \
		-buffering full
		
	# Create socket info for lwdaq connections.
	if {$protocol == "lwdaq"} {
		set sock_info "$sock $addr $port lwdaq client"
	} 
	
	# Create socket info for basic connections.
	if {$protocol == "basic"} {
		set sock_info "$sock $addr $port basic client"
	} 
	
	# Add the socket info to the LWDAQ socket list and return its name.
	lappend info(open_sockets) $sock_info
	
	return $sock
}

#
# LWDAQ_socket_protocol determines the message protocol in use on a socket.
#
proc LWDAQ_socket_protocol {sock} {
	global LWDAQ_Info
	
	set i [lsearch $LWDAQ_Info(open_sockets) "$sock *"]
	if {$i >= 0} {
		set protocol [lindex $LWDAQ_Info(open_sockets) $i end-1]
	} {
		set protocol "basic"
	}
	
	return $protocol
}

#
# LWDAQ_socket_listen opens a server socket for listening on the specified port
# on the local machine. You specify an acceptance procedure that TCL will call
# when the server accepts a new connection.
#
proc LWDAQ_socket_listen {{accept ""} {port ""}} {
	global LWDAQ_Info
	if {$port == ""} {set port $LWDAQ_Info(basic_server_port)}
	if {$accept == ""} {set accept LWDAQ_socket_accept}
	if {[llength $accept] != 1} {
		error "cannot use \"$accept\" procedure to accept connections"
	}
	set sock [socket -server $accept $port]
	lappend LWDAQ_Info(open_sockets) "$sock 0.0.0.0 $port basic listening"
	return $sock
}

#
# LWDAQ_socket_accept is an example socket acceptance routine. It sets up the
# socket to call LWDAQ_socket_interpreter whenever a new line of data arrives
# from the socket.
#
proc LWDAQ_socket_accept {sock addr port} {
	global LWDAQ_Info
	lappend LWDAQ_Info(open_sockets) "$sock $addr $port basic server"
	fconfigure $sock -buffering line
	fileevent $sock readable [list LWDAQ_socket_interpreter $sock]
	return 1
}

#
# LWDAQ_socket_interpreter is an example socket interpreter. It calls the LWDAQ
# socket closing routine to make sure that the open_sockets list is kept up to
# date.
#
proc LWDAQ_socket_interpreter {sock} {
	if {[eof $sock] || [catch {gets $sock line}]} {
		LWDAQ_socket_close $sock
	} {
		puts "$sock received \"$line\""
	}
}

#
# LWDAQ_socket_close closes a socket if it exists, and returns a 1. Otherwise
# it returns a zero. If the socket is listed in the LWDAQ open sockets list,
# this routine will remove the socket from the list. If the socket is a LWDAQ
# client, the routine sends an end of transmission character before closing the
# socket.
#
proc LWDAQ_socket_close {sock} {
	global LWDAQ_Info
	set sl [list]
	set i [lsearch $LWDAQ_Info(open_sockets) "$sock *"]
	if {$i >= 0} {
		set sock_info [lindex $LWDAQ_Info(open_sockets) $i]
		set LWDAQ_Info(open_sockets) [lreplace $LWDAQ_Info(open_sockets) $i $i]
	} {
		set sock_info ""
	}
	if {[catch {
		if {[string match "*lwdaq client*" $sock_info]} {
			puts -nonewline $sock $LWDAQ_Info(lwdaq_close_string)
		}
		close $sock
		if {[string match "*client*" $sock_info]} {
			LWDAQ_wait_ms $LWDAQ_Info(close_delay_ms)
		}
	}]} {return 0}
	if {$sock_info != ""} {return 1} {return 0}
}

#
# LWDAQ_close_all_sockets closes all open sockets.
#
proc LWDAQ_close_all_sockets {} {
	global LWDAQ_Info
	set LWDAQ_Info(open_sockets) [list]
	for {set i 1} {$i<100} {incr i} {LWDAQ_socket_close sock$i}	
	set LWDAQ_Info(open_sockets) [list]
}

#
# LWDAQ_socket_flush flushes output from a socket. It returns
# an error message starting with a capitalized nown.
#
proc LWDAQ_socket_flush {sock} {
	if {[catch {flush $sock} error_result]} {
		error "cannot flush socket, $error_result"
	}
	return 1
}

#
# LWDAQ_socket_read reads $size bytes from the input buffer of $sock. If
# the global LWDAQA_Info(blocking_sockets) variable is 1, the read
# takes place in one entire data block. While the data arrives, the LWDAQ
# program freezes. If the same variable is 0, the this procedure reads
# the data in fragments, allowing the program to respond to menu and window
# events between fragments. The routine collects all the necessary fragments
# together and returns them.
#
proc LWDAQ_socket_read {sock size} {
	global LWDAQ_Info
	
	# Check to see if the socket has any problems. If it
	# does, we abandon the read, close the socket, and report
	# and error that includes the socket status, if the socket
	# exists."
	if {[catch {set status [fconfigure $sock -error]} error_result]} {
		error "socket error, $error_result"
	}
	if {$status != ""} {
		LWDAQ_socket_close $sock
		error "broken socket, $status"
	}

	# We flush the socket to make sure we send any data
	# that might provoke the return of our data.
	LWDAQ_socket_flush $sock

	# If we are working with a blocking socket, we read
	# the data from the socket in one block. If the block
	# we get back from the read command is the wrong size,
	# we close the socket and report an error.
	if {$LWDAQ_Info(blocking_sockets)} {
		set data [read $sock $size]
		if {[string length $data] != $size} {
			LWDAQ_socket_close $sock
			error "failed to read from socket"
		}	
	} 

	# When we work with a non-blocking socket, which is
	# our default, we define a unique global variable
	# that we use in conjunction with vwait to direct a
	# data-reading loop that continues reading until all
	# the required data has arrived, or until the global
	# variable is set to an error string. A "readable"
	# file-event for the socket sets the global
	# variable, thus notifying the data-reading loop
	# that it should read all available data from the
	# socket. This "readable" file-event does not read
	# the data itself, and in this sense our use of the
	# "readable" event is unconventional. Most
	# asynchronous socket-handling in Tcl uses the
	# "readable" event to itself to read the data. But
	# we use the "readable" event only to set a global
	# variable. As a result, we retain control over the
	# asynchronous read, and we can preserve the
	# integrity of our event loop.
	if {!$LWDAQ_Info(blocking_sockets)} {
		set vwait_var_name [LWDAQ_vwait_var_name]
		upvar #0 $vwait_var_name vwait_var
		set vwait_var "Reading $size bytes from $sock."
		fileevent $sock readable [list set $vwait_var_name \
			"Reading $size bytes from $sock."]
		set data ""
		set cmd_id [after $LWDAQ_Info(tcp_timeout_ms) \
			[list set $vwait_var_name \
			"Timeout reading $size bytes from $sock."]]
		while {[string length $data] < $size} {
			fileevent $sock readable [list set $vwait_var_name \
				"Reading [expr $size - [string length $data]] of $size bytes from $sock."]
			LWDAQ_vwait $vwait_var_name
			set status [fconfigure $sock -error]
			if {$status != ""} {set vwait_var "socket error, $status"}
			if {![string match "Reading*" $vwait_var]} {break}
			set new_data [read $sock [expr $size - [string length $data]]]
			append data $new_data
			if {[string length $new_data] > 0} {
				after cancel $cmd_id
				set cmd_id [after $LWDAQ_Info(tcp_timeout_ms) \
					[list set $vwait_var_name \
					"Timeout reading $size bytes from $sock."]]
			}
		}
		fileevent $sock readable {}
		after cancel $cmd_id
		set vwait_var_copy $vwait_var
		unset vwait_var
		if {![string match "Reading*" $vwait_var_copy]} {
			LWDAQ_socket_close $sock
			error "$vwait_var_copy"
		}
	}

	return $data
} 

#
# LWDAQ_socket_write sends data to a socket's output buffer. Normally, 
# we don't send out our data until the buffer is full or we are about 
# to read from the socket. We call this 'lazy flushing'. Sending many 
# instructions in one data packet is more efficient, and we get to use 
# the TCP/IP buffer as a place to construct the string of commands. 
# But if we want to see what is happening on the driver, we might want 
# to send instructions to the LWDAQ Relay immediately. In that case, we 
# set the lazy_flush flag to zero. We must make sure puts does not add 
# a newline character to the end of every binary array it sends.
#
proc LWDAQ_socket_write {sock data} {
	global LWDAQ_Info
	if {[catch {
		puts -nonewline $sock $data
		if {!$LWDAQ_Info(lazy_flush)} {flush $sock}
		set status [fconfigure $sock -error]
		if {$status != ""} {error $status}
	} error_result]} {
		LWDAQ_socket_close $sock
		error "failed writing to $sock, $error_result"
	}
	return 1
}

#
# LWDAQ_socket_upload opens a socket to a server, writes a data string
# to the socket, and closes the socket. The target parameter is of
# the form a:b where a is an IP address in standard x.x.x.x format or a
# host name, b is an IP port number in decimal format. The routine treats
# the string as a binary object and transmits it without a carriage return
# at the end.
#
proc LWDAQ_socket_upload {target data} {
	set sock [LWDAQ_socket_open $target basic]
	LWDAQ_socket_write $sock $data
	LWDAQ_socket_close $sock
}

#
# LWDAQ_ip_addr_match takes two IP address strings and compares
# them to see if they point to the same driver socket. If the addresses
# match, the routine returns a 1. If they don't match, it returns a 0.
# A * in either parameter is a wild card, and will match.
#
proc LWDAQ_ip_addr_match {addr_1 addr_2} {
	global LWDAQ_Info
	if {[string match $addr_1 $addr_2]} {return 1}
	if {[string match $addr_2 $addr_1]} {return 1}
	regexp {([^:]+)?(:([0-9]+))?} $addr_1 match ipa_1 d1 ipp_1
	if {$ipa_1 == ""} {set ipa_1 $LWDAQ_Info(default_client_addr)}
	if {$ipp_1 == ""} {set ipp_1 $LWDAQ_Info(lwdaq_client_port)}
	regexp {([^:]+)?(:([0-9]+))?} $addr_2 match ipa_2 d1 ipp_2
	if {$ipa_2 == ""} {set ipa_2 $LWDAQ_Info(default_client_addr)}
	if {$ipp_2 == ""} {set ipp_2 $LWDAQ_Info(lwdaq_client_port)}
	if {[string match "$ipa_1\:$ipp_1" "$ipa_2\:$ipp_2"]} {return 1}
	return 0
}


#
# LWDAQ_queue_start starts the event queue if it's not running already.
#
proc LWDAQ_queue_start {} {
	global LWDAQ_Info
	if {!$LWDAQ_Info(queue_run)} {
		set LWDAQ_Info(queue_run) 1
		after $LWDAQ_Info(queue_ms) LWDAQ_queue_step
	}
	return 1
}

#
# LWDAQ_queue_step takes the first event out of the event queue
# deletes it, executes it, and posts itself to execute again after
# a delay of queue_ms.
#
proc LWDAQ_queue_step {} {
	global LWDAQ_Info
	
	# If we have pending events, take the first one out of the queue, remove
	# it from the pending list and execute it at the global scope. If we
	# encounter an error, report the error with the queue error procedure.
	if {[llength $LWDAQ_Info(queue_events)] > 0} {
		set LWDAQ_Info(current_event) [lindex $LWDAQ_Info(queue_events) 0]
		set LWDAQ_Info(queue_events) [lreplace $LWDAQ_Info(queue_events) 0 0]
		if {[catch {
			uplevel #0 $LWDAQ_Info(current_event)
		} error_result]} {
			LWDAQ_queue_error $LWDAQ_Info(current_event) $error_result
		}
	} 
	
	if {[llength $LWDAQ_Info(queue_events)] > 0} {
		set LWDAQ_Info(current_event) "Wait"
	} {
		set LWDAQ_Info(current_event) "Idle"
	}

	if {$LWDAQ_Info(queue_run)} {
		after $LWDAQ_Info(queue_ms) LWDAQ_queue_step
	} {
		set LWDAQ_Info(current_event) "Stop"
	}

	return 1
}

#
# LWDAQ_queue_stop stops the LWDAQ event manager.
#
proc LWDAQ_queue_stop {} {
	global LWDAQ_Info
	set LWDAQ_Info(queue_run) 0
	return 1
}

#
# LWDAQ_queue_clear clears the event queue.
#
proc LWDAQ_queue_clear {} {
	global LWDAQ_Info
	set LWDAQ_Info(queue_events) [list]
}

#
# LWDAQ_post adds the $event script to the LWDAQ Manager
# event list. If you set the optional parameter $place to
# "front" the the event gets added to the front of the 
# queue. Otherwise, the event gets added to the end of the
# queue.
#
proc LWDAQ_post {event {place "end"}} {
	global LWDAQ_Info
	if {$place == "front"} {
		set new_event_list [list $event]
		foreach e $LWDAQ_Info(queue_events) {
			lappend new_event_list $e
		}
		set LWDAQ_Info(queue_events) $new_event_list
	} {
		lappend LWDAQ_Info(queue_events) $event
	}
	return 1
}

#
# LWDAQ_queue_error displays an error for the event queue.
#
proc LWDAQ_queue_error {event error_result} {
	global errorInfo LWDAQ_Info
	if {$LWDAQ_Info(gui_enabled)} {
		set w [LWDAQ_toplevel_text_window 60 20]
		wm title $w "LWDAQ Event Manager Error Report"
		LWDAQ_print $w.text "Event: \"$event\""
		LWDAQ_print $w.text "ERROR: $error_result"
		LWDAQ_print $w.text "\nError Information:"
		if {[info exists errorInfo]} {
			LWDAQ_print $w.text $errorInfo blue
		} {
			LWDAQ_print $w.text "No error information available." blue
		}
	} {
		puts stdout "ERROR: \"$error_result\""
		if {[info exists errorInfo]} {
			puts stdout $errorInfo
		} {
			puts stdout "No error information available."
		}
	}
}

#
# LWDAQ_ndf_create creates a new Neuroscience Data Format file,
# which is the format used by LWDAQ to store archives of continuous
# time-series data. The NDF format begins with a four-byte format
# identifier, which is the string " ndf" (note the space at the
# beginning of the identifier string. Next come three four-byte
# numbers in big-endian format (most significant byte first). These
# are the byte offset to meta-data space, byte offset to data space, 
# and the length of meta-data string when last written. If the length
# is zero, routines that read the meta-data string should check the length
# for themselves. The header may contain additional binary information
# particular to the application. The meta-data space follows the header 
# and contains only a null-terminated character string. The data space
# comes next, and occupies the remainder of the file. This routine creates 
# a new file with an empty string and no data.
#
proc LWDAQ_ndf_create {file_name meta_data_size} {
	global LWDAQ_Info
	set f [open $file_name w]
	fconfigure $f -translation binary
	set header [binary format a4III \
		$LWDAQ_Info(ndf_prefix) \
		$LWDAQ_Info(ndf_header_size) \
		[expr $LWDAQ_Info(ndf_header_size) + $meta_data_size] \
		"0"]
	puts -nonewline $f $header
	set num_blank_bytes [expr $meta_data_size \
		+ $LWDAQ_Info(ndf_header_size) \
		- [string length $header]]
	set blank_bytes [binary format a$num_blank_bytes ""]
	puts -nonewline $f $blank_bytes
	close $f
	
	return $file_name
}

#
# LWDAQ_ndf_data_check returns the byte location of the
# file's data block and the length of the data block. If the 
# file is not NDF, the routine returns an error.
#
proc LWDAQ_ndf_data_check {file_name} {
	global LWDAQ_Info

	set f [open $file_name r]
	fconfigure $f -translation binary
	set header [read $f $LWDAQ_Info(ndf_header_size)]
	seek $f 0 end
	set e [tell $f]
	close $f
	binary scan $header a4III p m d l
	if {$p != $LWDAQ_Info(ndf_prefix)} {
		error "file \"[file tail $file_name]\" is not ndf"
	}
	
	return "$d [expr $e - $d]"
}

#
# LWDAQ_ndf_string_check returns the byte location of the
# file's meta-data string, the maximum length of the string
# and the actual length of the string. If the file is not NDF, 
# the routine returns an error.
#
proc LWDAQ_ndf_string_check {file_name} {
	global LWDAQ_Info

	set f [open $file_name r]
	fconfigure $f -translation binary
	set header [read $f $LWDAQ_Info(ndf_header_size)]
	close $f
	binary scan $header a4III p m d l
	if {$p != $LWDAQ_Info(ndf_prefix)} {
		error "file \"[file tail $file_name]\" is not ndf"
	}
	if {$l == 0} {
		set f [open $file_name r]
		fconfigure $f -translation binary
		seek $f $m
		set meta_data [read $f [expr $d - $m]]
		close $f
		binary scan $meta_data A* meta_data
		set l [string first "\x00" $meta_data]
		if {$l < 0} {set l [string length $meta_data]}
	}
	
	return "$m [expr $d - $m] $l"
}

#
# LWDAQ_ndf_string_write re-writes the meta-data string in an
# NDF-file on disk but leaves the data intact. The routine takes
# roughly 100 us to write a one-byte string and 1 ms to write
# a 10-kbyte string (on a 1.3 GHz G3 iBook).
#
proc LWDAQ_ndf_string_write {file_name meta_data} {
	global LWDAQ_Info

	scan [LWDAQ_ndf_string_check $file_name] %d%d%d location max_len actual_len
	
	set mdl [string length $meta_data]
	if {$mdl > $max_len} {
		error "trying to write $mdl bytes in space $max_len bytes"
	}

	set f [open $file_name r+]
	fconfigure $f -translation binary
	seek $f $LWDAQ_Info(ndf_string_length_addr)
	puts -nonewline $f [binary format I [string length $meta_data]]
	seek $f $location
	puts -nonewline $f $meta_data
	puts -nonewline $f "\x00"
	close $f
	
	return $mdl
}

#
# LWDAQ_ndf_string_read returns the meta-data string in an NDF file.
#
proc LWDAQ_ndf_string_read {file_name} {
	scan [LWDAQ_ndf_string_check $file_name] %d%d%d location max_len actual_len
	
	set f [open $file_name r]
	fconfigure $f -translation binary
	seek $f $location
	set meta_data [read $f $actual_len]
	close $f

	return $meta_data
}

#
# LWDAQ_ndf_string_append appends a meta-data string to the one that already 
# exists in an NDF file. It speeds itself up by using the actual length 
# value stored in the file header. It does not read the existing string
# from the file.  The routine takes roughly 100 us to append a one-byte 
# string regardless of the length of the existing string, and 1 ms to append
# a 10-kbyte string (on a 1.3 GHz G3 iBook).
#
proc LWDAQ_ndf_string_append {file_name meta_data} {
	global LWDAQ_Info

	scan [LWDAQ_ndf_string_check $file_name] %d%d%d location max_len actual_len
	set mdl [string length $meta_data]
	if {[expr $mdl + $actual_len] > $max_len} {
		error "trying to append $mdl bytes to $actual_len bytes in space $max_len bytes"
	}

	set f [open $file_name r+]
	fconfigure $f -translation binary
	seek $f $LWDAQ_Info(ndf_string_length_addr)
	puts -nonewline $f [binary format I [expr $actual_len + $mdl]]
	seek $f [expr $location + $actual_len]
	puts -nonewline $f $meta_data
	puts -nonewline $f "\x00"
	close $f

	return [string length $meta_data]
}

#
# LWDAQ_ndf_data_append appends new data to an NDF file.
#
proc LWDAQ_ndf_data_append {file_name data} {
	set f [open $file_name a]
	fconfigure $f -translation binary
	puts -nonewline $f $data
	close $f
	return 1
}

#
# LWDAQ_ndf_data_read reads num_bytes of data out of an
# NDF file data block, starting at byte start_addr. The
# first byte in the data block is byte zero. If you specify
# * for num_bytes, the routine reads all available data 
# bytes from the file.
#
proc LWDAQ_ndf_data_read {file_name start_addr num_bytes} {
	scan [LWDAQ_ndf_data_check $file_name] %d%d d l
	if {$num_bytes == "*"} {set num_bytes $l}
	set f [open $file_name r]
	fconfigure $f -translation binary
	seek $f [expr $d + $start_addr]
	set data [read $f $num_bytes]
	close $f
	return $data
}

#
# LWDAQ_xml_get_list takes an xml string and extracts the list of records from 
# the database that matches a specified tag you specify. If an xml string contains 
# one thousand entries delimited by <donor>...</donar>, the routine
# returns a TCL list of the contents of all the <donor> entries when you
# pass it the xml string and the tag "donar". You don't pass it the brackets
# on either side of the tag, even though these brackets always appear in the
# xml string. Each element in the list the routine returns will be the contents
# of a single record, with its start and end tags removed. You can now apply
# this same routine to each element in this list sequentially, to extract fields from
# each record, and you can apply LWDAQ_xml_get to these fields to look at sub-fields
# and so on.
#
proc LWDAQ_xml_get_list {xml tag} {
	set result [list]
	set index 0
	while {[regexp -start $index <$tag> $xml match]} {
		set i_start [string first "<$tag>" $xml $index]
		set i_end [string first "</$tag>" $xml $index]
		if {$i_start < 0} {break}
		if {$i_end < 0} {break}
		set field \
			[string range $xml \
				[expr $i_start + [string length "<$tag>"]] \
				[expr $i_end - 1]]
		set index [expr $i_end + [string length "</$tag>"]]
		lappend result $field
	}
	return $result
}

#
# LWDAQ_xml_get calls LWDAQ_xml_get_list and returns the contents of the first
# list entry in the result. We use this routine to extract the value of a field 
# in an xml record.
#
proc LWDAQ_xml_get {xml tag} {
	return [lindex [LWDAQ_xml_get_list $xml $tag] 0]
}

#
# LWDAQ_write_image_file writes an image to disk in the LWDAQ
# image format. If the file name has tail ".gif" (case insensitive),
# the routine saves the file in GIF format. If the file name ends
# with ".ndf", the routine writes the image file as an NDF file.
# Otherwise, the routine saves the image in the DAQ format. In a GIF
# or DAQ file, the LWDAQ image header, with dimensions, analysis bounds, 
# and results string, will be embedded in the first line of the image.
# In an NDF file, this header information is lost. The results string is 
# saved in the meta-data string and the image contents, starting with
# the first pixel of the first row, are stored in the NDF data block.
#
proc LWDAQ_write_image_file {image_name outfile_name} {
	global LWDAQ_Info
	set file_type [string tolower [file extension $outfile_name]]
	switch -exact -- $file_type {
		".gif" {
			set p [image create photo]
			lwdaq_draw $image_name $p -show_bounds 0 -clear 1
			$p write $outfile_name -format GIF
			image delete $p
		} 
		".ndf" {
			LWDAQ_ndf_create $outfile_name $LWDAQ_Info(ndf_string_size)
			LWDAQ_ndf_string_write $outfile_name [lwdaq_image_results $image_name]
			set data [lwdaq_image_contents $image_name \
				-truncate 1 -data_only 1 -record_size $LWDAQ_Info(ndf_record_size)]
			LWDAQ_ndf_data_append $outfile_name $data		
		}
		default {
			set outfile [open $outfile_name w]
			fconfigure $outfile -translation binary
			puts -nonewline $outfile \
				[lwdaq_image_contents $image_name -truncate 1]
			close $outfile
		}
	}
	return 1
}

#
# LWDAQ_read_image_file reads an image file from disk into
# the lwdaq image list and returns its list name. If the file
# name ends with ".gif" (case insensitive), the routine reads
# the file as a GIF image. The gray-scale values in the
# first line of the image should, for best results, contain
# a DAQ image header. The DAQ header contains the image 
# dimensions, the analysis bounds, and a result string. Two-
# dimensional image data begins only on the second line of the
# image. If the file name ends with ".ndf", the routine reads
# the file as an NDF (Neuroscience Data Format) file. It creates
# a new image that is approximately square, and large enough to
# contain the NDF data. It sets the image result string equal
# to the NDF meta-data string. It copies the NDF data into the
# image data area, which begins with the first pixel of the second
# row in the new image. If the file name ends with any other 
# extension, the routine reads the image in as a DAQ file.
# You can specify a name for the image if you like, otherwise 
# the routine will assign its own name.
#
proc LWDAQ_read_image_file {infile_name {image_name ""}} {
	global LWDAQ_Info
	set file_type [string tolower [file extension $infile_name]]
	switch -exact -- $file_type {
		".gif" {
			if {!$LWDAQ_Info(gui_enabled)} {
				error "gif format supported only with gui enabled"
			}
			set p [image create photo]
			$p read $infile_name -format GIF
			set data [lwdaq_photo_contents $p]
			image delete $p
			set image_name [lwdaq_image_create \
				-try_header 1 -data $data -name $image_name]	
		} 
		".ndf" {
			scan [LWDAQ_ndf_data_check $infile_name] %d%d a l
			if {$l < $LWDAQ_Info(ndf_min_data_size)} {
				set l $LWDAQ_Info(ndf_min_data_size)
			}
			set width [expr round(sqrt($l)) + 1]	
			set image_name [lwdaq_image_create \
				-try_header 0 -name $image_name \
				-width $width -height $width \
				-results [LWDAQ_ndf_string_read $infile_name] ]
			lwdaq_data_manipulate $image_name write 0 \
				[LWDAQ_ndf_data_read $infile_name 0 *]
		}
		default {
			set infile [open $infile_name r]
			fconfigure $infile -translation binary
			set data [read $infile]
			close $infile
			set image_name [lwdaq_image_create \
				-try_header 1 -data $data -name $image_name]	
		}
	}
	return $image_name
}

#
# LWDAQ_image_bounds returns a string containing the analysis
# bounds of an image. You can specify new bounds with four numbers
# in the order left, top, right, bottom. If you specify zero (0) 
# for the right or bottom bounds, the routine sets them
# to their maximum values. You can save the result of this routine
# in a string, change the bounds by calling the routine again, and
# then restore the earlier values by passing the saved string as its
# argument. But you have to do this with "eval" so that the TCL 
# interpreter will break the string into four elements before passing
# it to LWDAQ_image_bounds.
#
proc LWDAQ_image_bounds {image {left ""} {top ""} {right ""} {bottom ""}} {
	set s [lwdaq_image_characteristics $image]
	set j_max [expr [lindex $s 8] - 1]
	set i_max [expr [lindex $s 9] - 1]
	if {[string is integer -strict $left]} {
		if {$left < 0} {error "left boundary < left edge"}
		if {$left > $i_max} {error "left boundary > right edge"}
		lwdaq_image_manipulate $image none -left $left
	} {
		if {$left != ""} {error "expected integer, received \"$left\""}
	}
	if {[string is integer -strict $top]} {
		if {$top < 0} {error "top boundary < top edge"}
		if {$top > $j_max} {error "top boundary > bottom edge"}
		lwdaq_image_manipulate $image none -top $top
	} {
		if {$top != ""} {error "expected integer, received \"$top\""}
	}
	if {[string is integer -strict $right]} {
		if {$right == 0} {set right $i_max}
		if {$right < $left} {error "right boundary < left boundary"}
		if {$right > $i_max} {error "right boundary > right edge"}
		lwdaq_image_manipulate $image none -right $right
	} {
		if {$right != ""} {error "expected integer, received \"$right\""}
	}
	if {[string is integer -strict $bottom]} {
		if {$bottom == 0} {set bottom $j_max}
		if {$bottom < $top} {error "bottom boundary < top boundary"}
		if {$bottom > $j_max} {error "bottom boundary > bottom edge"}
		lwdaq_image_manipulate $image none -bottom $bottom
	} {
		if {$bottom != ""} {error "expected integer, received \"$bottom\""}
	}
	return [lrange [lwdaq_image_characteristics $image] 0 3]
}

#
# LWDAQ_image_pixels returns a string containing the intensities
# of all pixels in the analysis boundaries of an image. The pixels
# form an array by use of spaces and line breaks. There is a line
# break at the end of each row of pixels and a space between each 
# column. You can paste the output from this routine directly into
# Excel and obtain a two-dimensional intensity array.
#
proc LWDAQ_image_pixels {image_name} {
	set binary_pixels [lwdaq_image_contents $image_name]
	binary scan $binary_pixels c* string_pixels
	set bounds [lwdaq_image_characteristics $image_name] 
	set left [lindex $bounds 0]
	set top [lindex $bounds 1]
	set right [lindex $bounds 2]
	set bottom [lindex $bounds 3]
	set i_size [lindex $bounds 9]
	set j_size [lindex $bounds 8]
	set i 0
	set j 0
	set array_pixels ""
	foreach p $string_pixels {
		if {($i >= $left) && ($i <= $right) && ($j >= $top) && ($j <= $bottom)} {
			if {$p < 0} {set p [expr 256 + $p]}
			append array_pixels "$p "
			if {$i == $right} {append array_pixels "\n"}
		}
		incr i
		if {$i == $i_size} {
			set i 0
			incr j
		}
		if {$j > $bottom} {break}
	}
	return $array_pixels
}

#
# LWDAQ_get_file_name opens a file browser window and allows the user
# to select one or more files in the file system. The user can 
# select multiple files when multiple is one (1). By default, multiple
# is zero (0). The routine starts in the LWDAQ working directory, and
# when the user selects a file, it sets the working directory to the
# directory containing the file. If the user selects no file, or presses
# the cancel button in the pop-up window, the routine does nothing.
# We can specify an initial directory for the file search. By default
# the search begins in the LWDAQ working directory.
#
proc LWDAQ_get_file_name { {multiple 0} {initialdir ""} } {
	global LWDAQ_Info

	if {$initialdir == ""} {set initialdir $LWDAQ_Info(working_dir)}
	if {![file exists $initialdir]} {
		set initialdir $LWDAQ_Info(program_dir)
	}
	
	set fl [tk_getOpenFile \
		-initialdir $initialdir \
		-multiple $multiple]
	if {$fl == ""} {return ""}

	if {$multiple} {
		set LWDAQ_Info(working_dir) [file dirname [lindex $fl 0]]
	} {
		set LWDAQ_Info(working_dir) [file dirname $fl]
	}
	
	return $fl
}

#
# LWDAQ_get_dir_name opens a file browser and allows you to
# select a directory. We can specify an initial directory for 
# the file search. By default the search begins in the LWDAQ 
# working directory.
#
proc LWDAQ_get_dir_name { {initialdir ""} } {
	global LWDAQ_Info

	if {$initialdir == ""} {set initialdir $LWDAQ_Info(working_dir)}
	if {![file exists $initialdir]} {
		set initialdir $LWDAQ_Info(program_dir)
	}

	set dirname [tk_chooseDirectory \
		-initialdir $initialdir \
		-mustexist 0]
	if {$dirname == ""} {return ""}
	
	set LWDAQ_Info(working_dir) $dirname

	return $dirname
}

#
# LWDAQ_put_file_name opens a file browser window and allows the user
# to specify an output file. The browser allows the user to select an
# existing directory in the file system, and to type in a name for the
# file within that directory. If the "name" parameter is set when this
# procedure is called, the value of "name" will be the default file name
# in the browser window.
#
proc LWDAQ_put_file_name { {name ""} } {
	global LWDAQ_Info
	if {[file dirname $name] == "."} {
		if {![file exists $LWDAQ_Info(working_dir)]} {
			set LWDAQ_Info(working_dir) $LWDAQ_Info(program_dir)
		}
		set initialdir $LWDAQ_Info(working_dir)
	} {
		set initialdir [file dirname $name]
	}
	set f [tk_getSaveFile \
		-initialdir $initialdir \
		-initialfile [file tail $name]]
	if {$f != ""} {set LWDAQ_Info(working_dir) [file dirname $f]}
	return $f
}

#
# LWDAQ_find_files takes a directory and a glob matching pattern 
# to produce a list of all matching files in the directory and
# its sub-directories. It assembles the list by calling itself
# recursively. The routine is not sensitive to case in the matching
# pattern. The list is sorted in increasing alphabetical order.
#
proc LWDAQ_find_files {directory pattern} {
	set ffl [list]
	set dfl [glob -nocomplain [file join $directory *]]
	foreach fn $dfl {
		if {[string match -nocase *$pattern $fn]} {
			lappend ffl $fn
		}
		if {[file isdirectory $fn]} {
			foreach fn [LWDAQ_find_files $fn $pattern] {
				lappend ffl $fn
			}
		}
	}
	return [lsort -increasing $ffl]
}


#
# LWDAQ_split takes a list of parameters delimited by white space,
# colons, commas, equal-signs, semi-colons, and null characters. It
# returns a list containing no empty elements.
#
proc LWDAQ_split {s} {
	set a [string map {; \  , \  \0 \  = \ } $s]
	set a [split $a]
	set b [list]
	foreach e $a {if {![string is space $e] && !($e == "\0")} {lappend b $e}}
	return $b
}

#
# LWDAQ_decimal_to_binary takes a decimal integer, $decimal, and returns
# the least significant $length digits of its binary representation as a string
# of ones and zeros. By default, $length is 32, which is also the maximum
# value of $length supported by the routine. We include comment in the code 
# to explain our use of binary format and binary scan. It turns out that 
# we have to use both these routines to achieve our end. First we format 
# the integer as a binary object, then we scan this binary object for its 
# bits.
#
proc LWDAQ_decimal_to_binary {decimal {length 32}} {
	# Convert $i into a four-byte binary object in memory.
	set binary_object [binary format I $decimal]
	# Scan the bits of $binary_object to create a binary string.
	binary scan $binary_object B32 binary_string
	# Extract the lower $n bits of the string.
	if {$length>32} {set length 32}
	set result [string range $binary_string [expr 32 - $length] 31]
	# Return this string.
	return $result
}

#
# LWDAQ_set_bit takes a string of ones and zeros, called binary_string, and 
# sets bit number $bit_num to $value. By default, $value is 1, in keeping 
# with the electrical engineer's meaning of the word "set".
#
proc LWDAQ_set_bit {binary_string bit_num {value 1}} {
	return [string replace $binary_string end-$bit_num end-$bit_num $value]
}

#
# LWDAQ_time_stamp returns a year, month, date, hour, seconds
# time-stamp string for record keeping, or converts a [clock seconds] 
# result into a time-stamp.
#
proc LWDAQ_time_stamp { {s ""} } {
	if {$s == ""} {set s [clock seconds]}
	return [clock format $s -format "%Y%m%d%H%M%S"]
}

#
# LWDAQ_is_error_result returns 1 if and only if the first string
# begins with "ERROR: " (case sensitive).
#
proc LWDAQ_is_error_result {s} {
	return [string match "ERROR: *" $s]
}

#
# LWDAQ_vwait_var_name will return a unique name for a global 
# vwait variable. All LWDAQ routines that call TCL's vwait routine
# use a global timeout variable assigned by this routine, so that
# its partner routine LWDAQ_stop_vwaits can go through all existing
# timeout variables and set them, which aborts the vwaits.
#
proc LWDAQ_vwait_var_name {} {
	global LWDAQ_Info

	set i 1
	global LWDAQ_vwait_$i
	while {[info exists LWDAQ_vwait_$i]} {
		incr i
		global LWDAQ_vwait_$i
	}
	
	return LWDAQ_vwait_$i
}

#
# LWDAQ_vwait calls vwait, but also keeps a list of the current
# vwait variable stack, which the System Monitor uses to keep 
# track of LWDAQ vwaits.
#
proc LWDAQ_vwait {var_name} {
	global LWDAQ_Info $var_name
	
	if {$LWDAQ_Info(reset)} {
		# If a LWDAQ reset is in progress, we abort.
		return "Reset"
	} 

	# If there is no reset, we add the variable name to 
	# global vwait variable list and wait until it is 
	# set by some other process.
	lappend LWDAQ_Info(vwait_var_names) $var_name
	
	# Wait until the variable is set by some command or event.
	vwait $var_name
	
	# Delete the variable from the list, provided it is still
	# in there.
	set index [lsearch $LWDAQ_Info(vwait_var_names) $var_name]
	if {$index >= 0} {
		set LWDAQ_Info(vwait_var_names) \
			[lreplace $LWDAQ_Info(vwait_var_names) $index $index]
	}
	
	# If the variable has been set, return its value.
	# Otherwise return an empty string.
	if {[info exists $var_name]} {
		return [set $var_name]
	} {
		return ""
	}
}

#
# LWDAQ_stop_vwaits sets all vwait variables generated by the above 
# routine, which aborts all the current LWDAQ vwaits. Because TCL 
# vwaits are nested, LWDAQ_stop_vwaits will cause any depth of nesting 
# to terminate, even it the nesting is in deadlock.
#
proc LWDAQ_stop_vwaits {} {
	global LWDAQ_Info

	foreach var $LWDAQ_Info(vwait_var_names) {
		global $var
		if {[info exists $var]} {
			set $var "Aborted waiting for $var."
		}
	}

	return [llength $LWDAQ_Info(vwait_var_names)]
}

#
# LWDAQ_wait_ms waits for the specified time. By default, the routine 
# assigns a unique global name of its own. But it allows you to specify
# the name of the variable that will be used to control the delay. In this
# way, you can abort the waiting period by setting the variable from a 
# button or some other event command. When the waiting is done, we unset
# the waiting variable. When the waiting is aborted, we cancel the waiting 
# command so that the waiting variable will not be set later.
#
proc LWDAQ_wait_ms {time_ms {vwait_var_name ""}} {

	if {$vwait_var_name == ""} {
		set vwait_var_name [LWDAQ_vwait_var_name]
	}

	upvar #0 $vwait_var_name vwait_var
	set vwait_var "Waiting for $time_ms ms."
	set cmd [after $time_ms \
		[list set $vwait_var_name "Waited for $time_ms ms."]]
		
	LWDAQ_vwait $vwait_var_name
	
	set vwait_var_copy $vwait_var
	unset vwait_var
	after cancel $cmd
	
	return $vwait_var_copy
}

#
# LWDAQ_wait_seconds waits for the specified time.
#
proc LWDAQ_wait_seconds {t {vwait_var_name ""}} {
	LWDAQ_wait_ms [expr round( 1000 * $t )] $vwait_var_name
}

#
# LWDAQ_watch waits for a global variable to aquire a particular
# value, at which point it executes a command. We give the name
# of the global variable and the awaited value. When the condition
# is met, the procedure executes the command, otherwise it posts
# itself to the event queue. The command is a script.
#
proc LWDAQ_watch {watch_var watch_val command} {
	upvar #0 $watch_var wv
	if {[info exists wv] && ($wv == $watch_val)} {
		uplevel #0 $command
	} {
		LWDAQ_post [list LWDAQ_watch $watch_var $watch_val $command]
	}
}

#
# LWDAQ_update passes control to the TclTk event handler for analysis_update_ms.
# During this time, the event handler can perform window updates, respond to
# mouse clicks, and service TCPIP sockets.
#
proc LWDAQ_update {} {
	global LWDAQ_Info
	LWDAQ_wait_ms $LWDAQ_Info(update_ms)
	update
	return 1
}

#
# LWDAQ_support allows you to move windows while running a computation. You simply
# include a call to this routine in your repeating loop. Every support_ms, the 
# routine will call LWDAQ_update to handle system activity.
#
proc LWDAQ_support {} {
	global LWDAQ_Info
	set c [clock milliseconds]
	if {![info exists LWDAQ_Info(support_time)]} {set LWDAQ_Info(support_time) $c}
	if {$LWDAQ_Info(support_time) <= $c} {
		LWDAQ_update
		set LWDAQ_Info(support_time) [expr [clock milliseconds] + $LWDAQ_Info(support_ms)]
		return 1
	} {
		return 0
	}
}

#
# LWDAQ_global_var_name will return a unique name for a global 
# variable.
#
proc LWDAQ_global_var_name {} {
	set count 0
	set var "lwdaq_global_[incr count]"
	global $var
	while {[info exists $var]} {
		set var "lwdaq_global_[incr count]"
		global $var
	}
	return $var
}

#
# LWDAQ_random returns a number between min and max. If both
# min and max are integers, then the number returned is also
# and integer. If either min or max is real, then the number
# returned is real. The random calculation we take from Practical
# Programming in TCL and TK by Brent Welch et al. 
#
proc LWDAQ_random {{min 0.0} {max 1.0}} {
	global LWDAQ_random_seed
	if {![info exists LWDAQ_random_seed]} {
		set LWDAQ_random_seed [clock format [clock seconds] -format "1%M%S"]
	}
	set LWDAQ_random_seed [expr ($LWDAQ_random_seed*9301 + 49297) % 233280]
	set random [expr $LWDAQ_random_seed/double(233280)]
	set random [expr $min + ($max - $min)*$random]
	if {[string is integer $min] && [string is integer $max]} {
		set random [expr round($random)]
	}
	return $random
}

#
# LWDAQ_random_wait_ms waits for a random number of milliseconds between
# min and max. During the wait, it passes control to the TCL/TK event loop
# so that idle tasks can be executed.
#
proc LWDAQ_random_wait_ms {{min 0} {max 1000}} {
	set time [LWDAQ_random [expr round($min)] [expr round($max)]]
	LWDAQ_wait_ms $time
	return $time
}

#
# LWDAQ_load_settings reads settings out of the specified settings
# file. If you do not specify a setting file name, the routine
# opens a file browser window so the user can choose a settings file.
#
proc LWDAQ_load_settings {{file_name ""}} {
	LWDAQ_run_tool $file_name
	return 1
}

#
# LWDAQ_save_settings saves instrument settings to a settings file, as
# well as a few elements from the Info array. If you do not specify a 
# settings file name, the routine opens a file browser so the user can 
# choose a file name.
#
proc LWDAQ_save_settings {{file_name ""}} {
	global LWDAQ_Info LWDAQ_Driver
	if {$file_name == ""} {set file_name [LWDAQ_put_file_name Settings.tcl]}
	if {$file_name == ""} {return 0}
	set f [open $file_name w]
	foreach i $LWDAQ_Info(instruments) {
		upvar LWDAQ_info_$i info
		set vlist [array names info]
		foreach v $vlist {
			puts $f "set LWDAQ_info_$i\($v) \"$info($v)\""
		}
		upvar LWDAQ_config_$i config
		set vlist [array names config]
		foreach v $vlist {
			puts $f "set LWDAQ_config_$i\($v) \"$config($v)\""
		}
	}
	foreach i "quiet_update queue_ms support_ms basic_client_port \
		default_to_stdout server_address_filter lwdaq_close_string server_listening_port \
		lwdaq_client_port max_daq_attempts basic_server_port working_dir tcp_timeout_ms \
		lazy_flush daq_wait_ms tcp_timeout_ms monitor_ms update_ms close_delay_ms \
		default_lwdaq_addr" {
		puts $f "set LWDAQ_Info($i) \"$LWDAQ_Info($i)\""
	}
	close $f
	return 1
}

#
# LWDAQ_debug_dump opens a file called debug_dump.txt in the
# program directory and appends a string to the end of it, then
# closes the file.
#
proc LWDAQ_debug_dump {s} {
	global LWDAQ_Info
	set f [open [file join $LWDAQ_Info(program_dir) debug_dump.txt] a]
	puts $f $s
	close $f
	return $s
}

#
# LWDAQ_proc_list returns a list of all procedures declared in
# the specified file that match the proc_name string. The proc_name
# can contain wild cards * and ?. Each procedure must be declared
# on a new line that begins with "proc " followed by the procedure
# name.
#
proc LWDAQ_proc_list {{proc_name "LWDAQ_*"} {file_name ""} } {
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
		if {$file_name == ""} {return}
	}
	set f [open $file_name r]
	set names ""
	while {[gets $f line] >= 0} {
		if {[string match "proc $proc_name *" $line]} {
			set a [string last "\{" $line]
			set a [string replace $line $a end]
			set a [lindex $a 1]
			lappend names $a 
		}
	}
	close $f
	return $names
}

#
# LWDAQ_proc_description returns a list of procedure descriptions,
# such as this one, as exctracted from the TCL/TK script that defines
# the procedure. If there are procedures in the script that match the
# proc_name parameter, but do not have their own descriptions, the
# routine returns an empty element in its list. The script must indicate
# the description by quoting the procedure name after "# " on a new line.
# If you pass keep_breaks=1, the procedure will retain the original 
# line breaks, which can be useful for printing directly to the TCL 
# console.
proc LWDAQ_proc_description {{proc_name "LWDAQ_*"} {file_name ""} {keep_breaks 0} } {
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
		if {$file_name == ""} {return}
	}
	set proc_list [LWDAQ_proc_list $proc_name $file_name]
	set description ""
	foreach p $proc_list {
		set f [open $file_name r]
		set d "No description available."
		while {[gets $f line] >= 0} {
			if {[string match "# $p *" $line]} {
				set d $line
				while {[gets $f line] >= 0} {
					if {[string match "# *" $line]} {
						if {$keep_breaks == 1} {append d "\n"} {append d " "}
						append d "$line"
					} {
						break
					}
				}
				set d [string map {"# " ""} $d]
			}
		}
		lappend description $d
		close $f
	}
	if {[llength $description] > 1} {
		return $description
	} {
		return [lindex $description 0]
	}
}

#
# LWDAQ_proc_declaration returns a list of procedure declarations that
# match proc_name from the script file specified by file_name. The script
# must indicate a procedure declaration by quoting the procedure name after
# "proc " on a new line.
#
proc LWDAQ_proc_declaration {{proc_name "LWDAQ_*"} {file_name ""} } {
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
		if {$file_name == ""} {return}
	}
	set proc_list [LWDAQ_proc_list $proc_name $file_name]
	set declaration ""
	foreach p $proc_list {
		set f [open $file_name r]
		set d ""
		while {[gets $f line] >= 0} {
			if {[string match "proc $proc_name *" $line]} {
				set d [string last "\{" $line]
				set d [string replace $line $d end]
			}
		}
		lappend declaration $d
		close $f
	}
	if {[llength $declaration] > 1} {
		return $declaration
	} {
		return [lindex $declaration 0]
	}
}

#
# LWDAQ_proc_definition returns a list of procedure definitions that
# match proc_name from the script file specified by file_name. The script
# must indicate the start of a procedure definition by quoting the 
# procedure name after "proc " on a new line. It must indicate the end
# of the procedure definition with a line consisting only of a single
# right-brace "}".
#
proc LWDAQ_proc_definition {{proc_name "LWDAQ_*"} {file_name ""} } {
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
		if {$file_name == ""} {return}
	}
	set proc_list [LWDAQ_proc_list $proc_name $file_name]
	set definition ""
	foreach p $proc_list {
		set f [open $file_name r]
		set d ""
		while {[gets $f line] >= 0} {
			if {[string match "proc $proc_name *" $line]} {
				set d $line
				while {[gets $f line] >= 0} {
					append d "\n$line"
					if {$line == "\}"} {break}
				}
			}
		}
		lappend definition $d
		close $f
	}
	if {[llength $definition] > 1} {
		return $definition
	} {
		return [lindex $definition 0]
	}
}

#
# LWDAQ_script_description returns the introductory paragraph of a 
# TCL/TK script. It extracts the script name from the file_name
# parameter. The script name is the tail of the file_name. The script
# must indicate the introductory paragraph by quoting the script name
# after "# " on a new line. If you pass keep_breaks=1, the procedure
# will retain the original line breaks, which can be useful for printing
# directly to the TCL console.
#
proc LWDAQ_script_description {{file_name ""} {keep_breaks 0} } {
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
		if {$file_name == ""} {return}
	}
	set script_name [file tail $file_name]
	set f [open $file_name r]
	set description ""
	while {[gets $f line] >= 0} {
		if {[string match "# $script_name *" $line]} {
			append description $line
			while {[gets $f line] >= 0} {
				if {[string match "# *" $line]} {
					if {$keep_breaks == 1} {
						append description "\n"
					} {
						append description " "
					}
					append description "$line"
				} {
					break
				}
			}
		}
	}
	close $f
	set description [string map {"# " ""} $description]
	set description [regsub -all "$script_name" $description \
		"<a href=\"../../Software/Sources/$script_name\">$script_name</a>"]
	return $description
}

#
# LWDAQ_list_commands lists LWDAQ commands.
#
proc LWDAQ_list_commands { {pattern *} } {
	set clist [info commands lwdaq_$pattern]
	set sclist [lsort -dictionary $clist]
	foreach command $sclist {puts $command}
	set clist [info commands LWDAQ_$pattern]
	set sclist [lsort -dictionary $clist]
	foreach command $sclist {puts $command}
	return 1
}

#
# help provides help on all matching routines.
#
proc help { {pattern ""} {option "none"}} {
	global LWDAQ_Info
	if {$pattern == ""} {
		puts "Try LWDAQ_list_commands to get a list of LWDAQ commands."
		puts "Try \"help\" or \"man\" followed by a procedure name containing wild cards."
		puts "Try the LWDAQ Manual (web address is in the About dialog box)."
		puts "Try typing a routine name to get a list of parameters it requires."
		return
	}
	foreach f $LWDAQ_Info(scripts) {
		set names [LWDAQ_proc_list $pattern $f]
		if {[llength $names] > 0} {
			puts ""
			puts "From [file tail $f]: "
			puts ""
			foreach n $names {
				puts [LWDAQ_proc_description $n $f 1]
				puts ""
				if {$option == "definition"} {
					puts [LWDAQ_proc_definition $n $f]
					puts ""
				}
			}
		}
	}
}

#
# man calls help.
#
proc man { {pattern ""} {option "none"} } {
	help $pattern $option
}

#
# LWDAQ_html_contents creates a table of contents for an HTML document.
# Each h2 and h3 level heading must have a unique name in the document, because
# this routine uses the heading text as the identifier for each heading line.
# The table of contents will be placed underneath an h2 heading with text
# "Contents". Any pre-existing table of contents between this h2 heading and the
# next h2 heading will be removed from the document. The routine takes three
# optional parameters. The first two are cell_spacing and num_columns for the 
# h3 heading tables beneath each h2 heading. The third parameter is the name of the
# HTML file to be processed.
#
proc LWDAQ_html_contents { {cell_spacing 4} {num_columns 4} {file_name ""} } {
	# procedure that tabulates headings.
	proc LWDAQ_html_contents_tabulate {names outfile cell_spacing num_columns} {
		if {[llength $names] > 0} {
			puts $outfile "<table cellspacing=$cell_spacing>"
			set index 0
			foreach n $names {
				if {$index==0} {puts -nonewline $outfile "<tr><td></td>"}
				puts -nonewline $outfile "<td><a href=\"\#$n\">$n</a></td>"
				if {$index==[expr $num_columns -1]} {puts -nonewline $outfile "</tr>\n"}
				incr index
				if {$index==$num_columns} {set index 0}
			}
			if {$index != 0} {puts $outfile "</tr>"}
			puts $outfile "</table>"
			return 1
		} {
			return 0
		}
	}
	
	# Find the input file.
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
		if {$file_name == ""} {return 0}
	}
	set ft [file tail $file_name]
	set nfn [file join [file dirname $file_name] "new_$ft"]
	
	# Open the input file for reading, and temporary file for writing.
	set f [open $file_name r]
	set nf [open $nfn w]
	
	# Make a list of headings and instert heading identifiers in text of
	# temporary file.
	set headings [list]
	while {[gets $f line] > -1} {
		set h2 [regexp {[^<]*<h2([^>]*)>([^<]*)} $line a b c d e]
		if {$h2} {
			lappend headings h2
			lappend headings $c
			puts $nf "<h2 id=\"$c\">$c</h2>"
		} {
			set h3 [regexp {[^<]*<h3([^>]*)>([^<]*)} $line a b c d e]
			if {$h3} {
				lappend headings h3
				lappend headings $c
				puts $nf "<h3 id=\"$c\">$c</h3>"
			} {
				puts $nf $line
			}
		}
	}
	lappend headings "h2"
	lappend headings "End"
	
	# Close both files.
	close $f
	close $nf
	
	# Open the input file for writing, and the temporary file for reading.
	set f [open $file_name w]
	set nf [open $nfn r]
	
	# Copy $nf to $f until and including contents heading
	while {[gets $nf line] > -1} {
		puts $f $line
		if {[regexp {[^<]*<h2([^>]*)>([^<]*)Contents} $line a b c d e]} {
			puts $f ""
			break
		}	
	}
	
	# Create table of contents after contents heading
	set h3list [list]
	foreach {h t} $headings {
		if {$h == "h2"} {
			if {[llength $h3list] > 0} {
				LWDAQ_html_contents_tabulate $h3list $f $cell_spacing $num_columns
				set h3list [list]
			}
			if {($t != "End") && ($t != "Contents")} {
				puts $f "<a href=\"\#$t\">$t</a><br>"
			}
		}
		if {$h == "h3"} {
			lappend h3list $t
		}
	}
	
	# Add a line break before the next heading.
	puts $f ""
	
	# Skip over old contents until next heading.
	while {[gets $nf line] > -1} {
		if {[regexp {[^<]*<h2([^>]*)>([^<]*)} $line a b c d e]} {
			puts $f $line
			break
		}	
	}
	
	# Copy the rest of the file.
	while {[gets $nf line] > -1} {
		puts $f $line
	}
	
	# Close the files.
	close $f
	close $nf
	
	# Delete the temporary file.
	file delete $nfn
	
	return 1
}	

#
# LWDAQ_html_split takes a long file with h2-level chapters
# and splits it into chapter files. It puts the chapter files in
# a new directory. If the original file is called A.html, the
# directory is A, and the chapters are named A_1.html to A_n.html,
# where n is the number of chapters. There will be another file
# called index.html, which is the table of contents. Each chapter
# provides a link to the table of contents, to the previous chapter,
# and to the next chapter. Each preserves the header and stylsheets
# used in the original file. All local html links get displaced
# downwards by one level in order to account for the chapters being
# buried in a new directory. Internal links in the document are
# broken, so you will have to go in and fix them by hand. Any h2-level
# heading called "Contents" will be removed from the list of chapter,
# because we assume it's a table of contents generated by 
# the routine LWDAQ_html_contents.
#
proc LWDAQ_html_split {{file_name ""}} {
	# Find the input file.
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
	}
	if {$file_name == ""} {
		return 0
	}

	# Read input file.
	set f [open $file_name r]
	set master [read $f]
	close $f

	# Displace links down one into directory structure.
	regsub -all {href="} $master {href="../} master
	regsub -all {src="} $master {src="../} master
	
	# Split the master according to h2-level html headings.
	set chapters [list]
	while {1} {
		set n [string first "<h2" $master 3]
		if {$n < 0} {break}
		lappend chapters [string range $master 0 [expr $n - 1]]
		set master [string replace $master 0 [expr $n - 1] ""]
	}
	regsub -all {</body>} $master {} master
	regsub -all {</html>} $master {} master
	lappend chapters $master
	
	# Remove the table of contents, if there is one.
	for {set i 0} {$i < [llength $chapters]} {incr i} {
		if {[regexp {<h2[^>]*>[^<]*Contents} [lindex $chapters $i] a]} {
			set chapters [lreplace $chapters $i $i]
		}
	}
	
	# Extract the header: it's chapter zero now.
	set header [lindex $chapters 0]
	
	# Compose names for the new files.
	set fr [file rootname $file_name]
	set root [file tail $fr]

	# Make a list of chapter names. Give the zero-chapter the name
	# Contents, because that's what it's going to be. Set the zero
	# chapter to be a list of links to the remaining chapters.
	set contents ""
	for {set i 1} {$i < [llength $chapters]} {incr i} {
		if {[regexp {[^<]*<h2([^>]*)>([^<]*)} [lindex $chapters $i] a b c d e]} {
			lappend names $c
			append contents "<a href=\"$root\_$i\.html\">Chapter $i\: $c</a><br>\n"
		} {
			error "no h2 heading in chapter $i"
		}
	}
	lset chapters 0 $contents
	
	# Add links to previous chapters to each chapter except the first.
	for {set i 2} {$i < [llength $chapters]} {incr i} {
		lset chapters $i "<a href=\"$root\_[expr $i - 1]\.html\">Previous Chapter</a><br> \
			\n[lindex $chapters $i]"
	}
	
	# Add links to next chapters to each chapter except the last. We add
	# a link at the top and bottom of the chapter.
	for {set i 1} {$i < [expr [llength $chapters] - 1]} {incr i} {
		lset chapters $i "\
			<a href=\"$root\_[expr $i + 1]\.html\">Next Chapter</a><br>\n \
			[lindex $chapters $i]<br>\n \
			<a href=\"$root\_[expr $i + 1]\.html\">Next Chapter</a><br>\n"
	}
	
	# Add links to the table of contents to each chapter.
	for {set i 1} {$i < [llength $chapters]} {incr i} {
		lset chapters $i "<a href=\"index.html\">Contents</a><br>\n \
			[lindex $chapters $i]"
	}
	
	# Add the header and footer to all chapters.
	for {set i 0} {$i < [llength $chapters]} {incr i} {
		lset chapters $i "$header\n[lindex $chapters $i]\n</body>\n</html>"
	}
	
	# Make directory for chapters.
	file mkdir $fr

	# Save the contents as index.html.	
	set f [open [file join $fr index.html] w]
	puts $f [lindex $chapters 0]
	close $f

	# Save the chapters as $fr/root_$i.html
	for {set i 1} {$i < [llength $chapters]} {incr i} {
		set f [open [file join $fr "$root\_$i\.html"] w]
		puts $f [lindex $chapters $i]
		close $f
	}


	return 1
}

#
# LWDAQ_html_tables extracts all the tables from an HTML document and
# writes them to a new HTML document with Tables_ added to the beginning of
# the original document's file root. The routine takes one optional 
# parameter: the name of the HTML document.
#
proc LWDAQ_html_tables { {file_name ""} } {
	# Find the input file.
	if {$file_name == ""} {
		set file_name [LWDAQ_get_file_name]
	}
	set ft [file tail $file_name]
	set nfn [file join [file dirname $file_name] "Tables_$ft"]
	
	# Open the input file for reading, and new file for writing.
	set f [open $file_name r]
	set nf [open $nfn w]
	
	# Copy header from $f to $nf adding "Tables From" to title.
	while {[gets $f line] > -1} {
		if {[regexp {[^<]*<title>([^<]*)} $line a b]} {
			puts $nf "<title>Tables From $b</title>"
		} {
			puts $nf $line
		}
		if {[regexp {[^<]*<body>[^<]*} $line]} {
			puts $nf ""
			break
		}	
			
	}
	
	
	# Skip past the contents
	while {[gets $f line] > -1} {
		if {[regexp {[^<]*<h2([^>]*)>([^<]*)Contents} $line a]} {
			break
		}	
	}
	while {[gets $f line] > -1} {
		if {[regexp {[^<]*<h2([^>]*)>} $line a]} {
			break
		}	
	}
	
	# Copy all tables
	set in_table 0
	while {[gets $f line] > -1} {
		if {[regexp {[^<]*<table([^>]*)>} $line a]} {set in_table 1}
		if {$in_table} {
			puts $nf $line
		}
		if {[regexp {[^<]*</table} $line a]} {
			set in_table 0
			puts $nf "<br><br>"
		}
	}
	
	
	puts $nf "</body></html>"
	
	# Close the files.
	close $f
	close $nf
}

#
# LWDAQ_command_reference generates the LWDAQ software command reference manual
# automatically, using ./Sources/lwdaq.pas and ./LWDAQ.app/Contents/LWDAQ/CRT.html.
#
proc LWDAQ_command_reference { {file_name ""} } {
	global LWDAQ_Info
	
	proc LWDAQ_command_reference_tabulate {names outfile cell_spacing num_columns} {
		if {[llength $names] > 0} {
			puts $outfile "<table cellspacing=$cell_spacing>"
			set index 0
			foreach n $names {
				if {$index==0} {puts -nonewline $outfile "<tr><td></td>"}
				puts -nonewline $outfile "<td><a href=\"\#$n\">$n</a></td>"
				if {$index==[expr $num_columns -1]} {puts -nonewline $outfile "</tr>\n"}
				incr index
				if {$index==$num_columns} {set index 0}
			}
			if {$index != 0} {puts $outfile "</tr>"}
			puts $outfile "</table>"
			return 1
		} {
			return 0
		}
	}
	
	if {$file_name == ""} {
		set file_name [file join $LWDAQ_Info(working_dir) "Commands.html"]
	}
	set ref_file [open $file_name w]
	set template_file [open [file join $LWDAQ_Info(scripts_dir) CRT.html] r]
	
	while {[gets $template_file line] >= 0} {
		set line [string map "LWDAQ_Version_Here $LWDAQ_Info(program_patchlevel)" $line]
	
		if {$line == "Scripts"} {
			set script_files [list]
			foreach f $LWDAQ_Info(scripts) {
				lappend script_files [file tail $f]
			}
			LWDAQ_command_reference_tabulate $script_files $ref_file 4 4
			continue
		}
		
		if {$line == "Script_Commands"} {
			foreach f $LWDAQ_Info(scripts) {
				puts $f
				LWDAQ_update
				set names [lsort -dictionary [LWDAQ_proc_list LWDAQ_* $f]]
				if {[llength $names] > 0} {
					set s [file tail $f]
					puts $ref_file ""
					puts $ref_file "<h2>$s</h2>"
					puts $ref_file ""
					puts $ref_file "<p>[LWDAQ_script_description $f]</p>"
					foreach n $names {
						puts $ref_file ""
						puts $ref_file "<h3>$n</h3>"
						puts $ref_file ""
						puts $ref_file "<small><pre>[LWDAQ_proc_declaration $n $f]</pre></small>"
						puts $ref_file "<p>[LWDAQ_proc_description $n $f]</p>"
						puts $ref_file ""
					}
				}
			}
			continue
		}
	
		if {$line == "Library_Commands"} {
			set fn [file join $LWDAQ_Info(sources_dir) lwdaq.pas]
			puts $fn
			LWDAQ_update
			set f [open $fn r]
			set code [read $f]
			close $f
			
			puts $ref_file ""
			puts $ref_file "<h2>Library Commands</h2>"
			puts $ref_file ""
			set lwdaq_names [lsort -dictionary [info commands lwdaq_*]]
			foreach n $lwdaq_names {
				puts $ref_file ""
				puts $ref_file "<h3>$n</h3>"
				puts $ref_file ""
				if {[catch {$n} error_message]} {
					regexp {"([^"]+)"} $error_message match syntax
					puts $ref_file "<small><pre>$syntax</pre></small>"
				} {
					puts $ref_file "<small><pre>$n ?option value?</pre></small>"
				}
				set r "\{(\[^\\\}\]+)\}\[\\r\\t\\n \]*function $n"
				regexp $r $code match comment
				puts $ref_file "$comment"
			}
			continue
		}
		
		if {$line == "Library_Routines"} {
			set fn [file join $LWDAQ_Info(sources_dir) lwdaq.pas] 
			puts $fn
			LWDAQ_update
			set f [open $fn r]
			set code [read $f]
			close $f

			puts $ref_file ""
			puts $ref_file "<h2>Library Routines</h2>"
			puts $ref_file ""

			set r "\{(\[^\\\}\]+)\}\[\\r\\t\\n \]*function lwdaq\[^_\]"
			if {[regexp $r $code match comment]} {
				puts $ref_file "$comment"
			}

			catch {lwdaq *} error_message
			regexp {"\*"[^"]*"([^"]+)"} $error_message match names
			set lwdaq_routine_names [lsort -dictionary $names]
			foreach n $lwdaq_routine_names {
				puts $ref_file ""
				puts $ref_file "<h3>$n</h3>"
				puts $ref_file ""
				catch {lwdaq $n} error_message
				regexp {"([^"]+)"} $error_message match syntax
				puts $ref_file "<small><pre>$syntax</pre></small>"
				set r "option='$n'\[^\{\}\]+\{(\[^\}\]+)\}"
				if {[regexp $r $code match comment]} {
					puts $ref_file "$comment"
				}
			}
			continue
		}
		
		puts $ref_file $line
	}

	close $template_file
	close $ref_file
	
	LWDAQ_html_contents 3 3 $file_name
}