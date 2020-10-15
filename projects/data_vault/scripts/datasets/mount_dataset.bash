#!/bin/bash

# ./mount_dataset.bash -i cusp-10380 -p yproject-california_waterc -c yellow -x

# CONSTANTS-ISH
COLOR_GREEN="green"
COLOR_YELLOW="yellow"
GREEN_PROJECTS_PATH="/projects/projects"
YELLOW_PROJECTS_PATH="/yws/projects"

# declare variables
DEBUG=false
HELP_FLAG_IN=false
PROJECT_PATH=
DATA_PATH=

# declare variables - vault
VAULT_PATH="/data/vault"


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
DESTINATION_PROJECT_IN=
COLOR_IN=

# Options: -i <cusp_id> -p <project> -c <color> -x -h
#
# WHERE:
# ==> -i <cusp_id> = CUSP ID (including "cusp_" prefix) of the data set we are mounting.
# ==> -p <project> = string identifier of project (the name of the project directory and group).
# ==> -c <color> = The color of the data ("green" or "yellow")
# ==> -x = OPTIONAL DEBUG/verbose flag (v was already taken).  Defaults to false.
# ==> -h = OPTIONAL Help flag.  Defaults to false.
while getopts ":i:p:c:xh" opt; do
  case $opt in
    i) CUSP_ID_IN="$OPTARG"
    ;;
    p) DESTINATION_PROJECT_IN="$OPTARG"
    ;;
    c) COLOR_IN="$OPTARG"
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
        echo "DESTINATION_PROJECT_IN --> ${DESTINATION_PROJECT_IN}"
        echo "COLOR_IN --> ${COLOR_IN}"
    fi

    # parse out CUSP ID number
    parse_CUSP_ID_number "${CUSP_ID_IN}"
    CUSP_ID_NUMBER="${CUSP_ID_NUMBER_OUT}"

    # is the data in the vault?
    CUSP_DATASET_ID_PATH="${VAULT_PATH}/cusp/${CUSP_ID_NUMBER}"
    if [[ -d "${CUSP_DATASET_ID_PATH}" ]]
    then

        # check for path to the data for CUSP ID.
        cd -P "${CUSP_DATASET_ID_PATH}"

        # store output of PWD.
        DATA_PATH="$(pwd)"

        # DEBUG
        if [[ $DEBUG = true ]]
        then
            echo "DATA_PATH --> ${DATA_PATH}"
        fi

        # make sure there is something at the path.
        if [[ -d "${DATA_PATH}" ]]
        then

            # build project path.
            if [[ "${COLOR_IN}" == "${COLOR_GREEN}" ]]
            then
                PROJECT_PATH="${GREEN_PROJECTS_PATH}/${DESTINATION_PROJECT_IN}"
            elif [[ "${COLOR_IN}" == "${COLOR_YELLOW}" ]]
            then
                PROJECT_PATH="${YELLOW_PROJECTS_PATH}/${DESTINATION_PROJECT_IN}"
            fi

            echo "${PROJECT_PATH}"

            # check to make sure the project exists and has a datamarts folder.
            if [[ -d "${PROJECT_PATH}" ]]
            then
                
                # project path is good - datamarts?
                DATAMARTS_PATH="${PROJECT_PATH}/datamarts"
                if [[ -d "${DATAMARTS_PATH}" ]]
                then

                    # if everything OK:

                    # DEBUG
                    if [[ $DEBUG = true ]]
                    then
                        echo "DATAMARTS_PATH --> ${DATAMARTS_PATH}"
                    fi

                    # cd to datamarts folder
                    cd "${DATAMARTS_PATH}"

                    # copy data to datamarts folder.
                    cp -R "${DATA_PATH}" "${DATAMARTS_PATH}/"

                    # detect project group name.
                    PROJECT_GROUP_NAME="$(ls -al | grep "\.\." | awk '{print $4}')"

                    if [[ $DEBUG = true ]]
                    then
                        echo "PROJECT_GROUP_NAME --> ${PROJECT_GROUP_NAME}"
                    fi

                    # change owner to dd, group to project group name.
                    chown -R dd:${PROJECT_GROUP_NAME} ${CUSP_ID_IN}/

                    # change permissions on all child directories to 750.
                    find . -type d -exec chmod 750 {} \;

                    # change permissions on all child file to 640.
                    find . -type f -exec chmod 640 {} \;

                else

                    echo "!!!! ERROR - No datamarts folder in ${PROJECT_PATH}"

                fi

            else

                echo "!!!! ERROR - No project at path ${PROJECT_PATH}"

            fi

        else
            # it does not.  Error out.
            echo "!!!! ERROR - data path \"${DATA_PATH}\" does not exist."
        fi

    else
        # it does not.  Error out.
        echo "!!!! ERROR - data path \"${CUSP_DATASET_ID_PATH}\" does not exist."
    fi

# HELP!
else

    # display usage
    echo ""
    echo "USAGE:"
    echo ""
    echo "    ./mount_dataset.bash -i <cusp_id> -p <project> -c <color> (-x -h)"
    echo ""
    echo "WHERE:"
    echo ""
    echo "==> -i <cusp_id> = CUSP ID (including \"cusp_\" prefix) of the data set we are mounting."
    echo "==> -p <project> = string identifier of project (the name of the project directory and group)."
    echo "==> -c <color> = The color of the data (\"green\" or \"yellow\")"
    echo "==> -x = OPTIONAL DEBUG/verbose flag.  Defaults to DEBUG off."
    echo "==> -h = OPTIONAL Help flag.  Defaults to false."
    echo ""
    echo "EXAMPLE:"
    echo ""
    echo "# ./mount_dataset.bash -i cusp-10380 -p yproject-california_waterc -c yellow -x"
    echo ""
    echo "Preconditions:"
    echo ""
    echo "* Must have activated the vault using \"activate_vault.sh\"."
    echo "* Must have mounted the vault using \"mount_vault.sh\"."

fi
