#!/bin/bash

# ./dataset_to_vault.bash -i cusp-10369 -p orr_food -s /gcdf/Gcuration/restricted_green/orr_food/to_vault/cusp-10369 -x

# declare variables
DEBUG=false
HELP_FLAG_IN=false
PROJECT_PATH=
DATA_PATH=

# declare variables - vault
VAULT_PATH="/data/vault"
PROVIDERS_FOLDER_PATH="${VAULT_PATH}/providers"
PROVIDER_FOLDER_PATH=
CUSP_DATASET_ID_PATH=
DESTINATION_DIRECTORY=

#-------------------------------------------------------------------------------
# ! ----> FUNCTION: parse_CUSP_ID_number
#-------------------------------------------------------------------------------

# return reference
CUSP_ID_NUMBER_OUT=-1

function parse_CUSP_ID_number()
{

    # example CUSP ID: cusp_12345
    # parse on underscore, take the last token to get ID number.

    # parameters
    local CUSP_ID_IN="$1"
    
    # declare variables
    local CUSP_ID_TOKEN_ARRAY=
    local CUSP_ID_NUMBER=
    
    # parse the number off the end of the CUSP ID.
    IFS='-' read -ra CUSP_ID_TOKEN_ARRAY <<< "${CUSP_ID_IN}"
    for i in "${CUSP_ID_TOKEN_ARRAY[@]}"; do
        # process "$i"
        CUSP_ID_NUMBER="$i"
    done
    
    CUSP_ID_NUMBER_OUT="$CUSP_ID_NUMBER"

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "!!!! CUSP ID number = $CUSP_ID_NUMBER_OUT"
    fi
}



#===============================================================================
# ==> process options
#===============================================================================

# declare variables - option values, for use in scripts that pull this in.
CUSP_ID_IN=
PROVIDER_IN=
SOURCE_DIRECTORY_IN=

# Options: -i <cusp_id> -p <provider> -s <source_directory> -x -h
#
# WHERE:
# ==> -i <cusp_id> = CUSP ID (including "cusp_" prefix) of the data set we are mounting.
# ==> -p <provider> = string identifier of provider of data (the name of the provider directory).
# ==> -s <source_directory> = The source directory from which we'll pull the data.
# ==> -x = OPTIONAL DEBUG/verbose flag (v was already taken).  Defaults to false.
# ==> -h = OPTIONAL Help flag.  Defaults to false.
while getopts ":i:p:s:xh" opt; do
  case $opt in
    i) CUSP_ID_IN="$OPTARG"
    ;;
    p) PROVIDER_IN="$OPTARG"
    ;;
    s) SOURCE_DIRECTORY_IN="$OPTARG"
    ;;
    x) DEBUG=true
    ;;
    h) HELP_FLAG_IN=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# TODO - make sure vault is mounted.

