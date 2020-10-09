#!/bin/sh

# Dummy version of the flash script that reports that the image being used doesn't
# have the necessary bits installed

# ANSI COLORS
RED="$(echo -e '\033[1;31m')"
YELLOW="$(echo -e '\033[1;33m')"

clear
echo "${RED}############################################################${NORMAL}"
echo "${RED}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}"
echo "${RED}##############          NOT INSTALLED         ##############${NORMAL}"
echo "${RED}############################################################${NORMAL}"
echo
echo "${RED}If youa re seeingthis then you are running the skeleton disk${NORMAL}"
echo "${RED}image that has not been correctly configured.${NORMAL}"
echo
echo "${RED}You should download the correct image to flash your USB drive${NORMAL}"
echo "${RED}from https://github.com/remay/tmf-hudl/releases${NORMAL}"

echo
echo "${YELLOW}Press <enter> and wait from your computer to turn off before${NORMAL}"
echo -n "${YELLOW}you remove you USB drive.${NORMAL}"
read junk
