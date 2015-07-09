#!/bin/sh
find . -name Makefile | xargs grep -sl 5.4.1\/5.4 | xargs sed -i '' 's/5\.4\.1\/5\.4/5\.5\.0\/5\.5/g'

