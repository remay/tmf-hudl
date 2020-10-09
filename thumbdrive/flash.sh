#! /bin/bash

# flash our disk image to a usb stick

test "$#" -eq 1 || { cat << __EOF__

usage:    write.sh /dev/sdN

write disk image to (unmounted) flash drive.

__EOF__
exit
}

# Needs to be run as root so we are allowed to mount and set other permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   echo "Try re-running it as 'sudo $0'" 1>&2
   exit 1
fi

# TODO - put a check in here as this next command can be destructive of the wrong device is supplied
dd bs=4M if=tmf-hudl-thumb-drive.img of="$1" conv=fdatasync status=progress
