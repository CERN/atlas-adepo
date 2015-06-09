#!/bin/sh

find . -name Makefile | xargs grep -sl 5.4.1 | xargs sed -i'' 's/5\.4\.1/5\.4\.2/g'

