#!/bin/bash

echo pip version: $1

# first, try to upgrade pip
pip$1 install --upgrade pip

# get list of outdated packages in pip.
pip$1 list -o | \

# remove version information from end of string.
cut -d " " -f1 | \

# loop over packages
while read PIP_PACKAGE
do

    # flag to decide if we process current line
    DO_PROCESS_LINE=true

    # don't process if line starts with "Package" or "-------"
    case ${PIP_PACKAGE} in
        Package*) DO_PROCESS_LINE=false;;
        -------*) DO_PROCESS_LINE=false;;
    esac

    # OK to process?
    if [ "${DO_PROCESS_LINE}" == true ] ;
    then

        # upgrade each package
        echo $PIP_PACKAGE
        pip$1 install --upgrade $PIP_PACKAGE

    fi

done
