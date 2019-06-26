#!/bin/bash
set -euo pipefail

# Get system configuration information
HOSTNAME=$(hostname -s);
IPADDRESS=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{print $2}')
NETMASK=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{print $4}')
SCRIPTDIR=$(pwd)

# Set apt to not expect keyboard input
export DEBIAN_FRONTEND=noninteractive


# Write function will echogreen colored text
green=$(tput setaf 2)
bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)

function echogreen() {
    echo "${green}${bold}$1${normal}"
}

########################################################################################################################
####                             BEGIN SETUP FUNCTIONS                                                               ###
########################################################################################################################

function _installpackages() {
    echogreen "Installing packages for dnsmasq and nfs server..."
    apt-get -y -f install dnsmasq nfs-kernel-server nfs-common unzip wget kpartx
    #apt-get install qemu qemu-user-static binfmr-support 
}

function _makedirectories() {
    echogreen "Making directories in /srv"
    if [[ ! -d /srv/tftp ]]; then mkdir /srv/tftp; fi
    if [[ ! -d /srv/nfs ]]; then mkdir /srv/nfs; fi
    if [[ ! -d /srv/images ]]; then mkdir /srv/images; fi
}

function _configurednsmasq() {
    echogreen "Configuring Dnsmasq to respond only to Raspberry Pis"
    sed -e "s/{IPADDRESS}/${IPADDRESS}/" -e "s/{NETMASK}/${NETMASK}/" ${SCRIPTDIR}/config/rpiboot > /etc/dnsmasq.d/rpiboot

}

function _downloadraspbian() {
    echogreen "Downloading latest Raspbian Lite image (this may take a few minutes)"
    wget https://downloads.raspberrypi.org/raspbian_lite_latest -O /tmp/raspbian_lite_latest.zip
    #cp /root/raspbian_lite_latest /tmp/raspbian_lite_latest.zip

    echogreen "Unzipping image to /srv/images"
    unzip -uo /tmp/raspbian_lite_latest.zip -d /srv/images
    rm /tmp/raspbian_lite_latest.zip

}

function _extractimage() {
    # Find the newest image file
    IMAGEFILE=$(ls -t /srv/images/*.img | head -1)
    echogreen "Latest image file found at ${IMAGEFILE}"

    IMAGEDIR="/srv/images/$(basename ${IMAGEFILE} .img)"
    if [[ -d "${IMAGEDIR}" ]]; then
        echo "${IMAGEDIR} already exists. Skipping extracting image."
    else
        mkdir "${IMAGEDIR}"

        echogreen "Mounting and extracting ${IMAGEFILE} to ${IMAGEDIR}"
        if [[ ! -d /tmp/root ]]; then mkdir /tmp/root; fi
        if [[ ! -d /tmp/boot ]]; then mkdir /tmp/boot; fi
        kpartx -s -a -r -v "${IMAGEFILE}"

        LOOPDEV=$(losetup -j "${IMAGEFILE}" | sed -n 's/.*\(loop[0-9]\).*/\1/p')
        mount "/dev/mapper/${LOOPDEV}p1" /tmp/boot
        mount "/dev/mapper/${LOOPDEV}p2" /tmp/root
    
        echogreen "Copying image files to ${IMAGEDIR}"
        rsync -aAX --numeric-ids /tmp/root/ "${IMAGEDIR}"
        rsync -aAX --numeric-ids /tmp/boot/ "${IMAGEDIR}/boot"

        echogreen "Unmounting ${IMAGEFILE}"
        umount /tmp/boot
        umount /tmp/root
        rmdir /tmp/boot
        rmdir /tmp/root
        kpartx -s -d "${IMAGEFILE}"
    fi

    echogreen "Copying bootcode.bin from ${IMAGEDIR}/boot to tftp root"
    cp "${IMAGEDIR}/boot/bootcode.bin" /srv/tftp/

}

function _configurenfs() {
    echogreen "Exporting /srv/nfs as an NFS share"
    if grep -Fxq "/srv/nfs *(rw,sync,no_subtree_check,no_root_squash)" /etc/exports 
    then
        echo "/srv/nfs is already exported"
    else
        echo "/srv/nfs *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    fi

}

function _restartservices() {
    echogreen "Restarting Dnsmasq"
    service dnsmasq restart
    echogreen "Updating NFS exports"
    exportfs -a -r -v

}

function _copyscripts() {
    echogreen "Copying scripts to /usr/local/bin"
    cp $SCRIPTDIR/scripts/* /usr/local/bin/
}


###############
# Main script #
###############

# Make sure running as root
if [[ $EUID != 0 ]]; then
    echo "${red}This script must be run with root privileges.${normal}"
    echo "Exiting..."
    exit 1
fi

# Allow calling a specific function from the command line
if [ $# -eq 1 ]; then
    echo "Argument supplied.  Running function..."
    "$@"
else
    _installpackages
    _makedirectories
    _configurednsmasq
    _downloadraspbian
    _extractimage
    _configurenfs
    _restartservices
    _copyscripts
    
    echo
    echo
    echo "Server is ready to start network booting Raspberry Pis."
    echo 
    echo "Use 'extract-image <image file> <name>' to extract SD card images to /srv/images"
    echo "Use 'new-nfsroot' to copy an extracted image to /srv/nfs to create the filesystem for a specific Pi."
    echo "Use 'assign-nfsroot' to assign that images to a Pi. You must attempt network booting the Pi first so the serial number can be detected."
fi




