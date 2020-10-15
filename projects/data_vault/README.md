# Data facility vault file scripts

The scripts in this repository can be used to create, mount, unmount, and increase the size of encrypted data vault partitions.  A vault is an LVM logical volume, formatted in ext4, associated with a volume group made up of one or more encrypted data containers mounted as loop devices.  It can be decrypted and mounted to allow access to the data within, then unmounted and removed when it is not needed.

Contents:

- `README.md` - this file, contains overview of project and usage documentation.
- `scripts` - folder that contains the scripts that one can use to manage a data vault.

    - `scripts/vault_shared.sh` - contains re-usable bash shell functions and shell variables defined to hold default and standard values.  Included by all the other scripts.
    - `scripts/create_vault_file.sh` - create the individual encrypted files that are combined by LVM into the logical volume that is the vault.
    - `scripts/create_vault.sh` - tie vault files together into a vault.
    - `scripts/activate_vault.sh` - decrypt and prepare the vault for use.
    - `scripts/mount_vault.sh` - mount the vault on the file system.
    - `scripts/unmount_vault.sh` - unmount the vault from the file system.
    - `scripts/deactivate_vault.sh` - deactivate the vault, then decrypt and deactivate the indivdual files that make up the vault.
    - `scripts/extend_vault.sh` - starting with an activated vault, create new vault file with added space, then expand the vault to use the additional space.
    - `scripts/is_vault_active.sh` - checks based on volume group and logical volume passed in whether a vault with the desired group and volume is active.
    - `scripts/cleanup.sh` - deletes all traces of vault with current configuration.
    - `scripts/config_template.sh` - template for script that can be edited to hold configuration so you can reference it in commands rather than having to set all the options each time you run a command.

- `scripts/datasets` - folder that contains the scripts that one can use to manage data sets.

    - `scripts/datasets/dataset_to_vault.bash` - copies files for a data set into vault, setting up appropriate directory structure and links.
    - `scripts/datasets/mount_dataset.bash` - copies data set from vault to a given project.
    
# Quick start:

## Quick start - Vault

Assuming you use a configuration script to store your configuration:

- `cd` into the scripts directory on your server.

- to get help/usage information on any script, execute it with the "`-h`" option:

        # get help on activating a vault:
        ./activate_vault.sh -h

- to provide access to the vault:

        # activate vault (including entering the vault password):
        sudo ./activate_vault.sh -c <config_file_path>
        
        # mount the vault:
        sudo ./mount_vault.sh -c <config_file_path>
        
- to remove access to the vault:

        # deactivate the vault:
        sudo ./deactivate_vault.sh -c <config_file_path>

## Quick start - Data sets

- make sure the vault is mounted.
- cd into the datasets folder:

        cd /gcdf/vault_scripts/data_vault/scripts/datasets

- Move to vault:

        # use dataset_to_vault.bash:
        ./dataset_to_vault.bash -i cusp-10381 -p betagov -s /ycdf/ycuration/arangofranco_transfer/to_vault/cusp-10381 -x

    - WHERE:
        - -i is followed by the cusp id, including “cusp-“.
        - -p is followed by the provider name.
        - -s is followed by the absolute path to the folder that contains the files.
        - -x indicates verbose output.

- Copy dataset to project:

        # use mount_dataset.bash
        ./mount_dataset.bash -i cusp-10381 -p yproject-capstone_data_justice_2017 -c yellow -x

    - WHERE:
        - -i is followed by the CUSP ID, including “cusp-“
        - -p is followed by the project name.
        - -c is followed by the project type (“green” or “yellow”).
        - -x indicates verbose output.

# Installation

## Setup:

- Make sure you’ve created the loop\* devices on your OS: `mknod /dev/loop* b 7 *`

     - Example for loop0: `mknod /dev/loop0 b 7 0`
     - Example for loop1: `mknod /dev/loop1 b 7 1`
     
- You must install the "expect" extension to tcl on your system before running this script (`yum install expect`, `apt install expect`, etc.).  This will also install tcl.
- You must be able to run the scripts as root.
- If you use the default directories, you'll need to create the following:

    - `/vault`
    - `/data/warehouse`


# Vault Management

All vault management scripts must be run as root.

## Create a vault

The process for creating a vault:

