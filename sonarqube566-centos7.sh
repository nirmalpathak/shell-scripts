#!/bin/bash

#################################################################
# Date:     2017/08/25
# Author:   Nirmal Pathak
# Web:      https://technirmal.wordpress.com/about/
#
# Program:
#   Installing SonarQube 5.6.6 on Centos 7 with 'Nginx' as proxy.
#
#################################################################

#Upgrade CentOS 7 to latest release & install pre-requisites.
yum upgrade -y
yum install wget git net-tools unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel elinks
setenforce 0
echo 'Installing MySQL 5.7'
rpm -ivh http://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm #FOR MYSQL 5.7
yum install mysql-community-server -y

echo 'Starting mysql'
systemctl enable mysqld
systemctl start mysqld

echo 'Setting MySQL root password.'
oldpass=$( grep 'temporary.*root@localhost' /var/log/mysqld.log |
        tail -n 1 |  sed 's/.*root@localhost: //' )
newpass="Admin@123"
mysqladmin -u root --password=${oldpass} password $newpass

echo 'The root password is Admin@123'

# Setting up database for sonarqube

mysql -u root --password=Admin@123 -e "SHOW GLOBAL VARIABLES LIKE 'storage_engine';"
mysql -u root --password=Admin@123 -e "CREATE USER 'sonarqube'@'localhost' IDENTIFIED BY 'Admin@123';"
mysql -u root --password=Admin@123 -e "CREATE DATABASE sonarqube;"
mysql -u root --password=Admin@123 -e "GRANT ALL PRIVILEGES ON sonarqube.* TO 'sonarqube'@'localhost';"

# Download & configure SonarQube
cd /opt
sudo wget https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-5.6.6.zip
sudo unzip sonarqube-5.6.6.zip

cp /opt/sonarqube-5.6.6/conf/sonar.properties /opt/sonarqube-5.6.6/conf/sonar.properties.orig
echo -e '\n' >> /opt/sonarqube-5.6.6/conf/sonar.properties
echo -e 'sonar.web.host=127.0.0.1\n' >> /opt/sonarqube-5.6.6/conf/sonar.properties
echo -e 'sonar.jdbc.username=sonarqube\n' >> /opt/sonarqube-5.6.6/conf/sonar.properties
echo -e 'sonar.jdbc.password=Admin@123\n' >> /opt/sonarqube-5.6.6/conf/sonar.properties
echo sonar.jdbc.url='jdbc:mysql://localhost:3306/sonarqube?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance' >> /opt/sonarqube-5.6.6/conf/sonar.properties
echo -e '\n' >> /opt/sonarqube-5.6.6/conf/sonar.properties

#Setting up SonarQube service
cat << EOF >> /etc/init.d/sonar
#!/bin/sh
#
# rc file for SonarQube
#
# chkconfig: 345 96 10
# description: SonarQube system (www.sonarqube.org)
#
### BEGIN INIT INFO
# Provides: sonar
# Required-Start: $network
# Required-Stop: $network
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Short-Description: SonarQube system (www.sonarqube.org)
# Description: SonarQube system (www.sonarqube.org)
### END INIT INFO

/usr/bin/sonar \$*
EOF

ln -s /opt/sonarqube-5.6.6/bin/linux-x86-64/sonar.sh /usr/bin/sonar
chmod 755 /etc/init.d/sonar
chkconfig --add sonar
service sonar restart
chkconfig on sonar
#/opt/sonarqube-5.6.6/bin/linux-x86-64/sonar.sh start

#Install & configure 'nginx' as SonarQube proxy.

yum -y install epel-release
yum -y install nginx
mkdir -p /etc/nginx/conf.d
cat << EOF >> /etc/nginx/conf.d/sonar.conf
# the server directive is nginx's virtual host directive
server {
  # port to listen on. Can also be set to an IP:PORT
  listen 80;

  # sets the domain[s] that this vhost server requests for
  server_name sonarqube.aaspl-brd.com;

  location / {
    proxy_pass http://127.0.0.1:9000;
  }
}
EOF
systemctl enable nginx
systemctl start nginx

#Enable HTTP/S port in firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
