#!/bin/bash

MODULES="media vimc videodev"

function print_addr {
sudo cat /sys/module/$1/sections/.text
}

for mod in $MODULES; do
	echo $mod
	print_addr $mod
done
