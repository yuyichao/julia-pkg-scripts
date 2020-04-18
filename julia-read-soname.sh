#!/bin/bash

LANG=C objdump -p "$1" | grep SONAME | sed -e 's/\s*SONAME\s*//'
