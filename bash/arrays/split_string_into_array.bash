#-------------------------------------------------------------------------------
# ! ----> FUNCTION: split_string_into_array_ifs_read()
#-------------------------------------------------------------------------------

# Splits string into an array on a single character. Uses $IFS, so you can pass
#     a set of characters as delimiter, each of which is treated as a separate
#     delimiter.  Good information on this:
#     - https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash

# return reference
array_from_string_ifs_read_out=

function split_string_into_array_ifs_read()
{
    # parameters
    local string_in="$1"
    local delimiter_in="$2"

    # declare variables
    local default_delimiter=" "
    local list_delimiter=
    local string_token_array=

    # clear output variable
    array_from_string_ifs_read_out=

    # set delimiter to default if nothing passed in.
    list_delimiter="${delimiter_in}"
    if [[ -z "${list_delimiter}" ]]
    then

        # use default
        list_delimiter="${default_delimiter}"

    fi

    # parse the string into return array.
    IFS=${list_delimiter} read -ra array_from_string_ifs_read_out <<< "$string_in"

    # DEBUG
    if [[ $DEBUG = true ]]
    then

        # call the function to output items in an array.
        output_array "${array_from_string_ifs_read_out[@]}"

    fi

} #-- END function split_string_into_array_ifs_read() --#
