# !/bin/bash

#===============================================================================
# ==> declare variables
#===============================================================================


# declare variables - debug
if [[ -z "$DEBUG" ]]
then
    # debug off by default.
    DEBUG=false
fi

# declare variables - name constants-ish
DEFAULT_VAULT_FOLDER="/vault"
DEFAULT_VAULT_FILE_PREFIX="encrypted_vault"
DEFAULT_LUKS_VAULT_DEVICE_PREFIX="vault_file"
DEFAULT_LVM_VAULT_VOLUME_GROUP="data_vault_vg"
DEFAULT_LVM_VAULT_LOGICAL_VOLUME="data_vault_lv"
DEFAULT_VAULT_MOUNT_POINT="/data/warehouse"
DEFAULT_RANDOM_SOURCE="/dev/urandom"
DEFAULT_BLOCK_SIZE=1024

# allow config
ALLOW_CONFIG=true


#===============================================================================
# ==> error handling
#===============================================================================


# error handling
OK_TO_PROCESS=true
ERROR_MESSAGE=

#-------------------------------------------------------------------------------
# ! ----> FUNCTION: add_error
#-------------------------------------------------------------------------------

function add_error()
{
    # input parameters
    local ERROR_MESSAGE_IN=$1
    
    # declare variables
    
    # not OK to process
    OK_TO_PROCESS=false
    
    # store error message
    if [[ -z "$ERROR_MESSAGE" ]]
    then
        ERROR_MESSAGE="${ERROR_MESSAGE_IN}"
    else
        ERROR_MESSAGE="${ERROR_MESSAGE}\n${ERROR_MESSAGE_IN}"
    fi
    
    # DEBUG
    if [[ $DEBUG = true ]]
    then
        # output message
        printf "\n${ERROR_MESSAGE_IN}\n\n" >&2
    fi
}


#===============================================================================
# ==> process options
#===============================================================================


# declare variables - option values, for use in scripts that pull this in.
FILE_SIZE_IN=
FILE_NUMBER_IN=
VAULT_FOLDER_IN=
FILE_PREFIX_IN=
RANDOM_SOURCE_IN=
LUKS_VAULT_DEVICE_PREFIX_IN=
LVM_VAULT_VOLUME_GROUP_IN=
LVM_VAULT_LOGICAL_VOLUME_IN=
VAULT_MOUNT_POINT_IN=
CONFIG_FILE_PATH_IN=
HELP_FLAG_IN=

# Options: -s <file_size> -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -p <vault_device_prefix> -g <volume_group> -l <logical_volume> -m <data_source> -x
#
# WHERE:
# ==> -s <file_size> = size fo file to create when creating a vault file or extending a vault.  Required in those commands, otherwise optional.
# ==> -n <file_number> = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make).  Set to -1 to use next number.  Defaults to counting files that match pattern \"<vault_folder>/<file_prefix>*\", then adding 1.
# ==> -v <vault_folder> = (optional) path to folder that holds the files that make up the vault.  Defaults to $DEFAULT_VAULT_FOLDER.
# ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to $DEFAULT_VAULT_FILE_PREFIX.
# ==> -d <data_source> = (optional) source of data to read into new file (don't include parentheses).  Defaults to $DEFAULT_RANDOM_SOURCE.
# ==> -p <vault_device_prefix> = (optional) prefix of the LUKS device name assigned to each vault file after it is decrypted.  Defaults to $DEFAULT_LUKS_VAULT_DEVICE_PREFIX.
# ==> -g <volume_group> = (optional) name of LVM volume group that contains vault physical volumes.  Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
# ==> -l <logical_volume> = (optional) name of LVM logical volume that is the vault.  Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.
# ==> -m <mount_point> = (optional) directory to use as mount point for the vault.  Defaults to $DEFAULT_VAULT_MOUNT_POINT.
# ==> -c <config_file_path> = path to config shell script that will be included.  Intent is that you just set the "*_IN" variables inside.  You could do all kinds of nefarious things there.  Please don't.
# ==> -x = OPTIONAL Verbose flag (v was already taken).  Defaults to false.
while getopts ":s:n:v:f:d:p:g:l:m:c:xh" opt; do
  case $opt in
    s) FILE_SIZE_IN="$OPTARG"
    ;;
    n) FILE_NUMBER_IN="$OPTARG"
    ;;
    v) VAULT_FOLDER_IN="$OPTARG"
    ;;
    f) FILE_PREFIX_IN="$OPTARG"
    ;;
    d) RANDOM_SOURCE_IN="$OPTARG"
    ;;
    p) LUKS_VAULT_DEVICE_PREFIX_IN="$OPTARG"
    ;;
    g) LVM_VAULT_VOLUME_GROUP_IN="$OPTARG"
    ;;
    l) LVM_VAULT_LOGICAL_VOLUME_IN="$OPTARG"
    ;;
    m) VAULT_MOUNT_POINT_IN="$OPTARG"
    ;;
    c) CONFIG_FILE_PATH_IN="$OPTARG"
    ;;
    x) DEBUG=true
    ;;
    h) HELP_FLAG_IN=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# ==> External configuration file

