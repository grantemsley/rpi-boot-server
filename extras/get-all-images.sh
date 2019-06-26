cd /tmp
echo "Downloading Ubuntu Mate"
wget "https://ubuntu-mate.org/raspberry-pi/ubuntu-mate-18.04.2-beta1-desktop-armhf+raspi-ext4.img.xz"
unxz ubuntu-mate-18.04.2-beta1-desktop-armhf+raspi-ext4.img.xz
extract-image "ubuntu-mate-18.04-2-beta1-desktop-armhf+raspi-ext4.img" "UbuntuMate18.04"
rm /tmp/ubuntu-mate-18.04-2-beta1-desktop-armhf+raspi-ext4.img
rm /tmp/ubuntu-mate-18.04-2-beta1-desktop-armhf+raspi-ext4.img.xz

echo "Downloading Raspbian Stretch Desktop"
wget "http://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/2019-04-08-raspbian-stretch.zip"
unzip 2019-04-08-raspbian-stretch.zip
extract-image "2019-04-08-raspbian-stretch.img" "Raspbian_Stretch_20190408"
rm /tmp/2019-04-08-raspbian-stretch.zip
rm /tmp/2019-04-08-raspbian-stretch.img

echo "Downloading Raspbian Stretch Lite"
wget https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-04-09/2019-04-08-raspbian-stretch-lite.zip
unzip 2019-04-08-raspbian-stretch-lite.zip
extract-image "2019-04-08-raspbian-stretch-lite.img" "Raspbian_Stretch_Lite_20190409"
rm /tmp/2019-04-08-raspbian-stretch-lite.zip
rm /tmp/2019-04-08-raspbian-stretch-lite.img

echo "Downloading OctoPi 3D Printer OS"
wget https://octopi.octoprint.org/latest -O octopi.zip
unzip octopi.zip
extract-image *octopi*.img OctoPI
rm /tmp/octopi.zip
rm /tmp/*octopi*.img

echo "Downloading RetroPi"
wget https://github.com/RetroPie/RetroPie-Setup/releases/download/4.4/retropie-4.4-rpi2_rpi3.img.gz
gunzip retropi-4.4-rpi2_rpi3.img.gz
extract-image retropie-4.4-rpi2_rpi3.img RetroPi_4.4_for_RPI2-3
rm /tmp/retropi*






