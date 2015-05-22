#!/bin/bash

#Pass something like MainMenu.type and it'll
#give the value
#this should be the full path to the item
#this function is not intended for use in
#the main logic of the menu
function get_key()
{
	value_re="[[:space:]]+\"(.+)\"$"
	while read -r line; do
		[[ $line == "$1"* ]] && [[ $line =~ $value_re ]] &&  echo ${BASH_REMATCH[1]} && break
	done <<< "$menu_json"
}

#simply puts item between each element
#in the path. So Menu.Services.ITG
#become Menu.items.Services.items.ITG
function short_path_to_full_path()
{
	echo "${1//./.items.}"
}

#Functions below here are for convenience.
#They allow extraction of information about
#menus without having to constantly specifiy
#Menu.items.Thing.items.MenuIWant
#Instead you can just do Menu.Thing.MenuIWant

#Use a dot delim path to the item
#returns the type of the item
#e.g.,
#	menu
#	service
function get_item_type()
{
	full_path=$(short_path_to_full_path $1)
	get_key "$full_path.type"
}

function get_item_description()
{
        full_path=$(short_path_to_full_path $1)
        get_key "$full_path.description"
}

#Returns true if line is a child
#of the dot-delim menu passed in
#(line, dot-delim)
#note: child means _direct_ child
#this will exclude grandchildren etc
function is_child_of()
{
	full_path=$(short_path_to_full_path $2)
	items_in_path=$(grep -o "items" <<< "$full_path" | wc -l)
	items_in_line=$(grep -o "items" <<< "$1" | wc -l)

	if [[ "$1" == "$full_path"* ]] && [[ $((items_in_path + 1)) == "$items_in_line"  ]]; then
		return 0
	else
		return 1
	fi

}

#Use a dot delimited path to the menu
#e.g.,
#	MainMenu.Services
#	MainMenu.Services.Streaming
function render_menu()
{
	options=()
	while read -r line; do
		if is_child_of "$line" "$1"; then
			name_re="items.([a-zA-Z]+).description"
			desc_re=".description[[:space:]]\"(.+)\""
			[[ $line =~ $name_re ]] && name=${BASH_REMATCH[1]} && [[ $line =~ $desc_re ]] && desc=${BASH_REMATCH[1]} && options+=("$name" "$desc")
		fi
	done <<< "$menu_json"

	if [[ $1 == "MainMenu" ]]; then
		options+=("Quit" "Exit the menu masterqueef")
	else
		options+=("Back" "Go back")
	fi

	dialog --clear --backtitle "DivinElegy PreCom" --title "${1//./>}" --menu "$(get_item_description $1)" 15 50 4 "${options[@]}" 2>"${INPUT}"
}

function render_item()
{
	type=$(get_item_type $1)
	case $type in
		menu) render_menu $1;;
	esac
}

####################

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

trap "rm $OUTPUT' rm $INPUT; exit" SIGHUP SIGINT SIGTERM

menu_json="$(./JSON.sh -l < menu.json)"
current_item="MainMenu"

while true; do
	render_item $current_item
	selection=$(<"${INPUT}")

	case $selection in
		Quit) break;;
		Back) current_item="${current_item%.*}";;
		*) current_item="$current_item.$selection";;
	esac
done

#clear

[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
