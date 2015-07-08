#!/bin/bash

export DISPLAY=:0.0

/usr/bin/urxvt -pixmap /itg/launchbg.jpg \
	       -foreground White \
	       -bl \
	       -borderColor Black \
	       -color4 RoyalBlue \
	       -color12 RoyalBlue \
	       +sb \
	       -geometry 102x34+0+0 \
	       -e /itg/PreCom/start.sh

pid=$!

wait $pid
