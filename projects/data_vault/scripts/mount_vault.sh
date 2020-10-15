# !/bin/bash

# USAGE:
#
#    ./mount_vault.sh ( -g <volume_group> -l <logical_volume> -m <mount_point> )
#
# WHERE:
# ==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
# ==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.
# ==> -m <mount_point>  = OPTIONAL directory to use as mount point for the vault.  Defaults to $DEFAULT_VAULT_MOUNT_POINT.

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
    
    # run lvscan to just let the OS know this is active...  Without it, error:
    #     mount: special device /dev/data_vault_vg/data_vault_lv does not exist
    MESSAGE="==> Scanning logical volumes"
    COMMAND="lvscan"
    run_command "$COMMAND" "$MESSAGE"
    
    # mount the vault
    MESSAGE="==> Mounting vault from /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN to mount point $VAULT_MOUNT_POINT_IN"
    COMMAND="mount -t ext4 /dev/${LVM_VAULT_VOLUME_GROUP_IN}/${LVM_VAULT_LOGICAL_VOLUME_IN} ${VAULT_MOUNT_POINT_IN}"
    run_command "$COMMAND" "$MESSAGE"

else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./mount_vault.sh ( -g <volume_group> -l <logical_volume> -m <mount_point> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to "data_vault_vg" ($DEFAULT_LVM_VAULT_VOLUME_GROUP)."
    echo "==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to \"$DEFAULT_LVM_VAULT_LOGICAL_VOLUME\"."
    echo "==> -m <mount_point>  = OPTIONAL directory to use as mount point for the vault.  Defaults to \"$DEFAULT_VAULT_MOUNT_POINT\"."

    # output usage doc shared across all commands.
    output_common_usage

    echo ""
    echo "Preconditions:."
    echo ""

    # output preconditions shared across all commands.
    output_shared_preconditions

    #echo "* Must be run as root (or using sudo)"
    #echo "* Must be run in same directory as vault_shared.sh"

    echo "* Make sure you’ve created the vault files using \"create_vault_file.sh\"."
    echo "* Make sure you've already set up the vault in LVM using \"create_vault.sh\"."
    echo "* Must have activated the vault using \"activate_vault.sh\"."

    # output errors
    output_errors
fi
