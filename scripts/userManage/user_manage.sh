#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../../config/config.sh"
source "$PROJECT_ROOT/scripts/utils/utils.sh"
source "$PROJECT_ROOT/scripts/userManage/user_utils.sh"
source "$PROJECT_ROOT/scripts/userManage/userActions/create/user_create.sh"
source "$PROJECT_ROOT/scripts/userManage/userActions/delete/user_del.sh"
source "$PROJECT_ROOT/scripts/userManage/userActions/modify/user_mod.sh"

print_UserMenu() {
	printCoolTitle "$titleUserMan"
	printf "%-s\n" "Select:"
	printf "  %-3s - %-s\n" "(1)" "List All Users"
	printf "  %-3s - %-s\n" "(2)" "Add New User"
	printf "  %-3s - %-s\n" "(3)" "Delete User"
	printf "  %-3s - %-s\n" "(4)" "Modify User's Properties (Login/Display Name, Password, Permissions, etc..)"
	printf "  %-3s - %-s\n" "(5)" "Service Management"
	printf "  %-3s - %-10s\n" "(0)" "BACK"
}

UserManageMenu() {
	local choice=""
	local isChoiceFound=0
	while true ; do
		isChoiceFoundFun isChoiceFound print_UserMenu
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
				user_create
				;;
			# Delete User
			"3")
				printUserList
				user_del
				;;
			# Modify User's Properties
			"4")
				user_mod
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
