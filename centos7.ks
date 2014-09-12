# CentOS 7.0 kickstart for XenServer
# branch: develop
##########################################

# Install, not upgrade
install

#logging level for anaconda
logging --level=warning

# Install from a friendly mirror and add updates
#url --url http://mirror.rackspace.com/CentOS/7.0.1406/os/x86_64/
#repo --name=centos-updates --mirrorlist=http://mirrorlist.centos.org/?release=7.0.1406&arch=x86_64&repo=updates
cdrom

# Language and keyboard setup
lang en_US.UTF-8
keyboard pl2

# Configure networking without IPv6, firewall off

# for STATIC IP: uncomment and configure
network --onboot=yes --device=eth0 --bootproto=static --ip=192.168.1.38 --netmask=255.255.255.0 --gateway=192.168.1.1 --nameserver=192.168.1.1 --noipv6 --hostname=RamDisk

# for DHCP:
#network --bootproto=dhcp --device=eth0 --onboot=on

firewall --enabled --ssh

# Set timezone
timezone --utc Europe/Warsaw

# Authentication
#rootpw --lock
# if you want to preset the root password in a public kickstart file, use SHA512crypt e.g.
#rootpw --iscrypted $6$9dC4m770Q1o$FCOvPxuqc1B22HM21M5WuUfhkiQntzMuAV7MY0qfVcvhwNQ2L86PcnDWfjDd12IFxWtRiTuvO/niB0Q3Xpf2I.
rootpw --plaintext changeme
#user --name=centos --password=Asdfqwerty --plaintext --gecos="CentOS User" --shell=/bin/bash --groups=user,wheel
# if you want to preset the user password in a public kickstart file, use SHA512crypt e.g.
# user --name=centos --password=$6$9dC4m770Q1o$FCOvPxuqc1B22HM21M5WuUfhkiQntzMuAV7MY0qfVcvhwNQ2L86PcnDWfjDd12IFxWtRiTuvO/niB0Q3Xpf2I. --iscrypted --gecos="CentOS User" --shell=/bin/bash --groups=user,wheel
authconfig --enableshadow --passalgo=sha512

# SELinux enabled
selinux --disabled

# Disable anything graphical
skipx
text
eula --agreed

# Setup the disk
zerombr
clearpart --all

#part /boot --fstype=ext3 --size=500 --asprimary --ondisk=xvda
#part / --fstype=xfs --size=6192 --asprimary --ondisk=xvdb
#part raid.10 --asprimary --fstype=raid --size=1 --grow --ondrive=xvda
#part raid.11 --asprimary --fstype=raid --size=1 --grow --ondrive=xvdb

#raid pv.01 --device pv.01 --level=RAID1 raid.10 raid.11
#volgroup vg_test pv.01
#logvol /home --fstype=xfs --vgname=vg_test --size=1 --grow --name=lv_test

part raid.boota --asprimary --fstype="raid" --size=500 --ondrive=xvda
part raid.bootb --asprimary --fstype="raid" --size=500 --ondrive=xvdb
part raid.roota --asprimary --fstype="raid" --size=100 --grow --ondrive=xvda
part raid.rootb --asprimary --fstype="raid" --size=100 --grow --ondrive=xvdb

raid /boot --fstype ext4 --device boot --level=RAID1 raid.boota raid.bootb
raid pv.01 --device pv.01 --level=RAID1 raid.roota raid.rootb

volgroup vg_root pv.01
logvol / --vgname=vg_root --fstype=xfs --size=100 --grow --name=lv_root

bootloader --location=mbr --driveorder=xvda,xvdb --append="console=hvc0"

# Shutdown when the kickstart is done
reboot

# Minimal package set
%packages --excludedocs
@base
@network-file-system-client
deltarpm
yum-plugin-fastestmirror
dracut-config-generic
-dracut-config-rescue
-plymouth
-fprintd-pam
-wireless-tools
-NetworkManager
-NetworkManager-tui
-*-firmware
%end

%post --log=/root/ks-post.log

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF
echo -n "."

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
echo -n "."

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.1.39 RamDisk
EOF
echo -n "."

# since NetworkManager is disabled, need to enable normal networking
chkconfig network on
echo .

# generalization
echo -n "Generalizing"
rm -f /etc/ssh/ssh_host_*
echo .

# fix boot for older pygrub/XenServer
# you should comment out this entire section if on XenServer Creedence/Xen 4.4
echo -n "Fixing boot"
echo "== GRUB fixes ==" >> /root/ks-post.debug.log
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
cp /etc/default/grub /etc/default/grub.bak
cp --no-preserve=mode /etc/grub.d/00_header /etc/grub.d/00_header.bak
sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/' /etc/default/grub
sed -i 's/default="\\${next_entry}"/default="0"/' /etc/grub.d/00_header
echo -n "."
cp --no-preserve=mode /etc/grub.d/10_linux /etc/grub.d/10_linux.bak
sed -i 's/${sixteenbit}//' /etc/grub.d/10_linux
echo -n "."
grub2-mkconfig -o /boot/grub2/grub.cfg >> /root/ks-post.debug.log 2&>1
echo .

#base changes
rpm -ivh http://dl.fedoraproject.org/pub/epel/beta/7/x86_64/epel-release-7-1.noarch.rpm
yum -y update
yum install ntp git wget man mc zsh atop htop dstat nmon zsh -y
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
chkconfig ntpd on
chkconfig atop on

%end
