#-------------------------------------------------------------------------------
# ----> FUNCTION: output_array()
#-------------------------------------------------------------------------------

# to invoke:
#     output_array "${array[@]}"

#Function to print an array
# from: https://unix.stackexchange.com/questions/328882/how-to-add-remove-an-element-to-from-the-array-in-bash
# refined using: https://askubuntu.com/questions/674333/how-to-pass-an-array-as-function-argument
output_array()
{
    arr=("$@")
    for i in "${arr[@]}"
    do
        echo $i
    done
}
#-- END function output_array
