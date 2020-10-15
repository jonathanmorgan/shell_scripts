#-------------------------------------------------------------------------------
# ----> FUNCTION: write_random_file_text_line()
#-------------------------------------------------------------------------------

# declare variables
if [[ -z "$work_folder_path" ]]
then
    # debug off by default
    work_folder_path="."
fi

# return reference
text_file_path_out=

write_random_file_text_line()
{
    # declare variables
    local text_file_name_in="$1"
    local text_file_name=
    local text_file_folder_path=
    local text_file_path=
    local input_file_path="/dev/urandom"

    # init output
    text_file_path_out=

    # initialize paths
    text_file_folder_path="${work_folder_path}"

    # make sure there is a file name.
    if [[ ! -z "$text_file_name_in" ]]
    then

        # there is.  Use it.
        text_file_name="${text_file_name_in}"
        text_file_path="${text_file_folder_path}/${text_file_name}"
        text_file_path_out="${text_file_path}"

        # write a line of random text characters to the file.
        command="echo"
        file_line=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        command_text="${command} ${file_line} >> ${text_file_path}"
        command_message="${command} ${file_line} >> ${text_file_name}"
        capture_output=true
        run_command "${command_text}" "${command_message}" "${capture_output}"

    else

        # no file name.  Doing nothing.
        echo "No file name passed in ( ${text_file_name_in} ). Doing nothing, returning nothing."
        text_file_path_out=

    fi
}
#-- END function write_random_file_text_line() --#
