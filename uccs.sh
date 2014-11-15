#!/bin/bash
#inroduction
echo "Welcome to the Lanfest Linux server setup wizard"
echo "This script was created by Robert Ainsworth (Ainsey11)"
echo "please ask me before distributing"
echo ""
echo ""
#check if root or not
# Init
FILE="/tmp/out.$$"
GREP="/bin/grep"
#....
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
#make log directory
mkdir /var/log/setup-script/
#set logdir var
logdir=/var/log/setup-script
#find old server name 
oldservername=$(cat /etc/hostname)
#display old server name
echo "The server name is currently : $oldservername"
#ask for new server name
echo "What should the server name be?"
read newservername
#set server name in the correct dirs
echo "changing hostname to : $newservername"
hostname $newservername
sed -i "s/$oldservername/$newservername/g" /etc/hosts
sed -i "s/$oldservername/$newservername/g" /etc/hostname
#display new server name
echo "congrats, your server name is now : $newservername"
echo ""
echo "Press any key to continue"
read -n 1
#line breaks
echo ""
echo ""
echo ""

#perform server updates

echo "Now updating : $newservername's package lists"
apt-get update -qy >>$logdir/packagelist.txt
echo "Now updating $newservername's packages"
echo "Finished!"
apt-get upgrade -y >>$logdir/packageupdate.txt
echo "Finished!"
echo "$newservername has now been fully updated"
echo "press any key to continue"
read -n 1
echo""

#install basic packages

echo "Now installing standard packages"
apt-get install -y vim screen htop iftop iotop iperf openssh-server snmpd curl >> $logdir/packageinstallation.txt
echo "Finished!"
echo""
echo "Press any key to continue"
read -n 1

#set static IP configuration
echo "Setting up networking"
oldnetwork=$(ifconfig | grep "inet addr:")
echo "$newservername's network settings are $oldnetwork "
echo "What IP do you wish to set?"
read newip

#backup old network config and remove
cp /etc/network/interfaces /etc/network/interfaces.old
rm /etc/network/interfaces

#create empty conf file
touch /etc/network/interfaces

#add new IP settings to config file
echo "auto lo
	iface lo inet loopback
	auto eth0
	iface eth0 inet static
	address $newip
	netmask 255.255.255.0
	gateway 192.168.1.1" >> /etc/network/interfaces
echo "Finished!"
echo "Press any key to continue"
read -n 1

#configure snmpd for observium
echo "Downloading SNMP config"
curl http://lanfest.co.uk/scripts/snmpd.conf > /etc/snmp/snmpd.conf
echo "Finished!"
echo "press any key to continue"
read -n 1
echo ""
echo " Please ensure that lanfest-observer-1 is running before continuing and that a DNS record has been created on lanfest-inf-1"
echo "press any key to continue"
read -n 1

#create ssh keys and copy to lanfest-observer-1 for passwordless auth
ssh-keygen -t rsa -b 2048
ssh-copy-id "lanfest@lanfest-observer-1"

#ssh to lanfest-observer-1 and add device
observerserver=$"lanfest-irc-1"
observeraccount=$"lanfest"
"ssh $observeraccount@$observerserver 'cd /var/opt/observium; sudo ./addevice.php -h $newservername ; sudo ./poller.php -h $newservername ; sudo ./discover.php -h $newservername'"
echo "finished!"
echo "Press any key to continue"
read -n 1

#Set up steam tools
echo
echo "Installing SteamCMD"
	# set up steamcmd dirs
	mkdir -p /steam/steamcmd/
	cd /steam/steamcmd/
	#download steamcmd
	wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz >> $logdir/steamdownload.txt
	#extract tool
	tar -xvzf steamcmd_linux.tar.gz > $logdir/steamextract.txt
	#cd to home and finish
	#finish up 
	echo "All configuration complete, press any key to continue"
	read -n 1
echo " $newservername is now configured with the below settings:"
echo " The server name is now $newservername"
echo " The New IP is $newip"
echo " This server has been added onto observium and has passwordless ssh enabled"
echo " This server has also been updated and is fully secure against threats"
echo " Thanks for using this script, logs are in $logdir"
echo " The server is now going to reboot to apply the final settings"
echo " Press any key to continue and reboot"
read -n 1
reboot -n
exit

