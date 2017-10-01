#!/bin/bash
#========================================================================
#Genereal Info
#========================================================================
# Run this Script with ./install.sh username_forservice password_for_this_user
# example ./install.sh dangerough '!e$m%p(e)or_1n2o3r4t5on'
# (c) Dangerough 
# How this Script works:
# Edit OS_independent_packages, centos_packages and debian_packages - the packages which should be installed
# Then edit config sections and startup sections...
# WARNING permissions need to be changed in line 55, SE Linux is disabled by this script (!!!)
#========================================================================
# Prerequsities, needed files:
#========================================================================
# Unreal IRCd Files:
# main configuration file 	/tmp/unrealircd.conf 
# message of the day		/tmp/motd.conf
#========================================================================
# TOR Files
# TOR Repository for CentOS	
# CentOS 6 Repo File	/tmp/myCentOS6.repo
# CentOS 7 Repo File	/tmp/myCentOS7.repo
# TOR Repository for Debian /tmp/sources-list
# torrc 					/tmp/torrc
# private_key				/tmp/private_key
# hostname				    /tmp/hostname
#========================================================================
# Apache Files for Debian
# apache2.conf				/tmp/apache2.conf
# apache2.conf				/tmp/ports.conf
# Apache Files for RHEL
# httpd.conf				/tmp/httpd.conf
# ssl.conf					/tmp/ssl.conf
# The HTTP Site:
# ../www/...				/tmp/www/
#========================================================================
MAILTO="marcel@codemagic.net"
#========================================================================
echo "Description: - Dangerough IRCD Installation "
echo "Installs sharlote, TOR, apache/httpd and unrealircd"
#========================================================================
#Configure logging
fileName="install_ircd$$.log"
working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script is running from $working_dir"
if [ -f $working_dir/install_ircd$$.log ]
	then
	echo "removing old logfile"
rm $fileName
fi
echo "Creating new Logfile"
# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee $fileName)
# Without this, only stdout would be captured - no STDERR
exec 2>&1
echo "#========================================================================"
echo "Setup extra service account:"
echo "#========================================================================"
echo "checking if user is root"
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
echo "Please enter extra service user:"
#read user
user=$1
echo "Please enter service user password:"
#read password
password=$2
echo "$user with the password $password will be created and added to the sudoers file WRNING permissions have to be changed"
#read -p "Press [Enter] key if you have understood to create user..."
#$user = dangerough
#$password = "!e$m%p(e)or_1n2o3r4t5on"
useradd -m $user
echo -e "$password\n$password\n" | sudo passwd $user
# Worked only on Debian not on centos, lower solution should work on both
# adduser $user sudo
echo "$user ALL=(ALL:ALL) ALL" >> /etc/sudoers


echo "#========================================================================"
echo "Getting prerequisites: running on a RHEL or debian?"
echo "#========================================================================"
#Comment this out if you experience problem to let user manually choose OS-type
#read -n 1 -p "Pres d for debian or r for rhel " ans;
#case $ans in
#    d|D)
#      	installer="apt-get" 
#		system="debian"
#		;;
#   r|R)
#     	installer="yum" 
#	system="redhat"
#	;;
#    *)  echo "error"
#        exit;;
#esac
#echo " "


OS_CHECK=$(python -c "import platform;print(platform.platform())")
if [ "$OS_CHECK" == "Linux-2.6.32-042stab108.2-x86_64-with-centos-6.7-Final" ]
  then
     	installer="yum" 
		system="redhat"
		sudo setenforce 0
fi

if [ "$OS_CHECK" == "Linux-3.13.0-042stab108.7-x86_64-with-Ubuntu-14.04-trusty" ]
  then
     	installer="apt-get" 
		system="debian"
fi


echo "You have chosen to run $installer on a $system "
echo "#========================================================================"
echo "#========================================================================"
echo "#Adding Public Keys for repositories: TOR"
echo "#========================================================================"

