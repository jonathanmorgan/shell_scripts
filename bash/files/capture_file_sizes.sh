# !/bin/bash
#
# capture_file_sizes.sh

# TODO:
# - make better way to initialize with list of files you want to watch?

#==============================================================================#
# ! ==> variables
#==============================================================================#

# declare variables
default_output_file_path="./file_size_log.txt"
output_file_path="${default_output_file_path}"

# watched file array
declare -a watched_file_array

# log files
watched_file_array+=( "/var/log/messages" )
watched_file_array+=( "/var/log/secure" )
watched_file_array+=( "/var/log/maillog" )

# add log files at position, rather than append:
#watched_file_array[0]="/var/log/messages"
#watched_file_array[1]="/var/log/secure"
#watched_file_array[2]="/var/log/maillog"

# formatting
character_tab=$'\t'
newline_replacement=" ==> "

# get current user UID and username
user_uid="$(id -u)"
user_username="$(id -u -n)"
echo "running as uid: ${user_uid}; username: ${user_username}"

# configuration
column_separator="${character_tab}"
start_date_time_stamp=$(date +"%Y-%m-%d_%H-%M-%S")
my_host_name=$(hostname)
base_directory=$( pwd )

#===============================================================================
# ! ==> process options
#===============================================================================


# declare variables - option values, for use in scripts that pull this in.
debug_flag=
output_file_path=

# Options: -d <debug_flag> -o <output_file_path>
#
# WHERE:
# ==> -d = (optional) debug flag.  false if not present, true if present. If present, turns on debug output.
# ==> -o <output_file_path> = (optional) file path where command log output is to be sent.  Defaults to output_file_path="./file_size_log.txt"
while getopts ":do:" opt; do
  case $opt in
    d) debug_flag=true
    ;;
    o) output_file_path="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# ==> Defaults:

# debug_flag
if [[ -z "$debug_flag" ]]
then
    # debug off by default.
    debug_flag=false
    #debug_flag=true
fi

# output_file_path
if [[ -z "$output_file_path" ]]
then
    # use default
    output_file_path="${default_output_file_path}"
    #output_file_path=
fi


#==============================================================================#
# ! ==> do stuff
#==============================================================================#

# declare variables
output_header_line=""

# check to see if output file does not exist.
if [ ! -f "$output_file_path" ]; then

    echo "Output file ${output_file_path} does not exist. Initializing."

    # no file - initialize with header line.

    # date-time stamp
    column_value="date_time_stamp"
    output_header_line=${column_value}

    # host name
    column_value="hostname"
    output_header_line="${output_header_line}${column_separator}${column_value}"

    # loop over files, outputting the name of each as a header.
    for file_path in ${watched_file_array[@]}; do

        # DEBUG
        if [[ $debug_flag = true ]]
        then
            echo "header for ${file_path}"
        fi

        # current file column header
        column_value="${file_path}_size"
        output_header_line="${output_header_line}${column_separator}${column_value}"

        # current file column header
        column_value="${file_path}_line_count"
        output_header_line="${output_header_line}${column_separator}${column_value}"

    done

    # ...then append it to the end of the file, followed by a newline.
    echo "${output_header_line}" >> "${output_file_path}"

fi

# capture file sizes of each file in list now.
file_size_line=""

# date-time stamp
column_value="${start_date_time_stamp}"
file_size_line=${column_value}

# host name
column_value="${my_host_name}"
file_size_line="${file_size_line}${column_separator}${column_value}"

# loop over files, outputting the name of each as a header.
for file_path in ${watched_file_array[@]}; do

    # DEBUG
    if [[ $debug_flag = true ]]
    then
        echo "retrieving file size of file ${file_path}"
    fi

    # current file column header for file size
    column_value=$(stat -c %s ${file_path})
    file_size_line="${file_size_line}${column_separator}${column_value}"

    # current file column header for line count
    column_value=$(wc -l ${file_path} | awk '{ print $1 }')
    file_size_line="${file_size_line}${column_separator}${column_value}"

done

# ...then append it to the end of the file, followed by a newline.
echo "${file_size_line}" >> "${output_file_path}"
