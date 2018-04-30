#!/bin/bash
#
# Sets up a LAMP stack environment using CentOS 7, PHP 7, MySQL 5.6, and Apache.
# Also installs PHPUnit and XDebug.
# 
# INSTRUCTIONS FOR USE:
# 1. Copy this shell script to your home directory or the /tmp directory.
# 2. Make it executable with the following command: 
#      chmod a+x CentOS-7_LAMP.sh
# 3. Execute the script as a sudo user:
#      sudo ./CentOS-7_LAMP.sh
#
#
# IMPORTANT: as of this writing on 2015-01-11, this shell script will support
# CentOS 6.4, 6.5, and 7. It has not been tested on a release greater than
# v7. That is 7 flat, not 7.1, 7.x.
#
# If you wish to use this script with a version of CentOS greater than v7 such as
# 7.1 or higher when they come out, you have to edit this script to be sure that the IUS and EPEL
# repositories correctly use the repos needed for newer versions of CentOS. The
# same applies to all other areas in this file where there is a check for an exact
# version of CentOS before doing a download and/or installation.
#

# Since this script needs to be runnable on either CentOS7 or CentOS6, we need to first 
# check which version of CentOS that we are running and place that into a variable.
# Knowing the version of CentOS is important because some shell commands that had
# worked in CentOS 6 or earlier no longer work under CentOS 7
RELEASE=`cat /etc/redhat-release`
isCentOs7=false
isCentOs65=false
isCentOs64=false
isCentOs6=false
SUBSTR=`echo $RELEASE|cut -c1-22`
SUBSTR2=`echo $RELEASE|cut -c1-26`

if [ "$SUBSTR" == "CentOS Linux release 7" ]
then
    isCentOs7=true
elif [ "$SUBSTR2" == "CentOS release 6.5 (Final)" ]
then 
    isCentOs65=true

elif [ "$SUBSTR2" == "CentOS release 6.4 (Final)" ]
then 
    isCentOs64=true
else
    isCentOs6=true
fi

# TODO: add a check for versions earlier than 6.5

if [ "$isCentOs7" == true ]
then
    echo "I am CentOS 7"
elif [ "$isCentOs65" == true ]
then
    echo "I am CentOS 6.5"
elif [ "$isCentOs64" == true ]
then 
    echo "I am CentOS 6.4"
else
    echo "I am CentOS 6"
fi

CWD=`pwd`

# Let's make sure that yum-presto is installed:
sudo yum install -y yum-presto

# Let's make sure that mlocate (locate command) is installed as it makes much easier when searching in Linux:
sudo yum install -y mlocate

# Although not needed specifically for running a LAMP stack, I like to use vim, so let's make sure it is installed:
sudo yum install -y vim

# This shell script makes use of wget, so let's make sure it is installed:
sudo yum install -y wget

# it is important to sometimes work with content in a certain format, so let's be sure to install the following:
sudo yum install -y html2text

# This script makes use of 'sed' so let's make sure it is installed. While
# we're at it, let's also install 'awk'. It's most likely that these packages
# are already installed, but let's be sure. By the way, yes it is 'gawk' as the 
# pacakge name:
sudo yum install -y sed
sudo yum install -y gawk

# Let's make sure that we have the EPEL and IUS repositories installed.
# This will allow us to use newer binaries than are found in the standard CentOS repositories.
# http://www.rackspace.com/knowledge_center/article/install-epel-and-additional-repositories-on-centos-and-red-hat
sudo yum install -y epel-release
if [ "$isCentOs7" != true ]
then
    # The following is needed to get the epel repository to work correctly. Here is
    # a link with more information: http://stackoverflow.com/questions/26734777/yum-error-cannot-retrieve-metalink-for-repository-epel-please-verify-its-path
    sudo sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
fi

if [ "$isCentOs7" == true ]
then
    sudo wget -N http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-13.ius.centos7.noarch.rpm
    sudo rpm -Uvh ius-release*.rpm
else
    # Please note that v6.5, 6.4, etc. are all covered by the following repository:
    sudo wget -N http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm
    sudo rpm -Uvh ius-release*.rpm
fi

# Let's make sure that openssl is installed:
sudo yum install -y openssl

# Let's make sure that curl is installed:
sudo yum install -y curl

# Let's make sure we have a C/C++ compiler installed:
sudo yum install -y gcc

# Let's make sure we have the latest version of bash installed, which
# are patched to protect againt the shellshock bug. Here is an article explaning
# how to check if your bash is vulnerable: http://security.stackexchange.com/questions/68168/is-there-a-short-command-to-test-if-my-server-is-secure-against-the-shellshock-b
sudo yum update -y bash

# Let's make sure that firewalld is installed:
sudo yum install -y firewalld
sudo systemctl start firewalld

# Install and set-up NTP daemon:
if [ "$isCentOs7" == true ]; then
    sudo yum install -y ntp
    sudo firewall-cmd --add-service=ntp --permanent
    sudo firewall-cmd --reload

    sudo systemctl start ntpd
fi

# Let's install our LAMP stack by starting with Apache:
sudo yum install -y httpd mod_ssl openssh
if [ "$isCentOs7" == true ]
then
    sudo systemctl start httpd
else
    sudo service httpd start
fi

