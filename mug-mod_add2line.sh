#!/bin/sh

mod=`find -name $1`
echo $mod
func=$2
offset=$3
compiler=$4

${4}nm $mod | grep "${func}$" | grep '^[0-9a-f]* [tT]'
addr=`${4}nm $mod | grep "${func}$" | grep '^[0-9a-f]* [tT]' | awk '{ print "0x"$1 }'`

for ad in $addr; do
    echo "Symbol found at $ad, applying offset $offset"
    ad=`printf 0x%x $(($ad + $offset))`
    ${4}addr2line -pifae $mod $ad
done
