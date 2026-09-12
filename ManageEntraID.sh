#!/bin/bash
#==============================================================================================================================#
#       Description and how use this script 
#  
# Choice 1, list all user in Azure principaly in domain, here for example is my domainlab "czstudioutlook.onmicrosoft.com"
# you can set Variable $domain 
#
#Choice 2 and 3 you must indicate the userPrincipalName 
#
#==============================================================================================================================#
# set -o pipefail, force the pipeline return the exitcode  of the first command example for : "result=$({ df -h $filesystem | tr -s ' ' | cut -d ' ' -f5,6 | tail -1; } 2>&1)" the set -o pipefail will get the resultat of "df -h" instead of tail -1
set -o pipefail
datetoday=$(date | tr -s ' ' | cut -d ' ' -f1-4)
domain="czstudioutlook.onmicrosoft.com"

#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/tmp/Logs_script_personnal"
pathfilelog="$pathdirlog/AddUser-Azure.log"

SEPARATOR="============================================================="

function HeaderLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "START SCRIPT: $(basename "$0")" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#example to use : write-log  "the regex found" "INFO"
function write-log {
        local message="$1"
        local event="$2"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        if [ ! -d "$pathdirlog" ];then
                mkdir -p "$pathdirlog"
        fi
        echo "$timestamp [$event] - $message" >> "$pathfilelog"
}

function EndLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}
# 'trap' here ensure endlog function run if the script
trap EndLog EXIT INT 



function AddUserAzure {
	input=""
	read -p "Give me a FirstName User at added : " firstname
    read -p "Lastname ? : " lastname

	if [[ -n "$firstname" && -n "$lastname" ]]; then
        inputUPN="${firstname}.${lastname}@${domain}"
        displayName="$firstname $lastname"
		commandCheck=$(az ad user list --filter "userPrincipalName eq '$inputUPN'" --query "[].userPrincipalName" -o tsv )

		if [[ $commandCheck == $inputUPN ]]; then 
			echo "User already $inputUPN"
			write-log " Resultat command : user $inputUPN already present" "INFO"
		else
			write-log "The User $displayName not Found in Azure, creating user : $displayName" "INFO"
			echo -n "Set a Password for New User : $displayName : "
            read -s password
			commandAddUser=$(az ad user create --display-name "$displayName" --password "$password" --user-principal-name "$inputUPN")
            echo "User $displayName created "
            write-log "User $displayName created with success " "INFO"
		fi

	else 
		write-log "Variable input empty ! " "ERROR"
	fi

}

function DelUserAzure {
    input=""
    read -p "Give me a userprincipalname  you want to deleted (example: Jean.dupont@yourdomain): " input

    if [[ -n "$input" ]]; then
        inputUPN="${input}@${domain}"
        commandCheck=$(az ad user list --filter "userPrincipalName eq '$inputUPN'" --query "[].userPrincipalName" -o tsv)
        commandId=$(az ad user list --filter "userPrincipalName eq '$inputUPN'" --query "[].id" --output tsv)
        echo "User $inputUPN present in Azure deleting in progress ...."
        write-log "User:$inputUPN with present in Azure deleting in progress..." "INFO" 
        commandDel=$(az ad user delete --id $commandId)
            if [[ $? -eq 0 ]]; then
            write-log "User $inputUPN deleted from Azure" "INFO"
            fi
    else 
    write-log "Variable Input empty! " "ERROR"
    fi
}

function GetListUserAzure {
    commandCheck=$(az ad user list | grep  userPrincipalName)
    if [[ $? -eq 0 ]]; then
    echo "List of Users :$commandCheck"
    write-log "List of Users :$commandCheck" "INFO"
    else
    write-log "command CommandCheck return an error " "ERROR"
    fi
}

function AdUserInGroup {
    user=""
    group=""

    read -p "Give me a FirstName User at added : " firstname
    read -p "Lastname ? : " lastname
    read -p "Give me a Name of Group want move this user $user : " group

    if [[ -n "$firstname" && -n "$lastname" && -n "$group" ]]; then
    userUPN="${firstname}.${lastname}@${domain}"

    commandId=$(az ad user list --filter "userPrincipalName eq '$userUPN'" --query "[].id" --output tsv)
    if [[ -n "$commandId" ]]; then
    userId=$commandId
    else
    write-log "the user $user no exist in Azure" "INFO"
    return 1
    fi

        checkGroup=$(az ad group list --filter "displayName eq '$group'" --query "[].displayName" --output tsv)
        if [[ -n "$checkGroup" ]]; then
            groupexist=true 
            write-log "the group : '$group' exist in Azure" "INFO"
            echo "the group : $group exist in Azure"
        else 
            write-log "the group : '$group' no exist in Azure" "INFO"
            echo "the group : '$group' no exist in Azure"
            return 1
        fi
            moveuseringroup=$(az ad group member add --group $group --member-id $userId)
            if [[ $? -eq 0 ]]; then
            write-log "Move '$userUPN' to group '$group' done " "INFO"
            else
            write-log "an error occurred to move user:$user at group:$group" "INFO"
            fi
    else
    write-log "variable user and group empty ! " "ERROR"
    fi
}

function Menu_Manage_User_Azure {

    while true; do 
    echo -e "\n ----------- Manage User Azure -----------"
    echo "1) Listing User Azure"
    echo "2) Add User Azure"
    echo "3) Delete User Azure"
    echo "4) Move User In Group"
    echo "q|Q) Quit"
    read -p "Your Choice ? : " choice 

    case $choice in 

    1) 
    GetListUserAzure
    ;;
    2)
    AddUserAzure
    ;;
    3)
    DelUserAzure
    ;;
    4)
    AdUserInGroup
    ;;

    q|Q) echo "Bye ! Have a nice day, see you soon ^^"; exit 0;;
    
    esac
    done
}
HeaderLog
Menu_Manage_User_Azure
