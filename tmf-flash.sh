#!/bin/sh
############################################################
# Flash TMF Custom ROM to Hudl 1
# (c) Robert May, 2020
############################################################
# ./tmf-flash.sh [-f | --force] [-d | --dry-run] [-p | --partial] <img-dir>
############################################################

force=0
dry_run=0
partitions="boot recovery kernel system misc backup"
imgdir=

usage()
{
    printf "\n"
    printf "$0 [-d | --dry-run] [-f | --force] [-p | --partial] <img-dir>\n\n"

    printf "\t-h --help\tPrint this help\n"
    printf "\t-d --dry-run\tdon't need a device connected or actually flash\n"
    printf "\t-f --force\tDon't print all the verbose information or require answers to proceed\n"
    printf "\t-p --partial\tonly flash the system and misc partitions\n\n"

    printf "<img-dir> is the directory that will be searched for image files of the form\n"
    printf "xxx.img.  xxx is one or more of:\n"
    printf "boot recovery kernel system misc backup\n\n"
}

if [ $# -lt 1 ] ; then
    printf "ERROR: missing mandatory command line option. (Got $# expected 1).\n"
    usage
    exit 1
fi
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
	    exit
            ;;
        -d | --dry-run)
	    dry_run=1
            ;;
        -f | --force)
	    force=1
            ;;
        -p | --partial)
	    partitions="system misc"
            ;;
        -*)
            printf "ERROR: unknown command line parameter \"${PARAM}\"\n"
            usage
            exit 1
            ;;
         *)
            if [ $# -ne 1 ] ; then
                printf "ERROR: wrong number of arguements. Got: $# Expecting: 1\n"
                usage
                exit 1
            fi
            if [ ! -d $PARAM ] ; then
                printf "ERROR: not a directory: \"$PARAM\""
                usage
                exit 1
            fi
            imgdir=$PARAM
            ;;
    esac
    shift
done

if [ $dry_run -eq 1 ] ; then
	printf "dry-run=${dry_run} force=${force} partitions=$partitions}\n"
	printf "imgdir=${imgdir}\n"
fi

# ANSI COLORS
RED="$(printf '\033[1;31m')"
GREEN="$(printf '\033[1;32m')"
YELLOW="$(printf '\033[1;33m')"
MAGENTA="$(printf '\033[1;35m')"
NORMAL="$(printf '\033[0;39m')"

if [ $force -ne 1 ] ; then
    clear
    printf "${GREEN}############################################################${NORMAL}\n"
    printf "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}\n"
    printf "${GREEN}############## Step 1/5: Accept Liability     ##############${NORMAL}\n"
    printf "${GREEN}############################################################${NORMAL}\n\n"

    printf "${GREEN}This program will flash the TMF Custom ROM to a Hudl 1${NORMAL}\n"
    printf "${GREEN}device.   Abort at any time by pressing <CTRL-C>.${NORMAL}\n\n"

    printf "${RED}* WARNING: All at your own risk.  Make sure you have read the${NORMAL}\n"
    printf "${RED}* documentation and understand what you are doing before${NORMAL}\n"
    printf "${RED}* continuing.${NORMAL}\n\n"

    printf "${YELLOW}I understand what I'm doing and accept full responsibility${NORMAL}\n"
    printf "${YELLOW}for anything bad that happens (y/N): ${NORMAL}"
    read answer
    if [ "$answer" != "y" ] ; then exit ; fi

    clear
    printf "${GREEN}############################################################${NORMAL}\n"
    printf "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}\n"
    printf "${GREEN}############## Step 2/5: Connect Hudl         ##############${NORMAL}\n"
    printf "${GREEN}############################################################${NORMAL}\n\n"

    printf "${GREEN}Connect your Hudl to a USB port on this computer and then,${NORMAL}\n"
    printf "${GREEN}while holding the vol+ key on the Hudl, press and release${NORMAL}\n"
    printf "${GREEN}the Hudl's reset button with a paper clip (through the small${NORMAL}\n"
    printf "${GREEN}hole on the back cover near the power and volume buttons).${NORMAL}\n"
    printf "${GREEN}Keep re-trying the vol+/reset action until the device is${NORMAL}\n"
    printf "${GREEN}recognised as being in flash mode.${NORMAL}\n\n"
fi

printf "${MAGENTA}Waiting for Hudl to be connected ...${NORMAL}\n"

hudl_connected_flash_mode=0
hudl_connected_other_mode=0

if [ $dry_run -ne 1 ] ; then
    while [ $hudl_connected_flash_mode -eq 0 ]
    do
        if [ $force -ne 1 ] ; then
            lsusb -d0e79: 1>/dev/null 2>&1
            if [ $? -eq 0 ] ; then
                if [ $hudl_connected_other_mode -eq 0 ] ; then
                    printf "${RED}Hudl connected but not in flash mode ...${NORMAL}\n"
                fi
                hudl_connected_other_mode=1
            else
                if [ $hudl_connected_other_mode -eq 1 ] ; then
                    printf "${RED}Hudl disconnected ...${NORMAL}\n"
                fi
                hudl_connected_other_mode=0
            fi
        fi

        lsusb -d2207:310b 1>/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            hudl_connected_flash_mode=1
        else
            sleep .5
        fi
    done
fi
printf "${MAGENTA}... Hudl connected in flash mode.${NORMAL}\n\n"

if [ $force -ne 1 ] ; then
    printf "${GREEN}Your Hudl is now connected in flash mode.  You can let go${NORMAL}\n"
    printf "${GREEN}of the vol+ button.${NORMAL}\n\n"

    printf "${YELLOW}Are you ready to flash your Hudl with the TMF Custom${NORMAL}\n"
    printf "${YELLOW}ROM? (y/N): ${NORMAL}"
    read answer
    if [ "$answer" != "y" ] ; then exit ; fi

    clear
    printf "${GREEN}############################################################${NORMAL}\n"
    printf "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}\n"
    printf "${GREEN}############## Step 3/5: Flashing the ROM     ##############${NORMAL}\n"
    printf "${GREEN}############################################################${NORMAL}\n\n"

    printf "${GREEN}Flashing your Hudl will take about 5 minutes, but this script${NORMAL}\n"
    printf "${GREEN}will wait after flashing so feel free to go and make a cup${NORMAL}\n"
    printf "${GREEN}of tea.${NORMAL}\n\n"
fi

printf "${MAGENTA}Checking communications with the device ... ${NORMAL}"
can_flash=0
if [ $dry_run -ne 1 ] ; then
    rkflashtool v 2>&1 | grep 'chip version' 1>/dev/null 2>&1 && can_flash=1
else
    can_flash=1
fi

if [ $can_flash -eq 0 ] ; then printf "${RED}NOT OK${NORMAL}\n" ; exit 1 ; fi
printf "${GREEN}OK${NORMAL}\n\n"

if [ $force -ne 1 ] ; then
    printf "${MAGENTA}Starting to flash.${NORMAL}\n"
fi

# TODO - should we read the existing parameters and do some sanity check?

printf "${MAGENTA}Flashing parameter block ...${NORMAL}\n"
# FIXME: next line can return more than one match
file=`find "${imgdir}" -name "parameter" -print -o -name "parameter.gz" -print`
ext=${file##*.}
if [ $dry_run -ne 1 ] ; then
    if [ "${ext}" = "gz" ] ; then
        #zcat "${IMGDIR}/parameter.gz"    | rkflashtool P          2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
        zcat "${file}" | rkflashtool P
    else
        rkflashtool P <"${file}"
    fi
    printf "\n"
else
    printf "Would flash parameter block from ${file} (ext: \"${ext}\")\n\n"
fi

for p in $partitions ; do
    printf "${MAGENTA}Flashing ${p} partition ...${NORMAL}\n"

    # Find the right image file
    # FIXME: next line can return more than one match
    file=`find "${imgdir}" -name "${p}.img*" -print`
    ext=${file##*.}
    if [ $dry_run -ne 1 ] ; then
        if [ "${ext}" = "gz" ] ; then
            #zcat "${file}"     | rkflashtool w ${p}     2>&1 | tr '\r' '\n' | grep writing | tr '\n' '\r'
            zcat "${file}" | rkflashtool w ${p}
            printf "\n"
        else
            rkflashtool w ${p}  <"${file}"
        fi
    else
        printf "Would flash ${file} to the ${p} partition (ext: \"${ext}\")\n\n"
    fi
done

if [ $force -ne 1 ] ; then
    printf "${MAGENTA}Flash completed.${NORMAL}\n\n"

    printf "${GREEN}Your Hudl now needs to be rebooted.${NORMAL}\n\n"

    printf "${YELLOW}Press <Enter> to reboot your hudl: ${NORMAL}"
    read answer

    clear
    printf "${GREEN}############################################################${NORMAL}\n"
    printf "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}\n"
    printf "${GREEN}############## Step 4/5: Reboot Hudl          ##############${NORMAL}\n"
    printf "${GREEN}############################################################${NORMAL}\n\n"
fi

printf "${MAGENTA}Rebooting ...${NORMAL}\n\n"
if [ $dry_run -ne 1 ] ; then
    rkflashtool b 1>/dev/null 2>&1
fi

if [ $force -ne 1 ] ; then
    printf "${GREEN}Your Hudl will now boot into recovery mode and will${NORMAL}\n"
    printf "${GREEN}automatically clear all userdata(/data) and caches(/cache).${NORMAL}\n"
    printf "${GREEN}It will then reboot again and should start up normally.${NORMAL}\n"
    printf "${GREEN}This boot may take longer than you are used to, please${NORMAL}\n"
    printf "${GREEN}be patient.${NORMAL}\n\n"

    printf "${GREEN}It may look like nothing is happening for a while, but${NORMAL}\n"
    printf "${GREEN}you shoud see the recovery screen with messages about${NORMAL}\n"
    printf "${GREEN}'Formatting ...' and then a restart which shows the Hudl${NORMAL}\n"
    printf "${GREEN}splashscreen.${NORMAL}\n\n"

    printf "${YELLOW}Once the reboot has finished press <Enter> for the${NORMAL}\n"
    printf "${YELLOW}post-install steps: ${NORMAL}"
    read answer

    clear
    printf "${GREEN}############################################################${NORMAL}\n"
    printf "${GREEN}############## Flash TMF Custom ROM to Hudl 1 ##############${NORMAL}\n"
    printf "${GREEN}############## Step 5/5: Post Install Config  ##############${NORMAL}\n"
    printf "${GREEN}############################################################${NORMAL}\n\n"

    printf "${GREEN}POST INSTALL STEPS${NORMAL}\n\n"

    printf "${GREEN}1. Use settings to set up wifi.${NORMAL}\n"
    printf "${GREEN}2. Use settings to validate location settings.${NORMAL}\n"
    printf "${GREEN}3. Use settings to add a Google account.${NORMAL}\n"
    printf "${GREEN}4. Use Play Store to update apps, including Google${NORMAL}\n"
    printf "${GREEN}   Play Services${NORMAL}\n\n"

    printf "${GREEN}You should now have a functioning Hudl.  Enjoy it :-)${NORMAL}\n\n"

    printf "${YELLOW}Press <Enter> to finish: ${NORMAL}"
    read answer
fi
# TODO set imgdir on the commandline from the enclosing script
#TCEDIR=`readlink /etc/sysconfig/tcedir`
#IMGDIR="${TCEDIR}/tmf-flash"


# Move this to the enclosing shell TODO
#echo
#echo "${GREEN}This macine will now shut down.  Once the screen goes${NORMAL}"
#echo "${GREEN}blank it is safe to remove your USB drive.${NORMAL}"

#sudo poweroff