# Help?
if [[ $HELP_FLAG_IN = false ]]
then

    # DEBUG
    if [[ $DEBUG = true ]]
    then
        echo "CUSP_ID_IN --> ${CUSP_ID_IN}"
        echo "PROVIDER_IN --> ${PROVIDER_IN}"
        echo "SOURCE_DIRECTORY_IN --> ${SOURCE_DIRECTORY_IN}"
    fi

    # parse out CUSP ID number
    parse_CUSP_ID_number "${CUSP_ID_IN}"
    CUSP_ID_NUMBER="${CUSP_ID_NUMBER_OUT}"

    if [[ $DEBUG = true ]]
    then
        echo "CUSP_ID_NUMBER --> ${CUSP_ID_NUMBER}"
    fi

    # make sure the source directory exists.
    if [[ -d "${SOURCE_DIRECTORY_IN}" ]]
    then

        # TODO - make sure the vault is mounted.

        # make sure the "providers" directory exists.
        if [[ -d "${PROVIDERS_FOLDER_PATH}" ]]
        then

            # cd into the vault, into the "providers" directory
            cd "${PROVIDERS_FOLDER_PATH}"

            if [[ $DEBUG = true ]]
            then
                echo "PROVIDERS_FOLDER_PATH --> ${PROVIDERS_FOLDER_PATH}"
            fi

            # check if provider directory exists
            PROVIDER_FOLDER_PATH="${PROVIDERS_FOLDER_PATH}/${PROVIDER_IN}"
            if [[ ! -d "${PROVIDER_FOLDER_PATH}" ]]
            then

                # not there - create it.
                mkdir "${PROVIDER_FOLDER_PATH}"

            fi

            if [[ $DEBUG = true ]]
            then
                echo "PROVIDER_FOLDER_PATH --> ${PROVIDER_FOLDER_PATH}"
            fi

            # cd into provider directory
            cd "${PROVIDER_FOLDER_PATH}"

            # does CUSP ID directory already exist?
            if [[ ! -d "${CUSP_ID_IN}" ]]
            then

                # not there - create it.
                mkdir "${CUSP_ID_IN}"

            fi

            # cd into cusp ID directory
            cd "${CUSP_ID_IN}"

            # store off current path in CUSP_ID_FOLDER, relative to the root of the vault (so remove VAULT_PATH from beginning, then remove any leading slash).
            CUSP_ID_FOLDER_PATH="$(pwd)"
            CUSP_ID_FOLDER_PATH="${CUSP_ID_FOLDER_PATH#$VAULT_PATH}"
            CUSP_ID_FOLDER_PATH="${CUSP_ID_FOLDER_PATH#/}"

            if [[ $DEBUG = true ]]
            then
                echo "CUSP_ID_FOLDER_PATH --> ${CUSP_ID_FOLDER_PATH}"
            fi

            # create date directory for today's date.
            TODAY_DATE_STRING="$(date '+%Y.%m.%d')"
            
            if [[ $DEBUG = true ]]
            then
                echo "TODAY_DATE_STRING --> ${TODAY_DATE_STRING}"
            fi

            # does folder for today's date already exist?
            if [[ ! -d "${TODAY_DATE_STRING}" ]]
            then

                # not there - create it.
                mkdir "${TODAY_DATE_STRING}"

                # cd into today's date directory
                cd "${TODAY_DATE_STRING}"

                # copy contents of source directory into date directory
                DESTINATION_DIRECTORY="$(pwd)"
                echo ""
                echo "Vault directory setup complete.  Now, copy the files into the vault:"
                echo "# cp -R ${SOURCE_DIRECTORY_IN}/* ${DESTINATION_DIRECTORY}"

                # check to see if numeric part of CUSP ID is already present in "${VAULT_PATH}/cusp".  If yes, output message. If no, create symbolic link to "../${CUSP_ID_FOLDER_PATH}" named hte numeric part of the cusp ID.
                CUSP_DATASET_ID_PATH="${VAULT_PATH}/cusp/${CUSP_ID_NUMBER}"
                if [[ ! -d "${CUSP_DATASET_ID_PATH}" ]]
                then

                    # does not exist.  Create it.
                    cd "${VAULT_PATH}/cusp"
                    ln -s "../${CUSP_ID_FOLDER_PATH}" "${CUSP_ID_NUMBER}"

                fi

            else

                echo "!!!! ERROR - today's date folder already exists."

            fi

        #-- END check to see if vault is mounted. --#
        
        else
            # it does not.  Error out.
            echo "!!!! ERROR - providers folder path \"${PROVIDERS_FOLDER_PATH}\" does not exist."
        fi

    else
        # it does not.  Error out.
        echo "!!!! ERROR - data source path \"${SOURCE_DIRECTORY_IN}\" does not exist."
    fi
    #-- END check to see if source directory exists. --#

# HELP!
else

    # display usage
    echo ""
    echo "USAGE:"
    echo ""
    echo "    ./dataset_to_vault.bash -i <cusp_id> -p <provider> -s <source_directory> (-x -h)"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -i <cusp_id> = CUSP ID (including \"cusp_\" prefix) of the data set we are mounting."
    echo "==> -p <provider> = string identifier of provider of data (the name of the provider directory)."
    echo "==> -s <source_directory> = The source directory from which we'll pull the data (should be the \"cusp-<ID>\" folder itself)."
    echo "==> -x = OPTIONAL DEBUG/verbose flag.  Defaults to DEBUG off."
    echo "==> -h = OPTIONAL Help flag.  Defaults to false."
    echo ""
    echo "EXAMPLE:"
    echo ""
    echo "# ./dataset_to_vault.bash -i cusp-10369 -p orr_food -s /gcdf/Gcuration/restricted_green/orr_food/to_vault/cusp-10369 -x"
    echo ""
    echo "Preconditions:"
    echo ""
    echo "* Must have activated the vault using \"activate_vault.sh\"."
    echo "* Must have mounted the vault using \"mount_vault.sh\"."

fi
