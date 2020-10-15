# !/bin/bash

# USAGE:
#
#    ./unmount_vault.sh ( -g <volume_group> -l <logical_volume> )
#
# WHERE:
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
UMOUNT_OUTPUT=
IS_VAULT_MOUNTED=


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
        echo "Vault is still mounted!"
        
        # Huh?  Was there an error?
        is_umount_error "${UMOUNT_OUTPUT}"
        if [[ $IS_UMOUNT_ERROR_OUT = true ]]
        then
            
            echo "- message: ${UMOUNT_OUTPUT}"
            
        fi
    else
        echo "Vault unmounted."
    fi
    
else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./unmount_vault.sh ( -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
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

    echo "* Make sure you’ve created the vault files using \"create_vault_file.sh\"."
    echo "* Make sure you've already mounted the vault."

    # output errors
    output_errors
fi