if [[ $HELP_FLAG_IN = true ]]
then
    add_error "Usage help displayed, no action taken."
fi

if [[ $DEBUG = true ]]
then
    echo "Config file path = \"${CONFIG_FILE_PATH_IN}\""
fi

# do we have a config path?
if [[ ! -z "${CONFIG_FILE_PATH_IN}" ]]
then
    # check to see if we are allowing config
    if [[ $ALLOW_CONFIG = true ]]
    then
        # we do.  Does file at that path exist?
        if [[ -f "${CONFIG_FILE_PATH_IN}" ]]
        then
            # it does.  source it.
            echo "Loading configuration from ${CONFIG_FILE_PATH_IN}"
            source "${CONFIG_FILE_PATH_IN}"
        else
            # it does not.  Error out.
            add_error "!!!! ERROR - configuration file at path \"${CONFIG_FILE_PATH_IN}\" does not exist."
        fi
    else
        # configuration not allowed.  Error out.
        add_error "!!!! ERROR - configuration file specified ( ${CONFIG_FILE_PATH_IN} ), but using a configuration file is not allowed."
    fi
else
    if [[ $DEBUG = true ]]
    then
        echo "No defaults file specified."
    fi
fi

# ==> Defaults:

# file number
if [[ -z "$FILE_NUMBER_IN" ]]
then
    # no error - derive by counting files that match "$VAULT_FOLDER_IN/$FILE_PREFIX_IN*"
    FILE_NUMBER_IN=-1
fi

# vault folder
if [[ -z "$VAULT_FOLDER_IN" ]]
then
    VAULT_FOLDER_IN="$DEFAULT_VAULT_FOLDER"
    echo ">>>> using default vault folder ( \"$VAULT_FOLDER_IN\" )."
fi

# vault file prefix
if [[ -z "$FILE_PREFIX_IN" ]]
then
    FILE_PREFIX_IN="$DEFAULT_VAULT_FILE_PREFIX"
    echo ">>>> using default vault file prefix ( \"$FILE_PREFIX_IN\" )."
fi

# random source
if [[ -z "$RANDOM_SOURCE_IN" ]]
then
    RANDOM_SOURCE_IN="$DEFAULT_RANDOM_SOURCE"
    echo ">>>> using default data source ( \"$DEFAULT_RANDOM_SOURCE\" )."
fi

# LUKS vault device prefix
if [[ -z "$LUKS_VAULT_DEVICE_PREFIX_IN" ]]
then
    LUKS_VAULT_DEVICE_PREFIX_IN="$DEFAULT_LUKS_VAULT_DEVICE_PREFIX"
    echo ">>>> using default LUKS vault file prefix ( \"$DEFAULT_LUKS_VAULT_DEVICE_PREFIX\" )."
fi

