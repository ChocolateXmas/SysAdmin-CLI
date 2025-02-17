#!/bin.bash

source "$(dirname "$0")/utils.sh"

print_UserMan() {
	printCoolTitle "$titleUserMan"
	local msg="
Select:
  (1) - List All Users
  (2) - Add New User
  (3) - Delete User
  (4) - Modify User's Properties (Login/Display Name, Password, Permissions, etc..) 
  (5) - Service Management

  (0) - BACK"
	echo -e "$msg"
}

# User Management Functions
getUserList() {
	cat /etc/passwd | grep "/home" | cut -s -d : -f1
}

# True = 0 | False = 1
isUserExist() {
    if id "$1" &>/dev/null ; then
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
printUserEmpty() { echo -e "ERROR: User's $1 Name Can't Be Empty!\n"; } # $1 => "Display / Login" 
printUserRegExp() { echo -e "ERROR: $1 Name RegExp Format Not Allowed\n"; } # $1 => "Display / Login"

getUserDispName() {
	read -p "Enter User's Display Name: " usr_name
	while true; do
		if [[ -z "$usr_name" ]]; then
			printUserEmpty "Display"
			read -p "$(echo -e "ALERT, Display Name CAN Be Empty.\nKeep Display Name Empty? (y/N)")" emptyDispChoice
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
		    printUserRegExp "Display"
		    read -p "$(echo -e "Enter User's Display Name: ")" usr_name
		fi
	done
	local -n dispName="$1"
	dispName="$usr_name"
}

getUserLoginName() {
	read -p "Enter User's Login Name: " usr_login
	while true; do
		if id "$usr_login" &>/dev/null; then
		    printUserExist "$usr_login"
			read -p "$(echo -e "Enter User's Login Name: ")" usr_login
		elif [[ -z "$usr_login" ]]; then
			printUserEmpty "Login"
			read -p "$(echo -e "Enter User's Login Name: ")" usr_login
		elif [[ "$usr_login" =~ ^[a-z][-a-z0-9]{0,$(( $(getconf LOGIN_NAME_MAX)-2 ))}[a-z0-9]$ ]]; then
		    # Login Name is OK
		    break
		else
		    printUserRegExp "Login"
		    read -p "$(echo -e "Enter User's Login Name: ")" usr_login
		fi
	done
	local -n loginName="$1"
	loginName="$usr_login"
}

# NOT USED - DEPRECATED (Future usage may be)
getValidUserPass() {
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

selector_UserMan() {
	local choice=""
	local isChoiceFound=0
	while true ; do
		isChoiceFoundFun isChoiceFound print_UserMan
		echo
		read -p "Choose Option: " choice
		echo
		case "$choice" in
			# List All Users
			"1")
				printUserList
				;;
			# Add New User
			"2")
				local usr_name=""
				getUserDispName usr_name
				local usr_login=""
				getUserLoginName usr_login
				changeChoice="Y"
				while [[ "$changeChoice" =~ ^[Yy]$  ]]; do
					echo "Just to make things sure :-)"
					echo "Display Name: $usr_name"
					echo "Login Name: $usr_login"
					read -p "Do You Want To Change Anything Before Adding? (y/N) " changeChoice
					changeChoice="${changeChoice-N}"
					if [[ ! "$changeChoice" =~ ^[Yy]$ ]]; then break; fi
					printf "\nChange:\n"
					printf "  %-3s - %-25s\n" "(1)" "User Display Name"
					printf "       %-s\n" "Current: $usr_name"
					printf "  %-3s - %-25s\n" "(2)" "User Login Name"
					printf "       %-s\n" "Current: $usr_login"
					read -p "Select: " categoryChange
					case "$categoryChange" in 
						"1")
							getUserDispName usr_name
							;;
						"2")
							getUserLoginName usr_login
							;;
						*)
							printNotFound categoryChange
							;;
					esac
				done
				local finalDecision=""
				while [[ ! "$finalDecision" =~ ^[Yy]$  && ! "$finalDecision" =~ ^[Nn]$ ]]; do
					echo -n "Press Y/y to Add, N/n to Cancel Operation" 
					read -p "Select: " finalDecision
					if [[ "$finalDecision" =~ ^[Yy]$ ]]; then 
						# Add
						sudo useradd -c "$usr_name" -m "$usr_login" -s /bin/bash
						if [[ $? -ne 0 ]]; then
							echo "User <$usr_login> Creation Has FAILED !"
							break
						fi
						sudo passwd "$usr_login"
						if [[ $? -ne 0 ]]; then
							echo "User <$usr_login> Password Creation Has FAILED !"
							sudo userdel -r "$usr_login"
							break
						fi
						echo "User <$usr_login> Has Added Successfully !"
					elif [[ "$finalDecision" =~ ^[Nn]$ ]]; then
						# Cancel
						echo "User Creation CANCELD !"
						break
					else
						printNotFound finalDecision
					fi
					echo
				done
				;;
			# Delete User
			"3")
				printUserList
				while true; do
				    echo "$cancelTitle"
					read -p "Which User To Delete? > " usr2del
					if cancelRead "$usr2del" ; then break; fi
					if ! validateUserData "$usr2del" ; then continue; fi
					read -p "Are you sure you want to DELETE '$usr2del'? (y/N)" confirm
					if [[ "$confirm" =~ ^[Yy]$ ]]; then
						sudo userdel -r "$usr2del"
						if [[ $? -ne 0 ]]; then
						    echo "User Delete FAILED !"
						    break
						fi
						echo "$usr2del has been DELETED !"
						break
					else
						echo -e "User deletion has been CANCLED !\nNo Changes were made"
						break
					fi
				done
				;;
			# Modify User's Properties
			"4")
			    local title="MODS"
				printUserList
				while true; do
				    echo "$cancelTitle"
                    read -p "Which User To Modify? > " usr2mod
                    if cancelRead "$usr2mod" ; then break; fi
                    if ! validateUserData "$usr2mod" ; then continue; fi
					printCoolTitle "$title -> $usr2mod"
					printf "\nChange:\n"
					printf "  %-3s - %-25s\n" "(1)" "Display Name"
					printf "  %-3s - %-25s\n" "(2)" "Login Name"
					printf "  %-3s - %-25s\n" "(3)" "Password"
					printf "  %-3s - %-25s\n" "(2)" "Permissions"
					read -p "Select: " categoryChange
					#printf "~ %-s - %-25s\n" "$title" "$usr2mod"
					#printf "~ %-s %-s\n" "$(( ${#title} + ${#usr2mod} ))"
					#printf "  ("
				done
				echo ""
				;;
			# Service Management
			"5")
				echo ""
				;;
			# BACK	
			"0")
				break
				;;
			*)
				printNotFound isChoiceFound
				;;	
		esac
		isEnter2Continue enter2continue
	done
}
