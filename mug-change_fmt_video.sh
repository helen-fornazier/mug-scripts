#!/bin/bash

VDEV=/dev/video0
#FORMAT=RGB24
FORMAT=SBGGR8
WIDTH=$1
HEIGHT=$2

echo "OLD FORMAT:"
yavta --enum-formats $VDEV

echo "-------------------------------------------"
echo "CHANGING FORMAT:"
yavta -f $FORMAT -s ${WIDTH}x${HEIGHT} $VDEV

#echo "-------------------------------------------"
#echo "NEW FORMAT:"
#yavta --enum-formats $VDEV
