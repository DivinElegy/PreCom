#!/bin/bash

while getopts "p:s:" opt; do
echo "$opt" >> /tmp/someopts
echo "$OPTARG" >> /tmp/someopts
  case $opt in
    p)
      obs_profile="$OPTARG"
      ;;
    s)
      obs_scene="$OPTARG"
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
key_re="([a-zA-Z0-9_]+?)[[:space:]]*="
value_re="=[[:space:]]*(.+?)"

while IFS='' read -r line || [[ -n $line ]]; do
	[[ "$line" =~ $key_re ]] && key=${BASH_REMATCH[1]}
	[[ "$line" =~ $value_re ]] && value=${BASH_REMATCH[1]}

	if [[ ! -z "$key" ]] && [[ ! "${key}xxx" = "xxx" ]] && [[ ! -z "$value"  ]] && [[ ! "${value}xxx" = "xxx" ]]; then
		eval $key=$value
	fi
done < "/itg/PreCom/stream_parameters.txt"

dos2unix /mnt/shares/itg-repo/CaptureInfo.txt > /dev/null 2>&1

line1=$(sed -n "1p" "/mnt/shares/itg-repo/CaptureInfo.txt")
line2=$(sed -n "2p" "/mnt/shares/itg-repo/CaptureInfo.txt")

OLDIFS=$IFS
IFS=', ' read -a v1coords <<< "$line1"
IFS=', ' read -a v2coords <<< "$line2"
IFS=$OLDIFS

/usr/local/bin/ffmpeg -y -f x11grab -r "$framerate" -i 0:0 -f video4linux2 -i /dev/video0 -itsoffset 0.1 -f alsa -i "plughw:CARD=${device},DEV=0" -filter_complex \
"[0:v]setpts=PTS-STARTPTS+${video_offset}/TB,scale=$((v1coords[2])):$((v1coords[3])),pad=1280:720:$((v1coords[0])):$((v1coords[1])):black[v1];[1:v]setpts=PTS-STARTPTS,scale=$((v2coords[2])):$((v2coords[3]))[v2]; [v1][v2]overlay=$((v2coords[0])):$((v2coords[1]))" \
-f flv  -vcodec libx264 -g "$framerate" -keyint_min "$framerate" -b "$video_bitrate" -minrate "$video_bitrate" -maxrate "$video_bitrate" -pix_fmt yuv420p -preset ultrafast -tune film -threads 2 -s 1280:720 \
-strict experimental -bufsize "$video_bitrate" -ar "$audio_bitrate" /itg/stream.mp4 > /dev/null 2>&1 &

#if [[ -z "$stream" ]]; then
#	case $stream in
#	  peekingboo)
#		obs_profile="PeekingBoo-ITG"
#		obs_scene="PeekingBoo"
#		;;
#         birdymint)
#		obs_profile="BirdyMint-ITG"
#		obs_scene="PeekingBoo"
#		;;
#	  divinelegy)
#		obs_profile="DivinElegy-ITG"
#		obs_scene="PeekingBoo"
#		;;

if [[ -n "$obs_profile" ]] && [[ -n "$obs_scene" ]]; then
	ssh PeekingBoo@192.168.0.6 'C:\Program Files\PsExec.exe -i -s "C:\Program Files (x86)\OBS\OBS.exe"' -profile "$obs_profile" \
       -scenecollection "$obs_scene" -start > /dev/null 2>&1 &
fi

#XXX: Loop forever so start-stop-daemon can kill us
while :
do
	sleep 1
done
