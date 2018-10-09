#!/bin/bash

#############################################################
# Date:     2018/10/09
# Author:   Nirmal Pathak
# Web:      
#
# Program:
#   Installing & configuring Tiger VNC on Oracle Linux 7.x on
# Oracle Cloud Infrastrucutre compute instance. 
#
#############################################################

#Update system & install Tiger VNC
sudo yum groupinstall "Server with GUI" -y
sudo ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
sudo yum install mesa-libGL tigervnc-server -y

#Disable SELinux
sudo sed -ri 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Set VNC Password using 'vncpasswd'.
vncpasswd << EOF
Admin@123
Admin@123
EOF

#Configure VNC Server.
sudo cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@\:1.service
sudo sed -ri 's/<USER>/opc/g' /etc/systemd/system/vncserver@\:1.service

#Start VNC service
sudo systemctl daemon-reload
sudo systemctl enable vncserver@\:1.service
sudo systemctl start vncserver@\:1.service

#Adding VNC ports in Linux Firewall.
sudo firewall-cmd --zone=public --add-service=vnc-server
sudo firewall-cmd --zone=public --add-service=vnc-server --permanent
sudo firewall-cmd --zone=public --add-port=5901/tcp
sudo firewall-cmd --zone=public --add-port=5901/tcp --permanent

#Set 'opc' user password in order to unlock the screensaver on the GUI
echo -e "Admin@123" | (sudo passwd --stdin opc)

#Reboot System
echo "Rebooting system."
echo "Login Password is Admin@123 "
sudo shutdown -r now
