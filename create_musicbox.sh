#!/bin/bash

# build your own Pi MusicBox.
# reeeeeeaaallly alpha.

#Install the packages you need to continue:
apt-get update && apt-get --yes --no-install-suggests --no-install-recommends install sudo wget unzip mc

#Next, issue this command to update the distribution. 
#This is good because newer versions have fixes for audio and usb-issues:

apt-get dist-upgrade -y

#Next, configure the installation of Mopidy, the music server that is the heart of MusicBox.
wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list

#Then install all packages we need with this command:

sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install logrotate mopidy alsa-utils python-cherrypy3 python-ws4py wpasupplicant python-spotify gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base python-pylast cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update linux-wlan-ng alsa-firmware-loaders iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-ralink firmware-realtek zd1211-firmware linux-wlan-ng-firmware alsa-firmware-loaders hostapd isc-hdcp-server 

#**Configuration and Files**
cd /opt

#update time, just to be sure
ntpdate -u ntp.ubuntu.com

#Get the files of the Pi MusicBox project
wget https://github.com/woutervanwijk/Pi-MusicBox/archive/master.zip

#Unpack the zip-file and remove it if you want.
unzip master.zip
rm master.zip

#Then go to the directory which you just unpacked, subdirectory ‘filechanges’:
cd Pi-MusicBox-master/filechanges

#Now we are going to copy some files. Backup the old ones if you’re not sure!
#This sets up the boot and opt directories:
mkdir /boot/config
cp boot/config/settings.ini /boot/config/
cp opt/* /opt

#Make the system work:

cp etc/rc.local /etc
cp etc/avahi/services/* /etc/avahi/services/
cp etc/samba/smb.conf /etc/samba
cp etc/modules /etc
cp etc/network/* /etc/network/
ln -sf /etc/network/inferfaces-dhcp /etc/network/interfaces
cp etc/default/* /etc/default/
cp etc/dhcp/dhcpd.conf /etc/dhcp/
mkdir /etc/hostapd
cp etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
cp usr/sbin/hostapd /usr/sbin/hostapd
mkdir /etc/firewall
cp etc/firewall/* /etc/firewall

#**Install webclient**

cd /opt

#Get the webclient from github:
wget https://github.com/woutervanwijk/Mopidy-Webclient/archive/master.zip
#Unpack and copy:
unzip master.zip
rm master.zip

cd Mopidy-Webclient-master/
cp -R webclient /opt

#Next, create a symlink from the package to the /opt/defaultwebclient. This is done because you could install other webclients and just point the link to the newly installed client:
ln -s /opt/webclient /opt/defaultwebclient

#**Add the MusicBox user**
#Mopidy can run under the user musicbox. Add it.

useradd -m musicbox
passwd musicbox

#Add the user to the group audio:
usermod -a -G audio musicbox
#Create a couple of directories inside the user dir:
mkdir -p /home/musicbox/.config/mopidy
mkdir -p /home/musicbox/.cache/mopidy
mkdir -p /home/musicbox/.local/share/mopidy
chown -R musicbox:musicbox /home/musicbox

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
mkdir -p /music/local
mkdir -p /music/network
chmod -R 777 /music
chown -R musicbox:musicbox /music

#Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):
update-rc.d ssh disable

#**AirTunes**
#For AirPlay/AirTunes audio streaming, you have to compile and install Shairport. First issue this command to install the libraries needed to build it:

sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install libcrypt-openssl-rsa-perl libio-socket-inet6-perl libwww-perl

cd ~
#Build an updated version of Perl-Net
git clone https://github.com/njh/perl-net-sdp.git perl-net-sdp
cd perl-net-sdp
perl Build.PL
sudo ./Build
sudo ./Build test
sudo ./Build install

#Build Shairport:
cd ..
git clone https://github.com/hendrikw82/shairport.git
cd shairport
make

#Next, move the new shairport directory to /opt
mv shairport /opt

#Finally, copy libao.conf from the Pi MusicBox files to /etc :
cp /opt/Pi-MusicBox-master/filechanges/etc/libao.conf /etc

#**Optimizations**
#For the music to play without cracks, you have to optimize your system a bit. 
#For MusicBox, these are the optimizations:

#**USB Fix**
#It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc), 
# it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio 
# at high nitrates interferes with the ethernet activity, which also runs over USB. 
# These options are added at the beginning of the cmdline.txt file in /boot
sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt 

#cleanup
apt-get autoremove
apt-get clean
apt-get autoclean

#other options to be done by hand. Won't do it automatically on a running system

exit
