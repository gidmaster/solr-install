#!/bin/bash
zk=$(awk -F "[,=]" '{if ($1=="ZK_HOST") print  $2}' /etc/default/solr.in.sh)
cp /home/solradmin/_default_managed-schema.xml /opt/solr/server/solr/configsets/_default/conf/managed-schema
cp /home/solradmin/sitecore_configs_managed-schema.xml /opt/solr/server/solr/configsets/sitecore_configs/conf/managed-schema
/opt/solr/bin/solr zk upconfig -d _default -n _default -z $zk
/opt/solr/bin/solr zk upconfig -d sitecore_configs -n sitecore_configs -z $zk