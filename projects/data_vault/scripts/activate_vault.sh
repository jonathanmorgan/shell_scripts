# !/bin/bash

# USAGE:
#
#    ./activate_vault.sh ( -n <file_number> -v <volume_folder> -f <file_prefix> -g <volume_group> -l <logical_volume> )
#
# WHERE:
# ==> -n <file_number> = (optional) number of the vault file up to and including which you want to include when activating.  Any files with number above this will be omitted (so if you are creating a new file that is 4, you'd just want to include up to 3 when you activate).  Set to -1 to activate all files.
# ==> -v <vault_folder>  = (optional) path to folder that holds the files that make up the vault.  Defaults to $DEFAULT_VAULT_FOLDER.
# ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to $DEFAULT_VAULT_FILE_PREFIX.
# ==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
# ==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.

# Preconditions:
# - Must be run as root (or using sudo)
# - Make sure you’ve created the vault files using create_vault_file.sh.
# - Make sure you've already set up the vault in LVM using "create_vault.sh".
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
#LVM_VAULT_VOLUME_GROUP_IN=
#LVM_VAULT_LOGICAL_VOLUME_IN=
#VAULT_MOUNT_POINT_IN=

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
CURRENT_FILE_NUMBER=
OK_TO_CONTINUE=true
CLOSE_VAULT_FILE_NAME=


#===============================================================================
# ! ==> code
#===============================================================================


# must be run as root
if [[ $EUID != 0 ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - This script must be run as root."

fi

# run the is_vault_activated() function.
is_vault_activated "$LVM_VAULT_VOLUME_GROUP_IN" "$LVM_VAULT_LOGICAL_VOLUME_IN"

# active?
if [[ $IS_VAULT_ACTIVATED_OUT = true ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - vault /dev/${LVM_VAULT_VOLUME_GROUP_IN}/${LVM_VAULT_LOGICAL_VOLUME_IN} is already activated! (${IS_VAULT_ACTIVATED_OUT})"

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
    for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
    do

        # initialize variable to check if decrypt was successful.
        IS_FILE_MAPPERED_OUT=true

        # OK To continue
        if [[ $OK_TO_CONTINUE = true ]]
        then
    
            # was file number passed in?
            if [ $FILE_NUMBER_IN -gt 0 ]
            then
            
                # yes.  Parse number off end of current file name.
                parse_file_number "${VAULT_FILE_NAME}"
                CURRENT_FILE_NUMBER="${FILE_NUMBER_OUT}"
    
                # only activate vault files whose numbers are less than or equal to 
                #     the number passed in.
                if [ $CURRENT_FILE_NUMBER -le $FILE_NUMBER_IN ]
                then
    
                    # call open_vault_file
                    open_vault_file "${VAULT_FILE_NAME}" "${LUKS_PASS_PHRASE}" false
                    
                else
                
                    echo "====> File number ${CURRENT_FILE_NUMBER} is greater than max file number passed in ( ${FILE_NUMBER_IN} ).  Not activating."
                    
                fi
                    
            else
            
                # no max number passed in - just call open_vault_file
                open_vault_file "${VAULT_FILE_NAME}" "${LUKS_PASS_PHRASE}" false
                    
            fi
            
            # Did the file open successfully?
            OK_TO_CONTINUE="${IS_FILE_MAPPERED_OUT}"
            
        else
        
            # error opening a file.  Don't open anymore.
            echo "ERROR opening a previous file, so skipping ${VAULT_FILE_NAME}"

        fi
        
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
        
    done

    # check if there was an error.    
    if [[ $OK_TO_CONTINUE = true ]]
    then
    
        # no errors.
        
        # activate volume group.
        MESSAGE="==> Activating volume group $LVM_VAULT_VOLUME_GROUP_IN"
        COMMAND="vgchange -ay $LVM_VAULT_VOLUME_GROUP_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        # run lvscan to just let the OS know this is active...  Without it, error:
        #     mount: special device /dev/data_vault_vg/data_vault_lv does not exist
        MESSAGE="==> Scanning logical volumes"
        COMMAND="lvscan"
        run_command "$COMMAND" "$MESSAGE"

    else
    
        # there were errors.  Clean up.
        echo ""
        echo "**** There were errors decrypting vault files.  Vault not activated.  Cleaning up:"        
        echo ""
        
        # loop over mappered files and unmap and encrypt them.  Template:
        #     for K in "${!MYMAP[@]}"; do echo $K --- ${MYMAP[$K]}; done
        for CLOSE_VAULT_FILE_NAME in "${!VAULT_FILE_TO_DEV_MAP[@]}"
        do
        
            # call close_vault_file
            close_vault_file "${CLOSE_VAULT_FILE_NAME}"
    
        done
        
        # clear out arrays?
        
    fi
    
else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./activate_vault.sh ( -n <file_number> -v <volume_folder> -f <file_prefix> -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo "==> -n <file_number> = (optional) number of the vault file up to and including which you want to include when activating.  Any files with number above this will be omitted (so if you are creating a new file that is 4, you'd just want to include up to 3 when you activate).  Set to -1 to activate all files."
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
    echo "* Make sure you've already set up the vault in LVM using \"create_vault.sh\"."

    # output errors
    output_errors
fi
