#!/bin/bash

menu_json="$(./JSON.sh -l < menu.json)"

function debug()
{
	>&2 echo "$1"
}

function get_key_from_line()
{
	key_re="(.+?)[[:space:]]+\""
	while read -r line; do
		[[ "$1" =~ $key_re ]] && echo ${BASH_REMATCH[1]} && break
	done <<< "$menu_json"
}

#Pass something like MainMenu.type and it'll
#give the value
#nice bonus: If passed a full line from menu_json
#this will return the value for it
function get_value_from_key()
{
	value_re="[[:space:]]+\"(.+)\"$"
	while read -r line; do
		[[ $line == ${1}* ]] && [[ $line =~ $value_re ]] &&  echo ${BASH_REMATCH[1]} && break
	done <<< "$menu_json"
}

#Helper for short_path_to_full_path
#Given a menu item name, and a path to
#its parent (a real JSON path like MainMenu.items.0)
#this will return the path to the item from the given path
#For example if it is passed MainMenu.items.0 and "ITG" it might
#return: items.0
#name, path
function get_relative_child_path()
{
	if [[ -z "$2" ]]; then
		echo "$1"
	else
		re="${2//./\\.}\.items\.([0-9]+?)\.name"
		debug "$re"
		while read -r line; do
			if [[ "$line" =~ $re ]]; then
				sub_path=${BASH_REMATCH[1]}
				key=$(get_key_from_line "$line")
				value=$(get_value_from_key "$key")
				[[ "$value" == "$1" ]] && echo "items.$sub_path"
			fi
		done <<< "$menu_json"
	fi
}

#When talking about menus it's useful to
#be able to say something like:
#MainMenu.Service.ITG instead of
#MainMenu.items.0.items.0
#This function converts the nice path
#to the real JSON path.
function short_path_to_full_path()
{
	path_so_far=""
	while IFS='.' read -ra parts; do
		for i in "${parts[@]}"; do
			relative_path=$(get_relative_child_path "$i" "$path_so_far")

			if [[ -z "$path_so_far" ]]; then
				path_so_far="${relative_path}"
			else
				path_so_far="${path_so_far}.${relative_path}"
			fi
		done
	done <<< "$1"

	echo "$path_so_far"
}

short_path_to_full_path "MainMenu.Services.gEdit"
