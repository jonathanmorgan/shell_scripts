# !/bin/bash

#===============================================================================
# ! ==> includes
#===============================================================================

source ./vault_shared.sh

#===============================================================================
# ! ==> declare variables
#===============================================================================

#OK_TO_PROCESS=true - moved up into ./vault_shared.sh - DO NOT SET HERE!

# LVM information
DO_DELETE=false
LVM_VOLUME_GROUP_NAME=
LVM_LOGICAL_VOLUME_NAME=
LVM_LOGICAL_VOLUME_PATH=

# vault file information
VAULT_FILE_ARRAY=
CURRENT_FILE_NUMBER=
LUKS_DEVICE_PREFIX=

#===============================================================================
# ! ==> do stuff
#===============================================================================

# gather LVM and LUKS information
LVM_VOLUME_GROUP_NAME="${LVM_VAULT_VOLUME_GROUP_IN}"
LVM_LOGICAL_VOLUME_NAME="${LVM_VAULT_LOGICAL_VOLUME_IN}"
LVM_LOGICAL_VOLUME_PATH="/dev/${LVM_VOLUME_GROUP_NAME}/${LVM_LOGICAL_VOLUME_NAME}"
LUKS_DEVICE_PREFIX="${LUKS_VAULT_DEVICE_PREFIX_IN}"

# run the is_vault_activated() function.
is_vault_activated "$LVM_VAULT_VOLUME_GROUP_IN" "$LVM_VAULT_LOGICAL_VOLUME_IN"

# active?
if [[ $IS_VAULT_ACTIVATED_OUT = false ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - vault /dev/${LVM_VAULT_VOLUME_GROUP_IN}/${LVM_VAULT_LOGICAL_VOLUME_IN} is not active! (${IS_VAULT_ACTIVATED_OUT})"

fi

# OK to create?
if [[ $OK_TO_PROCESS = true ]]
then
    
    # OK to create?
    if [[ $DO_DELETE = true ]]
    then
    
        # unmount the vault
        MESSAGE="==> Unmounting the vault at LVM logical volume ${LVM_LOGICAL_VOLUME_PATH}:"
        COMMAND="umount ${LVM_LOGICAL_VOLUME_PATH}"
        run_command "$COMMAND" "$MESSAGE"
        
        # remove the vault's LVM logical volume
        MESSAGE="==> Removing the vault's LVM logical volume ${LVM_LOGICAL_VOLUME_PATH}:"
        COMMAND="lvremove ${LVM_LOGICAL_VOLUME_PATH}"
        run_command "$COMMAND" "$MESSAGE"
        
        # remove the vault's LVM volume group
        MESSAGE="==> Removing the vault's LVM logical volume ${LVM_LOGICAL_VOLUME_PATH}:"
        COMMAND="vgremove ${LVM_VOLUME_GROUP_NAME}"
        run_command "$COMMAND" "$MESSAGE"

        # loop over the individual files and clean up each as we go.
        # inside the vault folder, find all files that have the prefix passed in.
        get_vault_file_array "${VAULT_FOLDER_IN}" "${FILE_PREFIX_IN}"
        VAULT_FILE_ARRAY=("${VAULT_FILE_ARRAY_OUT[@]}")
    
        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "vault file array = ${VAULT_FILE_ARRAY[@]}"
        fi
        
        # mount and decrypt the vault files, then add them as physical volumes.
        CURRENT_FILE_NUMBER=0
        for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
        do
            # get the file number
    
            # parse the number off the end of the file name - returned in variable
            #     FILE_NUMBER_OUT.
            parse_file_number "${VAULT_FILE_NAME}"
            CURRENT_FILE_NUMBER="${FILE_NUMBER_OUT}"
                
            # DEBUG
            if [[ $DEBUG = true ]]
            then
                echo "current vault file = ${VAULT_FILE_NAME}, number = ${CURRENT_FILE_NUMBER}"
            fi
            
            # remove the file's LVM physical volume
            MESSAGE="==> Removing the vault's LVM physical volume - /dev/mapper/${LUKS_DEVICE_PREFIX}_${CURRENT_FILE_NUMBER}:"
            COMMAND="pvremove /dev/mapper/${LUKS_DEVICE_PREFIX}_${CURRENT_FILE_NUMBER}"
            run_command "$COMMAND" "$MESSAGE"
        
            # call close_vault_file
            close_vault_file "${VAULT_FILE_NAME}"
        
            # remove the actual file
            MESSAGE="==> Removing the actual vault file - ${VAULT_FILE_NAME}:"
            COMMAND="rm ${VAULT_FILE_NAME}"
            run_command "$COMMAND" "$MESSAGE"
                
        done
        
    else
    
        echo "Not doing anything until the DO_DELETE flag is true!"
    
    fi

else

    # output errors
    output_errors

fi
