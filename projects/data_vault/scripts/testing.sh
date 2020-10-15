#!/bin/bash

# import vault_shared.sh
source ./vault_shared.sh

# test get_vault_file_count()
get_vault_file_count "$VAULT_FOLDER_IN" "$FILE_PREFIX_IN"
echo "file count = ${VAULT_FILE_COUNT_OUT}"

# test get_next_vault_file_number()
get_next_vault_file_number "$VAULT_FOLDER_IN" "$FILE_PREFIX_IN"
echo "next vault file number = ${NEXT_VAULT_FILE_NUMBER_OUT}"
