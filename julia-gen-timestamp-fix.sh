#!/bin/bash

echo "timestamps-fix() {"
find "$@" -type f -exec \
     sh -c 'echo "  touch -c -d \"$(stat -c %y "{}")\" \"{}\""' \;
echo "}"
