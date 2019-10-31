#!/bin/bash

yum install -y wget java-1.8.0-openjdk lsof  > /dev/null
# Create users and folders
useradd zk -m
usermod --shell /bin/bash zk
echo "zk:$1" | chpasswd
usermod -aG wheel zk
# su -l zk
rm -rf /data/zookeeper
rm -rf /opt/zookeeper*
mkdir -p /data/zookeeper
chown zk:zk /data/zookeeper
cd /opt

# install zookeper
version="3.4.6"
wget "https://archive.apache.org/dist/zookeeper/zookeeper-$version/zookeeper-$version.tar.gz"
tar -xvf zookeeper-$version.tar.gz 
chown zk:zk -R  zookeeper-$version
ln -s zookeeper-$version zookeeper
chown -h zk:zk zookeeper

cat > /opt/zookeeper/conf/zoo.cfg << EOL
tickTime=2000
dataDir=/data/zookeeper
clientPort=2181
maxClientCnxns=800
initLimit=10
syncLimit=5
EOL

# Tune limits
grep "^\* hard nofile" /etc/security/limits.conf && sed -i 's/^\* hard nofile.*/solr hard nofile 500000/' /etc/security/limits.conf || echo "* hard nofile 500000" >>  /etc/security/limits.conf
grep "^\* soft nofile" /etc/security/limits.conf && sed -i 's/^\* soft nofile.*/solr soft nofile 500000/' /etc/security/limits.conf || echo "* soft nofile 500000" >>  /etc/security/limits.conf
grep "^\* hard nproc" /etc/security/limits.conf && sed -i 's/^\* hard nproc.*/solr hard nproc 500000/' /etc/security/limits.conf || echo "* hard nproc 500000" >>  /etc/security/limits.conf
grep "^\* soft nproc" /etc/security/limits.conf && sed -i 's/^\* soft nproc.*/solr soft nproc 500000/' /etc/security/limits.conf || echo "* soft nproc 500000" >>  /etc/security/limits.conf

sysctl -w fs.file-max=1000000
grep "^\* fs.file-max" /etc/security/limits.conf && sed -i 's/^\* fs.file-max.*/fs.file-max = 500000/' /etc/security/limits.conf || echo "fs.file-max = 500000" >> /etc/sysctl.conf
if [ $2 ] 
then
    echo "export JVMFLAGS=\"-Xmx$2\"" > /opt/zookeeper/conf/java.env    
fi
# Make zk service

cat > /etc/systemd/system/zk.service << EOL
[Unit]
Description=Zookeeper Daemon
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]    
Type=forking
WorkingDirectory=/opt/zookeeper
User=zk
Group=zk
ExecStart=/opt/zookeeper/bin/zkServer.sh start /opt/zookeeper/conf/zoo.cfg
ExecStop=/opt/zookeeper/bin/zkServer.sh stop /opt/zookeeper/conf/zoo.cfg
ExecReload=/opt/zookeeper/bin/zkServer.sh restart /opt/zookeeper/conf/zoo.cfg
TimeoutSec=30
Restart=on-failure

[Install]
WantedBy=default.target
EOL

systemctl daemon-reload
# Add service to startap

systemctl enable  zk