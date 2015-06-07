#!/bin/bash
#
# widget:	gauge
# description:	Modifies updates ITG's cache with output
#		tailiored to dialogs gauge widget.

while getopts ":d:" opt; do
  case $opt in
    d)
      cache_dir=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z "$cache_dir" ]] || [[ "${cache_dir}xxx" = "xxx" ]]; then
	echo "Cache directory not supplied.";
	exit 1
fi

num=$(wc -l < /tmp/newsongs.txt)
num_processed=0

if [[ $num -gt 0 ]]; then
	while read line; do
		read -r changes filename <<< "$line"
		#todo: change directory to be arg'able
		cacheline=$(grep -F "$filename" ${cache_dir}/*)
		IFS=":" read -r cachepath otherjunk <<< "$cacheline"

		if [[ ! -z "$cachepath" ]]; then
			rm "$cachepath"
		fi
		((num_processed++))

		printf '%i %i' $num_processed $num | mawk -Winteractive '{ pc=100*$1/$2; i=int(pc); print (pc-i<0.5)?i:i+1 }'
	done < /tmp/newsongs.txt
else
	echo 100
fi