# vault LVM volume group
if [[ -z "$LVM_VAULT_VOLUME_GROUP_IN" ]]
then
    LVM_VAULT_VOLUME_GROUP_IN="$DEFAULT_LVM_VAULT_VOLUME_GROUP"
    echo ">>>> using default vault LVM volume group ( \"$DEFAULT_LVM_VAULT_VOLUME_GROUP\" )."
fi

# vault LVM logical volume
if [[ -z "$LVM_VAULT_LOGICAL_VOLUME_IN" ]]
then
    LVM_VAULT_LOGICAL_VOLUME_IN="$DEFAULT_LVM_VAULT_LOGICAL_VOLUME"
    echo ">>>> using default vault LVM logical volume ( \"$DEFAULT_LVM_VAULT_LOGICAL_VOLUME\" )."
fi

# vault mount point
if [[ -z "$VAULT_MOUNT_POINT_IN" ]]
then
    VAULT_MOUNT_POINT_IN="$DEFAULT_VAULT_MOUNT_POINT"
    echo ">>>> using default vault mount point ( \"$DEFAULT_VAULT_MOUNT_POINT\" )."
fi

echo ""

#===============================================================================
# ! ==> functions
#===============================================================================


#-------------------------------------------------------------------------------
# ----> FUNCTION: convert_size_to_bytes
#-------------------------------------------------------------------------------

# return reference
SIZE_IN_BYTES_OUT=-1

