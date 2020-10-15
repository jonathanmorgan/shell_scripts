# !/bin/bash

# USAGE:
#
#    ./create_vault_file.sh <size_of_file> ( -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -g <volume_group> -l <logical_volume> )
#
# WHERE:
# ==> <size_of_file> = size of file (suffixes: #K = KB, #M = MB, #G = GB, #T = TB)
# ==> -n <file_number> = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make).  Set to -1 to use next number.  Defaults to counting files that match pattern \"<vault_folder>/<file_prefix>*\", then adding 1.
# ==> -v <vault_folder> = (optional) path to folder that holds the files that make up the vault.  Defaults to $DEFAULT_VAULT_FOLDER.
# ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to $DEFAULT_VAULT_FILE_PREFIX.
# ==> -d <data_source>  = OPTIONAL source of data to read into new file (don't include parentheses).  Defaults to $DEFAULT_RANDOM_SOURCE.

# Preconditions:
# - Should be run as root (or using sudo)
# - Make sure you’ve created the loop* devices on your OS: mknod /dev/loop* b 7 *
#     - Example for loop0: mknod /dev/loop0 b 7 0
#     - Example for loop1: mknod /dev/loop1 b 7 1
# - Figure out your LUKS password and assign the same password to each of the encrypted file fragments.
# - Must be run in same directory as vault_shared.sh

#===============================================================================
# ! ==> includes
#===============================================================================


source ./vault_shared.sh


#===============================================================================
# ! ==> declare variables
#===============================================================================


# standard options and default values moved to ./vault_shared.sh
#FILE_SIZE_IN
#FILE_NUMBER_IN=
#VAULT_FOLDER_IN=
#FILE_PREFIX_IN=
#RANDOM_SOURCE_IN=

# declare variables
#OK_TO_PROCESS=true - moved up into ./vault_shared.sh - DO NOT SET HERE!
OUTPUT_PATH_IN=
STATUS_MESSAGE=""
BLOCK_SIZE="$DEFAULT_BLOCK_SIZE"
SIZE_INT=
SIZE_BYTES=
BLOCK_COUNT=-1

# declare variables - mounting and encrypting file
LOOP_DEVICE_PATH=
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

# param defaults moved to 

# file size
if [[ -z "$FILE_SIZE_IN" ]]
then

    # call add_error function to register error.
    add_error "!!!! ERROR - You must provide file size (\"-s\" option)."

fi

# OK to DD?
if [[ $OK_TO_PROCESS = true ]]
then
    
    # prompt for passphrase
    #read -s -p "Enter Vault Passphrase: " LUKS_PASS_PHRASE
    #printf "%b" "\n"

    # do we have a file number for new file?
    if [ $FILE_NUMBER_IN -le 0 ]
    then
        # no.  Try to derive using folder and file prefix.

        # - no longer using count plus 1 - using function that finds max
        #     number, then adds one to that, so we keep adding on even
        #     if there are holes in the numbering.
        #get_vault_file_count "$VAULT_FOLDER_IN" "$FILE_PREFIX_IN"
        # next file number = count of files + 1
        #FILE_NUMBER_IN=$((VAULT_FILE_COUNT_OUT + 1))
        
        # get next vault file number.
        get_next_vault_file_number "${VAULT_FOLDER_IN}" "${FILE_PREFIX_IN}"
        FILE_NUMBER_IN="${NEXT_VAULT_FILE_NUMBER_OUT}"
    fi
    
    # build the full path to the file we will be creating.
    OUTPUT_PATH_IN="$VAULT_FOLDER_IN/${FILE_PREFIX_IN}_${FILE_NUMBER_IN}"
    
    # convert file size to bytes
    convert_size_to_bytes "$FILE_SIZE_IN"
    SIZE_BYTES="$SIZE_IN_BYTES_OUT"
    
    # number of blocks
    BLOCK_COUNT=$(( SIZE_BYTES / BLOCK_SIZE ))
    
    # DEBUG
    if [[ $DEBUG = true ]]
    then

        echo "==> Parameter setup:"
        echo "    dd if=$RANDOM_SOURCE_IN of=$OUTPUT_PATH_IN bs=$BLOCK_SIZE count=$BLOCK_COUNT (FILE_SIZE_IN=$FILE_SIZE_IN; SIZE_INT=$SIZE_INT; SIZE_BYTES=$SIZE_BYTES; BLOCK_SIZE=$BLOCK_SIZE)"
        echo ""
        
    fi
    
    # make sure BLOCK_COUNT is > 0.
    if (( $BLOCK_COUNT > 0 ))
    then
        
        # do it!  dd!
        MESSAGE="==> Creating file of random data:"
        COMMAND="dd if=$RANDOM_SOURCE_IN of=$OUTPUT_PATH_IN bs=$BLOCK_SIZE count=$BLOCK_COUNT"
        run_command "$COMMAND" "$MESSAGE"
        
        # set permissions to 600
        chmod 600 $OUTPUT_PATH_IN
        
        # get next open loop device
        LOOP_DEVICE_PATH="$(losetup -f)"
        
        #-----------------------------------------------------------------------
        # open file as a loop device
        #-----------------------------------------------------------------------

        MESSAGE="==> Adding file $OUTPUT_PATH_IN to loop device $LOOP_DEVICE_PATH:"
        COMMAND="losetup $LOOP_DEVICE_PATH $OUTPUT_PATH_IN"
        run_command "$COMMAND" "$MESSAGE"
        
        read -s -p "Press enter when ready to encrypt: " READY_TO_ENCRYPT
        
        #-----------------------------------------------------------------------
        # use cryptsetup to create encryption infrastructure and encrypt file.
        #-----------------------------------------------------------------------

        MESSAGE="==> Trying cryptsetup:"
        COMMAND="cryptsetup -v --cipher aes-xts-plain --key-size 512 --hash sha512 --use-random luksFormat $LOOP_DEVICE_PATH"
        run_command "$COMMAND" "$MESSAGE"
        
        # If we "--use-urandom", rather than "--use-random", then can use expect
        #     so we don't have to re-enter pass phrase 3 times.  With
        #     "--use-random", if the system runs out of entropy, expect kills
        #     the process and the file doesn't get encrypted.  Sigh.
        
        #echo ""
        #echo "$MESSAGE"
        #echo "    $COMMAND"
        #echo ""
        
        # set up expect
        #expect <<EOF
        
        # run cryptsetup    
        #spawn $COMMAND
        
        # figure out how to use "expect" for three prompts:

        # Prompt 1: "Are you sure? (Type uppercase yes): "
        #set prompt ":|#|\\\$"
        #expect "Are you sure? (Type uppercase yes):"
        #send "YES\r\n"

        # Prompt 2: "Enter passphrase: "
        #expect "Enter passphrase:"
        #send "${LUKS_PASS_PHRASE/\$/\\\$}\r\n"
        #send "${LUKS_PASSPHRASE_IN}\n"

        # Prompt 3: "Verify passphrase: "
        #expect "Verify passphrase:"
        #send "${LUKS_PASS_PHRASE/\$/\\\$}\r\n"

        # AND finally wait for the command to complete.
        #expect eof
    
        # the EOF below must be the first and only thing on the line - no white
        #     space before or after.
