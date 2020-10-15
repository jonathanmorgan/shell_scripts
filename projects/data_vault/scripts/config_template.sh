#!/bin/bash
    
# The config file can include:
# - `FILE_SIZE_IN` (`-s` option) - size of file to make when creating a new vault file or expanding the vault.
# - `VAULT_FOLDER_IN` (`-v` option) - the folder where vault files are stored
# - `FILE_PREFIX_IN` (`-f` option) - the prefix used when creating vault files
# - `RANDOM_SOURCE_IN` (`-d` option) - the source of data that is used to fill in new files (usually one of `/dev/urandom`, `/dev/random`, or `/dev/zero`).
# - `LUKS_VAULT_DEVICE_PREFIX_IN` (`-p` option) - prefix of the LUKS device name assigned to each vault file after it is decrypted.
# - `LVM_VAULT_VOLUME_GROUP_IN` (`-g` option) - name of LVM volume group that contains vault physical volumes.
# - `LVM_VAULT_LOGICAL_VOLUME_IN` (`-l` option) - name of LVM logical volume that is the vault.
# - `VAULT_MOUNT_POINT_IN` (`-m` option) - directory to use as mount point for the vault.
# - `DEBUG` (`-x` option) - set to "`true`" or "`false`".  If set to "`true`", results in much more verbose output.
#
# NOTE: When using configuration files, make sure to set variable "ALLOW_CONFIG" to "true" in scripts/vault_shared.sh.

# set configuration variables
#FILE_SIZE_IN=
#VAULT_FOLDER_IN=
#FILE_PREFIX_IN=
#RANDOM_SOURCE_IN=
#LUKS_VAULT_DEVICE_PREFIX_IN=
#LVM_VAULT_VOLUME_GROUP_IN=
#LVM_VAULT_LOGICAL_VOLUME_IN=
#VAULT_MOUNT_POINT_IN=
#DEBUG=
