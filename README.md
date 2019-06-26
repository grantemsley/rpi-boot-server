# rpi-boot-server
Configure and manage a Ubuntu server for network booting raspberry Pis

The scripts included make it easier manage creating the filesystems for Pis on the server.

Each Pi is assigned it's own folder, no data is shared between them.

Note:  There is no security for the NFS server. Anyone on the network can mount all of the images and write to them. Do not use this on an untrusted network without better securing the NFS exports.

## Installation

Run initial-server-setup.sh to configure the server.  This script:
  * Installs and configures dnsmasq and NFS packages
  * Downloads latest Raspbian image, extracts it, and puts the bootcode.bin file into the TFTP directory
  * Copies management scripts to /usr/local/bin

## Dnsmasq Configuration

Dnsmasq is used as the DHCP and TFTP server.  It is *not* configured to hand out DHCP addresses, only boot information.

The configuration installed will only reply to MAC addresses that start with b8:27:eb, so it will only respond to Raspberry Pis. It shouldn't interfere with any other PXE servers on the network.

## Folder Structure

`/srv/images` holds the extracted SD card images for each OS/image type.  These are used as the base to create new NFS root folders. Any changes you want to make to all Pis that are based on an image can be done in these folders.
`/srv/nfs` has a directory for each Pi's filesystem. These are initially copied from /srv/images, but are unique to each Pi.
`/srv/tftp` has a symlink with the serial number of the Pi to the boot folder of it's assigned image. This is how the images are assigned to that Pi.

## Scripts

### extract-image

Extracts an SD card image.

eg: `extract-image /tmp/raspbian.img Raspbian` will extract the image file `/tmp/rasbian.img` to the folder `/srv/images/Raspbian`

### new-nfsroot

Creates an NFS root folder for a new Pi in /srv/nfs based on an image in /srv/images.
The script will prompt you to select the image and name the new system.

It makes a few changes to the image after copying it:
  * The hostname will be set to match the name specified
  * /boot/cmdline.txt will be overwritten to set the appropriate boot parameters to boot from the correct folder on the NFS share
  * Mountpoints for SD card partitions will be removed
  * SSH will be enabled

### assign-nfsroot

Creates the symlink from `/srv/tftp/<serial number>` to `/srv/nfs/<name>/boot`.

This script parses /var/log/syslog to find the serial number of Pis that have recently attempted to boot.
It will prompt you to select the serial number of a Pi that hasn't been assigned yet, and the image file to assign to it.

If you are replacing a Pi with a new one and want to reuse the existing NFS root, you'll need to delete the symlink in /srv/tftp first.


