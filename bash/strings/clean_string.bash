#-------------------------------------------------------------------------------
# ! ----> FUNCTION: clean_string()
#-------------------------------------------------------------------------------

# return reference
cleaned_string_out=

function clean_string()
{
    # input parameters
    local work_string_in=$1

    # init.
    cleaned_string_out=

    # remove tabs and carriage returns.
    cleaned_string_out="${work_string_in//[$'\t\r']/""}"

    # replace newlines with " ==> "
    cleaned_string_out="${cleaned_string_out//$'\n'/"$newline_replacement"}"
}
#-- END function clean_string() --#
