install
lang zh_CN.UTF-8
keyboard us
timezone --utc Asia/Shanghai
auth --useshadow --enablemd5
selinux --disabled
firewall --disabled
services --enabled=NetworkManager,sshd
ignoredisk --only-use=sda
$SNIPPET('network_config')
reboot

bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype ext4 --size=200
part pv.01 --size=1 --grow
volgroup rootvg01 pv.01
logvol / --fstype ext4 --name=lv01 --vgname=rootvg01 --size=1 --grow
 
rootpw --iscrypted $6$XmAncpkAdpDoR5bO$.FI0THeFcxkxxIvXKr3HNh5gYdk1P2WJA9XfM1XOm3b18MpwWrjL9TNqWAFk7CrgwfKeaZd0CEX6UddBUr9CT.

repo --name=base --baseurl=http://10.20.0.3/cobbler/ks_mirror/centos66-x86_64/
url --url="http://10.20.0.3/cobbler/ks_mirror/centos66-x86_64/"

%pre
$SNIPPET('pre_install_network_config')
%end
 
%packages --nobase --ignoremissing
@core
%end

%post 
$SNIPPET('post_install_network_config')

# Config yum repo
rm -f /etc/yum.repos.d/*
cat > /etc/yum.repos.d/centos.repo <<EOF
[ceph]
name=ceph
baseurl=http://10.20.0.3/cobbler/ks_mirror/ceph/
gpgcheck=0
enabled=1
EOF

# Config ssh key
cd /root
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1HRgZfUJ0vGweHafYx+jf0mtTm2ft8q2cuC91UyPoeo2/5M+5vXj9IC+YVWeep/i1nwiMlv+77IPddUEPc3Nm5xlQYjKSWymnJZ+Aabzp2NSJDQLjLQqUmgTjV7NVe4bYIPJR3Qd3pg5IA4zAY9hoYJB/LnptXafQjVL39jCpZghSTmPDbSEgRO5wR+LxGB574lz3fH+y8XftvW2uG8fZFXOZycYThashQG/cujkQzHtYfk4aIyr11qUWOGcVRPIqkLLOuW6mz4ux4lm/JrCAOHpwS4CHHwSphUUB+g61KYXBaZHyVjnbAQRvNh4cEVLcEb6mZLguGKy+YS2/XhTcw== root@localhost.localdomain
PUBLIC_KEY

chmod 600 .ssh/authorized_keys

cat >> .ssh/config <<EOF
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
EOF

# Config sshd
sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

# Config network
sed -i "s/^hosts:.*/hosts: files/" /etc/nsswitch.conf

# Upgrade kernel
yum install -y kernel-ml
sed -i "s/^default=1/default=0/" /boot/grub/grub.conf
yum install -y btrfs-progs

# Install ntpdate
yum install -y ntpdate
echo "00 */1 * * * /usr/sbin/ntpdate 10.20.0.3 >/dev/null 2>&1; /sbin/hwclock -w >/dev/null 2>&1 " > /tmp/cron.ntp
crontab /tmp/cron.ntp

# Install parted
yum install -y parted

cat >> /etc/sysctl.conf <<EOF

# Added for CEPH
kernel.pid_max = 4194303
EOF

%end
