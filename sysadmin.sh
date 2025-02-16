#!/bin/bash

# Check for SUDO Command
if [ "$(id -u)" -ne 0 ] ; then
	echo "ERROR! Must Run With SUDO !"
	exit 1
fi

TOOL_VERSION="1.0"

titleMain="SysAdmin V$TOOL_VERSION"

title=" ~ ~ ~ Welcome to $titleMain ~ ~ ~"
titleSysHealth="$titleMain - System Health"
titleUserMan="$titleMain - User Management"
titleBackup="$titleMain - Backup"
titleLog="$titleMain - Log Analysis"
titleServiceMan="$titleMain - Service Management"

nullChoice="\n *** Not found, Try Again ***"

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

print_MainMenu() {
	clear
	printCoolTitle "$title"
	local msg="
Select:
  (1) - Show System Health
  (2) - User Management
  (3) - Backup
  (4) - Log Analysis
  (5) - Service Management

  (0) - EXIT"
	echo -e "$msg"
}

print_SysHealth() {
	printCoolTitle "$titleSysHealth"
	local msg="
Select:
  (1) - Show CPU Usage
  (2) - Show Memory Usage
  (3) - Show Disk Usage
  (4) - Log Analysis
  (5) - Service Management

  (0) - BACK"
	echo -e "$msg"
}

selector_SysHealth() {
	local choice=""
	local isCoiceFound=0
	while true ; do
		isChoiceFoundFun isChoiceFound print_SysHealth
		echo
		read -p "Choose Option: " choice
		echo
		case "$choice" in
			# Show CPU Usage
			"1")
				top -b -n 1 | head -15
				;;
			# Show Memory Usage
			"2")
				free
				;;
			# Show Disk Usage
			"3")
				df
				;;
			# Log Analysis
			"4")
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

isUserExist() {
    if ! echo "$1" | grep -qw getUserList ; then
        # User Not Found ! (1 :: FALSE)
        echo 1
    fi
    # User Found (0 :: TRUE)
    echo 0
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
				# START Pass Manipulation
				#local usr_pass=""
				#getValidUserPass usr_pass
				# END Pass Manipulation
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
				#local usr_list=$(getUserList)
				printUserList
				# echo -e "List of Users:\n$usr_list"
				while true; do
					read -p "Which User To Delete? > " usr2del 
					if [[ -z "$usr2del" ]]; then
						echo "No USER entered, try again."
						continue
					fi
					# TODO: Make a function to check if a user name exist
					if [[ $(isUserExist "$usr2del") -ne 0 ]]; then
					    echo "'$usr2del' NOT Found! try again."
						continue
					fi
					#if ! echo "$usr_list" | grep -qw $usr2del ; then
					#	echo "'$usr2del' NOT Found! try again."
					#	continue
					#fi
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
					fi
				done
				;;
			# Modify User's Properties
			"4")
				local usr_list=$(getUserList)
				echo -e "List of Users:\n$usr_list\n"
				while true; do
				    echo -n "Select User: "
					read usr2mod
					if ! echo "$usr_list" | grep -qw "$usr2mod" ; then
                        echo -e "User <$usr2mod> Not FOUND ! Try Again . . .\n"
                        continue					    
					fi
					local title="MODS"
					printf "~ %-s - %-20s" "$title" "$usr2mod"
					printf "~%.0s" "$(( ${#title} + ${#usr2mod} ))"
					printf "  ("
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

choice=""
while true ; do
	print_MainMenu
	echo
	read -p "Choose Option: " choice
	echo
	case "$choice" in
		# Show System Health
		"1")	
			selector_SysHealth
			;;
		# User Management
		"2")
			selector_UserMan
			;;
		# Backup
		"3")
			echo ""
			;;
		# Log Analysis
		"4")
			echo ""
			;;
		# Service Management
		"5")
			echo ""
			;;
		# Exit
		"0")
			break
			;;
		*)
			echo -e "$nullChoice"
			sleep 2
			;;
	esac
done
