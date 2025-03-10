#!/bin/bash

# User Management Functions
getInteractiveUserList() {
	/usr/bin/getent passwd | awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)/ {print $1}'
}

printUserList() {
    local usr_list="$(getInteractiveUserList)"
    echo "List of Users:"
    printf ">> %s\n" $(echo -e "$usr_list") 
}

# True = 0 | False = 1
isUserExist() {
    if /usr/bin/getent passwd "$1" &>/dev/null ; then
        # User Found / Exist
        return 0
    else
        return 1
    fi
}

isUserModifiable() {
    local userName="$1"
    local user_entry uid shell
    user_entry=$(/usr/bin/getent passwd "$userName")
    # Enty does NOT Exist
    if [[ -z "$user_entry" ]] ; then
        return 1
    fi
    # Extract user group id (Field 3) and login shell (Field 7)
    # Login shell should be differenet from "nologin", and different from "false"
    uid=$(echo "$user_entry" | cut -d: -f3)
    shell=$(echo "$user_entry" | cut -d: -f7)
    if [[ "$uid" -ge 1000 ]] && [[ "$shell" != "/usr/bin/nologin" ]] && [[ "$shell" != "/bin/false" ]] ; then
        return 0
    else
        return 1
    fi
}

printUserNotFound() { echo "ERROR: User <$1> NOT FOUND !"; } # $1 => User Display/Login Name
printUserExist() { echo "ERROR: User <$1> Already Exists !"; } # $1 => User <Name>
printHomeExist() { echo "ERROR: Directory <$1> Already Exist!"; } # $1 => Given HOME Dir  
printUserEmpty() { echo -e "ERROR: User's $1 Can't Be Empty!\n"; } # $1 => "Display / Login" 
printUserRegExp() { echo -e "ERROR: $1 RegExp Format Not Allowed\n"; } # $1 => "Display / Login"

displayRegExp_start="^[a-zA-Z0-9]"
displayRegExp_middle="[-a-zA-Z0-9._\'\ ]{0,$(( $(getconf LOGIN_NAME_MAX)-2 ))}"
displayRegExp_end="[a-zA-Z0-9]$"
displayRegExp_full="${displayRegExp_start}${displayRegExp_middle}${displayRegExp_end}"

