#!/bin/bash
#
# widget:	gauge
# description:	Modifies rsync's output to be used
#		with dialog's --progress option

#XXX: Some versions of rsync say to-chk instead of to-check, be careful
rsync --progress "$@" #| tee >(grep -v "*deleting" | grep -i ".sm" > /tmp/newsongs.txt) | mawk -Winteractive '{ if (index($0, "to-check=") > 0) { split($0, pieces, "to-check="); split(pieces[2], term, ")"); split(term[1], division, "/"); print (1-(division[1]/division[2]))*100 } }' \
		      #| sed --unbuffered 's/\([0-9]*\).*/\1/'
