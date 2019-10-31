#!/bin/bash

while [ -n "$1" ]
do
case "$1" in
-h) heapSize="$2"
shift ;;
-p) solrPassword="$2"
shift 
break;;
esac
shift
done

echo "Install wget java-1.8.0-openjdk lsof."
yum install -y wget java-1.8.0-openjdk lsof  > /dev/null
# Create users and folders
useradd solr -m
usermod --shell /bin/bash solr
echo "solr:$solrPassword" | chpasswd
usermod -aG wheel solr
# su -l solr
yum install -y wget java-1.8.0-openjdk lsof  > /dev/null
if systemctl is-active --quiet solr
then
    systemctl stop solr
fi
rm -rf /var/solr
rm -rf /opt/solr*
rm -f /etc/init.d/solr
rm -f /etc/default/solr.in.sh
rm -rf /data/solr

mkdir /var/solr
chown solr:solr /var/solr
cd /opt

# install solr
version="7.2.1"
wget "https://archive.apache.org/dist/lucene/solr/$version/solr-$version.tgz"
tar xzf solr-$version.tgz solr-$version/bin/install_solr_service.sh --strip-components=2 > /dev/null
bash install_solr_service.sh solr-$version.tgz -d /data/solr -n
chown solr:solr -R  solr-$version
# ln -s solr-$version solr
chown -h solr:solr solr

# Tune limits
grep "^\* hard nofile" /etc/security/limits.conf && sed -i 's/^\* hard nofile.*/solr hard nofile 1000000/' /etc/security/limits.conf || echo "* hard nofile 1000000" >>  /etc/security/limits.conf
grep "^\* soft nofile" /etc/security/limits.conf && sed -i 's/^\* soft nofile.*/solr soft nofile 1000000/' /etc/security/limits.conf || echo "* soft nofile 1000000" >>  /etc/security/limits.conf
grep "^\* hard nproc" /etc/security/limits.conf && sed -i 's/^\* hard nproc.*/solr hard nproc 1000000/' /etc/security/limits.conf || echo "* hard nproc 1000000" >>  /etc/security/limits.conf
grep "^\* soft nproc" /etc/security/limits.conf && sed -i 's/^\* soft nproc.*/solr soft nproc 1000000/' /etc/security/limits.conf || echo "* soft nproc 1000000" >>  /etc/security/limits.conf

sysctl -w fs.file-max=1000000
grep "^\* fs.file-max" /etc/security/limits.conf && sed -i 's/^\* fs.file-max.*/fs.file-max = 1000000/' /etc/security/limits.conf || echo "fs.file-max = 1000000" >> /etc/sysctl.conf

sysctl -p
# set SOLR_HEAP
sed -i "s/#SOLR_HEAP=.*/SOLR_HEAP=$heapSize/" /etc/default/solr.in.sh
# Or change it
sed -i "s/SOLR_HEAP=.*/SOLR_HEAP=$heapSize/" /etc/default/solr.in.sh

# Make solr service

cat > /etc/systemd/system/solr.service << EOL
[Unit]
Description=Solr Daemon
Documentation=https://lucene.apache.org/solr/guide/7_2/index.html
Requires=network.target
After=network.target

[Service]    
Type=forking
WorkingDirectory=/opt/solr
User=solr
Group=solr
ExecStart=/opt/solr/bin/solr start
ExecStop=/opt/solr/bin/solr stop
ExecReload=/opt/solr/bin/solr restart
TimeoutSec=180
Restart=on-failure

[Install]
WantedBy=default.target
EOL

systemctl daemon-reload

# Add service to startup

systemctl enable  solr