if [ "$system" == "debian" ]
  then
echo "Adding Public Keys for repositories: TOR"
gpg --keyserver keys.gnupg.net --recv 886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
fi



#========================================================================
# Configure and install software packages: Don't forget the space between the packages / end of line
#========================================================================
debian_packages="tor deb.torproject.org-keyring "  #TOR packages
debian_packages+="build-essential libcurl4-openssl-dev libcurl4-openssl-dev zlib1g zlib1g-dev zlibc libgcrypt11 libgcrypt11-dev"      #Unreal IRCD Prerequisites   
debian_packages+="apache2 "     #Apache / httpd
#========================================================================
centos_packages="httpd " #Apache / httpd
centos_packages="mod_ssl openssl " # SSL for httpd
centos_packages+="libevent.x86_64 " #TOR Dependecies
centos_packages+="tor " #TOR itself
#========================================================================
OS_independent_packages="wget openssl make gcc " #general tools
#========================================================================
#read -p "Press [Enter] key if you have understood to start installing software packages..."
echo "#========================================================================"
echo "following OS_independent_packages packages are known and will be installed: $OS_independent_packages"
if [ "$system" == "debian" ]
  then
echo "following debian packages are known and will be installed: $debian_packages"
$installer update
$installer install $OS_independent_packages
$installer install $debian_packages
fi

if [ "$system" == "redhat" ]
  then
echo "following centos packages are known and will be installed: $centos_packages"
$installer -y update
$installer -y install $OS_independent_packages
$installer -y install $centos_packages
fi
echo "#========================================================================"
echo "prerequisisites finished"
echo "#========================================================================"
echo ""
echo "#========================================================================"
echo "#Configuring Webserver"
echo "#========================================================================"
if [ "$system" == "debian" ]
  then
  echo "copying apache2 config for debian"
  cp /tmp/apache2.conf /etc/apache2/
  cp /tmp/ports.conf /etc/apache2/
fi

if [ "$system" == "redhat" ]
  then
  echo "copying apache2 config for RHEL"
  cp -avr /tmp/httpd.conf /etc/httpd/conf/
  cp -avr /tmp/ssl.conf /etc/httpd/conf.d/
fi
echo "copying website"
cp -avr /tmp/www /var
echo "#========================================================================"
echo "#Configuring unrealircd"
echo "#========================================================================"
echo "Warning: If you experience any Problems: Remote includes NO - ZIPLINKS NO"
#read -p "Press [Enter] key to wget UNREAL IRCD and start installation config..."
echo "#========================================================================"
sudo -u $user -H sh -c "cd ~;wget https://www.unrealircd.org/downloads/Unreal3.2.10.5.tar.gz;tar zxvf Unreal3.2.10.5.tar.gz;cd Unreal3.2.10.5;./Config;"
rm Unreal3.2.10.5.tar.gz
echo "installation config finished"
echo "if the installation was succesfull a makefile will be generated otherwise run ./Config again"
#read -p "Press [Enter] key to make / make install UnrealIRCd"
echo "#========================================================================"
sudo -u $user -H sh -c "cd ~;cd Unreal3.2.10.5;make;make install;"
echo "make and make install finished"
echo "#========================================================================"
#read -p "Press [Enter] key to copy config files"
#cp ~/Unreal3.2.10.5/doc/example.conf ~/Unreal3.2.10.5/unrealircd.conf
#vim ~/Unreal3.2.10.5/unrealircd.conf
cp -avr /tmp/unrealircd.conf /home/$user/Unreal3.2.10.5/unrealircd.conf
cp -avr /tmp/motd.conf /home/$user/Unreal3.2.10.5/motd.conf
#read -p "Press [Enter] key to create selfsigned SSL certificate"
openssl req -x509 -newkey rsa:2048 -keyout server.key.pem -out server.cert.pem
echo ""
echo "#========================================================================"
echo "#Configuring TOR"
echo "#========================================================================"
if [ "$system" == "debian" ]
  then