# We need to also make sure that ports 80 and 443 are open for the web:
# Port 80:
if [ "$isCentOs7" == true ]
then
    sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
fi

# Port 443:
if [ "$isCentOs7" == true ]
then
    sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
fi

# Install MySQL:
if [ "$isCentOs7" == true ]
then
    sudo yum install -y mariadb-server mariadb
	
    sudo systemctl start mysqld
elif [ "$isCentOs65" == true ]
then
    sudo wget -N https://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm
    sudo yum localinstall -y mysql-community-release-el6-5.noarch.rpm
    sudo yum install -y mysql-community-server

    sudo service mysqld start
elif [ "$isCentOs64" == true ]
then
    sudo wget -N https://repo.mysql.com/mysql-community-release-el6-4.noarch.rpm
    sudo yum localinstall -y mysql-community-release-el6-4.noarch.rpm
    sudo yum install -y mysql-community-server

    sudo service mysqld start
else
    sudo wget -N https://repo.mysql.com/mysql-community-release-el6.rpm
    sudo yum localinstall -y mysql-community-release-el6.rpm
    sudo yum install -y mysql-community-server
    sudo service mysqld start
fi

# We need to edit the my.cnf and make sure that it is using utf8 as the default charset:
MYCNF=`sudo find /etc -name my.cnf -print`
INSERT1='skip-character-set-client-handshake'
INSERT2='collation-server=utf8_unicode_ci'
INSERT3='character-set-server=utf8'
INSERT5="default_time_zone='+08:00'"
# We also want to allow remote connections:
INSERT4='bind-address=127.0.0.1'
sudo sed -i "/\[mysqld\]/a$INSERT1\n$INSERT2\n$INSERT3\n$INSERT4\n$INSERT5" "$MYCNF"
# comment out the statement 'skip-networking' is commented out:
sudo sed -i 's/skip-networking/# skip-networking/' "$MYCNF"

# Make sure that we restart MySQL so the changes take effect 
if [ "$isCentOs7" == true ]
then
    sudo systemctl restart mariadb
else
    sudo service mysqld restart
fi


# Install PHP 7
sudo yum install -y php70u php70u-mysqlnd php70u-cli php70u-bcmath php70u-common php70u-ctype php70u-devel php70u-embedded php70u-enchant php70u-gd php70u-hash php70u-intl php70u-json php70u-ldap php70u-mbstring php70u-odbc php70u-pdo php70u-pear.noarch php70u-pecl-jsonc php70u-pecl-memcache php70u-pgsql php70u-phar php70u-process php70u-pspell php70u-openssl php70u-recode php70u-snmp php70u-soap php70u-xml php70u-xmlrpc php70u-zlib php70u-zip php70u-mcrypt


# Edit the php.ini configuration file and set the default timezone to Asia/Kuala_Lumpur:
MYPHPINI=`sudo find /etc -name php.ini -print`
PATTERN=';date.timezone =';
REPLACEMENT='date.timezone = "Asia/Kuala_Lumpur"'
sudo sed -i "s/$PATTERN/$REPLACEMENT/" "$MYPHPINI"

# Restart Apache
if [ "$isCentOs7" == true ]
then
    sudo systemctl start httpd
else
    sudo service httpd start
fi

# Let's make sure that git is intalled:
sudo yum install -y git

# Setup Swap Space for Server (4GB):
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

# Secure server with Fail2Ban:
sudo yum install fail2ban
sudo systemctl enable fail2ban
MYJAILLOCAL=`sudo find /etc -name jail.local -print`
A1='[DEFAULT]'
A2='# Ban hosts for one month:'
A3='bantime = 2592000'
A4='# Override /etc/fail2ban/jail.d/00-firewalld.conf:'
A5='banaction = iptables-multiport'
A6='[sshd]'
A7='enabled = true'
A8='port = ssh'
A9='logpath = %(sshd_log)s'
sudo sed -i "s/$A1\n$A2\n$A3\n$A4\n$A5\n$A6\n$A7\n$A8\n$A9" "$MYJAILLOCAL"
sudo systemctl restart fail2ban


# Secure MariaDB Installation:
sudo mysql_secure_installation

# Make sure that when the server boots up that both Apache and MySQL start automatically:
if [ "$isCentOs7" == true ]
then
    sudo systemctl enable httpd
    sudo systemctl enable mariadb
	echo "Success Secure MariaDB Installation!!"
	echo ""
else
    sudo chkconfig httpd on
    sudo chkconfig mysqld on
fi

echo ""
echo "Finished with setup!"
echo ""
echo "You can verify that PHP is successfully installed with the following command: php -v"
echo "You should see output like the following:"
echo ""
echo "PHP 7.x.x (cli) (built: Mar 30 2018 09:32:58)"
echo "Copyright (c) 1997-2017 The PHP Group"
echo "Zend Engine v3.0.0, Copyright (c) 1998-2017 Zend Technologies"
echo ""
echo "If you are using CentOS 7, you can restart Apache with this command:"
echo "sudo systemctl restart httpd"
echo ""
echo "The MySQL account currently has no password, so be sure to set one."
echo "You can find info on securing your MySQL installation here: http://dev.mysql.com/doc/refman/5.6/en/postinstallation.html"
echo ""
echo "Happy development!"
echo ""