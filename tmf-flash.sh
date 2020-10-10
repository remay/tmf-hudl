#!/bin/sh
############################################################
# Flash TMF Custom ROM to Hudl 1
# (c) Robert May, 2020
############################################################
# tmf-flash.sh v0.1
############################################################
TCEDIR=`readlink /etc/sysconfig/tcedir`
IMGDIR="${TCEDIR}/tmf-flash"

# ANSI COLORS
RED="$(echo -e '\033[1;31m')"
GREEN="$(echo -e '\033[1;32m')"
YELLOW="$(echo -e '\033[1;33m')"
MAGENTA="$(echo -e '\033[1;35m')"
NORMAL="$(echo -e '\033[0;39m')"

clear
echo "${GREEN}############################################################${NORMAL}"
echo "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}"
echo "${GREEN}############## Step 1/5: Accept Liability     ##############${NORMAL}"
echo "${GREEN}############################################################${NORMAL}"
echo
echo "${GREEN}This program will flash the TMF Custom ROM to a Hudl 1${NORMAL}"
echo "${GREEN}device.   Abort at any time by pressing <CTRL-C>.${NORMAL}"
echo
echo   "${RED}* WARNING: All at your own risk.  Make sure you have read the${NORMAL}"
echo   "${RED}* documentation and understand what you are doing before${NORMAL}"
echo   "${RED}* continuing.${NORMAL}"

echo
echo "${YELLOW}I understand what I'm doing and accept full responsibility${NORMAL}"
echo -n "${YELLOW}for anything bad that happens (y/N): ${NORMAL}"
read answer
if [ "$answer" != "y" ] ; then exit ; fi

clear
echo "${GREEN}############################################################${NORMAL}"
echo "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}"
echo "${GREEN}############## Step 2/5: Connect Hudl         ##############${NORMAL}"
echo "${GREEN}############################################################${NORMAL}"
echo
echo "${GREEN}Connect your Hudl to a USB port on this computer and then,${NORMAL}"
echo "${GREEN}while holding the vol+ key on the Hudl, press and release${NORMAL}"
echo "${GREEN}the Hudl's reset button with a paper clip (through the small${NORMAL}"
echo "${GREEN}hole on the back cover near the power and volume buttons).${NORMAL}"
echo "${GREEN}Keep re-trying the vol+/reset action until the device is${NORMAL}"
echo "${GREEN}recognised as being in flash mode.${NORMAL}"

echo
echo "${MAGENTA}Waiting for Hudl to be connected ...${NORMAL}"

hudl_connected_flash_mode=0
hudl_connected_other_mode=0

while [ $hudl_connected_flash_mode -eq 0 ]
do
	lsusb -d0e79: 1>/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		if [ $hudl_connected_other_mode -eq 0 ]
		then
			echo "${RED}Hudl connected but not in flash mode ...${NORMAL}"
		fi
		hudl_connected_other_mode=1
	else
		if [ $hudl_connected_other_mode -eq 1 ]
		then
			echo "${RED}Hudl disconnected ...${NORMAL}"
		fi
		hudl_connected_other_mode=0
	fi

	lsusb -d2207:310b 1>/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		hudl_connected_flash_mode=1
	else
		sleep .5
	fi
done
echo "${MAGENTA}... Hudl connected in flash mode.${NORMAL}"

echo
echo "${GREEN}Your Hudl is now connected in flash mode.  You can let go${NORMAL}"
echo "${GREEN}of the vol+ button.${NORMAL}"

echo
echo "${YELLOW}Are you ready to flash your Hudl with the TMF Custom${NORMAL}"
echo -n "${YELLOW}ROM? (y/N): ${NORMAL}"
read answer
if [ "$answer" != "y" ] ; then exit ; fi

clear
echo "${GREEN}############################################################${NORMAL}"
echo "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}"
echo "${GREEN}############## Step 3/5: Flashing the ROM     ##############${NORMAL}"
echo "${GREEN}############################################################${NORMAL}"
echo
echo "${GREEN}Flashing your Hudl will take about 5 minutes, but this script${NORMAL}"
echo "${GREEN}will wait after flashing so feel free to go and make a cup${NORMAL}"
echo "${GREEN}of tea.${NORMAL}"
echo
echo -n "${MAGENTA}Checking communications with the device ... ${NORMAL}"

can_flash=0
rkflashtool v 2>&1 | grep 'chip version' 1>/dev/null 2>&1 && can_flash=1
if [ $can_flash -eq 0 ] ; then echo "${RED}NOT OK${NORMAL}" ; exit ; fi
echo "${GREEN}OK${NORMAL}"

