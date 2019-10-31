#!/bin/bash

address='http://localhost:8983/solr'
configSet="sitecore_configs"
shardCount=2
declare -a indexes=(
    "sitecore_core_index"
    "sitecore_core_index_rebuild"
    "sitecore_master_index"
    "sitecore_master_index_rebuild"
    "sitecore_web_index"
    "sitecore_web_index_rebuild"
    "sitecore_preview_index"
    "sitecore_preview_index_rebuild"
    "sitecore_fxm_master_index" 
    "sitecore_fxm_master_index_rebuild"
    "sitecore_fxm_web_index"
    "sitecore_fxm_web_index_rebuild"
    "sitecore_fxm_preview_index" 
    "sitecore_fxm_preview_index_rebuild"
    "sitecore_testing_index"
    "sitecore_testing_index_rebuild"
    "sitecore_suggested_test_index"
    "sitecore_suggested_test_index_rebuild"
    "sitecore_marketing_asset_index_master" 
    "sitecore_marketing_asset_index_master_rebuild"
    "sitecore_marketing_asset_index_web"
    "sitecore_marketing_asset_index_web_rebuild"
    "sitecore_marketingdefinitions_master"
    "sitecore_marketingdefinitions_master_rebuild"
    "sitecore_marketingdefinitions_web" 
    "sitecore_marketingdefinitions_web_rebuild"
    "mediaframework_brightcove_index"
    "mediaframework_brightcove_index_rebuild"
)

# create indexes
echo "Create indexes."
for indexName in ${indexes[@]}
do
    echo "Creating $indexName."
    curl  "$address/admin/collections?action=CREATE&collection.configName=$configSet&maxShardsPerNode=2&name=$indexName&numShards=$shardCount&replicationFactor=3&router.name=compositeId&routerName=compositeId&wt=json"
done
# create ailases and indexes
echo "Create ailases and indexes."
declare -A aliases=(
    ["sitecore_xdb_rebuild_internal"]="sitecore_xdb_rebuild"
    ["sitecore_xdb_internal"]="sitecore_xdb"
)
configSet="_default"
for indexName in ${!aliases[@]}
do
    echo "Creating $indexName."
    curl  "$address/admin/collections?action=CREATE&collection.configName=$configSet&maxShardsPerNode=2&name=$indexName&numShards=$shardCount&replicationFactor=3&router.name=compositeId&routerName=compositeId&wt=json"
    alias="${aliases[$indexName]}"
    echo "Creating alias $alias for $indexName."
    curl  "$address/admin/collections?action=CREATEALIAS&name=$alias&collections=$indexName"
done