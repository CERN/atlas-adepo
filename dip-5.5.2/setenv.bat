@echo off
echo ===================================================
echo Setting up DIP Environment
echo ===================================================

if (%DIPBASE%)==() (
echo DIPBASE not set, defaulting to current directory
set DIPBASE=%CD%
)

set PATH=%DIPBASE%\lib;%PATH%
echo PATH was prepended with %DIPBASE%\lib
set DIM_DNS_PORT=2506
echo DIM DNS PORT was set to DIP standard 2506
set CLASSPATH=%DIPBASE%\lib\dip-jni-5.5.2.nar;%DIPBASE%\lib\dip-jni-5.5.2-.nar;%CLASSPATH%
echo CLASSPATH was prepended with %DIPBASE%\lib\dip-jni-5.5.2.nar
echo Done.
