#!/bin/bash

# script to unpack teh stock Hudl image and apply the changes to make the
# TMF Custom ROM

# TODO Should do an initial check for the tools that we need:
# wget, unzip, imgrepackrk, zip, composite, zopflipng

# We need to run as root to keep permissions within the image file correct
# Check we are running as root
# TODO - see if we can down-privilege the commands that don't need to be run as root

version='0.2'

basepath=".tmf-rom-build"
cachepath="${basepath}/cache"
buildpath="${basepath}/v${version}"
mnt="${buildpath}/mnt"
anipath="${buildpath}/bootanimation"
aniflags=

stockimg="${cachepath}/hudl.20140424.153851.stock.img"
stockimg_url='https://github.com/remay/tmf-hudl/releases/download/stock-rom-v1.0/hudl.20140424.153851.stock.img.zip'

tmfimg="${buildpath}/hudl.20140424.153851.TMF-Custom-v${version}.img"
sysimg="${tmfimg}.dump/Image/system.img"
miscimg="${tmfimg}.dump/Image/misc.img"

thumbimg="${buildpath}/tmf-hudl-thumbdrive-v${version}.img"

force=0
clear_cache=0
compress=1
build_rkfw=1
build_thumb=1

usage()
{
    printf "\n"
    printf "$0 [ OPTIONS ]\n\n"

    printf "\t-h --help\tPrint this help\n"
    printf "\t-f --force\tRe-build, overwriting previous changes\n"
    printf "\t-b --bootanimation-no-compression\tSpeed up creating the boot animation by turning off image compression\n"
    printf "\t-n --img-no-compression\tDon't compress the .img artefacts\n"
    printf "\t-r --no-build-rkfw\tDon't build the Rockchip Batch Image\n"
    printf "\t-t --no-build-thumbdrive\tDon't build the Thumb drive Image\n"
    printf "\t-l --clear-cache\tClear the cache and re-download/re-build the cached data.  Implies -f\n"
    printf "\t-c --clean\tClean (delete) the build directory and exit.  Ignore all other options.\n\n"
}

while [ "$1" != "" ]; do
    PARAM=`printf "%s" $1 | awk -F= '{print $1}'`
    VALUE=`printf "%s" $1 | awk -F= '{print $2}'`
    case $PARAM in
        -b | --bootanimation-no-compression)
            aniflags="${aniflags} -n"
            ;;
        -c | --clean)
	    rm -rf "${basepath}"
	    printf "Cleaned build directory \"${basepath}\".\n"
	    exit 0
            ;;
        -f | --force)
            force=1
	    # TODO need an option to force re-build of the bootanimation, but -f isn't it
	    #aniflags="${aniflags} -f"
            ;;
        -h | --help)
            usage
            exit
            ;;
        -l | --clear-cache)
            clear_cache=1
            force=1
            ;;
        -n | --img-no-compression)
            compress=0
            ;;
        -r | --no-build-rkfw)
            build_rkfw=0
            ;;
        -t | --no-build-thumbdrive)
            build_thumb=0
            ;;
        -*)
            printf "ERROR: unknown command line parameter \"${PARAM}\"\n"
            usage
            exit 1
            ;;
         *)
            printf "ERROR: unknown command line parameter \"${PARAM}\"\n"
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root\n"
   printf "Try re-running it as 'sudo $0 $@'\n\n"
   exit 1
fi

# Clear the cache
[ $clear_cache -eq 1 ] && rm -vrf "${cachepath}"

# Make the build directories, if needed
mkdir -pv "${cachepath}" || exit 1
mkdir -pv "${buildpath}" || exit 1
mkdir -pv "${mnt}" || exit 1
mkdir -pv "${anipath}" || exit 1

# Download and unpack the stock image, if needed
[ -f "${stockimg}" ] || [ -f "${stockimg}.zip" ] || wget --no-verbose --show-progress --directory-prefix "${cachepath}" $stockimg_url || exit 1
[ -f "${stockimg}" ] || unzip "${stockimg}.zip" -d "${cachepath}" || exit 1
[ -d "${stockimg}.dump" ] || imgrepackerrk "${stockimg}" || exit 1

# Copy the stock image as our staring image
if [ -d "${tmfimg}.dump" ] ; then
    if [ $force -eq 1 ] ; then
        rm -vrf "${tmfimg}.dump"
        rm -vf "${tmfimg}"
        rm -vf "${tmfimg}.zip"
        rm -vf "${thumbimg}"
        rm -vf "${thumbimg}.zip"
    else
        printf "Directory \"${tmfimg}.dump\" exists.  Try again using the -f/--force commandline option.\n"
        exit 1
    fi
fi
cp -av "${stockimg}.dump" "${tmfimg}.dump"

# mount the system image so we can modify it
mount -v "${sysimg}" "${mnt}" || exit 1

# ** Remove the annoying boot jingle
mv -v "${mnt}/media/audio/boot.ogg" "${mnt}/media/audio/boot.ogg.nothanks"

# ** Install our custom bootanimation
#    - extract the original bootanimation (if needed)
[ -f "${anipath}/bootanimation-orig.zip" ] || cp -v "${mnt}/media/bootanimation.zip" "${anipath}/bootanimation-orig.zip"
#    - create the new bootanimation (if needed)
./bootanimation/mkanimation ${aniflags} -w="${anipath}/tmp" "${anipath}/bootanimation-orig.zip" "${anipath}/bootanimation.zip" "bootanimation/tmf-custom-rom.png"
#    - copy the new bootanimation back to the image
cp -v "${anipath}/bootanimation.zip" "${mnt}/media/bootanimation.zip"

