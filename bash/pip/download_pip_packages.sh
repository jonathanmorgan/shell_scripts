#!/bin/bash

# loop over lines in available file:
requirements_file_path_in=$1
download_dir_path_in=$2
pip_executable_in=$3

# defaults
requirements_file_path="./pip_master_package_list.txt"
download_dir_path="./pip_download"
pip_executable="pip"

# check if requirements file path specified
if [ ! -z "${requirements_file_path_in}" ]
then

    # there is a requirements file path - use it.
    requirements_file_path="${requirements_file_path_in}"

fi

# check if download dir path specified
if [ ! -z "${download_dir_path_in}" ]
then

    # there is a download dir path specified - use it.
    download_dir_path="${download_dir_path_in}"

fi

# check if pip executable specified
if [ ! -z "${pip_executable_in}" ]
then

    # there is an executable specified - use it.
    pip_executable="${pip_executable_in}"

fi

echo "- requirements_file_path: ${requirements_file_path}"
echo "- download_dir_path: ${download_dir_path}"
echo "- pip_executable: ${pip_executable}"

# make sure the requirements file exists
if [ -f "${requirements_file_path}" ]
then
    # make sure the download directory exists
    if [ -d "${download_dir_path}" ]
    then

        # loop over the lines in the file, downloading each.
        while read current_package
        do

            # does it start with a pound?
            if [[ ! "${current_package}" =~ ^# && -n "${current_package}" ]]
            then

                # download the package!
                echo "----> downloading package: ${current_package}"
                ${pip_executable} download -d "${download_dir_path}" "${current_package}"

            else

                echo "----> SKIP: ${current_package}"

            fi

        done <"${requirements_file_path}"

    else

        echo "Download directory ${download_dir_path} does not exist!"

    fi

else

    echo "Requirements file ${requirements_file_path} not found!"
fi
