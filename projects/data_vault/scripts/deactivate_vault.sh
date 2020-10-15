# !/bin/bash

# USAGE:
#
#    ./deactivate_vault.sh ( -v <volume_folder> -f <file_prefix> -g <volume_group> -l <logical_volume> )
#
# WHERE:
# ==> -n <file_number> = (optional) number of the vault file up to and including which you want to include when activating.  Any files with number above this will be omitted (so if you are creating a new file that is 4, you'd just want to include up to 3 when you activate).  Set to -1 to activate all files.
# ==> -v <vault_folder>  = (optional) path to folder that holds the files that make up the vault.  Defaults to "/vault" ($DEFAULT_VAULT_FOLDER).
# ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to "vault_" ($DEFAULT_VAULT_FILE_PREFIX).
# ==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to "data_vault_vg" ($DEFAULT_LVM_VAULT_VOLUME_GROUP).
# ==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to "data_vault_lv" ($DEFAULT_LVM_VAULT_LOGICAL_VOLUME).

# Preconditions:
# - Must be run as root (or using sudo)
# - Make sure you’ve created the vault files using create_vault_file.sh.
# - Make sure you've already mounted the vault.
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
VAULT_FILE_ARRAY=()
LOSETUP_RESULT=
FILE_LOOP_DEVICE=


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
if [[ $IS_VAULT_ACTIVATED_OUT = false ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - vault /dev/${LVM_VAULT_VOLUME_GROUP_IN}/${LVM_VAULT_LOGICAL_VOLUME_IN} is not active! (${IS_VAULT_ACTIVATED_OUT})"

fi

# param defaults - moved to options in ./vault_shared.sh

# OK to create?
if [[ $OK_TO_PROCESS = true ]]
then
    
    # inside the vault folder, find all files that have the prefix passed in.
    get_vault_file_array "${VAULT_FOLDER_IN}" "${FILE_PREFIX_IN}"
    VAULT_FILE_ARRAY=("${VAULT_FILE_ARRAY_OUT[@]}")

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "vault file array = ${VAULT_FILE_ARRAY[@]}"
    fi
    
    # unmount the vault
    MESSAGE="==> Un-mounting vault device /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
    COMMAND="umount /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
    run_command "$COMMAND" "$MESSAGE" true

    # check to see if umount error.
    UMOUNT_OUTPUT="${OUTPUT_OUT}"
    
    # check to see if the vault is still mounted.
    is_vault_mounted "${LVM_VAULT_VOLUME_GROUP_IN}" "${LVM_VAULT_LOGICAL_VOLUME_IN}"
    IS_VAULT_MOUNTED="${IS_VAULT_MOUNTED_OUT}"
    if [[ $IS_VAULT_MOUNTED = true ]]
    then
        # still mounted?
        echo "Vault is still mounted!  Please look at error below and figure out why vault couldn't be unmounted, then run this script again."

        # Huh?  Was there an error?
        is_umount_error "${UMOUNT_OUTPUT}"
        if [[ $IS_UMOUNT_ERROR_OUT = true ]]
        then

            echo "- message: ${UMOUNT_OUTPUT}"

        fi
    else
        
        echo "Vault unmounted."

        # deactivate volume group and all associated logical volumes.
        MESSAGE="==> De-activating volume group $LVM_VAULT_VOLUME_GROUP_IN"
        COMMAND="vgchange -an $LVM_VAULT_VOLUME_GROUP_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        # loop over file names.
        for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
        do
        
            # was file number passed in?
            if [ $FILE_NUMBER_IN -gt 0 ]
            then
            
                # yes.  Parse number off end of current file name.
                parse_file_number "${VAULT_FILE_NAME}"
                CURRENT_FILE_NUMBER="${FILE_NUMBER_OUT}"
    
                # only deactivate vault files whose numbers are less than or equal
                #     to the number passed in.
                if [ $CURRENT_FILE_NUMBER -le $FILE_NUMBER_IN ]
                then
    
                    # call close_vault_file
                    close_vault_file "${VAULT_FILE_NAME}"
                    
                else
                
                    echo "====> File number ${CURRENT_FILE_NUMBER} is greater than max file number passed in ( ${FILE_NUMBER_IN} ).  Not deactivating."
                    
                fi
                    
            else
            
                # no max number passed in - just call close_vault_file
                close_vault_file "${VAULT_FILE_NAME}"
                    
            fi
    
        done
        
    fi
    
else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./deactivate_vault.sh ( -v <volume_folder> -f <file_prefix>  -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -n <file_number> = (optional) number of the vault file up to and including which you want to include when activating.  Any files with number above this will be omitted (so if you are creating a new file that is 4, you'd just want to include up to 3 when you activate).  Set to -1 to activate all files."
    echo "==> -v <vault_folder>  = (optional) path to folder that holds the files that make up the vault.  Defaults to \"/vault\"."
    echo "==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to \"vault_\"."
    echo "==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to \"$DEFAULT_LVM_VAULT_VOLUME_GROUP\"."
    echo "==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to \"$DEFAULT_LVM_VAULT_LOGICAL_VOLUME\"."

    # output usage doc shared across all commands.
    output_common_usage

    echo ""
    echo "Preconditions:"

    # output preconditions shared across all commands.
    output_shared_preconditions

    #echo "* Must be run as root (or using sudo)"
    #echo "* Must be run in same directory as vault_shared.sh"

    echo "* Make sure you’ve created the vault files using create_vault_file.sh."
    echo "* Make sure you've already mounted the vault."

    # output errors
    output_errors
fi
