    # !/bin/bash

# USAGE:
#
#    ./mount_vault.sh ( -g <volume_group> -l <logical_volume> )
#
# WHERE:
# ==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
# ==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.

# Preconditions:
# - Must be run as root (or using sudo)
# - Make sure you’ve created the vault files using create_vault_file.sh.
# - Make sure you've already set up the vault in LVM using "create_vault.sh".
# - Must be run in same directory as vault_shared.sh
# - Must have activated the vault using "activate_vault.sh"

#===============================================================================
# ! ==> includes
#===============================================================================


source ./vault_shared.sh


#===============================================================================
# ! ==> declare variables
#===============================================================================


# standard options and default values moved to ./vault_shared.sh
#LVM_VAULT_VOLUME_GROUP_IN=
#LVM_VAULT_LOGICAL_VOLUME_IN=
#VAULT_MOUNT_POINT_IN=

# declare variables
#OK_TO_PROCESS=true - moved up into ./vault_shared.sh - DO NOT SET HERE!
STATUS_MESSAGE=""
COMMAND=


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
    
    # not activated!
    echo "Checking status of vault: /dev/${LVM_VAULT_VOLUME_GROUP_IN}/${LVM_VAULT_LOGICAL_VOLUME_IN}"

    # run the is_vault_activated() function.
    is_vault_activated "$LVM_VAULT_VOLUME_GROUP_IN" "$LVM_VAULT_LOGICAL_VOLUME_IN"

    # active?
    if [[ $IS_VAULT_ACTIVATED_OUT = true ]]
    then
        # activated!
        echo "Activated! (${IS_VAULT_ACTIVATED_OUT})"
    else
        # not activated!
        echo "Not activated! (${IS_VAULT_ACTIVATED_OUT})"
    fi

else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./is_vault_active.sh ( -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to \"${DEFAULT_LVM_VAULT_VOLUME_GROUP}\"."
    echo "==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to \"${DEFAULT_LVM_VAULT_LOGICAL_VOLUME}\"."

    # output usage doc shared across all commands.
    output_common_usage

    echo ""
    echo "Preconditions:."
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
