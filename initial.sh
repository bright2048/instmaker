#!/bin/bash
echo root:${rootPwd} | chpasswd >/dev/null
sed -i '/UsePAM yes/s/yes/no/g' /etc/ssh/sshd_config
sed -i '/#PermitRootLogin/s/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sed -i '/PermitRootLogin prohibit-password/s/prohibit-password/yes/g' /etc/ssh/sshd_config
service ssh start
cd /etc/vncc && nohup ./vncc -c vncc.conf &
