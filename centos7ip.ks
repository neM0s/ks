# CentOS 7.0 kickstart for XenServer
# branch: develop
##########################################

# Install, not upgrade
install

#logging level for anaconda
# Install from a friendly mirror and add updates
#url --url http://mirror.rackspace.com/CentOS/7.0.1406/os/x86_64/
#repo --name=centos-updates --mirrorlist=http://mirrorlist.centos.org/?release=7.0.1406&arch=x86_64&repo=updates
cdrom

# Language and keyboard setup
lang en_US.UTF-8
keyboard pl2

# Configure networking without IPv6, firewall off

# for STATIC IP: uncomment and configure
 network --onboot=yes --device=eth0 --bootproto=static --ip=192.168.1.39 --netmask=255.255.255.0 --gateway=192.168.1.1 --nameserver=192.168.1.20 --noipv6 --hostname=RamDisk
