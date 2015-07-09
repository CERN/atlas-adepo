#!/bin/sh

find . -name Makefile | xargs grep -sl 5.4.2 | xargs sed -i'' 's/5\.4\.2/5\.5\.0/g'

