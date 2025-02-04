#!/bin/bash

#######
### Copy customized jails, filters and action configuration files to fail2ban
### directory and activate them
#######


### set script output colours
normal="\e[0m"
err="\e[1;31m"
ok="\e[32m"
lit="\e[93m"
info="\e[96m"
note="\e[95m"


### functions

function copyFailure {
    echo
    echo -e "${err}There was a problem backing-up/copying the configuration" \
        "files."
    echo -e "This suggests some kind of permissions error. Please remedy this" \
        "and rerun"
    echo -e "this script."
    echo
    echo -e "${normal}Error copying: ${lit}$1"
    echo
    echo -e "${err}Exiting.${normal}"
    echo
    exit 100
}

### end of functions


### pre-requisites
# exit script if fail2ban is not installed
if ! [ -x "$(command -v fail2ban-client)" ]; then
    echo
    echo -e "${err}Cannot find fail2ban, is it installed? Exiting script." \
        "${normal}"
    echo
    exit 1
fi

# check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "${err}This script MUST be run as ROOT. Exiting.${normal}"
    echo
    exit 2
fi


### default values for variables
F2B_DIR="/etc/fail2ban"


### handle provided fail2ban configuration directory provided by user
if [ "$1" ]; then
    # test if provided path actually exists
    if [ ! -d "$1" ]; then
        echo
        echo -e "${err}Could not find the specified fail2ban configuration" \
            "directory."
        echo -e "${lit}($1)"
        echo -e "${err}Perhaps you mistyped it?  Exiting.${normal}"
        echo
        exit 3
    elif [ ! -f "$1/fail2ban.conf" ]; then
        echo
        echo -e "${err}The specified fail2ban configuration directory does" \
            "not seem to contain"
        echo -e "fail2ban configuration files.  Perhaps you provided the" \
            "wrong directory?"
        echo -e "${lit}($1)"
        echo -e "${err}Exiting.${normal}"
        echo
        exit 4
    else
        F2B_DIR="${1%/}"
    fi
fi


### last check: is the directory writable
if [ ! -w "${F2B_DIR}" ]; then
    echo
    echo -e "${err}The specified fail2ban configuration directory is not" \
        "writable."
    echo -e "${lit}(${F2B_DIR})"
    echo -e "${err}Exiting.${normal}"
    echo
    exit 5
fi


### user info preamble
echo
echo -e "${note}--------------------------------------------------------------------------------${normal}"
echo -e "${info}This script will copy customized configuration files to your" \
    "fail2ban"
echo -e "configuration directory.  It will backup any existing files with the" \
    "extension"
echo -e "${note}'.original'${info}.${normal}"
echo
echo -e "${info}Please ensure you have reviewed the ${note}README${info} in" \
    "this git archive and/or it's"
echo -e "associated wiki or the blog post at${note}" \
    "https://mytechiethoughts.com${info} to understand"
echo -e "how to customize these template files.${normal}"
echo -e "${note}--------------------------------------------------------------------------------${normal}"
echo

# # confirm user wants to proceed
# while true; do
#     read -rp "Do you want to proceed? (default: Yes) " yn
#     case "${yn}" in
#         [Yy]*|'')
#             break
#             ;;
#         [Nn]*)
#             # exit gracefully, user choice
#             echo -e "\n${info}Exiting now.${normal}\n"
#             exit 0
#             ;;
#         *)
#             # invalid input
#             echo -e "\n${lit}Please answer (Y)es or (N)o or accept default" \
#                 "${normal}"
#             ;;
#     esac
# done


### copy template files
# note: prefixing cp with '\' to override any alias settings
# copy .local files
if ! \cp --force --backup=simple --suffix=.original \
    etc/fail2ban/*.local "${F2B_DIR}/"; then
        copyFailure 'general config files (.local)'
fi
echo -e "${info}Copy general configuration files${normal} -- ${ok}[OK]${normal}"

# copy action configuration files
if ! \cp --force --backup=simple --suffix=.original \
    etc/fail2ban/action.d/* "${F2B_DIR}/action.d/"; then
        copyFailure 'action files'
fi
echo -e "${info}Copy action configuration files${normal} -- ${ok}[OK]${normal}"

# copy filter configuration files
if ! \cp --force --backup=simple --suffix=.original \
    etc/fail2ban/filter.d/* "${F2B_DIR}/filter.d/"; then
        copyFailure 'filter files'
fi
echo -e "${info}Copy filter configuration files${normal} -- ${ok}[OK]${normal}"

# copy jail configuration files
if ! \cp --force --backup=simple --suffix=.original \
    etc/fail2ban/jail.d/* "${F2B_DIR}/jail.d/"; then
        copyFailure 'jail files'
fi
echo -e "${info}Copy jail configuration files${normal} -- ${ok}[OK]${normal}"


### user post-amble
echo
echo -e "${note}--------------------------------------------------------------------------------${normal}"
echo -e "${ok}Script operations completed successfully!"
echo
echo -e "${info}You can now customize the template files if/as you desire." \
    "Then do the"
echo -e "following to load and confirm your new configuration:${normal}"
echo -e "1. systemctl restart fail2ban.service"
echo -e "2. systemctl --full --no-pager status fail2ban.service"
echo -e "3. fail2ban-client status"
echo
echo -e "${note}To revert your configuration, simply copy the ${lit}.original" \
    "${note}files over the modified"
echo -e "files.  For example, ${lit}cp jail.local.original jail.local${normal}"
echo -e "${note}--------------------------------Script--Complete--------------------------------${normal}"
echo


### exit gracefully
exit 0


### error code summary
# 1:    fail2ban executable file could not be found -- fail2ban likely not
#       installed
# 2:    script not run as ROOT (needed to avoid any permissions issues)
# 3:    invalid fail2ban configuration directory provided by user
# 4:    provided fail2ban configuration directory is missing fail2ban.conf
# 5:    fail2ban configuration directory is not writable
# 99:   internal testing error code, should *not* appear in releases
# 100:  error copying files to fail2ban configuration directory and/or making 
#       simultaneous backup copies of any exisitng files.
