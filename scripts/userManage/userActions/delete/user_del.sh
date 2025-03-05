#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../../../../config/config.sh"
source "$PROJECT_ROOT/scripts/userManage/user_utils.sh"

user_del() {
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
}