#!/bin/bash

gdb -ex "add-auto-load-safe-path ${1}-gdb.py" \
    -ex "file ${1}" \
    -ex 'target remote localhost:1234'
