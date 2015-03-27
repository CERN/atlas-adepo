#!/bin/bash

# IMPORTANT : This script must be sourced, not executed !
# e.g. :  source ./setenv64.sh

if [ ! -z $DIPBASE ]; then
	echo DIPBASE was set manually to $DIPBASE
else
	export DIPBASE=`pwd`
	echo DIPBASE was set automatically to $DIPBASE
fi
export CLASSPATH=$DIPBASE/lib64/dip-jni-5.5.2.nar:$DIPBASE/lib64/dip-jni-5.5.2-.nar:.:$CLASSPATH
export LD_LIBRARY_PATH=$DIPBASE/lib64:$LD_LIBRARY_PATH
echo
echo CLASSPATH was extended with $DIPBASE/lib64/dip-jni-5.5.2.nar:.
echo
echo LD_LIBRARY_PATH was extended with $DIPBASE/lib64
echo
echo Done.
