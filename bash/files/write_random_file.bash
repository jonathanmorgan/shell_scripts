#-------------------------------------------------------------------------------
# ----> FUNCTION: write_random_file()
#-------------------------------------------------------------------------------

# declare variables
if [[ -z "$work_folder_path" ]]
then
    # debug off by default
    work_folder_path="."
fi

# return reference
random_file_path_out=

write_random_file()
{
    # declare variables
    local file_name_in="$1"
    local block_size_in="$2"
    local block_count_in="$3"
    local file_name=
    local file_folder_path=
    local file_block_size="1M"
    local file_block_count="1"
    local file_path=
    local input_file_path="/dev/urandom"

    # init output
    random_file_path_out=

    # initialize file information
    file_folder_path="${work_folder_path}"

    # make sure there is a file name.
    if [[ ! -z "$file_name_in" ]]
    then

        # there is. Use it.
        file_name="${file_name_in}"

        # Is there a block size?
        if [[ ! -z "$block_size_in" ]]
        then
            # there is.  Use it.
            file_block_size="${block_size_in}"
        fi

        # Is there a block count?
        if [[ ! -z "$block_count_in" ]]
        then
            # there is.  Use it.
            file_block_count="${block_count_in}"
        fi

        # make and store path
        file_path="${file_folder_path}/${file_name}"
        random_file_path_out="${file_path}"
        #file_path_array+=("${file_path}")

        # execute dd command
        command="dd"
        command_text="${command} if=${input_file_path} of=${file_path} bs=${file_block_size} count=${file_block_count}"
        command_message="${command} if=${input_file_path} of=${file_name} bs=${file_block_size} count=${file_block_count}"
        capture_output=true
        run_command "${command_text}" "${command_message}" "${capture_output}"

    else

        # no file name.  Doing nothing.
        echo "No file name passed in ( ${file_name_in} ). Doing nothing, returning nothing."
        random_file_path_out=

    fi
}
#-- END function write_random_file
