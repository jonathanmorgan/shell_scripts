#!/bin/bash

# set variables
SCRIPT_DIRECTORY=
CONFIG_FILE_PATH=
COMMAND_SCRIPT=
OK_TO_RUN=true

# Make sure we have a SCRIPT_DIRECTORY
if [[ -z "${SCRIPT_DIRECTORY}" ]]
then

    # no script directory.  Error.
    echo "ERROR - Must specify a script directory."
    OK_TO_RUN=false

fi

# Make sure we have a CONFIG_FILE_PATH
if [[ -z "${CONFIG_FILE_PATH}" ]]
then

    # no config file path directory.  Error.
    echo "ERROR - Must specify a configuration file path."
    OK_TO_RUN=false

fi

# Make sure we have a COMMAND_SCRIPT
if [[ -z "${COMMAND_SCRIPT}" ]]
then

    # no command script name.  Error.
    echo "ERROR - Must specify a command script to run."
    OK_TO_RUN=false

fi

# OK to run the script?
if [[ $OK_TO_RUN = true ]]
then
    
    # cd into the scripts folder.
    cd ${SCRIPT_DIRECTORY}

    # run the script, referencing the CONFIG_FILE_PATH.
    ./${COMMAND_SCRIPT} -c ${CONFIG_FILE_PATH}

fi