- choose a password for your vault.  The vault has 256-bit encryption keys (perhaps excessive, but still, shouldn't slow down your drive), but they are embedded in the individual files and protected by your vault password.  A weak vault password means it is easy to get at the keys and decrypt your files.  So you should have a good long password (see [https://blog.agilebits.com/2011/06/21/toward-better-master-passwords/](https://blog.agilebits.com/2011/06/21/toward-better-master-passwords/), for example).
- create one or more container files, files that are mounted as loop devices and then encrypted using cryptsetup/dm-crypt.  These are the encrypted underpinnings of the vault.  They default to being stored in a directory named `/vault`, and to being named `encrypted_vault_<number>` where `<number>` is an integer that reflects the count of vault files after a given file was added to the vault.
- add your decrypted loop devices as physical volumes to LVM.
- combine them into a volume group (named "`data_vault_vg`" by default).
- create a logical volume that uses 100% of the free space in the volume group (named "`data_vault_lv`" by default).
- format that logical volume with the ext4 file system.
- mount it on your file system (mounts to "`/data/warehouse`" by default) and test.

In practice, there are two scripts that implement this process:

- "`create_vault_file.sh`"

    - For each file, run the script "`create_vault_file.sh`", passing it at least the size of the file.  If you don't specify a directory or a file prefix, this command will default to those defined in "`vault_shared.sh`" (`DEFAULT_VAULT_FOLDER="/vault"` and `DEFAULT_VAULT_FILE_PREFIX="encrypted_vault"`).  If you don't specify a file number, it will count files that fit your directory and prefix and use a number 1 greater than that count.   Examples using all the defaults:

            # first file, 200 MB in size:
            sudo ./create_vault_file.sh -s 200M
            
            # second file, 2 GB in size:
            sudo ./create_vault_file.sh -s 2G
            
            # third file, 2 TB in size:
            sudo ./create_vault_file.sh -s 2T
            
        You can also override the location where the files are stored and the file name prefix (it always requires an underscore then a number at the end at this point). Example in `/data/vault_home` (option "-v"), with file prefix of `warehouse_file` (option "-f"):
        
            # first file, 200 MB in size:
            sudo ./create_vault_file.sh -s 200M -v "/data/vault_home" -f "warehouse_file"
            
            # second file, 2 GB in size:
            sudo ./create_vault_file.sh -s 2G -v "/data/vault_home" -f "warehouse_file"
            
            # third file, 2 TB in size:
            sudo ./create_vault_file.sh -s 2T -v "/data/vault_home" -f "warehouse_file"

- "`create_vault.sh`"

    - Once you have created all of your vault files, then you can use "`create_vault.sh`" to tie them together into a vault file.  By default, this script uses the same default file location and file prefix as "`create_vault_file.sh`", stored in "`vault_shared.sh`", and can be run with no arguments:
    
            # tie vault files together into a vault partition:
            sudo ./create_vault.sh
            
            # use our custom directory and file name:
            sudo ./create_vault.sh -v "/data/vault_home" -f "warehouse_file"
            
            # ...and assign a custom LUKS device prefix, LVM volume group and
            #     logical volume (perhaps you want two vaults):
            sudo ./create_vault.sh -v "/data/vault_home" -f "warehouse_file" -p "vault_2_file" -g "vault_2_vg" -l "vault_2_lv"
            
- Once you run "`create_vault.sh`", in LVM there will be a volume group named "`data_vault_vg`" that contains a logical volume named "`data_vault_lv`", and the logical volume will contain an ext4-formatted file system.  These names are also pulled from "`vault_shared.sh`", and so can be changed if you choose.
- If you want to create multiple vaults on a machine, you'll need to override:
    - the vault file directory (-v)
    - the vault file prefix (-f)
    - the LUKS device prefix (-p) - to avoid collisions with existing physical volumes.
    - the LVM volume group (-g)
    - the LVM logical volume (-l)
- Now, you'll want to mount the resulting partition.  The default mount point is "`/data/warehouse`".  Like the rest of the default values, this value is stored in "`vault_shared.sh`" and can be overridden (if enough people override, we'l build in the ability to specify an override script where the overrides can live, so we can keep them separate from "`vault_shared.sh`").  In preparation for mounting your vault, create the directory "`/data/warehouse`".  Then, use the command "`mount -t ext4 /dev/data_vault_vg/data_vault_lv /data/warehouse`" to mount your volume.
- At this point, you should be able to interact with "`/data/warehouse`" as you would any other directory on your system.  Make a test folder there, then place a file inside, just so you can verify that mounting and unmounting are working.
- Finally, you'll want to either mount or deactivate the vault.  At this point, your vault is "activated", but not mounted.  If you want to mount the vault:

        sudo ./mount_vault.sh
        
    If you want to deactivate it:
    
        sudo ./deactivate_vault.sh

