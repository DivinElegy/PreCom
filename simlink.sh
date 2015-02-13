#TITLE: Organise Simfiles
#PARENT: ITG Options
#WIDGET: progress_bar

#!/bin/bash

songs_dir=/home/cameron/Games/OpenITG/Songs
symlink_dir=/home/cameron/Games/OpenITG/Songs/Fast

IFS=$'\n'

#(file, key)
function extract_key()
{
	key=$(grep $2 $1 | cut -d ':' -f 2 | cut -d ';' -f 1 | tr -d $'\r')
	echo "$key"
}

function song_length_minutes()
{
	path=$1
	music_file=$(extract_key $1 "MUSIC")
	music_path=${path%/*}

	length=$(ffmpeg -i "$music_path/$music_file" 2>&1 | grep Duration |awk '{print $2}' | cut -d ':' -f 2 | tr -d ,)
	length=${length##0}

	echo "$length"
}

function max_bpm()
{
	bpms=$(extract_key $1 "BPMS")
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
	maxbpm=$(max_bpm $file)
	songlength=$(song_length_minutes $file)

	echo "$maxbpm"
	echo "$difficulty"
	echo "$songlength"
done
