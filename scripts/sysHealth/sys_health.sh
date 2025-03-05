#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../../config/config.sh"
source "$PROJECT_ROOT/scripts/utils/utils.sh"

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

SysHealthMenu() {
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