## Mount a vault

Process for mounting a vault:

- each of the individual vault files is:

    - added to the system as a loop device, so it can be interacted with like you would a standard disk partition.
    - then, each of these loop devices is decrypted and added to LVM, using the name "`vault_file_<number>`" (the same name used when the vault was created).

- the volume group that contains the physical volumes is re-enabled (it is disabled when the vault is unmounted).
- the logical volume for the vault is mounted on the file system at "`/data/warehouse`" so it can be accessed.

The "`activate_vault.sh`" script implements the above steps up to actually mounting the logical volume.  The "`mount_vault.sh`" script actually mounts the vault:

    # mount vault using defaults
    sudo ./activate_vault.sh
    sudo ./mount_vault.sh
    
    # if you changed directory and file name:
    sudo ./activate_vault.sh -v "/data/vault_home" -f "warehouse_file"
    sudo ./mount_vault.sh
    
    # ...and if you assign a custom LVM volume group and logical volume:
    sudo ./activate_vault.sh -v "/data/vault_home" -f "warehouse_file" -g "vault_2_vg" -l "vault_2_lv"
    sudo ./mount_vault.sh -g "vault_2_vg" -l "vault_2_lv"

## Unmount a vault

Process for unmounting a vault:

- unmount the vault's logical volume from "`/data/warehouse`".
- deactivate the volume group that contains the logical volume.
- then, for each of the individual vault files:

    - closes off the encrypted area of the file.
    - detaches the file from the loop device on which it was mounted.
    
The "`unmount_vault.sh`" script unmounts the vault's logical volume from its mount point.  The "`deactivate_vault.sh`" script implements the rest of the steps (and also tries to unmount at the beginning, so can be used by itself to unmount and deactivate, but don't do this):

    # unmount vault using defaults
    sudo ./unmount_vault.sh
    sudo ./deactivate_vault.sh
    
    # if you changed directory and file name:
    sudo ./unmount_vault.sh
    sudo ./deactivate_vault.sh -v "/data/vault_home" -f "warehouse_file"
    
    # ...and if you assign a custom LVM volume group and logical volume:
    sudo ./unmount_vault.sh -g "vault_2_vg" -l "vault_2_lv"
    sudo ./deactivate_vault.sh -v "/data/vault_home" -f "warehouse_file" -g "vault_2_vg" -l "vault_2_lv"

## Adding storage to a vault

Process for adding storage to a vault:

- create a new vault file that contains the space you want to add to your vault.
- attach it to a loop device and decrypt it.
- add it as a physical volume
- add the new physical volume to your vault's volume group.
- update the logical volume so it includes the space added by the new physical volume.
- extend the file system so that it adds the new additional storage space.

The scripts "`create_vault_file.sh`" and "`extend_vault.sh`" implement these steps, defaulting to using the defaults in "`vault_shared.sh`".

First, create a new vault file by running the script "`create_vault_file.sh`", passing it at least the size of the file.  This step can be done while the vault is in use.  If you don't specify a directory or a file prefix, this command will default to those defined in "`vault_shared.sh`" (`DEFAULT_VAULT_FOLDER="/vault"` and `DEFAULT_VAULT_FILE_PREFIX="encrypted_vault"`).  If you don't specify a file number, it will count files that fit your directory and prefix and use a number 1 greater than that count.   Examples:

    # new file 200 MB in size:
    sudo ./create_vault_file.sh -s 200M
    
    # if you changed directory and file name:
    sudo ./create_vault_file.sh -s 200M -v "/data/vault_home" -f "warehouse_file"

    # ...and LUKS device prefix, LVM volume group, and logical volume:
    sudo ./create_vault_file.sh -s 200M -v "/data/vault_home" -f "warehouse_file" -p "vault_2_file" -g "vault_2_vg" -l "vault_2_lv"

Second, use "`extend_vault.sh`" to add the new storage to your vault.  "`extend_vault.sh`" accepts the number of the vault file you created with "`create_vault_file.sh`":

_IMPORTANT NOTE: This script assumes the vault is activated when it starts.  If the vault is not activated, the script will fail and leave a mess.  Please make sure the vault is activated but not mounted before expanding the vault._

    # extend vault by 200 MB using defaults:
    sudo ./extend_vault.sh -n 3
    
    # if you changed directory and file name:
    sudo ./extend_vault.sh -n 3 -v "/data/vault_home" -f "warehouse_file"
    
    # ...and LUKS device prefix, LVM volume group, and logical volume:
    sudo ./extend_vault.sh -n 3 -v "/data/vault_home" -f "warehouse_file" -p "vault_2_file" -g "vault_2_vg" -l "vault_2_lv"
    
