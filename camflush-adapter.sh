#!/bin/bash
#
# widget:	msgbox
# description:	Flushed the camera then says cool.

v4l2-ctl -d /dev/video0 -c focus_auto=0 -c focus_absolute=0 -c exposure_auto_priority=3 -c exposure_auto=3>/dev/null 2>&1 &

sleep 6

v4l2-ctl -d /dev/video0 -c exposure_auto=1 -c exposure_absolute=500>/dev/null 2>&1 &

sleep 2

echo "Camera flushed"
