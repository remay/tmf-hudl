#!/bin/bash

# script to unpack teh stock Hudl image and apply the changes to make the
# TMF Custom ROM

# TODO Should do an initial check for the tools that we need:
# wget, unzip, imgrepackrk, zip, composite, zopflipng

# We need to run as root to keep permissions within the image file correct
# Check we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   echo "Try re-running it as 'sudo $0'" 1>&2
   exit 1
fi

version='0.2'
stockimg='hudl.20140424.153851.stock.img'
stockimg_url='https://github.com/remay/tmf-hudl/releases/download/stock-rom-v1.0/hudl.20140424.153851.stock.img.zip'
tmfimg="hudl.20140424.153851.TMF-Custom-v${version}.img"
sysimg="${tmfimg}.dump/Image/system.img"
miscimg="${tmfimg}.dump/Image/misc.img"
mnt='mnt'

# Download and unpack the stock image, if needed
[ -f "${stockimg}" ] || [ -f "${stockimg}.zip" ] || wget --no-verbose --show-progress $stockimg_url || exit 1
[ -f "${stockimg}" ] || unzip "${stockimg}.zip" || exit 1
[ -d "${stockimg}.dump" ] || imgrepackerrk $stockimg || exit 1

# Rename the unpacked folder to match our release version
[ -d "${tmfimg}.dump" ] && echo "Directory ${tmfimg}.dump exists.  Remove it and try again." && exit 1
mv -v "${stockimg}.dump" "${tmfimg}.dump"

# Create a mount point and mount the system image so we can modify it
mkdir -pv "${mnt}" && mount -v $sysimg $mnt

# ** Remove the annoying boot jingle
mv -v $mnt/media/audio/boot.ogg $mnt/media/audio/boot.ogg.nothanks

# ** Install our custom bootanimation
#    - extract the original bootanimation
[ -f bootanimation/bootanimation-orig.zip ] || cp -v $mnt/media/bootanimation.zip bootanimation/bootanimation-orig.zip
#    - create the new bootanimation
[ -f bootanimation/bootanimation.zip ] || ( cd bootanimation && ./mkanimation )
#    - copy the new bootanimation back to the image
cp -v bootanimation/bootanimation.zip $mnt/media/bootanimation.zip

# ** Stop tht setup wizard from running
echo "Modifying install-recovery.sh"
cat SetupWizard/stop-wizard >> $mnt/etc/install-recovery.sh

# ** Remove all non-functional apps
rm -v $mnt/app/appupdater.apk        # Hudl App Updater - One of the sources of call to the defunct Tesco server
rm -v $mnt/app/otaclient.apk         # Hudl OTA Client - Another source of calls to the defunct TEsco server
rm -v $mnt/app/otaclient.odex
rm -v $mnt/app/hudlsetup.apk         # Hudl setup - addd the extra Tesco Account setup pages after the startup Wizard
rm -v $mnt/app/hudlsetup.odex
rm -v $mnt/app/blinkboxmovies.apk    # BlinkBox Movies
rm -v $mnt/app/blinkboxmusic.apk     # BlinkBox Music
rm -v $mnt/app/blinkboxwidget.apk    # BlinkBox Widget
rm -v $mnt/app/clubcardtv.apk        # Club Card TV
rm -v $mnt/app/clubcardwidget.apk    # Club Card Widget
rm -v $mnt/app/getstarted.apk        # Get Started App
rm -v $mnt/app/grocery.apk           # Tesco Groceries
rm -v $mnt/app/grocerywidget.apk     # Tesco Groceries Widget
rm -v $mnt/app/storelocator.apk      # Tesco Store Locator
rm -v $mnt/app/tescoaccountapp.apk   # Tesco Account App
rm -v $mnt/app/tescodirectwidget.apk # Tesco Direct Widget
rm -v $mnt/app/tescolauncher.apk     # Tesco App Launcher

# ** Get rid of the [T] Tesco button from the navigation bar
cp -v SystemUI/SystemUI.apk.new $mnt/app/SystemUI.apk

# ** Put our build info into the build.properties file
# Appears in the settings app: About Tablet -> Build  number field
sed -i -e "s/ro.build.display.id=JDQ39.20140424.153851/ro.build.display.id=TMF Custom ROM v${version} JDQ39.20140424.153851/" $mnt/build.properties

# unmount the system image and remove our mount point
umount -v $mnt && rm -rf $mnt

# create a misc.img that on first boot wipes userdata and cache and then reboots tp get us cleanly into the new
# image
echo "Creating new misc.img"
rkmisc wipe_all $miscimg >/dev/null 2>&1

# Re-pack the monolithic image and zip it up
imgrepackerrk "${tmfimg}.dump"
zip -dd -v "${tmfimg}.zip" ${tmfimg}

# Make the flash drive image, if needed
[ -f thubmdrive/tmf-hudl-thumb-drive.img ] || ( cd thumbdrive; ./mkthumbdrive.sh )

# Make a copy of the thumbdrive amd push the image parts and flash program into it

# Tidy up (remove this if you want to make you own additional changes to the image
rm -rf "${tmfimg}.dump"
rm "${tmfimg}"
