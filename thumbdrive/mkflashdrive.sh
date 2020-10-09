#!/bin/bash

# Create a .img file that can be burned to a flash drive and used
# to flash the TMF Custom ROM to a Hudl

# Here we make the skeleton that we need, and then during the build
# process we inject the custom ROM and the flashing program into
# this disk.

# TODO should have options to clean up the build artefacts

# Needs to be run as root so we are allowed to mount and set other permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   echo "Try re-running it as 'sudo $0'" 1>&2
   exit 1
fi

imgfile="tmf-hudl-thumb-drive.img"
tcliso="Core-current.iso"
tcliso_url="http://tinycorelinux.net/11.x/x86/release/${tcliso}"
mntimg="mnt/img"
mntiso="mnt/iso"
tce_cache="tce-cache"

# Start by making an empty .img file.  cw750MB is plenty TODO: tune this down
# creating this as a sparse file saves time and disk space
echo "Creating empty file: ${imgfile}"
#dd if=/dev/zero of="${imgfile}" bs=1M count=750 status=none
dd if=/dev/zero of="${imgfile}" bs=1 count=0 seek=750M status=none

# Attach a loop device to the file
loop_device=`losetup --show -f ${imgfile}`
echo "${imgfile} attached to ${loop_device}"

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
echo "Making the partion on ${imgfile}"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${loop_device} >/dev/null
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  t # set the type of the new partition
  c # set teh tpe to 0xC (Win95 FAT32 (LBA))
  a # Mark the partitionas bootable
  w # write the partition table and quit
  q # quit
EOF

# Get the OS to use the new partition table
echo "Updating the OS to use the new partition(s)"
partprobe ${loop_device}

# Format the imag as FAT32
# The volume name "TMF-HUDL" is used by the syslinux boot process to wait until
# the disk is mount and availble before finishing the boot process
echo "Formatting the image as FAT32"
mkfs.vfat -n TMF-HUDL "${loop_device}p1"

# Make the mount points
mkdir -pv ${mntimg}
mkdir -pv ${mntiso}

# Mount our new drive
mount -v ${loop_device}p1 ${mntimg}

# Get the Tiny Core Linux ISO file:
[ -f "${tcliso}" ] || wget --no-verbose --show-progress $tcliso_url || exit 1

# mount the ISO file
mount -v ${tcliso} ${mntiso}

# Copy everything from the ISO to our flash image:
# TODO: Perhaps we shoudl only copy what we actually want?
cp -aTv "${mntiso}" "${mntimg}"

# unmount the ISO and remove the mount point
umount -v ${mntiso}
rm -rfv ${mntiso}

# Modify the ISOLINUX from the ISO and replace with SYSLINUX
mv -v "${mntimg}/boot/isolinux" "${mntimg}/boot/syslinux"
rm -v "${mntimg}/boot/syslinux/isolinux.bin"
rm -v "${mntimg}/boot/syslinux/boot.cat"
rm -v "${mntimg}/boot/syslinux/isolinux.cfg"
cp -v syslinux.cfg "${mntimg}/boot/syslinux"

# Add our Tiny Core Linux extensions here:
mkdir -pv ${mntimg}/tce/optional
mkdir -pv ${mntimg}/tce/ondemand
mkdir -pv ${mntimg}/tce/tmf-flash
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

echo "usbutils.tcz" >> "${mntimg}/tce/onboot.lst"
cp -v "rktools.tcz" "${mntimg}/tce/optional"
echo "libusb.tcz" >> "${mntimg}/tce/optional/rktools.tcz.dep"
echo "rktools.tcz" >> "${mntimg}/tce/onboot.lst"

# TODO tmf-flash.sh and images are added by the build process

# TODO add a data.tgz file that overwrites something to launch tmf-flash.sh

# Fix ownerships
chown -cR root:root ${mntimg}

# Unmount our device and remove the mount point
umount -v ${loop_device}p1
rm -rfv ${mntimg}
rm -fdv mnt

echo "Making the image bootable"
# Install SYSLINUX
syslinux --directory /boot/syslinux --install "${loop_device}p1"
# Install MBR
dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/mbr.bin of="${loop_device}" status=none

# Unattach the loop device
losetup -d ${loop_device}

# Done - we should be able to push that onto a usb stick and boot from it