echo
echo "${MAGENTA}Starting to flash.${NORMAL}"

# TODO - should we read the existing parameters and do some sanity check?

echo "${MAGENTA}Flashing parameter block ...${NORMAL}"
#zcat "${IMGDIR}/parameter.gz"    | rkflashtool P          2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/parameter.gz" | rkflashtool P
echo
echo "${MAGENTA}Flashing boot partition ...${NORMAL}"
#zcat "${IMGDIR}/boot.img.gz"     | rkflashtool w boot     2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/boot.img.gz" | rkflashtool w boot
echo
echo "${MAGENTA}Flashing recovery partition ...${NORMAL}"
#zcat "${IMGDIR}/recovery.img.gz" | rkflashtool w recovery 2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/recovery.img.gz" | rkflashtool w recovery
echo
echo "${MAGENTA}Flashing kernel partition ...${NORMAL}"
#zcat "${IMGDIR}/kernel.img.gz"   | rkflashtool w kernel   2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/kernel.img.gz" | rkflashtool w kernel
echo
echo "${MAGENTA}Flashing system partition ...${NORMAL}"
#zcat "${IMGDIR}/system.img.gz"   | rkflashtool w system   2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/system.img.gz" | rkflashtool w system
echo
echo "${MAGENTA}Flashing misc partition ...${NORMAL}"
#zcat "${IMGDIR}/misc.img.gz"     | rkflashtool w misc     2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/misc.img.gz" | rkflashtool w misc
echo
echo "${MAGENTA}Flashing backup partition ...${NORMAL}"
#zcat "${IMGDIR}/backup.img.gz"   | rkflashtool w backup   2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
zcat "${IMGDIR}/backup.img.gz" | rkflashtool w backup

echo
echo "${MAGENTA}Flash completed.${NORMAL}"

echo
echo "${GREEN}Your Hudl now needs to be rebooted.${NORMAL}"

echo
echo -n "${YELLOW}Press <Enter> to reboot your hudl: ${NORMAL}"
read answer

clear
echo "${GREEN}############################################################${NORMAL}"
echo "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}"
echo "${GREEN}############## Step 4/5: Reboot Hudl          ##############${NORMAL}"
echo "${GREEN}############################################################${NORMAL}"
echo
echo "${MAGENTA}Rebooting ...${NORMAL}"

rkflashtool b 1>/dev/null 2>&1

echo
echo "${GREEN}Your Hudl will now boot into recovery mode and will${NORMAL}"
echo "${GREEN}automatically clear all userdata(/data) and caches(/cache).${NORMAL}"
echo "${GREEN}It will then reboot again and should start up normally.${NORMAL}"
echo "${GREEN}This boot may take longer than you are used to, please${NORMAL}"
echo "${GREEN}be patient.${NORMAL}"

echo
echo "${GREEN}It may look like nothing is happening for a while, but${NORMAL}"
echo "${GREEN}you shoud see the recovery screen with messages about${NORMAL}"
echo "${GREEN}'Formatting ...' and then a restart which shows the Hudl${NORMAL}"
echo "${GREEN}splashscreen.${NORMAL}"

echo
echo "${YELLOW}Once the reboot has finished press <Enter> for the${NORMAL}"
echo -n "${YELLOW}post-install steps: ${NORMAL}"
read answer

clear
echo "${GREEN}############################################################${NORMAL}"
echo "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}"
echo "${GREEN}############## Step 5/5: Post Install Config  ##############${NORMAL}"
echo "${GREEN}############################################################${NORMAL}"
echo
echo "${GREEN}POST INSTALL STEPS${NORMAL}"
echo
echo "${GREEN}1. Use settings to set up wifi.${NORMAL}"
echo "${GREEN}2. Use settings to validate location settings.${NORMAL}"
echo "${GREEN}3. Use settings to add a Google account.${NORMAL}"
echo "${GREEN}4. Use Play Store to update apps, including Google${NORMAL}"
echo "${GREEN}   Play Services${NORMAL}"

echo
echo "${GREEN}You should now have a functioning Hudl.  Enjoy it :-)${NORMAL}"

echo
echo "${GREEN}This macine will now shut down.  Once the screen goes${NORMAL}"
echo "${GREEN}blank it is safe to remove your USB drive.${NORMAL}"

echo
echo -n "${YELLOW}Press <Enter> to finish and shut-down: ${NORMAL}"
read answer

sudo poweroff
