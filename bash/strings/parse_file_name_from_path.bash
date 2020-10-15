#-------------------------------------------------------------------------------
# ! ----> FUNCTION: parse_file_name_from_path
#-------------------------------------------------------------------------------

# declare variables - debug
if [[ -z "$DEBUG" ]]
then
    # debug off by default.
    DEBUG=false
fi

# declare variables - slash
if [[ -z "$slash" ]]
then
    # default slash to unix-style "/".
    slash="/"
fi

# return reference
file_name_out=-1

function parse_file_name_from_path()
{
    # parameters
    local file_path_in="$1"

    # declare variables
    local file_path_token_array=
    local file_name=

    # parse the last item off the file path.
    IFS=${slash} read -ra file_path_token_array <<< "$file_path_in"
    for i in "${file_path_token_array[@]}"; do
        # process "$i"
        file_name="$i"
    done

    file_name_out="$file_name"

    # DEBUG
    if [[ $DEBUG = true ]]
    then

        echo "!!!! file name = $file_name_out"

    fi

} #-- END function parse_file_name_from_path() --#
