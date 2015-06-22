#!/bin/bash
#
# widget:       gauge
# description:  Sorts simfiles in to footspeed and stamina folders
#		based on user defined thresholds.
#		Input is tailored to suit dialog's gauge widget.
#

while getopts ":d:f:s:r:" opt; do
  case $opt in
    d)
      songs_dir=$OPTARG
      ;;
    f)
      footspeed_cutoff=$OPTARG
      ;;
    s)
      stamina_cutoff=$OPTARG
      ;;
    r)
      rating_cutoff=$OPTARG
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

if [[ -z "$songs_dir" ]] || [[ "${songs_dir}xxx" = "xxx" ]]; then
        echo "Songs directory not supplied.";
        exit 1
fi

if [[ -z "$footspeed_cutoff" ]] || [[ "${footspeed_cutoff}xxx" = "xxx" ]]; then
        echo "Footspeed cutoff not supplied.";
        exit 1
fi

if [[ -z "$stamina_cutoff" ]] || [[ "${stamina_cutoff}xxx" = "xxx" ]]; then
        echo "Stamina cutoff not supplied.";
        exit 1
fi

if [[ -z "$rating_cutoff" ]] || [[ "${rating_cutoff}xxx" = "xxx" ]]; then
        echo "Rating cutoff not supplied.";
        exit 1
fi

[[ ! $footspeed_cutoff =~ ^-?[0-9]+$ ]] && echo "Footspeed cutoff must be integer" && exit 1
[[ ! $stamina_cutoff =~ ^-?[0-9]+$ ]] && echo "Stamina cutoff must be integer" && exit 1
[[ ! $rating_cutoff =~ ^-?[0-9]+$ ]] && echo "Rating cutoff must be integer" && exit 1

[[ ! -d "$songs_dir" ]] && echo 100 && exit 0

num=$(wc -l < /tmp/newsongs.txt)

[[ ! $num -gt 0 ]] && echo 100 && exit 0

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

mkdir -p "${songs_dir}/Footspeed"
mkdir -p "${songs_dir}/Stamina"

total_charts=$(find "$songs_dir" -name *.sm | wc -l)
num_processed=0

for file in $(find "$songs_dir" -name *.sm)
do
	difficulty=$(difficulty $file)
	maxbpm=$(max_bpm $file)
	songlength=$(song_length_minutes $file)

	if [[ "$difficulty" > $rating_cutoff ]]; then
		path_to_chart="$(dirname "$file")"
		folder_name="$(basename "$path_to_chart")"
		[[ "$maxbpm" > "$footspeed_cutoff" ]] && ln -s "${path_to_chart}" "${songs_dir}/Footspeed/${folder_name}" > /dev/null  2>&1
		[[ "$songlength" > "$stamina_cutoff" ]] &&  ln -s "${path_to_chart}" "${songs_dir}/Stamina/${folder_name}" > /dev/null 2>&1
	fi

        ((num_processed++))

        printf '%i %i' $num_processed $total_charts | mawk -Winteractive '{ pc=100*$1/$2; i=int(pc); print (pc-i<0.5)?i:i+1 }'
done
