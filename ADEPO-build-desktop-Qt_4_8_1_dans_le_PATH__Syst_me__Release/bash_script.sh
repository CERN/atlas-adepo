#!/bin/bash 
cp scripts_lwdaq/Acquisifier_params.tcl /home/cern-mehdi/ADEPO/input_folder/LWDAQ/LWDAQ.app/Contents/LWDAQ/Startup/
cp scripts_lwdaq/Acquisifier_Settings.tcl /home/cern-mehdi/ADEPO/input_folder/LWDAQ/Tools/Data/
cp scripts_lwdaq/Acquisifier_script_file.tcl /home/cern-mehdi/ADEPO/input_folder/LWDAQ/Tools/Data/
/home/cern-mehdi/ADEPO/input_folder/LWDAQ/lwdaq --no-console 
ps -eH | grep tclsh8.5 > PID.txt 
read pid reste < PID.txt 
sleep 30s
kill "$pid" 
