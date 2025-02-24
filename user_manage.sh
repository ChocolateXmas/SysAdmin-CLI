#!/bin.bash

source "$(dirname "$0")/utils.sh"

print_UserMan() {
	printCoolTitle "$titleUserMan"
	printf "%-s" "Select: "
	printf "  %-3s - %-s\n" "(1)" "List All Users"
	printf "  %-3s - %-s\n" "(2)" "Add New User"
	printf "  %-3s - %-s\n" "(2)" "Add New User"
	printf "  %-3s - %-s\n" "(3)" "Delete User"
	printf "  %-3s - %-s\n" "(4)" "Modify User's Properties (Login/Display Name, Password, Permissions, etc..)"
	printf "  %-3s - %-s\n" "(5)" "Service Management"
	printf "  %-3s - %-10s\n" "(0)" "BACK"
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
printHomeExist() { echo "ERROR: Directory <$1> Already Exist!" } # $1 => Given HOME Dir  
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

readUserHomeDir() {
	while true; do
		read -p "Enter User's Home Directory: " homeDir
		if [[ -z "$homeDir" ]]; then
			printUserEmpty "HOME Dir"
			read -p "$(echo -e "WARNING, HOME Dir CAN Be Empty, BUT The User Would NOT Have Any HOME Folder!\nKeep HOME Dir Empty? (y/N)")" emptyHomeChoice
			emptyHomeChoice="${emptyHomeChoice-N}"
			if [[ "$emptyHomeChoice" =~ ^[Yy]$ ]]; then
			    homeDir="" #Empty HOME Dir
			    break
			else
			    read -p "$(echo -e "Enter User's HOME Dir: ")" homeDir
			fi
		elif [[ -d "$homeDir" ]]; then
			printHomeExist "$homeDir"
			read -p "Continue? (Y/n) " existingDirChoice
			if [[ "$existingDirChoice" =~ ^[Yy]$ ]]; then
				# Use Exisiting HOME Dir
				break
			fi
			continue
		elif [[ "$homeDir" =~ ^/(?:[A-Za-z0-9._-]+/?)+$ ]]; then
		    # HOME Dir OK
		    break
		else
		    printUserRegExp "HOME Dir"
		    read -p "$(echo -e "Enter User's HOME Dir: ")" homeDir
		fi
	done
	local -n newHome="$1"
	newHome="$homeDir"
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
				readUserDispName usr_name
				local usr_login=""
				readUserLoginName usr_login
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
					local categoryChange; read -p "Select: " categoryChange
					case "$categoryChange" in 
						"1")
							readUserDispName usr_name
							;;
						"2")
							readUserLoginName usr_login
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
							echo "ERROR: User <$usr_login> Creation Has FAILED !"
							break
						fi
						sudo passwd "$usr_login"
						if [[ $? -ne 0 ]]; then
							echo "ERROR: User <$usr_login> Password Creation Has FAILED !"
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
				while true; do
					printUserList
				    echo "$cancelTitle"
                    read -p "Which User To Modify? > " usr2mod
                    if cancelRead "$usr2mod" ; then break; fi
                    if ! validateUserData "$usr2mod" ; then continue; fi
					while true; do
						local title="MODS"
						echo
						printCoolTitle "$title -> $usr2mod"
						local dispName="$(getent passwd "$usr2mod" | cut -d: -f5 )"
						dispName="${dispName:-No Display Name}"
						local loginName="$(getent passwd "$usr2mod" | cut -d: -f1)"
						local homeDir="$(getent passwd $usr2mod | cut -d: -f6)"
						homeDir="${homeDir:-No HOME Dir}"
						printf "Change:\n"
						printf "  %-3s - %-25s\n" "(1)" "Display Name"
						printf "       %-s\n" "Current: <$dispName>"
						printf "  %-3s - %-25s\n" "(2)" "Login Name"
						printf "       %-s\n" "Current: <$loginName>"
						printf "  %-3s - %-25s\n" "(3)" "Password"
						printf "  %-3s - %-25s\n" "(4)" "Permissions"
						printf "  %-3s - %-25s\n" "(5)" "HOME dir"
						printf "       %-s\n" "Current: $homeDir"
						printf "  %-3s - %-10s\n" "(0)" "BACK"
					    local categoryChange; read -p "Select: " categoryChange
					    case "$categoryChange" in
					        # Display Name
					        "1")
					            local newDispName=""
					            readUserDispName newDispName
					            sudo usermod "$usr2mod" -c "$newDispName"
								if [[ $? -ne 0 ]]; then
									echo "ERROR: User Display Name Change FAILED"
									break
								fi
								echo "Success!"
								enter2continue
								continue
					            ;;
					        # Login Name
					        "2")
					            local newLoginName=""
					            readUserLoginName newLoginName
					            sudo usermod "$usr2mod" -l "$newLoginName"
								if [[ $? -ne 0 ]]; then
									echo "ERROR: User Login Name Change FAILED"
									break
								fi
								echo "Success!"
								usr2mod="$newLoginName"
								enter2continue
								continue
					            ;;
					        # Password    
				            "3")
								sudo passwd "$usr2mod"
								if [[ $? -ne 0 ]]; then
									echo "ERROR: User Login Password Change FAILED"
									break
								fi
								echo "Success!"
								enter2continue
								continue
								;;
					        # Permissions
					        "4")
					            ;;
					        # HOME dir
					        "5")
					            local newHomeDir=""
								read -p ""
					            ;;
					        # BACK
					        "0")
					            break
					            ;;
					        *)
					            printNotFound categoryChange
					            ;;
                        esac    
					done
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