# ** Stop the setup wizard from running
printf "Modifying install-recovery.sh ...\n"
cat SetupWizard/stop-wizard >> "${mnt}/etc/install-recovery.sh"

# ** Remove all non-functional apps
rm -v "${mnt}/app/appupdater.apk"        # Hudl App Updater - One of the sources of call to the defunct Tesco server
rm -v "${mnt}/app/otaclient.apk"         # Hudl OTA Client - Another source of calls to the defunct TEsco server
rm -v "${mnt}/app/otaclient.odex"
rm -v "${mnt}/app/hudlsetup.apk"         # Hudl setup - addd the extra Tesco Account setup pages after the startup Wizard
rm -v "${mnt}/app/hudlsetup.odex"
rm -v "${mnt}/app/blinkboxmovies.apk"    # BlinkBox Movies
rm -v "${mnt}/app/blinkboxmusic.apk"     # BlinkBox Music
rm -v "${mnt}/app/blinkboxwidget.apk"    # BlinkBox Widget
rm -v "${mnt}/app/clubcardtv.apk"        # Club Card TV
rm -v "${mnt}/app/clubcardwidget.apk"    # Club Card Widget
rm -v "${mnt}/app/getstarted.apk"        # Get Started App
rm -v "${mnt}/app/grocery.apk"           # Tesco Groceries
rm -v "${mnt}/app/grocerywidget.apk"     # Tesco Groceries Widget
rm -v "${mnt}/app/storelocator.apk"      # Tesco Store Locator
rm -v "${mnt}/app/tescoaccountapp.apk"   # Tesco Account App
rm -v "${mnt}/app/tescodirectwidget.apk" # Tesco Direct Widget
rm -v "${mnt}/app/tescolauncher.apk"     # Tesco App Launcher

# ** Get rid of the [T] Tesco button from the navigation bar
cp -v SystemUI/SystemUI.apk.new "${mnt}/app/SystemUI.apk"

# ** Put our build info into the build.prop file
# Appears in the settings app: About Tablet -> Build  number field
sed -i -e "s/ro.build.display.id=JDQ39.20140424.153851/ro.build.display.id=TMF Custom ROM v${version} JDQ39.20140424.153851/" "${mnt}/build.prop"

# Pull ro.product.model from build.prop to use later
ro_product_model=`grep 'ro.product.model' "${mnt}/build.prop" | awk -F= '{print $2}'`

# unmount the system image
umount -v "${mnt}"

# create a misc.img that on first boot wipes userdata and cache and then reboots tp get us cleanly into the new
# image
printf "Creating new misc.img ...\n"
rkmisc wipe_all $miscimg >/dev/null 2>&1

# Re-pack the monolithic image and zip it up
if [ $build_rkfw -eq 1 ] ; then
    # Update the "MACHINE_MODEL" to match the ro.product.model from build.prop - this is needed to pass the
    # tests when flasking an RK Image file from an SD Card
    sed -i -e "s/^MACHINE_MODEL:.*$/MACHINE_MODEL:${ro_product_model/" "${tmfimg}.dump/parameter"

    # Pack up the RKFW .img file
    imgrepackerrk "${tmfimg}.dump"

    # ZIP it if unless requested not to
    if [ $compress -eq 1 ] ; then
      ( img=`basename "${tmfimg}"` ; cd "${buildpath}" ; zip -dd -v "${img}.zip" "${img}" )
    fi
fi

# TODO mkthumbdrive should take a parameter for the name of the img it creates
# TODO mkthumbdrive should take an option for the mount path (and use a TMP dir if not supplied)
# Make the flash drive image, if needed
if [ $build_thumb -eq 1 ] ; then
    [ -f "${cachepath}/tmf-hudl-thumb-drive.img" ] || ./thumbdrive/mkthumbdrive.sh thumbdrive "${cachepath}" "${mnt}" || exit 1;

    # Make a copy of the thumbdrive amd push the image parts and flash program into it
    cp -v "${cachepath}/tmf-hudl-thumb-drive.img" "${thumbimg}"

    # mount the thumbdrive image so we can modify it
    loop_device=`losetup --show -f "${thumbimg}"`
    mount -v "${loop_device}p1" "${mnt}"

    # Copy compressed partition images to the thumbdrive
    gzip -cv9 "${tmfimg}.dump/parameter"              >"${mnt}/tce/tmf-hudl/parameter.gz"
    gzip -cv9 "${tmfimg}.dump/Image/boot.img"         >"${mnt}/tce/tmf-hudl/boot.img.gz"
    gzip -cv9 "${tmfimg}.dump/Image/recovery.img"     >"${mnt}/tce/tmf-hudl/recovery.img.gz"
    gzip -cv9 "${tmfimg}.dump/Image/kernel.img"       >"${mnt}/tce/tmf-hudl/kernel.img.gz"
    gzip -cv9 "${tmfimg}.dump/Image/system.img"       >"${mnt}/tce/tmf-hudl/system.img.gz"
    gzip -cv9 "${tmfimg}.dump/Image/misc.img"         >"${mnt}/tce/tmf-hudl/misc.img.gz"
    gzip -cv9 "${tmfimg}.dump/backupimage/backup.img" >"${mnt}/tce/tmf-hudl/backup.img.gz"
    cp -v hudl-flash.sh "${mnt}/tce/tmf-hudl"

    # unmount the thumbdrive image and remove our mount point
    umount -v $mnt
    losetup -d ${loop_device}

    # zip up the thumbdrive img file
    if [ $compress -eq 1 ] ; then
      ( img=`basename "${thumbimg}" .img` ; cd "${buildpath}" ; zip -dd -v "${img}.zip" "${img}.img" )
    fi
fi

# Tidy up
rm -vd "${mnt}"
