#!/bin/bash


rsync --progress "$@" | tee >(grep -i ".sm" > /tmp/newsongs.txt) | mawk -Winteractive '{ if (index($0, "to-check=") > 0) { split($0, pieces, "to-check="); split(pieces[2], term, ")"); split(term[1], division, "/"); print (1-(division[1]/division[2]))*100 } }' \
		      | sed --unbuffered 's/\([0-9]*\).*/\1/'
