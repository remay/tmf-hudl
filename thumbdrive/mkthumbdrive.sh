#!/bin/bash

# Create a .img file that can be burned to a USB flash drive and used
# to boot a computer and run a program to flash the TMF Custom ROM to a Hudl

# Here we make the skeleton that we need, and then during the build
# process we inject the custom ROM and the flashing program into
# this disk.

force=0
mnt="/tmp/mkthumbdrive_mnt..$$";
mnt_supplied=0;

usage()
{
    printf "\n"
    printf "$0 [-m <mnt-dir> | --mount <mnt-dir>] <res-dir> <cache-dir>\n\n"

    printf "<res-dir>    is the directory where the build resources are found\n"
    printf "<cache-dir>  is the directory where the build artefacts are stored\n\n"

    printf "--mount|-m <mnt-dir>\t<mnt-dir> is a directory used to create two temporary mount\n"
    printf "                    \tpoints while building the image.  If not specified uses a tmp\n"
    printf "                    \tlocation.\n\n"
}

if [ $# -lt 2 ] ; then
    printf "ERROR: missing mandatory command line option. (Got $# expected 2).\n"
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    PARAM=`printf "%s" $1 | awk -F= '{print $1}'`
    VALUE=`printf "%s" $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -m | --mount)
            mnt=$VALUE
	    mnt_supplied=1
            ;;
        -*)
            printf "ERROR: unknown command line parameter \"${PARAM}\"\n"
            usage
            exit 1
            ;;
         *)
            if [ $# -ne 2 ] ; then
                printf "ERROR: wrong number of mandatory arguements. Got: $# Expecting: 2\n"
                usage
                exit 1
            fi
            respath=$1
            shift
            cachepath=$1
            ;;
    esac
    shift
done

if ! [ -d "${respath}" ]
then
        printf "ERROR: \"${respath}\" is not a directory\n"
        exit 1
fi
if ! [ -d "${cachepath}" ]
then
        printf "ERROR: \"${cachepath}\" is not a directory\n"
        exit 1
fi
if ! [ -d "${mnt}" ]
then
        printf "ERROR: \"${mnt}\" is not a directory\n"
        exit 1
fi

# Needs to be run as root so we are allowed to mount and set other permissions
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root"
   printf "Try re-running it as 'sudo $0 $@'"
   exit 1
fi

imgfile="${cachepath}/tmf-hudl-thumb-drive.img"
tcliso="${cachepath}/Core-current.iso"
tcliso_url="http://tinycorelinux.net/11.x/x86/release/Core-current.iso"
mntimg="${mnt}/img"
mntiso="${mnt}/iso"
tce_cache="${cachepath}/tce"

# Start by making an empty .img file.  600MB is plenty TODO: tune this down
# creating this as a sparse file saves time and disk space
printf "Creating empty file: ${imgfile}\n"
dd if=/dev/zero of="${imgfile}" bs=1 count=0 seek=600M status=none >/dev/null 2>&1

# Attach a loop device to the file
loop_device=`losetup --show -f ${imgfile}`
printf "${imgfile} attached to ${loop_device}\n"

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
printf "Making the partion(s) on ${imgfile}\n"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${loop_device} >/dev/null
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  t # set the type of the new partition
  c # set the type to 0xC (Win95 FAT32 (LBA))
  a # Mark the partition as bootable
  w # write the partition table
  q # quit
EOF

# Get the OS to use the new partition table
printf "^- Expected failure: \"Re-reading the partition table failed.: Invalid argument\".\n"
printf "Updating the OS to use the new partition(s) to fix this ...\n"
partprobe ${loop_device}

# Format the image as FAT32
# The volume name "TMF-HUDL" is used by our syslinux boot process to wait until
# the disk is mounted and available before finishing the boot process
printf "Formatting the image as FAT32\n"
mkfs.vfat -n TMF-HUDL "${loop_device}p1"

# Make the mount points
mkdir -pv ${mntimg}
mkdir -pv ${mntiso}

# Mount our new drive
mount -v ${loop_device}p1 ${mntimg}

# Get the Tiny Core Linux ISO file:
[ -f "${tcliso}" ] || wget --no-verbose --show-progress --directory-prefix "${cachepath}" $tcliso_url || exit 1

# mount the ISO file
mount -v ${tcliso} ${mntiso}

# Copy everything from the ISO to our flash image:
# TODO: Perhaps we should only copy what we actually want?
cp -aTv "${mntiso}" "${mntimg}"

# unmount the ISO and remove the mount point
umount -v ${mntiso}
rm -vd ${mntiso}

# Modify the ISOLINUX from the ISO and replace with SYSLINUX
mv -v "${mntimg}/boot/isolinux" "${mntimg}/boot/syslinux"
rm -v "${mntimg}/boot/syslinux/isolinux.bin"
rm -v "${mntimg}/boot/syslinux/boot.cat"
rm -v "${mntimg}/boot/syslinux/isolinux.cfg"
cp -v "${respath}/syslinux.cfg" "${mntimg}/boot/syslinux"

# Add our Tiny Core Linux extensions here:
mkdir -pv ${mntimg}/tce/optional
mkdir -pv ${mntimg}/tce/ondemand
touch ${mntimg}/tce/onboot.lst

mkdir -pv $tce_cache
for p in libffi glib2 udev-lib libusb usbutils
do
	if [ ! -f "${tce_cache}/${p}.tcz" ]
	then
		wget -P "${tce_cache}" --no-verbose --show-progress "http://tinycorelinux.net/11.x/x86/tcz/${p}.tcz"
		wget -P "${tce_cache}" --no-verbose --show-progress "http://tinycorelinux.net/11.x/x86/tcz/${p}.tcz.dep"
		wget -P "${tce_cache}" --no-verbose --show-progress "http://tinycorelinux.net/11.x/x86/tcz/${p}.tcz.md5.txt"
	fi
	cp -v "${tce_cache}/${p}."* "${mntimg}/tce/optional"
done

printf "usbutils.tcz\n" >> "${mntimg}/tce/onboot.lst"
cp -v "${respath}/rktools.tcz" "${mntimg}/tce/optional"
printf "libusb.tcz\n" > "${mntimg}/tce/optional/rktools.tcz.dep"
printf "rktools.tcz\n" >> "${mntimg}/tce/onboot.lst"

# hudl-flash.sh and images are added to /tce/tmf-hudl by the build process
# write a dummy hudl-flash.sh to report the error if anyone runs this image
mkdir -pv "${mntimg}/tce/tmf-hudl"
cp -v "${respath}/hudl-flash.skel.sh" "${mntimg}/tce/tmf-hudl/hudl-flash.sh"

# Add a data.tgz file that overwrites the tc user's ~/.profile to start the hudl-flash.sh script automatically
# TODO: would be good to build this from scratch to get paths to match what's done in this script
cp -v "${respath}/mydata.tgz" "${mntimg}/tce"

# Fix ownerships
chown -cR root:root ${mntimg}

# Unmount our device and remove the mount point
umount -v ${loop_device}p1
rm -vd ${mntimg}

# Remove the moutn directory if we created it
if [ $mnt_supplied -eq 0 ] ; then
	rm -vd ${mnt}
fi

printf "Making the image bootable\n"
# Install SYSLINUX on the image
syslinux --directory /boot/syslinux --install "${loop_device}p1"
# Install MBR
dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/mbr.bin of="${loop_device}" status=none

# Unattach the loop device
losetup -d ${loop_device}
printf "${imgfile} detached from ${loop_device}\n"

# Done - we should be able to push that onto a usb stick and boot from it
