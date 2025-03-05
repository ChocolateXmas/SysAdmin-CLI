#!/bin/bash

# User Management Functions
getUserList() {
	cat /etc/passwd | grep "/home" | cut -s -d : -f1
}

# True = 0 | False = 1
isUserExist() {
    if /usr/bin/id "$1" &>/dev/null ; then
        # User Not Found / Not Exist
        return 0
    else
        return 1
    fi
}

printUserList() {
    local usr_list="$(getUserList)"
    echo "List of Users:"
    printf ">> %s\n" $(echo -e "$usr_list") 
}

printUserNotFound() { echo "ERROR: User <$1> NOT FOUND !"; } # $1 => User Display/Login Name
printUserExist() { echo "ERROR: User <$1> Already Exists !"; } # $1 => User <Name>
printHomeExist() { echo "ERROR: Directory <$1> Already Exist!"; } # $1 => Given HOME Dir  
printUserEmpty() { echo -e "ERROR: User's $1 Can't Be Empty!\n"; } # $1 => "Display / Login" 
printUserRegExp() { echo -e "ERROR: $1 RegExp Format Not Allowed\n"; } # $1 => "Display / Login"

readUserDispName() {
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
		elif [[ "$usr_name" =~ ^[a-zA-Z0-9][-a-zA-Z0-9._\'\ ]{0,$(( $(getconf LOGIN_NAME_MAX)-2 ))}[a-zA-Z0-9]$ ]]; then
		    # Display Name OK
		    break
		else
		    printUserRegExp "Display Name"
		    read -p "$(echo -e "Enter User's Display Name: ")" usr_name
		fi
	done
	local -n dispName="$1"
	dispName="$usr_name"
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
		elif [[ "$usr_login" =~ ^[a-z][-a-z0-9]{0,$(( $(getconf LOGIN_NAME_MAX)-2 ))}[a-z0-9]$ ]]; then
		    # Login Name is OK
		    break
		else
		    printUserRegExp "Login Name"
		    read -p "$(echo -e "Enter User's Login Name: ")" usr_login
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