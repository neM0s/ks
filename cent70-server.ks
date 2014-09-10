#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
repo --name="centos-updates" --mirrorlist=http://mirrorlist.centos.org/?release=7.0.1406&arch=x86_64&repo=updates
# Keyboard layouts
keyboard 'pl2'
# Halt after installation
halt
# Root password
rootpw --iscrypted $1$tqODm1VF$9m663mf8BfPTowOPSqYFr/
# System timezone
timezone Europe/Warsaw --isUtc
# Use network installation
url --url="http://mirror.rackspace.com/CentOS/7.0.1406/os/x86_64/"
# System language
lang en_US
# License agreement
eula --agreed
# Firewall configuration
firewall --enabled --service=ssh
# Network information
network  --bootproto=static --device=eth0 --gateway=192.168.1.1 --ip=192.168.1.39 --nameserver=192.168.1.20 --netmask=255.255.255.0
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text mode install
text
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx

# System bootloader configuration
bootloader --append="console=hvc0" --location=mbr --driveorder="xvda" --timeout=5
# Partition clearing information
clearpart --all  --drives=xvda,xvdb
# Disk partitioning information
part  --asprimary --fstype="raid" --ondisk=xvda --size=500
part  --asprimary --fstype="raid" --grow --ondisk=xvda --size=1
part  --asprimary --fstype="raid" --ondisk=xvdb --size=500
part  --asprimary --fstype="raid" --grow --ondisk=xvdb --size=1
raid /boot --device=md0 --fstype="ext3" --level=1 raid.boota raid.bootb
raid / --device=md1

%post
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

# simple eth0 config, again not hard-coded to the build hardware
#cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
#DEVICE="eth0"
#BOOTPROTO="dhcp"
#ONBOOT="yes"
#TYPE="Ethernet"
#PERSISTENT_DHCLIENT="yes"
#EOF
#echo -n "."

# generic localhost names
#cat > /etc/hosts << EOF
#127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

#EOF
#echo -n "."

# since NetworkManager is disabled, need to enable normal networking
chkconfig network on
echo .

# utility script
echo -n "Utility scripts"
echo "== Utility scripts ==" >> /root/ks-post.debug.log
wget -O /opt/domu-hostname.sh https://github.com/frederickding/xenserver-kickstart/raw/develop/opt/domu-hostname.sh 2>> /root/ks-post.debug.log
chmod +x /opt/domu-hostname.sh
echo .

# remove unnecessary packages
echo -n "Removing unnecessary packages"
echo "== Removing unnecessary packages ==" >> /root/ks-post.debug.log
yum -C -y remove linux-firmware >> /root/ks-post.debug.log 2&>1
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
%end

%packages --excludedocs
@base
@network-file-system-client
deltarpm
dracut-config-generic
yum-plugin-fastestmirror
-*-firmware
-NetworkManager
-NetworkManager-tui
-dracut-config-rescue
-fprintd-pam
-plymouth
-wireless-tools

%end
/etc/grub.d/00_header /etc/grub.d/00_header.bak
sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/' /etc/default/grub
sed -i 's/default="\\${next_entry}"/default="0"/' /etc/grub.d/00_header
echo -n "."
cp --no-preserve=mode /etc/grub.d/10_linux /etc/grub.d/10_linux.bak
sed -i 's/${sixteenbit}//' /etc/grub.d/10_linux
echo -n "."
grub2-mkconfig -o /boot/grub2/grub.cfg >> /root/ks-post.debug.log 2&>1
echo .

%end