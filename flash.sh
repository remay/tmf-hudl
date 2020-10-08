#!/bin/bash

# Quick script to re-flash only the system and misc partitions of a Hudl during development.
# Assumes the partition table and all other partitions are already consistent with
# the final stock Tesco released image.  If not, or if there is any doubt then don't
# use this and follow the instructions to build a full image.



# Make sure we have root permissions
# No longer needed - see changes to udev config
#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

version='0.2' # Must match the version used by the build script, and teh build script must leave
              # the .dump directory after completing the build.  See the -d option to build
imgdir="hudl.20140424.153851.TMF-Custom-v${version}.img.dump/Image"

echo
echo
echo
echo
read -p "About to FLASH a modified system.img/misc.img  to your Hudl - PRESS ANY KEY to CONTINUE or CTRL-C to ABORT..."


# TODO check that the Hudl is in bootloader mode

try_adb=1
echo "Waiting for a connected Hudl in flash mode ..."
while ! lsusb -d 2207:310b 1>/dev/null 2>&1
do
	lsusb -d 0e79: 1>/dev/null 2>&1
        if [ $? -eq 0 ]
        then
                if [ $try_adb -eq 1 ]
                then
			# See if we can use adb to put us in flash mode: 
			echo "Trying to reboot Hudl into flash mode using adb (needs USB debugging enabled)."
			echo "If this fails then do it manually by holding vol+ and pressing reset."
			adb reboot bootloader
			# TODO Should check for availability of adb command, and shoudl catch failure here
			sleep 5
                fi
                try_adb=0
	fi
done
echo "Hudl in flash mode, starting to flash ..."

# TODO should check that parameter block is correct for the images being flashed ....
rkflashtool w misc   < ${imgdir}/misc.img
rkflashtool w system < ${imgdir}/system.img

# Reboot
echo "Flash complete, rebooting Hudl ..."
rkflashtool b

# TODO add instructions for completing setup
echo ===================================================================================================
echo === TMF Custom ROM now flashed to your device.  The device should reboot, wipe and reboot again.===
echo ===================================================================================================

