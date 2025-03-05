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
								# TODO: check more users on this group given use2mod's group, change the group (if exist) of the current user accordingly without breaking the other users group. Make a new group for the new login name if needed. 
					            local newLoginName=""
					            readUserLoginName newLoginName
					            sudo usermod "$usr2mod" -l "$newLoginName"
								if [[ $? -ne 0 ]]; then
									echo "ERROR: User Login Name Change FAILED"
									break
								fi
								echo "Success!"
								usr2mod="$newLoginName" # For script change to be visible on the next menu run
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
								readUserHomeDir newHomeDir "$usr2mod" 
								echo "Old Dir: $homeDir"
								echo "New Dir: $newHomeDir"
								if [[ "$newHomeDir" == "$homeDir" ]]; then
									echo "No Changes Were Made To HOME Dir !"
									break
								elif [[ -z newHomeDir ]]; then
									echo "New HOME Dir Will Be NON-Existing"
								fi
							
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
