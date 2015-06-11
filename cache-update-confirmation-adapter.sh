#!/bin/bash
#
# widget:	msgbox
# description:	Displays the number of updated simfiles

num=$(wc -l < /tmp/newsongs.txt)
#rm /tmp/newsongs.txt

if [[ $num -gt 0 ]]; then
	echo "$num New/updated simfiles"
else
	echo "No new/updated simfiles"
fi
