#-------------------------------------------------------------------------------
# ! ----> FUNCTION: find_and_replace()
#-------------------------------------------------------------------------------

# return reference
find_and_replaced_string_out=

function find_and_replace()
{
    # input parameters
    local work_string_in=$1
    local find_in=$2
    local replace_with_in=$3

    # init.
    find_and_replaced_string_out=

    # do it.  Based on:
    # - https://stackoverflow.com/questions/13210880/replace-one-substring-for-another-string-in-shell-script
    # - https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/

    # bash-only
    find_and_replaced_string_out="${work_string_in//$find_in/$replace_with_in}"

    # posix compliant using sed:
    #find_and_replaced_string_out=$(echo "${work_string_in}" | sed "s/${find_in}/${replace_with_in}/g")
}
#-- END function find_and_replace() --#