isDisplayNameValid() {
    if [[ ${#1} -eq 1  ]] ; then
        # Validate a single character login name
        if [[ "$1" =~ $regexp_start ]] ; then
            return 0
        else
            return 1
        fi
    else   
        # Validated multi character login name
        if [[ "$1" =~ $regexp_full ]] ; then
            return 0
        else
            return 1
        fi 
    fi
}

readUserDispName() {
    local usr_name=""
	while true; do
		read -p "Enter User's Display Name: " usr_name
		if [[ -z "$usr_name" ]]; then
			printUserEmpty "Display Name"
			read -p "$(echo -e "WARNING, Display Name CAN Be Empty.\nKeep Display Name Empty? (y/N)")" emptyDispChoice
			emptyDispChoice="${emptyDispChoice-N}"
			if [[ "$emptyDispChoice" =~ ^[Yy]$ ]]; then
			    usr_name="" #Empty User Display Name
			    break
			else
			    read -p "$(echo -e "Enter User's Display Name: ")" usr_name
			fi
		elif [[ isDisplayNameValid "$usr_name" ]]; then
		    # Display Name OK
		    break
		else
		    printUserRegExp "Display Name"
		    continue
		fi
	done
	local -n dispName="$1"
	dispName="$usr_name"
}

loginRegExp_start="^[a-z]"
loginRegExp_middle="[-a-z0-9._\']{0,$(( $(getconf LOGIN_NAME_MAX)-2 ))}"
loginRegExp_end="[a-z0-9]$"
loginRegExp_full="${loginRegExp_start}${loginRegExp_middle}${loginRegExp_end}"

isLoginNameValid() {
    if [[ -z "$1" ]] ; then 
        return 1
    elif [[ ${#1} -eq 1  ]] ; then
        # Validate a single character login name
        if [[ "$1" =~ $loginRegExp_start ]] ; then
            return 0
        else
            return 1
        fi
    else   
        # Validated multi character login name
        if [[ "$1" =~ $loginRegExp_full ]] ; then
            return 0
        else
            return 1
        fi 
    fi
}

readUserLoginName() {
	while true; do
		read -p "Enter User's Login Name: " usr_login
		if id "$usr_login" &>/dev/null; then
		    printUserExist "$usr_login"
			read -p "$(echo -e "Enter User's Login Name: ")" usr_login
		elif [[ -z "$usr_login" ]]; then
			printUserEmpty "Login Name"
			read -p "$(echo -e "Enter User's Login Name: ")" usr_login
		elif [[ isLoginNameValid "$usr_login" ]]; then
		    # Login Name is OK
		    break
		else
		    printUserRegExp "Login Name"
		    continue
		fi
	done
	local -n loginName="$1"
	loginName="$usr_login"
}

# NOT USED - DEPRECATED (Future usage may be)
readValidUserPass() {
	local validPass="$1"
	while true; do
		echo -n "Enter User's Password: "
		read -s usr_pass_1
		echo -en "\nEnter User's Password AGAIN: "
		read -s usr_pass_2
		if [[ -z "$usr_pass_1" || -z "$usr_pass_2" ]]; then
			echo -e "\nPassword cannot be empty. Try again . . ."
			continue
		fi
		if [[ "$usr_pass_1" != "$usr_pass_2" ]]; then
			echo -e "\nPasswords Don't Match! Try again . . .\n"
		else
			echo -e "\nPasswords Match! Proceeding . . .\n"
			eval "validPass=$usr_pass_1"
			break
		fi
	done
}

validateUserData() {
    if [[ -z "$1" ]]; then
		echo "No USER entered, try again."
		return 1
	fi
	if ! isUserExist "$1" ; then
	    printUserNotFound "$1"
		return 1
	fi
    if ! isUserModifiable "$1" ;then
        echo "User <$1> is a system account or not intended for modifications."
        return 1;
    fi
	return 0
}

# Given Args:
# $1 = Home Directory
# $2 = wanted User Name to change its new HOME Dir 
setPermissionHome() {
	local homeDir="$1"
	local usr="$2"
	local group="$2"
	# Check if group exists before setiing permissions
	if ! getent group "$group" &>/dev/null ; then
		echo "Group <$group> does NOT exist.\nCreating now..."
		sudo groupadd "$group"
	fi
	# Recursive - apply ownership for all subdirectories in path
	sudo chown -R "$usr":"$usr" "$homeDir" || { echo "ERROR: FAILED to set Ownership for $homeDir"; exit 1; }
	sudo chmod 700 "$homeDir" || { echo "ERROR: FAILED to set permission for $homeDir"; exit 2; }
}

# Given Args:
# $1 = Home Directory outerscope parameter pointer
# $2 = wanted User Name to change its new HOME Dir 
readUserHomeDir() {
	local inputMsg="Enter User's NEW Home Directory: "
	local usr="$2"
	local homeDir=""
	while true; do
		read -p "$inputMsg" homeDir
		if [[ -z "$homeDir" ]]; then
			# printUserEmpty "HOME Dir"
			read -p "$(echo -e "WARNING, HOME Dir CAN Be Empty, BUT The User Would NOT Have Any HOME Folder!\nKeep HOME Dir Empty? (y/N)")" emptyHomeChoice
			emptyHomeChoice="${emptyHomeChoice-N}"
			if [[ "$emptyHomeChoice" =~ ^[Yy]$ ]]; then
			    homeDir="" #Empty HOME Dir
			    break
			fi
		elif [[ -d "$homeDir" ]]; then
			printHomeExist "$homeDir"
			read -p "Use this path and Continue? (Y/n) " existingDirChoice
			existingDirChoice="${existingDirChoice-Y}"
			if [[ "$existingDirChoice" =~ ^[Yy]$ ]]; then
				setPermissionHome "$homeDir" "$usr" # Ensure permission for existing folder
				break # Use Exisiting HOME Dir
			fi
		elif [[ "$homeDir" =~ ^/[A-Za-z0-9._-]+(/?[A-Za-z0-9._-]+)*/? ]]; then
		    # HOME Dir OK
			if ! id "$usr" &>/dev/null; then
				echo "ERROR: User <$usr> does NOT exist. Can't change HOME Dir"
				break
			fi
			sudo mkdir -p "$homeDir"
			if [[ $? -ne 0 ]]; then
				echo "ERROR: FAILED to create $homeDir !"
			fi
			setPermissionHome "$homeDir" "$usr"
		    break
		else
		    printUserRegExp "HOME Dir"
		fi
	done
	local -n newHome="$1"
	newHome="$homeDir"
}