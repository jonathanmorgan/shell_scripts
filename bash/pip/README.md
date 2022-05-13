Scripts:

- download_pip_packages.sh

    - Can accept 3 arguments:

        - 1 - requirements_file_path_in - path to requirements file you want to download all packages from. Defaults to "`./pip_master_package_list.txt`".
        - 2 - download_dir_path_in - path of folder where you want downloaded packages to be stored. Defaults to "`./pip_download`".
        - 3 - pip_executable_in - path to pip executable you want to use to download the packages. Can be left empty, defaults to "`pip`".

    - to install from downloaded files, use this pattern:

            pip install --find-links=file://<download_folder_path> --no-index <package>
            Example: pip install --find-links=file:///opt/packages/pip_download --no-index tensorflow-gpu==2.3.4

- TK
