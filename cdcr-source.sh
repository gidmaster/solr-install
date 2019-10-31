#!/bin/bash

while [ -n "$1" ]
do
case "$1" in
-z) zk_nodes_list="$2"
shift 
break ;;
esac
shift
done

yum -y install epel-release
yum -y install xmlstarlet

zk_nodes=$(sed 's/,/ /g' <<< $zk_nodes_list)
our_zk_nodes=$(awk -F "[,=:]" '{if ($1=="ZK_HOST") print  $2" "$4" "$6}' /etc/default/solr.in.sh)
zk=$(awk -F "[,=]" '{if ($1=="ZK_HOST") print  $2}' /etc/default/solr.in.sh)
zk_host=""
for zk_node in $zk_nodes
do
	if [[ ! $our_zk_nodes =~ "$zk_node" ]]
	then
    if [ $zk_host ]
    then
      zk_host+=","
    fi
		zk_host+="$zk_node:2181"
	fi
done
#---------------CHECK COLLECTION NAMES  before commit
sitecore_configs_collection_names="sitecore_core_index
sitecore_core_index_rebuild
sitecore_master_index
sitecore_master_index_rebuild
sitecore_web_index
sitecore_web_index_rebuild
sitecore_preview_index
sitecore_preview_index_rebuild
sitecore_fxm_master_index 
sitecore_fxm_master_index_rebuild
sitecore_fxm_web_index
sitecore_fxm_web_index_rebuild
sitecore_fxm_preview_index 
sitecore_fxm_preview_index_rebuild
sitecore_testing_index
sitecore_testing_index_rebuild
sitecore_suggested_test_index
sitecore_suggested_test_index_rebuild
sitecore_marketing_asset_index_master 
sitecore_marketing_asset_index_master_rebuild
sitecore_marketing_asset_index_web
sitecore_marketing_asset_index_web_rebuild
sitecore_marketingdefinitions_master
sitecore_marketingdefinitions_master_rebuild
sitecore_marketingdefinitions_web 
sitecore_marketingdefinitions_web_rebuild
mediaframework_brightcove_index
mediaframework_brightcove_index_rebuild"

_default_collection_names="sitecore_xdb_rebuild_internal
sitecore_xdb_internal"

configsets="_default sitecore_configs"

for configset in $configsets
do
  echo $configset
  collections=""
  if [ "${configset}_collection_names" = "sitecore_configs_collection_names" ]
    then
      collection_names=$sitecore_configs_collection_names
    else
      collection_names=$_default_collection_names
    fi
  for collection in $collection_names
  do
      collections+="
  <lst name=\"replica\">
    <str name=\"zkHost\">$zk_host</str>
    <str name=\"source\">$collection</str>
    <str name=\"target\">$collection</str>
  </lst>
  "
  done

  sed -i 's/<updateLog>/<updateLog class="solr.CdcrUpdateLog">/' /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml

  xmlstarlet ed --inplace -d "//updateRequestProcessorChain[@name='cdcr-processor-chain']" /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
  xmlstarlet ed --inplace -d "//requestHandler[@class='solr.UpdateRequestHandler']" /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
  xmlstarlet ed --inplace -d "//requestHandler[@name='/cdcr']" /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml

  if ! grep -q "cdcr-processor-chain" /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
    then

    sed -i '/<\/config>/d' /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
    cat <<EOT >> /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
<updateRequestProcessorChain name="cdcr-processor-chain">
  <processor class="solr.CdcrUpdateProcessorFactory"/>
  <processor class="solr.RunUpdateProcessorFactory"/>
</updateRequestProcessorChain>

<requestHandler name="/update" class="solr.UpdateRequestHandler">
  <lst name="defaults">
    <str name="update.chain">cdcr-processor-chain</str>
  </lst>
</requestHandler>

<requestHandler name="/cdcr" class="solr.CdcrRequestHandler">
$collections


  <lst name="replicator">
    <str name="threadPoolSize">8</str>
    <str name="schedule">1000</str>
    <str name="batchSize">128</str>
  </lst>

  <lst name="updateLogSynchronizer">
    <str name="schedule">1000</str>
  </lst>

</requestHandler>

</config>
EOT

    fi

  /opt/solr/bin/solr zk upconfig -d $configset -n $configset -z $zk

done
