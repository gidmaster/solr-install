#!/bin/bash
zk=$(awk -F "[,=]" '{if ($1=="ZK_HOST") print  $2}' /etc/default/solr.in.sh)

configsets="_default sitecore_configs"
for configset in $configsets
do
  sed -i 's/<updateLog>/<updateLog class="solr.CdcrUpdateLog">/' /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml

  if ! grep -q "cdcr-processor-chain" /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
  then
 
    sed -i '/<\/config>/d' /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
    cat <<EOT >> /opt/solr/server/solr/configsets/$configset/conf/solrconfig.xml
<requestHandler name="/cdcr" class="solr.CdcrRequestHandler">
  <!-- recommended for Target clusters -->
  <lst name="buffer">
    <str name="defaultState">disabled</str>
  </lst>
</requestHandler>

<requestHandler name="/update" class="solr.UpdateRequestHandler">
  <lst name="defaults">
    <str name="update.chain">cdcr-processor-chain</str>
  </lst>
</requestHandler>

<updateRequestProcessorChain name="cdcr-processor-chain">
  <processor class="solr.CdcrUpdateProcessorFactory"/>
  <processor class="solr.RunUpdateProcessorFactory"/>
</updateRequestProcessorChain>
</config>
EOT

  fi

/opt/solr/bin/solr zk upconfig -d $configset -n $configset -z $zk
done
