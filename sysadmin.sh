#!/bin/bash

# Check for SUDO Command
if [ "$(id -u)" -ne 0 ] ; then
	echo "ERROR! Must Run With SUDO !"
	exit 1
fi

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/sys_manage.sh"
source "$(dirname "$0")/user_manage.sh"

TOOL_VERSION="1.2"

titleMain="SysAdmin V$TOOL_VERSION"

title=" ~ ~ ~ Welcome to $titleMain ~ ~ ~"
titleSysHealth="$titleMain - System Health"
titleUserMan="$titleMain - User Management"
titleBackup="$titleMain - Backup"
titleLog="$titleMain - Log Analysis"
titleServiceMan="$titleMain - Service Management"

nullChoice="\n *** Not found, Try Again ***"

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
			UserManageMenu
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
