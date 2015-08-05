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
# 6) ENTITY=1
# 7) CODE=RGB888_1X24
# 8) VERBOSE=
def change_sd_fmt(params, mdev):
    print params
    print "==========================================="
    print params['name'] + " SD: OLD FORMAT:"
    print "==========================================="
    print ""
    cmd = 'sudo media-ctl '+ params['verbose'] +' -d '+ mdev +' --get-v4l2 ' \
          + params['entity'] +':'+ params['pad']
    print '>' + cmd
    os.system(cmd)

    cmd = 'sudo media-ctl '+ params['verbose'] +' -d '+ mdev +' -V ' \
          + params['entity'] +':'+ params['pad'] +'[fmt:'+ params['code'] +'/'+ params['width'] +'x'+ params['height'] +']'
    print '>' + cmd
    os.system(cmd)

    print "-------------------------------------------"
    print params['name'] + " SD: NEW FORMAT:"
    cmd = 'sudo media-ctl '+ params['verbose'] +' -d '+ mdev +' --get-v4l2 '+ params['entity'] +':'+ params['pad']
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
        new_fmt.group(2) != params['width'] + 'x' + params['height']:

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
    print params['name'] + " VID: OLD FORMAT:"
    print "==========================================="
    print ""
    cmd = 'yavta --enum-formats '+ params['dev']
    print '>' + cmd
    os.system(cmd)

    print "-------------------------------------------"
    print params['name'] + " VID: NEW FORMAT:"
    cmd = 'yavta -f '+ params['fmt'] + \
              ' -s '+ params['width'] +'x'+ params['height'] +' '+ params['dev']
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
        new_fmt.group(2) != params['width'] + 'x' + params['height']:

        print ""
        print "ERR: Could not apply format"
        exit(-1)

    print ""




# ENT_SEN_A=1
# ENT_SEN_B=2
# ENT_DEB_A=3
# ENT_DEB_B=4
# ENT_CAP_0=5
# ENT_CAP_1=6
# ENT_INP=7
# ENT_SCA=8
# ENT_CAP_RGB_YUV=9

WIDTH=640
HEIGHT=480
SCALER_MULT=3
BAYER_FMT='SBGGR8'
DEBAYER_FMT='RGB888_1X24'
CAP_DEBAYER_FMT='RGB24'
CAP_BAYER_FMT=BAYER_FMT
MDEV='/dev/media0'

pads= [ \
        {
            'name':     'Sensor A',
            'entity':   '1',
            'pad':      '0',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Sensor B',
            'entity':   '2',
            'pad':      '0',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer A',
            'entity':   '3',
            'pad':      '0',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer A',
            'entity':   '3',
            'pad':      '1',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer B',
            'entity':   '4',
            'pad':      '0',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     BAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Debayer B',
            'entity':   '4',
            'pad':      '1',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Raw Capture 0',
            'dev':      '/dev/video0',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'fmt':      CAP_BAYER_FMT
        },
        {
            'name':     'Raw Capture 1',
            'dev':      '/dev/video1',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'fmt':      CAP_BAYER_FMT
        },
        {
            'name':     'Scaler',
            'entity':   '8',
            'pad':      '0',
            'width':    str(WIDTH),
            'height':   str(HEIGHT),
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'Scaler',
            'entity':   '8',
            'pad':      '1',
            'width':    str(WIDTH*SCALER_MULT),
            'height':   str(HEIGHT*SCALER_MULT),
            'code':     DEBAYER_FMT,
            'verbose':  ''
        },
        {
            'name':     'RGB/YUV Capture',
            'dev':      '/dev/video2',
            'width':    str(WIDTH*SCALER_MULT),
            'height':   str(HEIGHT*SCALER_MULT),
            'fmt':      CAP_DEBAYER_FMT
        },
    ]

#print pads

for pad in pads:
    if 'code' in pad:
        change_sd_fmt(pad, MDEV)
    else:
        change_vid_fmt(pad)

cmd = 'sudo media-ctl -p -d ' + MDEV
print '>' + cmd
os.system(cmd)
