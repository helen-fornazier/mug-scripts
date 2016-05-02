#!/bin/sh

mod=`find -name $1`
echo $mod
func=$2
offset=$3

addr=`nm $mod | grep $func | grep '^[0-9a-f]* [tT]' | awk '{ print "0x"$1 }'`
addr=`printf 0x%x $(($addr + $offset))`
echo $addr

addr2line -a -e $mod -i $addr