function convert_size_to_bytes()
{
    # declare variables
    local SIZE_IN="$1"
    local SIZE_INT=
    local SIZE_BYTES=
    
    # convert file size to bytes - TB to B.
    if [[ "${SIZE_IN}" == *T ]]
    then

        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "TB!"
        fi

        # divide to get down to bytes
        SIZE_INT="${SIZE_IN%T}"
        SIZE_BYTES=$(( SIZE_INT * 1024 * 1024 * 1024 * 1024 ))

    # convert file size to bytes - GB to B.
    elif [[ "${SIZE_IN}" == *G ]]
    then

        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "GB!"
        fi

        # divide to get down to bytes
        SIZE_INT="${SIZE_IN%G}"
        SIZE_BYTES=$(( SIZE_INT * 1024 * 1024 * 1024 ))

    # convert file size to bytes - MB to B.
    elif [[ "${SIZE_IN}" == *M ]]
    then

        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "MB!"
        fi

        # divide to get down to bytes
        SIZE_INT="${SIZE_IN%M}"
        SIZE_BYTES=$(( SIZE_INT * 1024 * 1024 ))

    # convert file size to bytes - KB to B.
    elif [[ "${SIZE_IN}" == *K ]]
    then

        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "KB!"
        fi

        # divide to get down to bytes
        SIZE_INT="${SIZE_IN%K}"
        SIZE_BYTES=$(( SIZE_INT * 1024 ))
    
    else

        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "B!"
        fi

        # bytes - just use SIZE_IN
        SIZE_BYTES=SIZE_IN

    fi
    
    SIZE_IN_BYTES_OUT="$SIZE_BYTES"
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: parse_file_number
#-------------------------------------------------------------------------------

# return reference
FILE_NUMBER_OUT=-1

function parse_file_number()
{
    # parameters
    local FILE_PATH_IN="$1"
    
    # declare variables
    local FILE_PATH_TOKEN_ARRAY=
    local FILE_NUMBER=
    
    # parse the number off the end of the file name.
    IFS='_' read -ra FILE_PATH_TOKEN_ARRAY <<< "$FILE_PATH_IN"
    for i in "${FILE_PATH_TOKEN_ARRAY[@]}"; do
        # process "$i"
        FILE_NUMBER="$i"
    done
    
    FILE_NUMBER_OUT="$FILE_NUMBER"

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "!!!! file number = $FILE_NUMBER_OUT"
    fi
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: get_vault_file_array
#-------------------------------------------------------------------------------

# return reference
VAULT_FILE_ARRAY_OUT=()

function get_vault_file_array()
{
    # input parameters
    local VAULT_FOLDER_IN=$1
    local FILE_PREFIX_IN=$2
    
    # declare variables
    local VAULT_FILE_ARRAY=
    
    # inside the vault folder, find all files that have the prefix passed in.
    VAULT_FILE_ARRAY_OUT=( $VAULT_FOLDER_IN/$FILE_PREFIX_IN* )
    
    # is it empty?
    if [[ "${VAULT_FILE_ARRAY_OUT[@]}" = "${VAULT_FOLDER_IN}/${FILE_PREFIX_IN}*" ]]
    then

        # yes.  return empty array.
        VAULT_FILE_ARRAY_OUT=()
        
    fi
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: get_next_vault_file_number
#-------------------------------------------------------------------------------

# return reference
NEXT_VAULT_FILE_NUMBER_OUT=-1

function get_next_vault_file_number()
{
    # input parameters
    local VAULT_FOLDER_IN=$1
    local FILE_PREFIX_IN=$2
    
    # declare variables
    local VAULT_FILE_ARRAY=
    local VAULT_FILE_COUNTER=
    local CURRENT_VAULT_FILE_NUMBER=
    local MAX_VAULT_FILE_NUMBER=-1
    local KEY=
    local VALUE=
    
    # inside the vault folder, find all files that have the prefix passed in.
    get_vault_file_array "${VAULT_FOLDER_IN}" "${FILE_PREFIX_IN}"
    VAULT_FILE_ARRAY=("${VAULT_FILE_ARRAY_OUT[@]}")

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "vault file array = ${VAULT_FILE_ARRAY[@]}"
    fi
    
    # find MAX vault file number.
    MAX_VAULT_FILE_NUMBER=0
    
    # array empty (contents equal to pattern string)?
    if [[ "${VAULT_FILE_ARRAY[@]}" != "$VAULT_FOLDER_IN/$FILE_PREFIX_IN*" ]]
    then

        # not empty array.  Loop.
        for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
        do
            if [[ $DEBUG = true ]]
            then
                echo "vault file $VAULT_FILE_COUNTER = $VAULT_FILE_NAME"
            fi
        
            # get the file number
            parse_file_number "${VAULT_FILE_NAME}"
            CURRENT_VAULT_FILE_NUMBER="${FILE_NUMBER_OUT}"
            
            if [[ $DEBUG = true ]]
            then
                echo "comparing CURRENT_VAULT_FILE_NUMBER ( ${CURRENT_VAULT_FILE_NUMBER} ) to MAX_VAULT_FILE_NUMBER ( ${MAX_VAULT_FILE_NUMBER} )"
            fi
        
            # larger than the current max?
            if [ "${CURRENT_VAULT_FILE_NUMBER}" -gt "${MAX_VAULT_FILE_NUMBER}" ]
            then
                # new max!
                MAX_VAULT_FILE_NUMBER="${CURRENT_VAULT_FILE_NUMBER}"
            fi
            
        done

    fi
    
    # return value - is MAX_VAULT_FILE_NUMBER > 0 (are there any files)?
    if [ "${MAX_VAULT_FILE_NUMBER}" -gt 0 ]
    then
        # there is at least one file.  Use MAX_VAULT_FILE_NUMBER + 1.
        NEXT_VAULT_FILE_NUMBER_OUT=$(( MAX_VAULT_FILE_NUMBER + 1 ))

        if [[ $DEBUG = true ]]
        then
            echo "there were some files (MAX_VAULT_FILE_NUMBER = ${MAX_VAULT_FILE_NUMBER})"
        fi
    else
        # no files - just set to 1.
        NEXT_VAULT_FILE_NUMBER_OUT=1

        if [[ $DEBUG = true ]]
        then
            echo "there were no files (MAX_VAULT_FILE_NUMBER = ${MAX_VAULT_FILE_NUMBER})"
        fi
    fi
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: get_vault_file_count
#-------------------------------------------------------------------------------

# return reference
VAULT_FILE_COUNT_OUT=-1

function get_vault_file_count()
{
    # input parameters
    local VAULT_FOLDER_IN=$1
    local FILE_PREFIX_IN=$2
    
    # declare variables
    local VAULT_FILE_ARRAY=
    local VAULT_FILE_COUNTER=
    local KEY=
    local VALUE=
    
    # inside the vault folder, find all files that have the prefix passed in.
    get_vault_file_array "${VAULT_FOLDER_IN}" "${FILE_PREFIX_IN}"
    VAULT_FILE_ARRAY="${VAULT_FILE_ARRAY_OUT}"

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "vault file array = ${VAULT_FILE_ARRAY[@]}"
    fi
    
    # count the vault files.
    VAULT_FILE_COUNTER=0
    
    # array empty (contents equal to pattern string)?
    if [[ "${VAULT_FILE_ARRAY[@]}" != "$VAULT_FOLDER_IN/$FILE_PREFIX_IN*" ]]
    then

        # not empty array.  Loop.
        for VAULT_FILE_NAME in "${VAULT_FILE_ARRAY[@]}"
        do
            if [[ $DEBUG = true ]]
            then
                echo "vault file $VAULT_FILE_COUNTER = $VAULT_FILE_NAME"
            fi
        
            # increment file counter
            VAULT_FILE_COUNTER=$(( VAULT_FILE_COUNTER + 1 ))
            
        done

    fi
    
    # return counter
    VAULT_FILE_COUNT_OUT="$VAULT_FILE_COUNTER"    
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: is_file_decrypted
#-------------------------------------------------------------------------------

# return reference
IS_FILE_MAPPERED_OUT=false

function is_file_mappered()
{
    # input parameters
    local FILE_DEVICE_NAME_IN="$1"
    
    # declare variables
    local FILE_DEVICE_NAME=
    local LS_RESULT=
    local IS_FILE_MAPPERED=false
    
    # make sure we have a file number.
    if [[ ! -z "${FILE_DEVICE_NAME_IN}" ]]
    then
        
        # call ls
        LS_RESULT="$(ls -al /dev/mapper | grep ${FILE_DEVICE_NAME_IN})"
        #echo "mount result: ${MOUNT_RESULT}"
    
        # anything in ls result?
        if [[ -z "${LS_RESULT}" ]]
        then
            # no - file is not in /dev/mapper.
            IS_FILE_MAPPERED=false
            #echo "IS_FILE_MAPPERED=${IS_FILE_MAPPERED} (false)"
        else
            # yes - file is in /dev/mapper.
            IS_FILE_MAPPERED=true
            #echo "IS_FILE_MAPPERED=${IS_FILE_MAPPERED} (true)"
        fi
        
    else
        echo "ERROR - File name is required.  Returning false."
    fi

    # return flag
    IS_FILE_MAPPERED_OUT="${IS_FILE_MAPPERED}"
    #echo "IS_FILE_MAPPERED_OUT=${IS_FILE_MAPPERED_OUT}"
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: is_positive_integer
#-------------------------------------------------------------------------------

# return reference
IS_INTEGER_OUT=false

function is_positive_integer()
{
    # input parameters
    local VALUE_IN=$1
    
    # declare variables
    local IS_INTEGER=false
    
    # check to see if value is a positive integer.
    case $VALUE_IN in
        ''|*[!0-9]*) IS_INTEGER=false ;;
        *) IS_INTEGER=true ;;
    esac    
    
    # return counter
    IS_INTEGER_OUT="$IS_INTEGER"    
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: is_umount_error
#-------------------------------------------------------------------------------

# return reference
IS_UMOUNT_ERROR_OUT=false

function is_umount_error()
{
    # input parameters
    local UMOUNT_OUTPUT_IN=$1
    
    # declare variables

    case "${UMOUNT_OUTPUT_IN}" in
        
        # look for "device is busy" in output from umount.
        *"device is busy"*) IS_UMOUNT_ERROR_OUT=true ;;
  
    esac
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: is_vault_activated
#-------------------------------------------------------------------------------

# return reference
IS_VAULT_ACTIVATED_OUT=false

function is_vault_activated()
{
    # input parameters
    local VAULT_VG_IN=${1:=${LVM_VAULT_VOLUME_GROUP_IN}}
    local VAULT_LV_IN=${2:=${LVM_VAULT_LOGICAL_VOLUME_IN}}
    
    # declare variables
    local LVSCAN_RESULT=
    local IS_VAULT_ACTIVATED=false
    
    # call losetup
    LVSCAN_RESULT="$(lvscan | grep ACTIVE.*${VAULT_VG_IN}\/${VAULT_LV_IN})"

    # anything in LVSCAN result?
    if [[ -z "$LVSCAN_RESULT" ]]
    then
        # no - vault's logical volume is not active.
        IS_VAULT_ACTIVATED=false
    else
        # yes - vault's logical volume is active.
        IS_VAULT_ACTIVATED=true
    fi

    # return flag
    IS_VAULT_ACTIVATED_OUT="$IS_VAULT_ACTIVATED"    
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: is_vault_mounted
#-------------------------------------------------------------------------------

# return reference
IS_VAULT_MOUNTED_OUT=false

function is_vault_mounted()
{
    # input parameters
    local VAULT_VG_IN=${1:=${LVM_VAULT_VOLUME_GROUP_IN}}
    local VAULT_LV_IN=${2:=${LVM_VAULT_LOGICAL_VOLUME_IN}}
    
    # declare variables
    local MOUNT_RESULT=
    local IS_VAULT_MOUNTED=false
    
    # call mount
    MOUNT_RESULT="$(mount | grep /dev/mapper/${VAULT_VG_IN}-${VAULT_LV_IN})"
    #echo "mount result: ${MOUNT_RESULT}"

    # anything in mount result?
    if [[ -z "${MOUNT_RESULT}" ]]
    then
        # no - vault is not mounted.
        IS_VAULT_MOUNTED=false
        #echo "IS_VAULT_MOUNTED=${IS_VAULT_MOUNTED} (false)"
    else
        # yes - vault is mounted.
        IS_VAULT_MOUNTED=true
        #echo "IS_VAULT_MOUNTED=${IS_VAULT_MOUNTED} (true)"
    fi

    # return flag
    IS_VAULT_MOUNTED_OUT="${IS_VAULT_MOUNTED}"
    #echo "IS_VAULT_MOUNTED=${IS_VAULT_MOUNTED_OUT}"
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: output_common_usage
#-------------------------------------------------------------------------------

function output_common_usage()
{
    # declare variables
    
    echo "==> -c <config_file_path> = absolute path to config shell script that will be included.  Intent is that you just set the \"*_IN\" variables inside.  See \"config_template.sh\" for copy-able template.  If you want to use config, you must set ALLOW_CONFIG=true in vault_shared.sh.  Also, FYI - You could do all kinds of unrelated, potentially nefarious things in the config shell script.  Please don't."
    echo "==> -x = OPTIONAL Verbose flag (v was already taken).  Defaults to false."
    echo "==> -h = OPTIONAL Help flag - just outputs the usage instructions.  No other action taken.  Does check inputs for validity.  Defaults to false."
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: output_errors
#-------------------------------------------------------------------------------

function output_errors()
{
    # declare variables
    
    if [[ -z "$ERROR_MESSAGE" ]]
    then
        echo ""
    else
        printf "\nERROR MESSAGE(S):\n" >&2
        printf "${ERROR_MESSAGE}\n\n" >&2
    fi
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: output_shared_options
#-------------------------------------------------------------------------------

SHARED_OPTIONS_OUT=
function output_shared_options()
{
    # declare variables
    
    SHARED_OPTIONS_OUT="-c <config_file_path> -x -h"
}


#-------------------------------------------------------------------------------
# ! ----> FUNCTION: output_shared_preconditions
#-------------------------------------------------------------------------------

function output_shared_preconditions()
{
    # declare variables
    
    echo "* Must be run as root (or using sudo)"
    echo "* Must be run in same directory as \"vault_shared.sh\""
}


#-------------------------------------------------------------------------------
# ----> FUNCTION: run_command
#-------------------------------------------------------------------------------

# return reference
OUTPUT_OUT=

function run_command()
{
    # declare variables
    local COMMAND_IN="$1"
    local MESSAGE_IN="$2"
    local STORE_OUTPUT_IN="$3"

    if [[ -z "$STORE_OUTPUT_IN" ]]
    then
        STORE_OUTPUT_IN=false
    fi
    
    echo ""
    echo "$MESSAGE_IN"
    echo "    $COMMAND_IN"
    echo ""
    if [[ -z "$COMMAND_IN" ]]
    then
        echo "ERROR - no command passed in!"
    else
        if [[ $STORE_OUTPUT_IN = true ]]
        then
            OUTPUT_OUT=$( eval $COMMAND_IN 2>&1 )
            if [[ $DEBUG = true ]]
            then
                echo "Stored output: ${OUTPUT_OUT}"
            fi
        else
            eval $COMMAND_IN
        fi
    fi
}



#-------------------------------------------------------------------------------
# ----> FUNCTION: open_vault_file
#-------------------------------------------------------------------------------

# DO NOT DECLARE A VARIABLE, THEN RE_DECLARE IT AS AN ARRAY
# - this will result in an array with a single item already in it, key of 0,
#     value empty.
# so, DO NOT:
#VAULT_FILE_TO_LOOP_DEV_MAP=
#declare -A VAULT_FILE_TO_LOOP_DEV_MAP

# return references
declare -A VAULT_FILE_TO_LOOP_DEV_MAP
declare -A VAULT_FILE_TO_DEV_MAP
IS_VAULT_FILE_OPENED_OUT=true

function open_vault_file()
{
    # parameters
    local FILE_PATH_IN="$1"
    local LUKS_PASSPHRASE_IN="$2"
    local LVM_CREATE_PV_IN=${3:=false}

    # declare variables
    local COMMAND=
    local MESSAGE=
    local FILE_PATH_TOKEN_ARRAY=
    local FILE_NUMBER=
    local LOOP_DEVICE_PATH=
    local DEV_MAPPER_NAME=
    local DID_FILE_DECRYPT=false
    local IS_OK_TO_CONTINUE=true
        
    # parse the number off the end of the file name - returned in variable
    #     FILE_NUMBER_OUT.
    parse_file_number "$FILE_PATH_IN"
    FILE_NUMBER="$FILE_NUMBER_OUT"

    # get next open loop device
    LOOP_DEVICE_PATH="$(losetup -f)"
    
    # open file as a loop device
    MESSAGE="==> Adding file $FILE_PATH_IN to loop device $LOOP_DEVICE_PATH:"
    COMMAND="losetup $LOOP_DEVICE_PATH $FILE_PATH_IN"
    run_command "$COMMAND" "$MESSAGE"
    
    # set up for decrypting and mounting file.
    DEV_MAPPER_NAME="${LUKS_VAULT_DEVICE_PREFIX_IN}_${FILE_NUMBER}"
    MESSAGE="==> Using expect to decrypt and mount ${LOOP_DEVICE_PATH} at ${DEV_MAPPER_NAME}"
    COMMAND="cryptsetup luksOpen ${LOOP_DEVICE_PATH} ${DEV_MAPPER_NAME}"
    echo "$MESSAGE"
    echo "    $COMMAND"

    # set up expect
    expect <<EOF
    
    # run cryptsetup    
    spawn $COMMAND
    
    # figure out how to use "expect" to pass the passphrase to the cryptsetup
    #     command.
    # prompt = "Enter passphrase for /vault/vault_<number>:"
    set prompt ":|#|\\\$"
    expect "Enter passphrase for $FILE_PATH_IN:"
    send "${LUKS_PASSPHRASE_IN/\$/\\\$}\r\n"
    #send "${LUKS_PASSPHRASE_IN}\n"
    expect eof

    # the EOF below must be the first and only thing on the line - no white
    #     space before or after.
EOF

    # check to see if the file is in /dev/mapper (if so, decrypt was success,
    #     if not, decrypt failed).
    is_file_mappered "${DEV_MAPPER_NAME}"
    DID_FILE_DECRYPT="${IS_FILE_MAPPERED_OUT}"
    
    # did file decrypt?
    if [[ $DID_FILE_DECRYPT = true ]]
    then
        
        # add loop device to map.
        VAULT_FILE_TO_LOOP_DEV_MAP["$FILE_PATH_IN"]="$LOOP_DEVICE_PATH"
        
        # add DEV_MAPPER_NAME to map.
        VAULT_FILE_TO_DEV_MAP["$FILE_PATH_IN"]="$DEV_MAPPER_NAME"
        
        # set output variable to true.
        IS_VAULT_FILE_OPENED_OUT=true

        # create physical volume?
        if [[ $LVM_CREATE_PV_IN = true ]]
        then
    
            # create physical volume
            MESSAGE="==> Create physical volume in LVM for /dev/mapper/$DEV_MAPPER_NAME"
            COMMAND="pvcreate /dev/mapper/$DEV_MAPPER_NAME"
            run_command "$COMMAND" "$MESSAGE"
    
        fi

    else
    
        # file did not decrypt.
        
        # release loop device.
        echo ""
        MESSAGE="**** ERROR decrypting file ${FILE_PATH_IN} - Remove file from loop device $LOOP_DEVICE_PATH"
        COMMAND="losetup -d ${LOOP_DEVICE_PATH}"
        run_command "$COMMAND" "$MESSAGE"
        
        # set output variable to false.
        IS_VAULT_FILE_OPENED_OUT=false
    
    fi
    
}


#-------------------------------------------------------------------------------
# ----> FUNCTION: close_vault_file
#-------------------------------------------------------------------------------

function close_vault_file()
{
    # parameters
    local FILE_PATH_IN="$1"

    # declare variables
    local COMMAND=
    local MESSAGE=
    local FILE_NUMBER=
    local LUKS_DEVICE_FILE=
    local LOSETUP_RESULT=
    local LOSETUP_RESULT_TOKEN_ARRAY=
    local LOOP_DEVICE_FILE=
    
    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "!!!! Parameters = $FILE_PATH_IN ($1)"
    fi

    # ! ==> get name of LUKS device for the file passed in.

    # parse the number off the end of the file name - returned in variable
    #     FILE_NUMBER_OUT, then use it to build LUKS_DEVICE_FILE.
    parse_file_number "$FILE_PATH_IN"
    FILE_NUMBER="$FILE_NUMBER_OUT"
    LUKS_DEVICE_FILE="${LUKS_VAULT_DEVICE_PREFIX_IN}_${FILE_NUMBER}"
    
    # test - close the file
    MESSAGE="==> Close the decrypted file $LUKS_DEVICE_FILE"
    COMMAND="cryptsetup luksClose $LUKS_DEVICE_FILE"
    run_command "$COMMAND" "$MESSAGE"
    
    # ! ==> lookup the loop device for this file

    LOSETUP_RESULT=$(losetup -j $FILE_PATH_IN)

    # Example output:
    # /dev/loop0: []: (/vault/vault_1)
    
    # parse on ":" to split up into parts of result we care about
    IFS=':' read -ra LOSETUP_RESULT_TOKEN_ARRAY <<< "$LOSETUP_RESULT"

    # first thing should be the loop dev path.
    LOOP_DEVICE_FILE=${LOSETUP_RESULT_TOKEN_ARRAY[0]}
    
    # remove files as a loop device
    MESSAGE="==> Remove file from loop device $LOOP_DEVICE_FILE"
    COMMAND="losetup -d $LOOP_DEVICE_FILE"
    run_command "$COMMAND" "$MESSAGE"
        
}
