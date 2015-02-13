#!/bin/bash

songs_dir=/home/cameron/Games/OpenITG/Songs
symlink_dir=/home/cameron/Games/OpenITG/Songs/Fast

IFS=$'\n'

function maxbpm()
{
	bpms=$(grep "BPMS" $1)
	bpms=${bpms:6:-2}

	IFS=',' read -a array <<< "$bpms"

	max300=0.00
        for bpm in "${array[@]}"
	do
		bpm=$(cut -d '=' -f 2 <<< "$bpm")
		comp=$(echo "$bpm > $max300" | bc)
		((comp > 0)) && max300=$bpm
	done

	echo "$max300"
}

function difficulty()
{
	noteslines=$(grep -n "NOTES" $1)
	readarray -t array <<<"$noteslines"
	max300=0

        for noteline in "${array[@]}"
	do
		linenum=$(cut -d ':' -f 1 <<< "$noteline")
		linenum=$((linenum+4))
		line=$(sed -n "${linenum}p" $1 | cut -d ':' -f 1)
		diff="$(echo -e "${line}" | tr -d '[[:space:]]')"
		comp=$(echo "$diff > $max300" | bc)
		((comp > 0)) && max300=$diff
	done

	echo "$max300"
}

for file in $(find "$songs_dir" -name *.sm)
do
	difficulty=$(difficulty $file)
	maxbpm=$(maxbpm $file)

	echo "$maxbpm"
	echo "$difficulty"
done
