#!/bin/bash

printCoolTitle() {
	local title="$1"
	sep=$(printf '+%.0s' $(seq ${#title}))
	echo -e "$sep\n$title\n$sep\n"
}

delCurrentLine() {
	tput cuu 1
	tput el
}

enter2continue() {
	read -p "Press ENTER to Continue ..."
	delCurrentLine
}

# check wether to print "Press ENTER to Continue ..." or Not, by checking given choice argument
isEnter2Continue() {
	if [[ $1 -eq 0 ]]; then
		enter2continue
		delCurrentLine
	fi
}

# Print Choice Not Found, and assign the outer scope choice argument as False(1)
printNotFound() {
	echo -e "$nullChoice"
	localChoice="$1"
	eval "$localChoice=1"
	sleep 2
	delCurrentLine
}

# Check isChoiceFound and accordingly print the menu again if needed (with the given function as a parameter) 
# $1 = Choice Argument
# $2 = print_<GIVEN MENU PRINTING FUNCTION>
isChoiceFoundFun() {
	local newChoice="$1"
	local function_name=$2
	if [[ newChoice -eq 0 ]]; then
		$function_name
	else
		eval "$newChoice=0"
	fi
}

cancelTitle="Type 0 To Get Back"
# If user's input is 0, then cancel the "read" input and get back
cancelRead() {
    if [[ "$1" == "0" ]]; then
        return 0
    fi
    return 1
}