#EOF

        #-----------------------------------------------------------------------
        # test - decrypt and open/map the file.
        #-----------------------------------------------------------------------

        MESSAGE="==> Decrypt and open/map the file"
        COMMAND="cryptsetup luksOpen $LOOP_DEVICE_PATH temp_vault_file"
        run_command "$COMMAND" "$MESSAGE"
        
        #echo ""
        #echo "$MESSAGE"
        #echo "    $COMMAND"
        #echo ""

        # set up expect
        #expect <<EOF
        
        # run cryptsetup    
        #spawn $COMMAND
        
        # Prompt: "Enter passphrase for /vault/encrypted_vault_<number>:"
        #set prompt ":|#|\\\$"
        #expect "Enter passphrase for ${OUTPUT_PATH_IN}:"
        #send "${LUKS_PASS_PHRASE/\$/\\\$}\r\n"

        # AND finally wait for the command to complete.
        #expect eof
    
        # the EOF below must be the first and only thing on the line - no white
        #     space before or after.
#EOF
                
        #-----------------------------------------------------------------------
        # test - close the file
        #-----------------------------------------------------------------------

        MESSAGE="==> Unmount the file"
        COMMAND="cryptsetup luksClose temp_vault_file"
        run_command "$COMMAND" "$MESSAGE"
        
        #-----------------------------------------------------------------------
        # remove files as a loop device
        #-----------------------------------------------------------------------

        MESSAGE="==> Remove file from loop device"
        COMMAND="losetup -d $LOOP_DEVICE_PATH"
        run_command "$COMMAND" "$MESSAGE"
        
    fi
    
else

    # render shared option string.
    output_shared_options

    # display usage
    echo "USAGE:"
    echo ""
    echo "    ./create_vault_file.sh <size_of_file> ( -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -g <volume_group> -l <logical_volume> ${SHARED_OPTIONS_OUT} )"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> <size_of_file> = size of file (suffixes: #K = KB, #M = MB, #G = GB, #T = TB)"
    echo "==> -n <file_number> = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make).  Set to -1 to use next number.  Defaults to counting files that match pattern \"<vault_folder>/<file_prefix>*\", then adding 1."
    echo "==> -v <vault_folder> = (optional) path to folder that holds the files that make up the vault.  Defaults to \"$DEFAULT_VAULT_FOLDER\"."
    echo "==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to \"$DEFAULT_VAULT_FILE_PREFIX\"."
    echo "==> -d <data_source>  = OPTIONAL source of data to read into new file.  Defaults to \"$DEFAULT_RANDOM_SOURCE\"."

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
    
    # output errors
    output_errors
fi
