#-------------------------------------------------------------------------------
# ! ----> FUNCTION: has_tabs()
#-------------------------------------------------------------------------------

# return reference
has_tabs_out=false

function has_tabs()
{
    # input parameters
    local value_in=$1

    # declare variables
    local has_tabs=false

    # check to see if value contains a tab.
    case $value_in in
        *${character_tab}*) has_tabs=true ;;
        *) has_tabs=false ;;
    esac

    # return counter
    has_tabs_out="${has_tabs}"
}
#-- END function has_tabs() --#
