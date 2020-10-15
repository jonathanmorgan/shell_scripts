#!/bin/bash

# set up environment
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Documents/work/virtualenv_projects
source `which virtualenvwrapper.sh`

# get directory of this script, and cd to this directory.
DIRECTORY=`dirname $0`
cd $DIRECTORY
echo "Script in $DIRECTORY"

# get list of virtualenvs.
lsvirtualenv | \

# loop over lines
while read VIRTUALENV_NAME
do
	# contents of line will either be a line of "=", blank, or the name of a
	#    virtualenv.  Only do stuff if line is not empty, or does not start
	#    with an equal sign.

	# first, check if empty.
	if [ -z "$VIRTUALENV_NAME" ]
    then

    	# empty.  Move on.
        echo zero length

    else

    	# check if a line of equal signs.
        if [[ "${VIRTUALENV_NAME}" == ==* ]]
        then

        	# equal signs.
        	echo equals-line

        else

        	# we have a virtualenv.
        	echo "==> $VIRTUALENV_NAME"

        	# activate it.
        	workon $VIRTUALENV_NAME

        	# update it
        	./pip_upgrade_all.sh

        	# deactivate
        	deactivate

      	fi
    fi
done