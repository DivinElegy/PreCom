#!/bin/bash

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

menu_json="$(./JSON.sh -l < menu.json)"
current_item="MainMenu"
backtitle="DivinElegy PreCom"
box_width=70
box_height=30

function debug()
{
	>&2 echo "$1"
	sleep 2
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
	full_path=$(short_path_to_full_path "$1")
	get_value_from_key "$full_path.type"
}

function get_item_description()
{
        full_path=$(short_path_to_full_path "$1")
        get_value_from_key "$full_path.description"
}

#(dot-delim, key)
function get_item_key()
{
	full_path=$(short_path_to_full_path $1)
	get_value_from_key "$full_path.$2"
}

#Returns true if line is a child
#of the dot-delim menu passed in
#(line, dot-delim)
#note: child means _direct_ child
#this will exclude grandchildren etc
function is_item_of_menu()
{
	full_path=$(short_path_to_full_path "$2")

        items_in_path=$(grep -o items <<< "$full_path" | wc -l)
        items_in_line=$(grep -o items <<< "$1" | wc -l)

        if [[ $1 == ${full_path}* ]] && [[ $((items_in_path + 1)) == $items_in_line ]]; then
                return 0
        else
                return 1
        fi
}

function is_child_of()
{
	if [[ $1 == ${2}* ]]; then
		return 0
	else
		return 1
	fi
}

#file, #detail
function get_adapter_detail()
{
        value_re="# ${2}:[[:space:]]+(.+)$"

        while read -r line; do
                [[ $line =~ $value_re ]] &&  echo ${BASH_REMATCH[1]} && break
        done < "$1"
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
		#Yes I do, it's because $line has a tab followed by text in it.
		#Without the quotes it thinks what follows the tab is the second arg
		if is_item_of_menu "$line" "$1"; then
			#Match on name as it is unique per item
			#Multiple lines will match per item without this
			name_re=".name[[:space:]].+?\"(.+)\""
			if [[ $line =~ $name_re ]]; then
				key=$(get_key_from_line "$line")
				desc=$(get_value_from_key "${key%.*}.description")
				name=$(get_value_from_key "${key%.*}.name")
				options+=("$name" "$desc")
			fi
		fi
	done <<< "$menu_json"

	if [[ $1 == "MainMenu" ]]; then
		options+=("Quit" "Exit the menu masterqueef")
	else
		options+=("Back" "Go back")
	fi

	#Also cracks the shits without quotes.
	#Also don't know why.
	dialog --clear --backtitle "$backtitle" --title "${1//./>}" --nocancel --menu "$(get_item_description $1)" "$box_height" "$box_width" 4 "${options[@]}" 2>"${INPUT}"
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

function run_task()
{
	#I tried $(short_path_to_full_path $1).commands
	#but it produced a weird result.
	local full_path=$(short_path_to_full_path "$1")

	while read -r line; do
        	if is_child_of "$line" "${full_path}.commands"; then
			command_re=".\/(.+.sh)"
			if [[ $line =~ $command_re ]]; then
				widget=$(get_adapter_detail "${BASH_REMATCH[1]}" "widget")
				key=$(get_key_from_line "$line")
				command="$(get_value_from_key $key)"
				title=$(get_value_from_key "${key%.*}.title")

				case "$widget" in
					gauge) eval "$command" | dialog --clear --backtitle "$backtitle" --title "Running $1" --gauge "$title" 6 60;;
					msgbox) eval "$command" | dialog --clear --backtitle "$backtitle" --title "$title" --msgbox "$(eval \"$command\")" 8 40;;
				esac
			fi
               fi
        done <<< "$menu_json"

	echo "Back" > "${INPUT}"
}

function run_preset()
{
        local full_path=$(short_path_to_full_path $1)
        while read -r line; do
                if is_child_of "$line" "${full_path}.itemsToRun"; then
			key=$(get_key_from_line "$line")
			item=$(get_value_from_key "$key")
			process_item "$item"
		fi
	done <<< "$menu_json"

	echo "Back" > "${INPUT}"
}

function process_item()
{
	type=$(get_item_type "$1")

	case $type in
		menu) render_menu "$1" "$2";;
		service) toggle_service "$1" "$2";;
		task) run_task "$1" "$2";;
		preset) run_preset "$1" "$2";;
	esac
}

############# 
# Main loop #
############

while true; do
        process_item "$current_item"
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

[[ -f $OUTPUT ]] && rm $OUTPUT
[[ -f $INPUT ]] && rm $INPUT
