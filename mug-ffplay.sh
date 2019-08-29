#!/bin/bash

set -x

# Execute "ffplay -pix_fmts" to see possible values
PIX_FMT=nv12
IMG_SIZE="1280x960"

if [$# -ne 1]; then
	echo "Usage: $0 {file}"
	exit 0
fi

ffplay -loglevel warning -v info -f rawvideo -pixel_format "$PIX_FMT" -video_size "$IMG_SIZE" "$1"