_NOTE:_

- While you are creating a new file, there will be more files present than are included in your actual vault.  To activate or deactivate the vault while you are creating a new data file, use the -n option to tell the scripts the number of file to stop at.  So, if you are creating a 4th vault file, to just activate 3 files:

        sudo ./activate_vault.sh -n 3
        
    and to deactivate just 3 (though deactivation will successfully complete if you forget, where activate will create a mess):
    
        sudo ./deactivate_vault.sh -n 3

# Standard options

The vault management scripts have a standard set of optional options that can be set to customize the way a given vault is stored and mounted.  These options are added after a given shell script, like this:

    -s <file_size> -n <file_number> -v <vault_folder> -f <file_prefix> -d <data_source> -p <vault_device_prefix> -g <volume_group> -l <logical_volume> -m <data_source> -c <config_file_path> -x

WHERE:

- `-s <file_size>` = size of file to create when creating a vault file or extending a vault.  Required in those commands, otherwise optional.
- `-n <file_number>` = (optional) number of the vault file you are creating (start them at 1, increase by one for each additional file you make).  Set to -1 to use next number.  Defaults to counting files that match pattern "`<vault_folder>/<file_prefix>*`", then adding 1.
- `-v <vault_folder>` = (optional) path to folder that holds the files that make up the vault.  Defaults to `$DEFAULT_VAULT_FOLDER`.
- `-f <file_prefix>` = (optional) prefix that each vault fragment starts with, followed by a number to indicate which fragment it is.  Defaults to `$DEFAULT_VAULT_FILE_PREFIX`.
- `-d <data_source>` = (optional) source of data to read into new file (don't include parentheses).  Defaults to `$DEFAULT_RANDOM_SOURCE`.
- `-p <vault_device_prefix>` = (optional) prefix of the LUKS device name assigned to each vault file after it is decrypted.  Defaults to `$DEFAULT_LUKS_VAULT_DEVICE_PREFIX`.
- `-g <volume_group>` = (optional) name of LVM volume group that contains vault physical volumes.  Defaults to `$DEFAULT_LVM_VAULT_VOLUME_GROUP`.
- `-l <logical_volume>` = (optional) name of LVM logical volume that is the vault.  Defaults to `$DEFAULT_LVM_VAULT_LOGICAL_VOLUME`.
- `-m <mount_point>` = (optional) directory to use as mount point for the vault.  Defaults to `$DEFAULT_VAULT_MOUNT_POINT`.
- `-c <config_file_path>` = (optional) path to config shell script that will be included.  Intent is that you just set the "*_IN" variables inside.  You could do all kinds of nefarious things there.  Please don't.
- `-x` = (optional) Verbose flag (v was already taken).  Defaults to false.
- `-h` = (optional) Help flag - If set, does nothing, just outputs the usage help for the command.

Any of these options can be set for any script, but a given script will likely only make use of a subset of these options.

## Options by script:

### `create_vault_file.sh`

Supported options:

- `-s <file_size>`
- `-n <file_number>`
- `-v <vault_folder>`
- `-f <file_prefix>`
- `-d <data_source>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `create_vault.sh`

Supported options:

- `-v <vault_folder>`
- `-f <file_prefix>`
- `-g <volume_group>`
- `-l <logical_volume>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `activate_vault.sh`

Supported options:

- `-n <file_number>`
- `-v <vault_folder>`
- `-f <file_prefix>`
- `-g <volume_group>`
- `-l <logical_volume>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `mount_vault.sh`

Supported options:

- `-g <volume_group>`
- `-l <logical_volume>`
- `-m <mount_point>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `unmount_vault.sh`

Supported options:

- `-g <volume_group>`
- `-l <logical_volume>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `deactivate_vault.sh`

Supported options:

- `-n <file_number>`
- `-v <vault_folder>`
- `-f <file_prefix>`
- `-g <volume_group>`
- `-l <logical_volume>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `extend_vault.sh`

Supported options:

- `-n <file_number>`
- `-v <vault_folder>`
- `-f <file_prefix>`
- `-d <data_source>`
- `-p <vault_device_prefix>`
- `-g <volume_group>`
- `-l <logical_volume>`
- `-c <config_file_path>`
- `-x`
- `-h`

### `is_vault_active.sh`

Supported options:

- `-g <volume_group>`
- `-l <logical_volume>`
- `-c <config_file_path>`
- `-x`
- `-h`

# Using a configuration file

Rather than pass command line options to each command, you can also specify a set of options in a shell script, then just load those option values each time you run a command using the "`-c`" option:

- `-c <config_file_path>` = (optional) path to config shell script that will be included.  Intent is that you just set the "*_IN" variables inside.  You could do all kinds of nefarious things there.  Please don't.

Loading options from a configuration file is disabled by default.  In order to allow it, you must first edit vault_shared.sh and set the "`ALLOW_CONFIG`" variable to "`true`".

Then, you can make a copy of the file `data_vault/scripts/config_template.sh`, rename it to describe the vault whose configuration it holds, then set the variables inside as you like and store it somewhere on your file system (I usually store it in the folder where I place the encrypted vault files, with permissions 700).

Once you have created your configuration file, when you run each command, rather than setting individual options, use the "`-c`" option to tell it what configuration file to load.  For example, if you are creating a vault file:

    sudo ./create_vault_file.sh -c "/vault/files/vault_config.sh"
    
## Setting options in a configuration file

The template configuration file ("`data_vault/scripts/config_template.sh`") looks like the following:

    #!/bin/bash
    
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
    
For each value you want to set, uncomment the line with that value, then place a value to the right of the equal sign, with no spaces between the equal sign and the value, and in quotation marks.

For example, if you have multiple vaults on a machine, here is a configuration file that modifies the defaults so the second vault doesn't conflict with the first vault:

    #!/bin/bash
    
    # set configuration variables
    FILE_SIZE_IN="200M"
    VAULT_FOLDER_IN="/vault/files"
    FILE_PREFIX_IN="warehouse_file"
    #RANDOM_SOURCE_IN=
    LUKS_VAULT_DEVICE_PREFIX_IN="vault_2_file"
    LVM_VAULT_VOLUME_GROUP_IN="vault_2_vg"
    LVM_VAULT_LOGICAL_VOLUME_IN="vault_2_lv"
    VAULT_MOUNT_POINT_IN="/data/warehouse2"
    #DEBUG=

The config file can include:

- `FILE_SIZE_IN` (`-s` option) - size of file to make when creating a new vault file or expanding the vault.
- `VAULT_FOLDER_IN` (`-v` option) - the folder where vault files are stored
- `FILE_PREFIX_IN` (`-f` option) - the prefix used when creating vault files
- `RANDOM_SOURCE_IN` (`-d` option) - the source of data that is used to fill in new files (usually one of `/dev/urandom`, `/dev/random`, or `/dev/zero`).
- `LUKS_VAULT_DEVICE_PREFIX_IN` (`-p` option) - prefix of the LUKS device name assigned to each vault file after it is decrypted.
- `LVM_VAULT_VOLUME_GROUP_IN` (`-g` option) - name of LVM volume group that contains vault physical volumes.
- `LVM_VAULT_LOGICAL_VOLUME_IN` (`-l` option) - name of LVM logical volume that is the vault.
- `VAULT_MOUNT_POINT_IN` (`-m` option) - directory to use as mount point for the vault.
- `DEBUG` (`-x` option) - set to "`true`" or "`false`".  If set to "`true`", results in much more verbose output.

_NOTE:_

- You can set values on the command line that are not set in the configuration file.
- Values set in configuration file override values set on command line.
- _IMPORTANT - since the configuration script is `source`ed and these scripts are run as root, you should lock this file down so only root can write to it, and you shouldn't put anything in this file other than setting variables.  There is serious potential for shenanigans if you don't lock down vault configuration files._

# Troubleshooting

Examples below assume:

- vault file folder: `/vault`
- encrypted vault file prefix: `encrypted_vault_` (example: "`encrypted_vault_1`", "`encrypted_vault_2`", etc.)
- Loop device prefix: `/dev/loop` (example: "`/dev/loop0`", "`/dev/loop1`", etc.)
- LUKS vault file prefix: `vault_file_` (example: "`vault_file_1`", "`vault_file_2`", etc.)
- LVM vault volume group: `data_vault_vg`
- LVM vault logical volume: `data_vault_lv`
- vault mount point is: `/data/warehouse`

## creating a vault file manually

- first, use `dd` to create a file of the size you want to add to your vault that contains random data.

        # create 200 MB random files, 1 KB blocks, 200 MB = 204,800 1 KB blocks
        sudo dd if=/dev/urandom of=/vault/encrypted_vault_1 bs=1024 count=204800
        sudo dd if=/dev/urandom of=/vault/encrypted_vault_2 bs=1024 count=204800
        ...
        
        # etc.
        
- use `losetup` to setup each of the files that make up the vault as loop devices.

        # check to see what the next open loop device is
        losetup -f
        
        # example output when no loop devices are in use:
        # /dev/loop0
        
        # associate each of your vault files with a loop device.
        sudo losetup /dev/loop0 /vault/encrypted_vault_1
        sudo losetup /dev/loop1 /vault/encrypted_vault_2
        ...
        
        # etc.
        
- Use `cryptsetup` to encrypt each of the files via its loop device.  Make sure to choose a strong pass phrase.  If you are going to be using the above scripts to manage, use the same pass phrase for each file.

        # use cryptsetup to create encryption infrastructure and encrypt file.
        sudo cryptsetup -v --cipher aes-xts-plain --key-size 512 --hash sha512 --use-random luksFormat /dev/loop0
        sudo cryptsetup -v --cipher aes-xts-plain --key-size 512 --hash sha512 --use-random luksFormat /dev/loop1
        ...
        
        # etc.
        
- Use `cryptsetup` to test decrypting each file.

        # test - decrypt and open the file.
        
        # file 1 (/dev/loop0)
        sudo cryptsetup luksOpen /dev/loop0 temp_vault_file
        sudo cryptsetup luksClose temp_vault_file
        
        # file 2 (/dev/loop1)
        sudo cryptsetup luksOpen /dev/loop1 temp_vault_file
        sudo cryptsetup luksClose temp_vault_file
        
        # etc.
        
- Use `losetup` to detach files from loop devices.

        sudo losetup -d /dev/loop0
        sudo losetup -d /dev/loop1
        
        # etc.
        
- At this point, you are ready to use LVM to create a vault!

## creating a vault manually

- use `losetup` to setup each of the files that make up the vault as loop devices.

        # check to see what the next open loop device is
        losetup -f
        
        # example output when no loop devices are in use:
        # /dev/loop0
        
        # associate each of your vault files with a loop device.
        sudo losetup /dev/loop0 /vault/encrypted_vault_1
        sudo losetup /dev/loop1 /vault/encrypted_vault_2
        ...
        
        # etc.
        
- use `cryptsetup` and LUKS to decrypt each file then add decrypted volume as device, entering the pass phrase for each.

        # use "luksOpen", rather than "open -t luks" for CentOS 6 compatibility.
        sudo cryptsetup luksOpen /dev/loop0 vault_file_1
        sudo cryptsetup luksOpen /dev/loop1 vault_file_2
        ...
        
        # etc.

- use `pvcreate` to register each of the mapped devices as an LVM physical volume.

        # register each file as an LVM physical volume.
        pvcreate /dev/mapper/vault_file_1
        pvcreate /dev/mapper/vault_file_2
        ...
        
        # etc.
        
- use `vgcreate` to create an LVM volume group out of your vault's physical volumes.

        # combine vault physical volumes into volume group
        vgcreate data_vault_vg /dev/mapper/vault_file_1 /dev/mapper/vault_file_2 ...
        
- use `lvcreate` to create an LVM logical volume that uses up 100% of the space in your vault's LVM volume group.

        # create vault logical volume that uses all space in volume group.
        lvcreate -n data_vault_lv -l 100%FREE data_vault_vg
        
- use `mkfs.ext4` to format the vault's logical volume with an ext4 filesystem.

        # make default ext4 file system on the logical volume
        mkfs.ext4 /dev/data_vault_vg/data_vault_lv
        
- use `mount` to mount the logical volume for use.

        # mount it up!
        sudo mount -t ext4 /dev/data_vault_vg/data_vault_lv /data/warehouse

## activating and mounting the vault manually

- use `losetup` to set up each of the files that make up the vault as a loop device.

        # check to see what the next open loop device is
        losetup -f
        
        # example output when no loop devices are in use:
        # /dev/loop0
        
        # associate each of your vault files with a loop device.
        sudo losetup /dev/loop0 /vault/encrypted_vault_1
        sudo losetup /dev/loop1 /vault/encrypted_vault_2
        ...
        
        # etc.
        
- use `cryptsetup` and LUKS to decrypt then add decrypted volume as device, entering the pass phrase for each..

        # use "luksOpen", rather than "open -t luks" for CentOS 6 compatibility.
        sudo cryptsetup luksOpen /dev/loop0 vault_file_1
        sudo cryptsetup luksOpen /dev/loop1 vault_file_2
        ...
        
        # etc.
        
- use `vgchange` to activate the volume group to make the logical volume available.

        # use "-a" activate flag set to "y"es to activate volume group and
        #     associated logical volume(s).
        sudo vgchange -ay data_vault_vg
        
- run `lvscan` (logical volume scan) to make sure everything is ready for mounting.

        # run lvscan to make sure logical volume is ready to mount (sometimes
        #     this is needed so OS can see that logical volume is active).
        sudo lvscan
        
- use `mount` to mount the vault to your mount point.

        # use "mount" to mount the vault file.
        sudo mount -t ext4 /dev/data_vault_vg/data_vault_lv /data/warehouse

## unmounting and deactivating the vault manually

If you try to extend a vault without it being activated, or if activation or deactivation are interrupted mid-execution, you'll have some clean up to do:

- check if the vault's logical volume is mounted.  If so, use `umount` to unmount it:

        sudo umount /dev/data_vault_vg/data_vault_lv

- use `lvscan` to check to see if the vault's volume group is active (by checking status of logical volume for vault):

        sudo lvscan

        # example output (vault is ACTIVE):        
          ACTIVE            '/dev/rhel/swap' [1.60 GiB] inherit
          ACTIVE            '/dev/rhel/root' [13.91 GiB] inherit
          ACTIVE            '/dev/data_vault_vg/data_vault_lv' [392.00 MiB] inherit

- if active, use `vgchange` to deactivate the volume group (can't hurt to do this even if it is already deactivated):

        sudo vgchange -an data_vault_vg
         
- Each of the vault files might be assigned to a loop device and decrypted.  First, check for decrypted files:

        ls -al /dev/mapper | grep vault_file_
        
        # example output:
        lrwxrwxrwx.  1 root root       7 Oct 21 17:01 vault_file_1 -> ../dm-3
        lrwxrwxrwx.  1 root root       7 Oct 21 17:01 vault_file_2 -> ../dm-4
        lrwxrwxrwx.  1 root root       7 Oct 21 16:59 vault_file_3 -> ../dm-2
        
    Close each file that is listed in the results of this command.
    
        sudo cryptsetup luksClose vault_file_1
        sudo cryptsetup luksClose vault_file_2
        sudo cryptsetup luksClose vault_file_3
        ...

    Look for associated loop devices:
    
        losetup -a
        
        # example output (what a mess I've made...):
        /dev/loop0: []: (/vault/encrypted_vault_3)
        /dev/loop1: []: (/vault/encrypted_vault_1)
        /dev/loop2: []: (/vault/encrypted_vault_2)
        /dev/loop3: []: (/vault/vault_3 (deleted))
        /dev/loop4: []: (/vault/vault_1 (deleted))
        /dev/loop5: []: (/vault/vault_2 (deleted))
        /dev/loop6: []: (/vault/vault_3 (deleted))
        /dev/loop7: []: (/vault/encrypted_vault_3)
        
    Remove any that is a vault file (other programs might use loop devices, as well):

        sudo losetup -d /dev/loop0
        sudo losetup -d /dev/loop1
        sudo losetup -d /dev/loop2
        ...
        
    Then verify that the next loop device is what you'd expect (likely /dev/loop0):
    
        losetup -f
        
        # example output:
        /dev/loop0
        
- At this point, you should be back at the point where you'd run "`activate_vault.sh`", then "`mount_vault.sh`"

## adding a vault file to the vault manually

If you've created a new fault file and want to add it to the volume group (could be something you did purposely, might also need to be done if expansion is interrupted):

- first, activate the vault, but don't mount it.
- deactivate the volume group:

        sudo vgchange -an data_vault_vg

- if you need to open the vault file or add it as an LVM physical volume:

    - manually:
    
        - associate the file with a loop device, then decrypt it.

                # find next available loop device
                losetup -f
                
                # associte file with loop device (using 0 as example)
                sudo losetup /dev/loop0 /vault/encrypted_vault_1
                
                # LUKS - decrypt and add as device
                sudo cryptsetup luksOpen /dev/loop0 vault_file_1
        
        - create a physical volume for it.
        
                # look to see if it is already a physical volume:
                sudo pvdisplay
                
                # look for something like this:
                  "/dev/mapper/vault_file_3" is a new physical volume of "198.00 MiB"
                  --- NEW Physical volume ---
                  PV Name               /dev/mapper/vault_file_3
                  VG Name               
                  PV Size               198.00 MiB
                  Allocatable           NO
                  PE Size               0   
                  Total PE              0
                  Free PE               0
                  Allocated PE          0
                  PV UUID               WLoflv-fcuq-qyl3-r5Kq-xPYd-eDi9-jLTG7p

                # if not present, create:
                sudo pvcreate /dev/mapper/vault_file_1
                
    - using "`open_vault_file`" bash function from "`vault_shared.sh`" - in a bash script:
    
            # !/bin/bash
            source ./vault_shared.sh
            open_vault_file "/vault/encrypted_vault_1" "<LUKS_PASS_PHRASE>" true
            
- add the physical volume to the volume group.

        # see if you need to add it to volume group
        sudo pvdisplay
        
        # look for something like this:
          "/dev/mapper/vault_file_3" is a new physical volume of "198.00 MiB"
          --- NEW Physical volume ---
          PV Name               /dev/mapper/vault_file_3
          VG Name               
          PV Size               198.00 MiB
          Allocatable           NO
          PE Size               0   
          Total PE              0
          Free PE               0
          Allocated PE          0
          PV UUID               WLoflv-fcuq-qyl3-r5Kq-xPYd-eDi9-jLTG7p
          
        # If you see a "NEW" physical volume, it is not yet part of a volume group.  Add it!
        sudo vgextend data_vault_vg /dev/mapper/vault_file_1

- extend the logical volume so it uses 100% of volume group.

        # see if logical volume includes new physical volume
        sudo lvscan
        
        # example output:
          ACTIVE            '/dev/rhel/swap' [1.60 GiB] inherit
          ACTIVE            '/dev/rhel/root' [13.91 GiB] inherit
          inactive          '/dev/data_vault_vg/data_vault_lv' [392.00 MiB] inherit

        # if size of vault logical volume does not include your new file:
        sudo lvextend -l +100%FREE /dev/data_vault_vg/data_vault_lv

- activate the volume group.

        sudo vgchange -ay data_vault_vg

- extend the file system.

        resize2fs /dev/data_vault_vg/data_vault_lv
        
    You might need to run a file system check on the vault before you resize.  This is nothing to be alarmed about (well, unless it fails):
    
        e2fsck -f /dev/data_vault_vg/data_vault_lv
        
- Now you are where you'd be if you'd run "`activate_volume.sh`".  Mount or deactivate.

## deleting all parts of a vault

If you really screw things up and just want to remove a vault and start over:

- use `umount` to unmount the vault's logical volume if it is mounted:

        umount /dev/data_vault_vg/data_vault_lv

- use `lvremove` to remove the logical volume of the vault:

        sudo lvremove /dev/data_vault_vg/data_vault_lv
        
    If you accidentally deleted the vault files without first dismantling the LVM logical volume, volume group, and physical volumes, you will be unable to delete the logical volume, and so unable to remove the rest of the LVM configuration for the vault.  To enable removal of the logical volume, you'll need to:
    
    - create a new vault file with the next number that would have been added had you extended your vault (so if you had and deleted 4 files, use 5):
    
            sudo ./create_vault_file.sh -s 200M -n 5

    - extend the vault with this new file (you will see errors once it starts to extend the file system, but that is fine - the other files are gone anyway - you are just trying to clean up):
    
            sudo ./extend_vault.sh -n 5
            
    - activate the volume group, allowing partial activation:
    
            sudo vgchange -ay data_vault_vg --activationmode partial
            
    Now, you should be able to use the `lvremove` command above to remove the logical volume.  Once you've removed the logical volume, you'll have to do one more thing - remove the missing physical volumes from the volume group:
    
        sudo vgreduce --removemissing data_vault_vg
        
- use `vgremove` to remove the volume group that contained all your vault's physical volumes:

        sudo vgremove data_vault_vg
        
- use `pvremove` to remove each of the physical volumes associated with your vault's files:

        sudo pvremove /dev/mapper/vault_file_1
        sudo pvremove /dev/mapper/vault_file_2
        sudo pvremove /dev/mapper/vault_file_3
        # etc. ...

- use `cryptsetup` to close out your vault's files:

        sudo cryptsetup luksClose vault_file_1
        sudo cryptsetup luksClose vault_file_2
        sudo cryptsetup luksClose vault_file_3
        # etc. ...

- use `losetup` to detach the files from the loop devices with which they are associated:

        sudo losetup -d /dev/loop0
        sudo losetup -d /dev/loop1
        sudo losetup -d /dev/loop2
        # etc. ...

- use `rm` to remove the underlying encrypted files themselves:

        sudo rm /vault/vault_1
        sudo rm /vault/vault_2
        sudo rm /vault/vault_3
        # etc. ...
        
- you can also use `cleanup.sh` to perform these exact steps, based on your configuration.