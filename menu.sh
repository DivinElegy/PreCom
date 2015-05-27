#!/bin/bash

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

trap "rm $OUTPUT' rm $INPUT; exit" SIGHUP SIGINT SIGTERM

menu_json="$(./JSON.sh -l < menu.json)"
current_item="MainMenu"
backtitle="DivinElegy PreCom"
box_width=50
box_height=15

#Pass something like MainMenu.type and it'll
#give the value
#this should be the full path to the item
#this function is not intended for use in
#the main logic of the menu
function get_key()
{
	value_re="[[:space:]]+\"(.+)\"$"
	while read -r line; do
		[[ $line == ${1}* ]] && [[ $line =~ $value_re ]] &&  echo ${BASH_REMATCH[1]} && break
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

#(dot-delim, key)
function get_item_key()
{
	full_path=$(short_path_to_full_path $1)
	get_key "$full_path.$2"
}

#Returns true if line is a child
#of the dot-delim menu passed in
#(line, dot-delim)
#note: child means _direct_ child
#this will exclude grandchildren etc
function is_child_of()
{
	full_path=$(short_path_to_full_path "$2")
	items_in_path=$(grep -o items <<< "$full_path" | wc -l)
	items_in_line=$(grep -o items <<< "$1" | wc -l)

	if [[ $1 == ${full_path}* ]] && [[ $((items_in_path + 1)) == $items_in_line  ]]; then
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
		#Cracks the shits without the quotes on the args,
		#I don't know why.
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

	#Also cracks the shits without quotes.
	#Also don't know why.
	dialog --clear --backtitle "$backtitle" --title "${1//./>}" --menu "$(get_item_description $1)" "$box_height" "$box_width" 4 "${options[@]}" 2>"${INPUT}"
}

function toggle_service()
{
	service_command=$(get_item_key $1 command)
	service_name=$(basename $service_command)

	#If the quotes aren't here then the application launches
	#Not sure why
	pid="$(pgrep $service_name)"

	if [[ $pid ]]; then
		dialog --clear --backtitle "$backtitle" --title "Disable $service_name" --yesno "This will stop $service_name. Are you sure?" 6 50
		[[ $? == 0 ]] && kill -9 $pid
	else
		dialog --clear --backtitle "$backtitle" --title "Enable $service_name" --yesno "This will start $service_name. Are you sure?" 6 50
		[[ $? == 0 ]] && $service_command > /dev/null 2>&1 &
	fi

	#Kind of a hack? When we get here current_item will be:
	#thing.otherThing.this_service
	#but after we leave here we want to render thing.otherThing
	#so returning Back gets the main loop to do that.
	echo "Back" > "${INPUT}"
}

function process_item()
{
	type=$(get_item_type $1)
	case $type in
		menu) render_menu $1;;
		service) toggle_service $1;;
	esac
}

#############
# Main loop #
############

while true; do
        process_item $current_item
	#todo: Is it possible to avoid using a file for this?
        selection=$(<"${INPUT}")

        case $selection in
                Quit) break;;
                Back) current_item="${current_item%.*}";;
                *) current_item="$current_item.$selection";;
        esac
done

###########
# Cleanup #
###########
clear

[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
