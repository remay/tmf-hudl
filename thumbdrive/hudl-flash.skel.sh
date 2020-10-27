#!/bin/sh

# Dummy version of the flash script that reports that the image being used doesn't
# have the necessary bits installed

# ANSI COLORS
RED="$(printf '\033[1;31m')"
YELLOW="$(printf '\033[1;33m')"
NORMAL="$(printf '\033[0;39m')"

clear
printf "${RED}############################################################${NORMAL}\n"
printf "${RED}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}\n"
printf "${RED}##############          NOT INSTALLED         ##############${NORMAL}\n"
printf "${RED}############################################################${NORMAL}\n\n"

printf "${RED}If you are seeing this then you are running the skeleton disk${NORMAL}\n"
printf "${RED}image that has not been correctly configured.${NORMAL}\n\n"

printf "${RED}You should download the correct image to flash your USB drive${NORMAL}\n"
printf "${RED}from https://github.com/remay/tmf-hudl/releases${NORMAL}\n\n"

printf "${YELLOW}Press <enter> to end:${NORMAL}"
read junk
