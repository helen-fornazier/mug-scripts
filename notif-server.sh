#!/bin/bash

set -x

# Use the following to trigger the notification
# ssh -R 4444:localhost:4444 host.com 
# nc -w1 localhost 4444

PORT=4444
CMD="notify-send -t 0 daisy_test_done; canberra-gtk-play --file=/usr/share/sounds/gnome/default/alerts/bark.ogg; "
echo "$CMD"
echo "Notification server on port $PORT"
socat -u tcp-l:$PORT,fork "system:${CMD@Q}"
