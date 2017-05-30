#!/bin/bash

#############################################################
# Date:     2017/05/15
# Author:   Nirmal Pathak
# Web:      
#
# Program:
#   Installing Subversion 1.7.X on Centos 5.11 from source. 
#
#############################################################

SVN_VERSION=1.7.0 #Change Subversion version number you want to install in this variable.

#Setup Repositories for CentOS 5.11
cat << EOF > /etc/yum.repos.d/CentOS-Base.repo
# CentOS-Base.repo
#
# The vault system uses the connecting IP address of the client and the
# update status of each vault to pick vaults that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other vaults.
#
# If the mirrorlist= does not work for you, as a fall back you can try the
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-5.11 - Base
#mirrorlist=http://mirrorlist.centos.org/?release=5.11&arch=$basearch&repo=os
baseurl=http://vault.centos.org/5.11/os/x86_64/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5

#released updates
[updates]
name=CentOS-5.11 - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=5.11&arch=$basearch&repo=updates
baseurl=http://vault.centos.org/5.11/updates/x86_64/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5

#additional packages that may be useful
[extras]
name=CentOS-5.11 - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=5.11&arch=$basearch&repo=extras
baseurl=http://vault.centos.org/5.11/extras/x86_64/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-5.11 - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=5.11&arch=$basearch&repo=centosplus
baseurl=http://vault.centos.org/5.11/centosplus/x86_64/
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5

#contrib - packages by Centos Users
[contrib]
name=CentOS-5.11 - Contrib
#mirrorlist=http://mirrorlist.centos.org/?release=5.11&arch=$basearch&repo=contrib
baseurl=http://vault.centos.org/5.11/contrib/x86_64/
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
EOF

cat << EOF > /etc/yum.repos.d/libselinux.repo
[libselinux]
name=CentOS-5.11 - libselinux
#mirrorlist=http://mirrorlist.centos.org/?release=5.11&arch=$basearch&repo=centosplus
baseurl=http://vault.centos.org/5.11/centosplus/x86_64/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
includepkgs=libselinux*
EOF

#Install SVN Pre-Requisites.
yum install wget httpd httpd-devel unzip make zlib-devel libxml2 -y
wget http://archive.apache.org/dist/subversion/subversion-$SVN_VERSION.tar.gz
tar -xzvf subversion-$SVN_VERSION.tar.gz
cd subversion-$SVN_VERSION
./get-deps.sh
./configure --prefix=/opt/subversion --with-apxs=/usr/sbin/apxs
make
make install

cat << EOF > /etc/httpd/conf.d/subversion.conf
# Needed to do Subversion Apache server.
LoadModule dav_svn_module     modules/mod_dav_svn.so
# Only needed if you decide to do "per-directory" access control.
LoadModule authz_svn_module   modules/mod_authz_svn.so

<Location /svn>
        DAV svn
        SVNParentPath /svn/
        AuthName "AA SVN Repo"
        AuthType Basic
        AuthName "Subversion Repository"
        AuthUserFile /etc/httpd/dav_svn.passwd
        Require valid-user
</Location>
EOF

htpasswd -b -cm /etc/httpd/dav_svn.passwd svnadmin admin123
mkdir /svn/ && /opt/subversion/bin/svnadmin create /svn/myrepo && chown apache:apache -R /svn/myrepo
service httpd start
chkconfig httpd on

echo "Subversion $SVN_VERSION installation complete."
echo "You can access the default Subversion repository in browser by accessing following URL with Username: 'svnadmin' & Password: 'admin123'"
echo "http://<YOUR_IP>/svn/myrepo"
