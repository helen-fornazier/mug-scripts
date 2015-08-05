#!/bin/bash

DEV=/dev/media0
PAD=0
# The entity must be its corresponding number, the name doesn't work
#ENTITY="\"Sensor A\""
ENTITY=1

CODE=RGB888_1X24
#CODE=SBGGR8
WIDTH=$1
HEIGHT=$2

#VERBOSE=-v
VERBOSE=

echo "OLD FORMAT:"
sudo media-ctl $VERBOSE -d $DEV --get-v4l2 $ENTITY:$PAD

sudo media-ctl $VERBOSE -d $DEV -V $ENTITY:$PAD[fmt:${CODE}/${WIDTH}x${HEIGHT}]

echo "-------------------------------------------"
echo "NEW FORMAT:"
sudo media-ctl $VERBOSE -d $DEV --get-v4l2 $ENTITY:$PAD
