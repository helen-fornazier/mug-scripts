#!/bin/sh

mod=`find -name $1`
echo $mod
func=$2
offset=$3

nm $mod | grep "${func}$" | grep '^[0-9a-f]* [tT]'
addr=`nm $mod | grep "${func}$" | grep '^[0-9a-f]* [tT]' | awk '{ print "0x"$1 }'`

for ad in $addr; do
    echo "Symbol found at $ad, applying offset $offset"
    ad=`printf 0x%x $(($ad + $offset))`
    addr2line -pifae $mod $ad
done
