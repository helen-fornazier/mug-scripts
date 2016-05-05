#!/usr/bin/python

import os
import commands
import re

# params: 
# 1) NAME
# 2) WIDTH=$2
# 3) HEIGHT=$3
# 4) DEV=/dev/media0
# 5) PAD=0
# 7) CODE=RGB888_1X24
# 8) VERBOSE=
def change_sd_fmt(params, mdev):
    print "==========================================="
    print "%s, Pad %d" % (params['name'], params['pad'])
    print "==========================================="
    #print params

    # Add quotes in the name
    name = "\'" + params['name'] + "\'"

    # Print the old format
    cmd = "sudo media-ctl %s -d %s --get-v4l2 \"%s:%d\"" % (params['verbose'], mdev, name, params['pad'])
    print '>' + cmd
    os.system(cmd)

    # Set the new format
    cmd = "sudo media-ctl %s -d %s -V \"%s:%s [fmt:%s/%dx%d]\"" % (params['verbose'], mdev, name, params['pad'], params['code'], params['width'], params['height'])
    print '>' + cmd
    os.system(cmd)

    # Print the new format
    cmd = "sudo media-ctl %s -d %s --get-v4l2 \"%s:%d\"" % (params['verbose'], mdev, name, params['pad'])
    print '>' + cmd
    output = commands.getstatusoutput(cmd)
    print output[1]
    if output[0] != 0:
        print ""
        print "ERR: Could not apply format"
        exit(-1)

    # Check if we could apply the format
    new_fmt = re.search(':(.*)/(.*)]', output[1])
    if not new_fmt or \
        new_fmt.group(1) != params['code'] or \
        new_fmt.group(2) != "%dx%d" % (params['width'], params['height']):

        print ""
        print "ERR: Could not apply format"
        exit(-1)

# params
# 1) NAME
# 2) WIDTH=$2
# 3) HEIGHT=$3
# 4) VDEV=/dev/video0
# 5) FORMAT=SBGGR8
def change_vid_fmt(params):
    print "==========================================="
    print params['name']
    print "==========================================="

    cmd = 'yavta --enum-formats '+ params['dev']
    print '>' + cmd
    os.system(cmd)

    cmd = "yavta -f %s -s %dx%d %s" % (params['fmt'], params['width'], params['height'], params['dev'])
    print '>' + cmd
    output = commands.getstatusoutput(cmd)
    print output[1]
    if output[0] != 0:
        print ""
        print "ERR: Could not apply format"
        exit(-1)

    # Check if we could apply the format
    new_fmt = re.search('Video format: (.*?) .*? (.*?) ', output[1])
    if not new_fmt or \
        new_fmt.group(1) != params['fmt'] or \
        new_fmt.group(2) != "%dx%d" % (params['width'], params['height']):

        print ""
        print "ERR: Could not apply format"
        exit(-1)

    print ""


WIDTH=300
HEIGHT=400
SCALER_MULT=3
BAYER_FMT='SBGGR8_1X8'
DEBAYER_FMT='RGB888_1X24'
CAP_DEBAYER_FMT='RGB24'
CAP_BAYER_FMT='SBGGR8'
MDEV='/dev/media0'

pads= [ \
        {
            'name':     'Sensor A',
            'pad':      0,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Sensor B',
            'pad':      0,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer A',
            'pad':      0,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer A',
            'pad':      1,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer B',
            'pad':      0,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer B',
            'pad':      1,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Raw Capture 0',
            'dev':      '/dev/video0',
            'width':    WIDTH,
            'height':   HEIGHT,
            'fmt':      CAP_BAYER_FMT
        },
        {
            'name':     'Raw Capture 1',
            'dev':      '/dev/video1',
            'width':    WIDTH,
            'height':   HEIGHT,
            'fmt':      CAP_BAYER_FMT
        },
        {
            'name':     'Scaler',
            'pad':      0,
            'width':    WIDTH,
            'height':   HEIGHT,
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Scaler',
            'pad':      1,
            'width':    WIDTH*SCALER_MULT,
            'height':   HEIGHT*SCALER_MULT,
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'RGB/YUV Capture',
            'dev':      '/dev/video2',
            'width':    WIDTH*SCALER_MULT,
            'height':   HEIGHT*SCALER_MULT,
            'fmt':      CAP_DEBAYER_FMT
        },
    ]

#print pads

for pad in pads:
    if 'code' in pad:
        change_sd_fmt(pad, MDEV)
    else:
        change_vid_fmt(pad)

print "==========================================="
print "SUMMARY"
print "==========================================="
cmd = 'sudo media-ctl -p -d ' + MDEV
print '>' + cmd
os.system(cmd)
