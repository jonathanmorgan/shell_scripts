# !/bin/bash

# USAGE:
#
#    ./create_vault.sh ( -v <vault_folder> -f <file_prefix> -g <volume_group> -l <logical_volume> )
#
# WHERE:
# ==> -v <vault_folder>  = (optional) path to folder that holds the files that make up the vault.  Defaults to $DEFAULT_VAULT_FOLDER.
# ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to $DEFAULT_VAULT_FILE_PREFIX.
# ==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
# ==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.


# Preconditions:
# - Must be run as root (or using sudo)
# - Make sure you’ve created the vault files using create_vault_file.sh.
# - You must install the "expect" extension to tcl on your system before running this script (yum install expect).  This will also install tcl.
# - Must be run in same directory as vault_shared.sh


#===============================================================================
# ! ==> includes
#===============================================================================


source ./vault_shared.sh


#===============================================================================
# ! ==> declare variables
#===============================================================================


# standard options and default values moved to ./vault_shared.sh
#VAULT_FOLDER_IN=$1
#FILE_PREFIX_IN=$2

# declare variables
#OK_TO_PROCESS=true - moved up into ./vault_shared.sh - DO NOT SET HERE!
STATUS_MESSAGE=""
COMMAND=

# declare variables - mounting and encrypting file
LUKS_PASS_PHRASE=
VAULT_FILE_ARRAY=()
VGCREATE_COMMAND_STRING=
VOLUME_GROUP_NAME=
LOGICAL_VOLUME_NAME=
OK_TO_CONTINUE=true


#===============================================================================
# ! ==> code
#===============================================================================


# must be run as root
if [[ $EUID != 0 ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - This script must be run as root."

fi

# param defaults - moved to options in ./vault_shared.sh

# OK to create?
if [[ $OK_TO_PROCESS = true ]]
then
    
    # prompt for passphrase
    read -s -p "Enter Vault Passphrase: " LUKS_PASS_PHRASE
    printf "%b" "\n"

    # inside the vault folder, find all files that have the prefix passed in.
    get_vault_file_array "${VAULT_FOLDER_IN}" "${FILE_PREFIX_IN}"
    VAULT_FILE_ARRAY=("${VAULT_FILE_ARRAY_OUT[@]}")

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "vault file array = ${VAULT_FILE_ARRAY[@]}"
    fi
    
    # mount and decrypt the vault files, then add them as physical volumes.
    CURRENT_INDEX=0
    for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
    do
        # increment current index
        let CURRENT_INDEX+=1
        
        # initialize variable to check if decrypt was successful.
        IS_FILE_MAPPERED_OUT=true

        # OK To continue
        if [[ $OK_TO_CONTINUE = true ]]
        then
    
            # call open_vault_file
            open_vault_file "$VAULT_FILE_NAME" "$LUKS_PASS_PHRASE" true
            
            # DEBUG
            if [[ $DEBUG = true ]]
            then
                # output the hashes
                
                # underlying loop devices
                echo ""
                echo "====> name-value pairs in VAULT_FILE_TO_LOOP_DEV_MAP:"
                for KEY in "${!VAULT_FILE_TO_LOOP_DEV_MAP[@]}"
                do
                    VALUE=${VAULT_FILE_TO_LOOP_DEV_MAP["$KEY"]}
                    echo "$KEY = $VALUE"
                done
                
                # unencrypted volumes
                echo ""
                echo "====> name-value pairs in VAULT_FILE_TO_DEV_MAP:"
                for KEY in "${!VAULT_FILE_TO_DEV_MAP[@]}"
                do
                    VALUE=${VAULT_FILE_TO_DEV_MAP["$KEY"]}
                    echo "$KEY = $VALUE"
                done
            fi
        
            # Did the file open successfully?
            OK_TO_CONTINUE="${IS_FILE_MAPPERED_OUT}"
            
        else
        
            # error opening a file.  Don't open anymore.
            echo "ERROR opening a previous file, so skipping ${VAULT_FILE_NAME}"

        fi

    done
    
    # check if there was an error.    
    if [[ $OK_TO_CONTINUE = true ]]
    then
    
        # create volume group (get name from constants-ish in vault_functions.sh)
        VOLUME_GROUP_NAME="$LVM_VAULT_VOLUME_GROUP_IN"
        
        # build command
        VGCREATE_COMMAND_STRING="vgcreate $VOLUME_GROUP_NAME"
        for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
        do
            # get dev mapper name
            DEV_MAPPER_NAME=${VAULT_FILE_TO_DEV_MAP["$VAULT_FILE_NAME"]}
            
            # add to VGCREATE_COMMAND_STRING
            VGCREATE_COMMAND_STRING="$VGCREATE_COMMAND_STRING /dev/mapper/$DEV_MAPPER_NAME"
        done
        
        # actually create file group
        MESSAGE="==> Creating volume group $VOLUME_GROUP_NAME"
        COMMAND="$VGCREATE_COMMAND_STRING"
        run_command "$COMMAND" "$MESSAGE"
        
        # create logical volume (get name from constants-ish in vault_functions.sh)
        LOGICAL_VOLUME_NAME="$LVM_VAULT_LOGICAL_VOLUME_IN"
        MESSAGE="==> Creating logical volume $LOGICAL_VOLUME_NAME"
        COMMAND="lvcreate -n $LOGICAL_VOLUME_NAME -l 100%FREE $VOLUME_GROUP_NAME"
        run_command "$COMMAND" "$MESSAGE"
        
        # format with ext4 file system
        MESSAGE="==> Creating ext4 file system on volume /dev/$VOLUME_GROUP_NAME/$LOGICAL_VOLUME_NAME"
        COMMAND="mkfs.ext4 /dev/$VOLUME_GROUP_NAME/$LOGICAL_VOLUME_NAME"
        run_command "$COMMAND" "$MESSAGE"
        
        # mount.

    else
    
        # there were errors.  Clean up.
        echo ""
        echo "**** There were errors decrypting vault files.  Vault not created.  Cleaning up:"
        echo ""
        
        # loop over mappered files and unmap and encrypt them.  Template:
        #     for K in "${!MYMAP[@]}"; do echo $K --- ${MYMAP[$K]}; done
        for VAULT_FILE_NAME in "${!VAULT_FILE_TO_DEV_MAP[@]}"
        do
        
            # call close_vault_file
            close_vault_file "${VAULT_FILE_NAME}"
    
        done
        
        # clear out arrays?
        
    fi

else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./create_vault.sh ( -v <vault_folder> -f <file_prefix> -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -v <vault_folder>  = (optional) path to folder that holds the files that make up the vault.  Defaults to \"$DEFAULT_VAULT_FOLDER\"."
    echo "==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to \"$DEFAULT_VAULT_FILE_PREFIX\"."
    echo "==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to \"$DEFAULT_LVM_VAULT_VOLUME_GROUP\"."
    echo "==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to \"$DEFAULT_LVM_VAULT_LOGICAL_VOLUME\"."

    # output usage doc shared across all commands.
    output_common_usage

    echo ""
    echo "Preconditions:"
    echo ""

    # output preconditions shared across all commands.
    output_shared_preconditions

    #echo "* Must be run as root (or using sudo)"
    #echo "* Must be run in same directory as vault_shared.sh"

    echo "* Make sure you’ve created the vault files using create_vault_file.sh."
    echo "* You must install the \"expect\" extension to tcl on your system before running this script (yum install expect).  This will also install tcl."

    # output errors
    output_errors
fi
