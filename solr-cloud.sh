#!/bin/bash

solrHost="$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"

echo $@

zk_host="ZK_HOST="

for last; do true; done
for node in $@
do
    zk_host+="$node:2181"
    if [ "$node" != "$last" ]
    then
        zk_host+=","
    fi
done


sed -i "s/^#ZK_HOST=.*/$zk_host/g"  /etc/default/solr.in.sh
sed -i "s/^ZK_HOST=.*/$zk_host/g"  /etc/default/solr.in.sh

sed -i "s/^#SOLR_HOST=.*/SOLR_HOST=$solrHost/g" /etc/default/solr.in.sh
sed -i "s/^SOLR_HOST=.*/SOLR_HOST=$solrHost/g" /etc/default/solr.in.sh

cp -r /opt/solr/server/solr/configsets/_default/ /opt/solr/server/solr/configsets/sitecore_configs
sed -i 's/<uniqueKey>id<\/uniqueKey>/<uniqueKey>_uniqueid<\/uniqueKey>/g' /opt/solr/server/solr/configsets/sitecore_configs/conf/managed-schema
sed -i 's/field name="id".*/field name="_uniqueid" type="string" indexed="true" stored="true" required="true" \/>/g' /opt/solr/server/solr/configsets/sitecore_configs/conf/managed-schema
sed -i 's/update.autoCreateFields:true/update.autoCreateFields:false/g' /opt/solr/server/solr/configsets/sitecore_configs/conf/solrconfig.xml

chown -R solr:solr /opt/solr/server/solr/configsets

/opt/solr/bin/solr zk upconfig -d sitecore_configs -n sitecore_configs -z $1:2181

systemctl restart solr