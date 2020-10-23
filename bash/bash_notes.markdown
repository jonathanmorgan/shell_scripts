# Table of Contents

- [Notes](#Notes)

    - [include .bashrc in .profile/.bash_profile](#include-bashrc-in-profilebash_profile)
    - [include user’s private ~/bin in path](#include-users-private-bin-in-path) 
    - [Setting prompt content and colors](#Setting-prompt-content-and-colors)

-   [Scripting](#Scripting)

    - [Arrays](#Arrays)
    - [Numbers](#Numbers)

        - [Arithmetic](#Arithmetic)

    - [Paths](#Paths)

        - [check if file or directory exists](#check-if-file-or-directory-exists)
        - [Convert relative path to absolute](#Convert-relative-path-to-absolute)
        - [Create directory if it does not exist](#Create-directory-if-it-does-not-exist)

    - [Program control](#Program-control)

        - [If-then-elif-else](#If-then-elif-else)

    - [strings](#strings)

         - [String comparison](#String-comparison)

            - [Empty strings](#Empty-strings)
            - [Test command (sh or bash)](#Test-command-sh-or-bash)
            - [Pattern matching in bash](#Pattern-matching-in-bash)

        - [string parsing](#string-parsing)
        - [File paths](#File-paths)

    - [variables](#variables)

        - [Check if set or populated](#Check-if-set-or-populated)
        - [Use variable value in reference to a separate variable](#Use-variable-value-in-reference-to-a-separate-variable)
        - [Variable expansion operators - default if variable not set](#Variable-expansion-operators---default-if-variable-not-set)

    - [wildcards in scripts](#wildcards-in-scripts)
    - [Getopts (with detailed examples)](#Getopts-with-detailed-examples)

        - [Example](#Example)
        - [Example within a bash function](#Example-within-a-bash-function)

# Notes

## include .bashrc in .profile/.bash\_profile
 
    # if running bash

    if [ -n "$BASH\_VERSION" ]; then

        # include .bashrc if it exists

        if [ -f "$HOME/.bashrc" ]; then

            . "$HOME/.bashrc"

        fi

    fi

## include user’s private ~/bin in path

    # set PATH so it includes user's private bin if it exists

    if [ -d "$HOME/bin" ] ; then

        PATH="$HOME/bin:$PATH"

    fi 

## Setting prompt content and colors

- to change content and colors in prompt, you set PS1 in your .bash\_profile/.profile/.bashrc

    - example with no color (  jonathanmorgan@JSM-2012-MacMini:~$  ):

        - `export PS1="\u@\h:\w\$ "`
        - WHERE:

            - `\u` = current user
            - `\h` = hostname
            - `\w` = path to current working directory

                - `\W` = just current directory, no path 

            - `\$` outputs dollar sign
            - More entities: [http://www.ibm.com/developerworks/linux/library/l-tip-prompt/](http://www.ibm.com/developerworks/linux/library/l-tip-prompt/)

    - you can also add color - example ( jonathanmorgan@JSM-2012-MacMini:~$  ):

        - `export PS1="\[\e[36m\]\u@\h\[\e[0m\]:\[\e[32m\]\w\[\e[0m\]\$ "`
        - WHERE

            - colors are preceded by “`\[`“ and followed by “`\]`” - escaped square brackets (tells bash that what is inside should not take up any space in the actual terminal):

                - `\[\e\[36;40m\]`

            - inside the escaped brackets, color numbers are always preceded by either “`\e[`” or “`\033[`” and followed by “m”:

                - `\[\e[36;40m\]`

                - OR `\[\033[36;40m\]`

            - Then, color information.  At least three ways this can work:

                - One number:

                    - a single number defines foreground color (36 is light blue, for example).
                    - special:

                        - 0 resets to default color (as does leaving a number out entirely).
                        - 1 sets to bold.

                - Two numbers:

                    - use two numbers separated by semi-colons to set foreground, then background text.

                        - `36;40` = light blue foreground (36), black background (40)

                    - OR, `1;<color>` sets foreground to bold:

                        - `1;36` = bold (1) light blue foreground (36)

                - Three numbers:

                    - bold text, foreground, background
                    - `1;36;40` = bold (1), light blue foreground (36), black background (40)

            - Colors

                - text:

                    - 30 - black
                    - 31 - red
                    - 32 - green
                    - 33 - yellow
                    - 34 - blue
                    - 35 - fuchsia
                    - 36 - aquamarine
                    - 37 - white

                - background:

                    - 40 - black
                    - 41 - red
                    - 42 - green
                    - 43 - yellow
                    - 44 - blue
                    - 45 - fuchsia
                    - 46 - aquamarine
                    - 47 - white

- Links:

    - [http://beckism.com/2009/02/better\_bash\_prompt/](http://beckism.com/2009/02/better_bash_prompt/)
    - [https://www.ibm.com/developerworks/linux/library/l-tip-prompt/](https://www.ibm.com/developerworks/linux/library/l-tip-prompt/)

# Scripting

## Arrays

- declare an array:

        my_array=()
        
- length of array:

        array_count=${#my_Array[@]}
        
    Examples:
    
        error_status_array=()
        error_status_array+=( "1" )
        error_status_array+=( "2" )
        error_status_array+=( "3" )
        array_count=${#error_status_array[@]}
        echo "Array Count: ${array_count}" # 3

        error_status_array=()
        error_status_array+=( "" )
        array_count=${#error_status_array[@]}
        echo "Array Count: ${array_count}" # 1

        error_status_array=()
        array_count=${#error_status_array[@]}
        echo "Array Count: ${array_count}" # 0

- check if array is empty:

        error_count=${#errors[@]}
        if [ ${error_count} -eq 0 ]; then
            echo "No errors, hooray"
        else
            echo "Oops, something went wrong..."
        fi
        
    - from: https://serverfault.com/questions/477503/check-if-array-is-empty-in-bash

- loop over items in an array:

        for item in "${arr[@]}"
        do
            echo $item
        done

## Numbers

### Arithmetic

- To do arithmetic, use the "`$(())`" operator.

    - [https://linuxize.com/post/bash-increment-decrement-variable/](https://linuxize.com/post/bash-increment-decrement-variable/)
    -   Example:

            i = $( ( i+1 ) )
            i = $( ( i-1 ) )

## Paths

### check if file or directory exists

- [http://www.cyberciti.biz/faq/unix-linux-test-existence-of-file-in-bash/](http://www.cyberciti.biz/faq/unix-linux-test-existence-of-file-in-bash/)
- [https://www.electrictoolbox.com/test-file-exists-bash-shell/](https://www.electrictoolbox.com/test-file-exists-bash-shell/)

        #!/bin/bash

        file="/etc/hosts"

        if [ -f "$file" ]
        then

                echo "$file found."

        else

                echo "$file not found."

        fi

-   Use "-d" to check if directory exists.
-   To check if does not exist, place an exclamation point before the -f or -d.

### Convert relative path to absolute

- [https://unix.stackexchange.com/questions/24293/converting-relative-path-to-absolute-path\#24297](https://unix.stackexchange.com/questions/24293/converting-relative-path-to-absolute-path#24297)

### Create directory if it does not exist

- [https://stackoverflow.com/questions/4906579/how-to-use-bash-to-create-a-folder-if-it-doesnt-already-exist](https://stackoverflow.com/questions/4906579/how-to-use-bash-to-create-a-folder-if-it-doesnt-already-exist)

## Program control

### If-then-elif-else

- Syntax:

        if <expression>; then

            <commands>

        elif <expression>; then

            <commands>

        else

            <commands>

        Fi

- Notes:

    - [https://www.tutorialkart.com/bash-shell-scripting/bash-else-if/](https://www.tutorialkart.com/bash-shell-scripting/bash-else-if/)

## Strings

### String comparison

- Example using "`[]`" command: 

        #!/bin/bash

        VAR1="Linuxize"  
        VAR2="Linuxize"

        if [ "$VAR1" = "$VAR2" ]; then  
            echo "Strings are equal."  
        else  
            echo "Strings are not equal."  
        Fi

- Example using "`[[]]`" command:

        #!/bin/bash

        read -p "Enter first string: " VAR1  
        read -p "Enter second string: " VAR2

        if [[ "$VAR1" == "$VAR2" ]]; then  
            echo "Strings are equal."  
        else  
            echo "Strings are not equal."  
        fi

- Links:

    - [https://linuxize.com/post/how-to-compare-strings-in-bash/](https://linuxize.com/post/how-to-compare-strings-in-bash/)
    - [https://stackoverflow.com/questions/4277665/how-do-i-compare-two-string-variables-in-an-if-statement-in-bash](https://stackoverflow.com/questions/4277665/how-do-i-compare-two-string-variables-in-an-if-statement-in-bash)
    - [https://linuxize.com/post/how-to-compare-strings-in-bash/](https://linuxize.com/post/how-to-compare-strings-in-bash/)
    - [https://stackoverflow.com/questions/10849297/compare-a-string-using-sh-shell](https://stackoverflow.com/questions/10849297/compare-a-string-using-sh-shell)

#### Empty strings (bash)

- use -z to return true for empty strings.
- Use -n to return true for non-empty strings.
- For more details, see Variables `-->` [Check if set or populated](#Check if set or populated)
- Example:

        # declare variables - debug
        
        if [[ -z "$DEBUG" ]]
        
        then
        
            # debug off by default.
            DEBUG=false
        
        fi

#### Test command (sh or bash)

- Use the "=" operator with the test ( "`[`" ) command for string comparison (-eq is for numbers).
- spaces are important - "`[`" is a command, so the thinsg that follow it are technically command line arguments, and so need to have spaces around them - so around square brackets ( "` [ `" and "` ] `" ), and around equals ( "` = `" ).
- Example:

        Sourcesystem="ABC"

        if [ "$Sourcesystem" = "XYZ" ]; then  
            echo "Sourcesystem Matched"  
        else  
            echo "Sourcesystem is NOT Matched $Sourcesystem"  
        fi;

- Links:

    - [https://stackoverflow.com/questions/10849297/compare-a-string-using-sh-shell](https://stackoverflow.com/questions/10849297/compare-a-string-using-sh-shell)

 
#### Pattern matching in bash

- Use the "`==`" operator with the "`[[`' command for pattern matching.
- Example:

        #!/bin/bash

        read -p "Enter first string: " VAR1  
        read -p "Enter second string: " VAR2

        if [[ "$VAR1" == "$VAR2" ]]; then  
            echo "Strings are equal."  
        else  
            echo "Strings are not equal."  
        fi

- Links:

    - [https://stackoverflow.com/questions/4277665/how-do-i-compare-two-string-variables-in-an-if-statement-in-bash](https://stackoverflow.com/questions/4277665/how-do-i-compare-two-string-variables-in-an-if-statement-in-bash)

### string parsing

        # return reference
        CUSP_ID_NUMBER_OUT=-1

        function parse_CUSP_ID_number()
        {

        

            # example CUSP ID: cusp_12345
            # parse on underscore, take the last token to get ID number.

            # parameters
            local CUSP_ID_IN="$1"

            # declare variables
            local CUSP_ID_TOKEN_ARRAY=
            local CUSP_ID_NUMBER=
            local parse_on="_"

            # parse the number off the end of the CUSP ID.
            IFS=${parse_on} read -ra CUSP_ID_TOKEN_ARRAY <<< "${CUSP_ID_IN}"

            for i in "${CUSP_ID_TOKEN_ARRAY[@]}"; do

                # process "$i"
                CUSP_ID_NUMBER="$i"

            done

            CUSP_ID_NUMBER_OUT="$CUSP_ID_NUMBER"

            # DEBUG
            if [[ $DEBUG = true ]]
            then

                echo "!!!! CUSP ID number = $CUSP_ID_NUMBER_OUT"

            fi

        }

### File paths

- Make an array of all file paths in a folder: `file_array=( <glob> )`

    - Returns absolute paths. Can include multiple directory path globs.
    - More info:

        -   [https://unix.stackexchange.com/questions/49844/how-to-put-the-specific-files-from-a-directory-in-an-array-in-bash](https://unix.stackexchange.com/questions/49844/how-to-put-the-specific-files-from-a-directory-in-an-array-in-bash)
        -   [https://mywiki.wooledge.org/ParsingLs](https://mywiki.wooledge.org/ParsingLs)
        -   [https://stackoverflow.com/questions/9954680/how-to-store-directory-files-listing-into-an-array](https://stackoverflow.com/questions/9954680/how-to-store-directory-files-listing-into-an-array)

## Variables

### Check if set or populated

- Check if a variable is:

    - empty/not set - use "-z" (is variable empty? true = empty/not set, false = not empty/is set):

            if [ -z ${1} ]
            then
                echo "var is unset"
            else
                echo "var is set to '$1'"
            fi

    - populated/set - use "-n" (is variable populated/set? true = set, false = not set):

            if [ -n "${1}" ]
            then
                echo "var is set to '${1}'"
            else
                echo "var is empty"
            fi

- From: [https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash\#13864829](https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash#13864829)

### Use variable value in reference to a separate variable

- Use variable value in reference to a separate variable:

    - `${literal_text_!<var_name>_literal_text}`

### Variable expansion operators - default if variable not set

- `${varname:-word}` which checks if argument passed, if not, return default value.
- `${varname:=word}` which *sets* the undefined varname instead of returning the word value;
- `${varname:?message}` which either returns varname if it's defined and is not null or prints the message and aborts the script (like the first example);
- `${varname:+word}` which returns word only if varname is defined and is not null; returns null otherwise.
- From: [https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script](https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script)
- Notes:

    - Example of use is when you are making bash functions and you want to have optional arguments at the end that you set to a default value when not passed:

            local image_name_IN=${1:=${DOCKER_IMAGE_NAME_IN}}
            local base_folder_path_IN=${2:=${BASE_FOLDER_PATH_IN}}
            local use_cache_IN=${3:-${USE_BUILD_CACHE_IN}}

    - For function parameters like the above example, if parameter might be missing, use "`:-`", not "`:=`".

### wildcards in scripts

- [https://stackoverflow.com/questions/21924351/copying-files-with-wildcard-to-a-folder-in-a-bash-script-why-isnt-it-work\#21924388](https://stackoverflow.com/questions/21924351/copying-files-with-wildcard-to-a-folder-in-a-bash-script-why-isnt-it-work#21924388)
- Short answer - don’t include the wild-carded part in quotes.
- So do this:

    - `cp "${CUSP_HOME}/"*.kdbx "${CRYPTED_DIRECTORY}/"`

- Not this:

    - `cp "${CUSP_HOME}/*.kdbx" "${CRYPTED_DIRECTORY}/"`

## Getopts (with detailed examples)**

- As soon as getopts encounters an unknown parameter or non-parameter, it will exit.  All values passed as normal arguments should be after any options.
- Notes:

    - [https://www.ibm.com/developerworks/library/l-bash-parameters/index.html](https://www.ibm.com/developerworks/library/l-bash-parameters/index.html)
    - [http://www.linuxcommand.org/lc3\_wss0120.php](http://www.linuxcommand.org/lc3_wss0120.php)

### Example

- Example:

        #===============================================================================
        # ==> process options
        #===============================================================================

        # declare variables - option values, for use in scripts that pull this in.
        FILE_SIZE_IN=
        FILE_NUMBER_IN=
        VAULT_FOLDER_IN=
        FILE_PREFIX_IN=
        RANDOM_SOURCE_IN=
        LUKS_VAULT_DEVICE_PREFIX_IN=
        LVM_VAULT_VOLUME_GROUP_IN=
        LVM_VAULT_LOGICAL_VOLUME_IN=
        VAULT_MOUNT_POINT_IN=
        CONFIG_FILE_PATH_IN=
        HELP_FLAG_IN=
        
        # Options: -s <file_size> -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -p <vault_device_prefix> -g <volume_group> -l <logical_volume> -m <data_source> -x
        #
        # WHERE:
        # ==> -s <file_size> = size fo file to create when creating a vault file or extending a vault. Required in those commands, otherwise optional.
        # ==> -n <file_number> = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make). Set to -1 to use next number. Defaults to counting files that match pattern \"<vault_folder>/<file_prefix>\*\", then adding 1.
        # ==> -v <vault_folder> = (optional) path to folder that holds the files that make up the vault. Defaults to $DEFAULT_VAULT_FOLDER.
        # ==> -f <file_prefix> = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is. Defaults to $DEFAULT_VAULT_FILE_PREFIX.
        # ==> -d <data_source> = (optional) source of data to read into new file (don't include parentheses). Defaults to $DEFAULT_RANDOM_SOURCE.
        # ==> -p <vault_device_prefix> = (optional) prefix of the LUKS device name assigned to each vault file after it is decrypted. Defaults to $DEFAULT_LUKS_VAULT_DEVICE_PREFIX.
        # ==> -g <volume_group> = (optional) name of LVM volume group that contains vault physical volumes. Defaults to $DEFAULT_LVM_VAULT_VOLUME_GROUP.
        # ==> -l <logical_volume> = (optional) name of LVM logical volume that is the vault. Defaults to $DEFAULT_LVM_VAULT_LOGICAL_VOLUME.
        # ==> -m <mount_point> = (optional) directory to use as mount point for the vault. Defaults to $DEFAULT_VAULT_MOUNT_POINT.
        # ==> -c <config_file_path> = path to config shell script that will be included. Intent is that you just set the "\*_IN" variables inside. You could do all kinds of nefarious things there. Please don't.
        # ==> -x = OPTIONAL Verbose flag (v was already taken). Defaults to false.

        while getopts ":s:n:v:f:d:p:g:l:m:c:xh" opt; do

            case $opt in
        
                s) FILE_SIZE_IN="$OPTARG"
                ;;
                n) FILE_NUMBER_IN="$OPTARG"
                ;;
                v) VAULT_FOLDER_IN="$OPTARG"
                ;;
                f) FILE_PREFIX_IN="$OPTARG"
                ;;
                d) RANDOM_SOURCE_IN="$OPTARG"
                ;;
                p) LUKS_VAULT_DEVICE_PREFIX_IN="$OPTARG"
                ;;
                g) LVM_VAULT_VOLUME_GROUP_IN="$OPTARG"
                ;;
                l) LVM_VAULT_LOGICAL_VOLUME_IN="$OPTARG"
                ;;
                m) VAULT_MOUNT_POINT_IN="$OPTARG"
                ;;
                c) CONFIG_FILE_PATH_IN="$OPTARG"
                ;;
                x) DEBUG=true
                ;;
                h) HELP_FLAG_IN=true
                ;;
                \?) echo "Invalid option -$OPTARG" >&2
                ;;
            
            esac
        
        done
        
        # ==> External configuration file
        
        if [[ $HELP_FLAG_IN = true ]]
        then
            add_error "Usage help displayed, no action taken."
        fi
        
        if [[ $DEBUG = true ]]
        then
            echo "Config file path = \"${CONFIG_FILE_PATH_IN}\""
        fi
        
        # do we have a config path?
        if [[ ! -z "${CONFIG_FILE_PATH_IN}" ]]
        then
        
            # check to see if we are allowing config
            if [[ $ALLOW_CONFIG = true ]]
            then
            
                # we do. Does file at that path exist?
                if [[ -f "${CONFIG_FILE_PATH_IN}" ]]
                then

                    # it does. source it.
                    echo "Loading configuration from ${CONFIG_FILE_PATH_IN}"
                    source "${CONFIG_FILE_PATH_IN}"
            
                else
            
                    # it does not. Error out.
                    add_error "!!!! ERROR - configuration file at path \"${CONFIG_FILE_PATH_IN}\" does not exist."
            
                fi
            
            else
            
                # configuration not allowed. Error out.
                add_error "!!!! ERROR - configuration file specified ( ${CONFIG_FILE_PATH_IN} ), but using a configuration file is not allowed."
            
            fi
            
        else
            
            if [[ $DEBUG = true ]]
            then
            
                echo "No defaults file specified."
            
            fi
        
        fi

        # ==> Defaults:
        
        # file number
        if [[ -z "$FILE_NUMBER_IN" ]]
        then
        
            # no error - derive by counting files that match "$VAULT_FOLDER_IN/$FILE_PREFIX_IN\*"
            FILE_NUMBER_IN=-1
        
        fi
        
        # vault folder
        if [[ -z "$VAULT_FOLDER_IN" ]]
        then

            VAULT_FOLDER_IN="$DEFAULT_VAULT_FOLDER"
            echo ">>>> using default vault folder ( \"$VAULT_FOLDER_IN\" )."
        
        fi
        
        # vault file prefix
        if [[ -z "$FILE_PREFIX_IN" ]]
        then
        
            FILE_PREFIX_IN="$DEFAULT_VAULT_FILE_PREFIX"
            echo ">>>> using default vault file prefix ( \"$FILE_PREFIX_IN\" )."
        
        fi
        
        # random source
        if [[ -z "$RANDOM_SOURCE_IN" ]]
        then
        
            RANDOM_SOURCE_IN="$DEFAULT_RANDOM_SOURCE"
            echo ">>>> using default data source ( \"$DEFAULT_RANDOM_SOURCE\" )."
        
        fi
        
        # LUKS vault device prefix
        if [[ -z "$LUKS_VAULT_DEVICE_PREFIX_IN" ]]
        then
        
            LUKS_VAULT_DEVICE_PREFIX_IN="$DEFAULT_LUKS_VAULT_DEVICE_PREFIX"
            echo ">>>> using default LUKS vault file prefix ( \"$DEFAULT_LUKS_VAULT_DEVICE_PREFIX\" )."
        
        fi
        
        # vault LVM volume group
        if [[ -z "$LVM_VAULT_VOLUME_GROUP_IN" ]]
        then
        
            LVM_VAULT_VOLUME_GROUP_IN="$DEFAULT_LVM_VAULT_VOLUME_GROUP"
            echo ">>>> using default vault LVM volume group ( \"$DEFAULT_LVM_VAULT_VOLUME_GROUP\" )."
        
        fi
        
        # vault LVM logical volume
        if [[ -z "$LVM_VAULT_LOGICAL_VOLUME_IN" ]]
        then
        
            LVM_VAULT_LOGICAL_VOLUME_IN="$DEFAULT_LVM_VAULT_LOGICAL_VOLUME"
            echo ">>>> using default vault LVM logical volume ( \"$DEFAULT_LVM_VAULT_LOGICAL_VOLUME\" )."
        
        fi
        
        # vault mount point
        if [[ -z "$VAULT_MOUNT_POINT_IN" ]]
        then
        
            VAULT_MOUNT_POINT_IN="$DEFAULT_VAULT_MOUNT_POINT"
            echo ">>>> using default vault mount point ( \"$DEFAULT_VAULT_MOUNT_POINT\" )."
        
        fi
        
        echo ""

### Example within a bash function

- Example within a bash function:

        #run:
        # docker run -v \`pwd\`/project:/project -v \`pwd\`/data:/data --name my_rcc_run my_rcc /project/code.sh
        #evaluate:
        # docker run -v \`pwd\`/project:/project -v \`pwd\`/data:/data --name my_rcc_run my_rcc /data/evaluate/evaluate.sh
        #run-interactive:
        # docker run -it -v \`pwd\`/project:/project -v \`pwd\`/data:/data --name my_rcc_run my_rcc

        function run()
        {
        
            #===============================================================================
            # ==> process options
            #===============================================================================

            # declare variables - option values, for use in scripts that pull this in.
            local project_folder_path_IN= #${1:=${PROJECT_FOLDER_PATH_IN}}
            local data_folder_path_IN= #${2:=${DATA_FOLDER_PATH_IN}}
            local input_folder_path_IN=
            local output_folder_path_IN=
            local image_name_IN= #${3:=${DOCKER_IMAGE_NAME_IN}}
            local container_name_IN= #${4:=${DOCKER_CONTAINER_NAME_IN}}
            local script_to_run_IN= #${5:-}
            local docker_custom_options_IN= #${6:=${DOCKER_CUSTOM_RUN_OPTIONS_IN}}
            local interactive_flag_IN=false
            
            # Options: -p <project_folder_path> -d <data_folder_path> -i <input_folder_path> -o <output_folder_path> -m <image_name> -c <container_name> -s <script_to_run> -t <docker_custom_options> -x
            #
            # WHERE:
            # ==> -p <project_folder_path> = Path to project folder where all model code and data lives.
            # ==> -d <data_folder_path> = (optional) Path to data folder if there is a single monolithic data folder that contains both "input" and "output" folders. Mounted internally to "/data".
            # ==> -i <input_folder_path> = (optional) Path to folder outside of docker container where input files live. Mounted internally to "/data/input".
            # ==> -o <output_folder_path> = (optional) Path to folder outside of docker container where output should be placed. Mounted internally to "/data/output".
            # ==> -m <image_name> = Name of docker image to run.
            # ==> -c <container_name> = Name to give to docker container.
            # ==> -s <script_to_run> = (optional) script to run inside the docker container after it is started.
            # ==> -t <docker_custom_options> = (optional) custom docker options to add to the end of the run command when you run the container (and "t" = first letter in "options" not taken by another option).
            # ==> -x = (optional) boolean interactive mode flag. If present, runs in interactive mode.
            
            local OPTIND
            local OPTARG
            local option
            while getopts ":p:d:i:o:m:c:s:t:x" option
            do
            
                case $option in
                
                    p) project_folder_path_IN="$OPTARG"
                    ;;
                    d) data_folder_path_IN="$OPTARG"
                    ;;
                    i) input_folder_path_IN="$OPTARG"
                    ;;
                    o) output_folder_path_IN="$OPTARG"
                    ;;
                    m) image_name_IN="$OPTARG"
                    ;;
                    c) container_name_IN="$OPTARG"
                    ;;
                    s) script_to_run_IN="$OPTARG"
                    ;;
                    t) docker_custom_options_IN="$OPTARG"
                    ;;
                    x) interactive_flag_IN=true
                    ;;
                    \?) echo "Invalid option -$OPTARG" >&2
                    ;;
                
                esac
            
            done
            
            # declare variables
            local project_folder_path=
            local input_folder_path=
            local output_folder_path=
            local interactive_flag=
            
            # set input and output folder paths.
            
            # do we have a data folder path?
            if [[ ! -z "${data_folder_path_IN}" ]]
            then
            
                # yes. Use it to set input and output folder.
                input_folder_path="${data_folder_path_IN}/input"
                output_folder_path="${data_folder_path_IN}/output"
            
            else
            
                # do we have input and output folder paths?
                if [[ ! -z "${input_folder_path_IN}" ]] && [[ ! -z "${output_folder_path_IN}" ]]
                then
            
                    # we do have input and output folders.
                    input_folder_path="${input_folder_path_IN}"
                    output_folder_path="${output_folder_path_IN}"
            
                else
            
                    add_error "Incomplete input and output file paths: data=${data_folder_path_IN}; input=${input_folder_path_IN}; output=${output_folder_path_IN};"
            
                fi
            
            fi
            
            # set interactive_flag
            if [[ $interactive_flag_IN = true ]]
            then
            
                interactive_flag="-it"
            
            fi
            
            # OK to process?
            if [[ $ok_to_process = true ]]
            then
            
                # convert to absolute paths.

                # project folder path
                absolute_path "${project_folder_path_IN}"
                project_folder_path="${absolute_path_OUT}"
            
                # input folder path
                absolute_path "${input_folder_path}"
                input_folder_path="${absolute_path_OUT}"
            
                # output folder path
                absolute_path "${output_folder_path}"
                output_folder_path="${absolute_path_OUT}"
                
                # DEBUG
                if [[ $DEBUG = true ]]
                then
                
                    echo "In run:"
                    echo "- project_folder_path_IN: \"${project_folder_path_IN}\""
                    echo "- project_folder_path: \"${project_folder_path}\""
                    echo "- data_folder_path_IN: \"${data_folder_path_IN}\""
                    echo "- input_folder_path: \"${input_folder_path}\""
                    echo "- output_folder_path: \"${output_folder_path}\""
                    echo "- image_name_IN: \"${image_name_IN}\""
                    echo "- container_name_IN: \"${container_name_IN}\""
                    echo "- interactive_flag: \"${interactive_flag}\""

                fi
                
                # remove JSON files from output.
                docker run ${docker_custom_options_IN} ${interactive_flag} -v \`pwd\`:/run_folder -v ${project_folder_path}:/project -v ${input_folder_path}:/data/input -v ${output_folder_path}:/data/output --name ${container_name_IN} ${image_name_IN} ${script_to_run_IN}
                
            else
                
                echo "ERROR - docker container did not run."
                output_errors
                
            fi
        
        } #-- END function run() --#
