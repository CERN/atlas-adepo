#!/bin/bash

# IMPORTANT : This script must be sourced, not executed !
# e.g. :  source ./setenv.sh

if [ ! -z $DIPBASE ]; then
	echo DIPBASE was set manually to $DIPBASE
else
	export DIPBASE=`pwd`
	echo DIPBASE was set automatically to $DIPBASE
fi
export CLASSPATH=$DIPBASE/lib/dip-jni-5.5.2.nar:$DIPBASE/lib/dip-jni-5.5.2-.nar:.:$CLASSPATH
export LD_LIBRARY_PATH=$DIPBASE/lib:$LD_LIBRARY_PATH
echo
echo CLASSPATH was prepended with $DIPBASE/lib/dip-jni-5.5.2.nar:.
echo
echo LD_LIBRARY_PATH was prepended with $DIPBASE/lib
echo
echo Done.
