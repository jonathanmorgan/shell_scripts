# !/bin/bash

# USAGE:
#
#    ./extend_vault.sh <size_of_file> ( -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -p <vault_device_prefix> -g <volume_group> -l <logical_volume> )
#
# WHERE:
# ==> -n <file_number> = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make). Set to -1 to use next number.  Defaults to counting files that match pattern \"<vault_folder>/<file_prefix>*\", then adding 1.
# ==> -v <vault_folder>  = (optional) path to folder that holds the files that make up the vault.  Defaults to $DEFAULT_VAULT_FOLDER.
# ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to $DEFAULT_VAULT_FILE_PREFIX.
# ==> -d <data_source>  = OPTIONAL source of data to read into new file (don't include parentheses).  Defaults to $DEFAULT_RANDOM_SOURCE.
# ==> -p <vault_device_prefix> = OPTIONAL prefix of the LUKS device name assigned to each vault file after it is decrypted.  Defaults to $DEFAULT_LUKS_VAULT_DEVICE_PREFIX.
# ==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
# ==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.


# Preconditions:
# - Must be run as root (or using sudo)
# - Make sure you’ve created the loop* devices on your OS: mknod /dev/loop* b 7 *
#     - Example for loop0: mknod /dev/loop0 b 7 0
#     - Example for loop1: mknod /dev/loop1 b 7 1
# - Figure out your LUKS password and assign the same password to each of the encrypted file fragments.
# - Make sure you’ve created the vault files using create_vault_file.sh.
# - Make sure you've created the vault using create_vault.sh.
# - You must install the "expect" extension to tcl on your system before running this script (yum install expect).  This will also install tcl.
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
#FILE_SIZE_IN=$1
#FILE_NUMBER_IN=$2
#VAULT_FOLDER_IN=$3
#FILE_PREFIX_IN=$4
#RANDOM_SOURCE_IN=$5

# declare variables
#OK_TO_PROCESS=true - moved up into ./vault_shared.sh - DO NOT SET HERE!
STATUS_MESSAGE=""
COMMAND=
LUKS_PASS_PHRASE=
VAULT_FILE_NAME=
DEV_MAPPER_NAME=
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

# run the is_vault_activated() function.
is_vault_activated "$LVM_VAULT_VOLUME_GROUP_IN" "$LVM_VAULT_LOGICAL_VOLUME_IN"

