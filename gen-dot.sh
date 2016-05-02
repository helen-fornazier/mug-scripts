#!/bin/bash

DEV=/dev/media0
sudo media-ctl -d $DEV --print-dot > /tmp/uvc.dot
dot -Tps -o /tmp/uvc.ps /tmp/uvc.dot
evince /tmp/uvc.ps