echo "Adding repository to sources.list"
#vi /etc/apt/source.list
#deb http://deb.torproject.org/torproject.org sid main
#deb-src http://deb.torproject.org/torproject.org sid main
#deb http://deb.torproject.org/torproject.org jessie main
#deb-src http://deb.torproject.org/torproject.org jessie main
#Debian trusty sources eintragen
#deb http://deb.torproject.org/torproject.org trusty main
#deb-src http://deb.torproject.org/torproject.org trusty main
echo "http://deb.torproject.org/torproject.org" | sudo tee -a /etc/apt/sources.list
fi

if [ "$system" == "redhat" ]
  then
#Fedora 21/22 and EL6/7 packages
#For Fedora 21, Fedora 22, RHEL 6, RHEL 7 (and clones), use following repo file - substitute DISTRIBUTION with one of the following: fc/21, fc/22, el/6, el/7 according to your distribution.
if [ "$OS_CHECK" == "Linux-2.6.32-042stab108.2-x86_64-with-centos-6.7-Final" ]
  then
    cp -avr /tmp/myCentOS6.repo /etc/yum.repos.d/myCentOS6.repo 
  else
	cp -avr /tmp/myCentOS7.repo /etc/yum.repos.d/myCentOS7.repo 
fi
yum -y clean all
yum -y clean expire-cache 
sudo $installer -y install $OS_independent_packages
sudo $installer -y install $centos_packages;
fi

echo "copy torrc Tor Config File"
cp -avr /tmp/torrc /etc/tor/torrc 
#vi /etc/tor/torrc
echo "creating hidden service directory - has to match torrc file"
mkdir /home/$user/hidden_service
cd /home/$user/
mkdir /home/$user/hidden_service/$user
echo "copying keyfiles"
cp -avr /tmp/private_key /home/$user/hidden_service/$user/private_key
cp -avr /tmp/hostname /home/$user/hidden_service/$user/hostname 
echo "#========================================================================"
echo "#Configuring Shalloth"
echo "#========================================================================"
sudo -u $user -H sh -c "cd ~;wget https://github.com/katmagic/Shallot/archive/master.zip;unzip master.zip -d Shallot;cd Shallot;cd Shallot-master;./configure && make"
rm master.zip
echo "#========================================================================"
echo "Starting up installed services"
echo "#========================================================================"
echo "Starting webserver"
echo "#========================================================================"
if [ "$system" == "debian" ]
	then
		sudo -u $user service apache2 start
	elif [ "$system" == "redhat" ]
	then
		sudo -u $user -H sh -c "sudo service httpd start;"
	else
		echo "ERROR OS not defined"
fi
echo "#========================================================================"
echo "Starting Unrealircd"
echo "#========================================================================"
sudo -u $user -H sh -c "cd ~;cd Unreal3.2.10.5;./unreal start;"
echo "#========================================================================"
echo "Starting TOR Service"
echo "#========================================================================"
if [ "$system" == "debian" ]
	then
		sudo -u $user tor
	elif [ "$system" == "redhat" ]
	then
		sudo -u $user -H sh -c "sudo service tor start;"
	else
		echo "ERROR OS not defined"
fi
echo "#========================================================================"
echo "Starting shallot"
echo "#========================================================================"
echo "ENTER:"
echo "cd /home/$user/Shallot"
echo "sudo -u $user ./shallot -d -f onionirc ^onionirc  - crack an adress onionirc* and save it to a file called onionirc"
echo "#========================================================================"
echo "#Sending LOG to $MAILTO"
echo "#========================================================================"
cd /tmp
echo "sending log via mail"
mail -s "$fileName" $MAILTO < $fileName
#Remove File because of cleartext password logged
if [ -f $working_dir/install_ircd$$.log ]
	then
rm $fileName
fi
echo "#========================================================================"
echo "Installation finished - have a nice day"
echo "#========================================================================"