# active?
if [[ $IS_VAULT_ACTIVATED_OUT = false ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - vault /dev/${LVM_VAULT_VOLUME_GROUP_IN}/${LVM_VAULT_LOGICAL_VOLUME_IN} is not active! (${IS_VAULT_ACTIVATED_OUT})"

fi

# do we have a file count?
if [ $FILE_NUMBER_IN -le 0 ]
then

    # no.  Must specify the file number to add to the vault.

    # call add_error function to register error.
    add_error "!!!! ERROR - Must specify the number of the vault file to be added to the vault (-n option)."

fi
    
# OK to create?
if [[ $OK_TO_PROCESS = true ]]
then
    
    # prompt for passphrase
    read -s -p "Enter Vault Passphrase: " LUKS_PASS_PHRASE
    printf "%b" "\n"

    # build vault file name
    VAULT_FILE_NAME="$VAULT_FOLDER_IN/${FILE_PREFIX_IN}_${FILE_NUMBER_IN}"
    
    # open the vault file, adding it as an LVM physical volume.
    open_vault_file "$VAULT_FILE_NAME" "$LUKS_PASS_PHRASE" true
    
    # Did the file open successfully?
    OK_TO_CONTINUE="${IS_FILE_MAPPERED_OUT}"
    
    # check if there was an error.    
    if [[ $OK_TO_CONTINUE = true ]]
    then
    
        # unmount the vault
        MESSAGE="==> Un-mounting vault device at /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        COMMAND="umount /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        # deactivate volume group and all associated logical volumes.
        MESSAGE="==> De-activating volume group $LVM_VAULT_VOLUME_GROUP_IN"
        COMMAND="vgchange -an $LVM_VAULT_VOLUME_GROUP_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        # add physical volume to volume group.
        DEV_MAPPER_NAME="${LUKS_VAULT_DEVICE_PREFIX_IN}_${FILE_NUMBER_IN}"
    
        # Extend LVM volume group
        MESSAGE="==> Extend LVM volume group $LVM_VAULT_VOLUME_GROUP_IN to include /dev/mapper/$DEV_MAPPER_NAME"
        COMMAND="vgextend $LVM_VAULT_VOLUME_GROUP_IN /dev/mapper/$DEV_MAPPER_NAME"
        run_command "$COMMAND" "$MESSAGE"
        
        # need also to extend logical volume
        # - from: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Logical_Volume_Manager_Administration/lv_extend.html
        MESSAGE="==> Extend LVM logical volume /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN to include added space"
        COMMAND="lvextend -l +100%FREE /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        # activate volume group again.
        MESSAGE="==> Activating volume group $LVM_VAULT_VOLUME_GROUP_IN"
        COMMAND="vgchange -ay $LVM_VAULT_VOLUME_GROUP_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        # check file system
        MESSAGE="==> Check health of ext4 file system on volume /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        COMMAND="e2fsck -f /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        run_command "$COMMAND" "$MESSAGE"
    
        # extend ext4 file system
        MESSAGE="==> Resizing ext4 file system on volume /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        COMMAND="resize2fs /dev/$LVM_VAULT_VOLUME_GROUP_IN/$LVM_VAULT_LOGICAL_VOLUME_IN"
        run_command "$COMMAND" "$MESSAGE"
        
    else
    
        # new file did not open OK.  Vault not extended.  No cleanup needed.
        echo ""
        echo "**** There were errors decrypting the new vault file.  Vault not expanded."
        echo ""
        
    fi

else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./extend_vault.sh <size_of_file> ( -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -n <file_number> = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make).  Set to -1 to use next number.  Defaults to counting files that match pattern \"<vault_folder>/<file_prefix>*\", then adding 1."
    echo "==> -v <vault_folder> = (optional) path to folder that holds the files that make up the vault.  Defaults to \"$DEFAULT_VAULT_FOLDER\"."
    echo "==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to \"$DEFAULT_VAULT_FILE_PREFIX\"."
    echo "==> -d <data_source>  = OPTIONAL source of data to read into new file.  Defaults to \"$DEFAULT_RANDOM_SOURCE\"."
    echo "==> -p <vault_device_prefix> = OPTIONAL prefix of the LUKS device name assigned to each vault file after it is decrypted.  Defaults to \"$DEFAULT_LUKS_VAULT_DEVICE_PREFIX\"."
    echo "==> -g <volume_group>  = OPTIONAL name of LVM volume group that contains vault physical volumes.  Defaults to \"$DEFAULT_LVM_VAULT_VOLUME_GROUP\"."
    echo "==> -l <logical_volume>  = OPTIONAL name of LVM logical volume that is the vault.  Defaults to  \"$DEFAULT_LVM_VAULT_LOGICAL_VOLUME\"."

    # output usage doc shared across all commands.
    output_common_usage

    echo ""
    echo "Preconditions:"
    echo ""

    # output preconditions shared across all commands.
    output_shared_preconditions

    #echo "* Must be run as root (or using sudo)"
    #echo "* Must be run in same directory as vault_shared.sh"

    echo "* Make sure you’ve created the loop* devices on your OS: mknod /dev/loop* b 7 *"
    echo "    * Example for loop0: mknod /dev/loop0 b 7 0"
    echo "    * Example for loop1: mknod /dev/loop1 b 7 1"
    echo "* Figure out your LUKS password and assign the same password to each of the encrypted file fragments."
    echo "* Make sure you’ve created the vault files using \"create_vault_file.sh\"."
    echo "* Make sure you've created the vault using \"create_vault.sh\"."
    echo "* You must install the \"expect\" extension to tcl on your system before running this script (yum install expect).  This will also install tcl."
    echo "* Must have activated the vault using \"activate_vault.sh\""

    # output errors
    output_errors
fi
