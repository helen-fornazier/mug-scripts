WIDTH=640
HEIGHT=480
SCALER_MULT=3
BAYER_FMT='SBGGR8_1X8'
DEBAYER_FMT='RGB888_1X24'
CAP_DEBAYER_FMT='RGB24'
CAP_BAYER_FMT='SBGGR8'

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
