#! /bin/bash

# flash our disk image to a usb stick

test "$#" -eq 2 || { cat << __EOF__

usage:    thumbflash.sh <file> <device>
e.g:      thumbflash.sh thumb.img /dev/sdb

write disk image to (unmounted) (flash) drive.
Take care to provide the right device - this can be destructive

__EOF__
exit
}

# Needs to be run as root so we are allowed to mount and set other permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   echo "Try re-running it as 'sudo $0 $1 $2'" 1>&2
   exit 1
fi

# TODO - put a check in here as this next command can be destructive of the wrong device is supplied
dd bs=4M if="$1" of="$2" conv=fdatasync status=progress
