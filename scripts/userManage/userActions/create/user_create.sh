#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../../../../config/config.sh"
source "$PROJECT_ROOT/scripts/userManage/user_utils.sh"

user_create() {
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
}