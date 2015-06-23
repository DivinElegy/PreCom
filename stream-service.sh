#!/bin/bash

key_re="([a-zA-Z0-9]+?)[[:space:]]*="
value_re="=[[:space:]]*(.+?)"

while IFS='' read -r line || [[ -n $line ]]; do
	[[ "$line" =~ $key_re ]] && key=${BASH_REMATCH[1]}
	[[ "$line" =~ $value_re ]] && value=${BASH_REMATCH[1]}

	if [[ ! -z "$key" ]] && [[ ! "${key}xxx" = "xxx" ]] && [[ ! -z "$value"  ]] && [[ ! "${value}xxx" = "xxx" ]]; then
		eval $key=$value
	fi
done < "stream_parameters.txt"

echo "$bitrate"
