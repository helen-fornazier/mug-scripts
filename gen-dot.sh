#!/bin/bash

DEV=/dev/media0
rm /tmp/uvc.dot
rm /tmp/uvc.ps
sudo media-ctl -d $DEV --print-dot > /tmp/uvc.dot
dot -Tps -o /tmp/uvc.ps /tmp/uvc.dot
evince /tmp/uvc.ps
