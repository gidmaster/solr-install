#!/bin/bash

while [ -n "$1" ]
do
case "$1" in
-u) username="$2"
shift ;;
-p) password="$2"
shift 
break ;;
esac
shift
done

collection_names="sitecore_core_index
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
mediaframework_brightcove_index_rebuild
sitecore_xdb_rebuild_internal
sitecore_xdb_internal"

for collection in $collection_names
do
    curl -u $username:$password "http://localhost:8983/solr/$collection/cdcr?action=START"
    curl -u $username:$password "http://localhost:8983/solr/$collection/cdcr?action=DISABLEBUFFER"
    curl -u $username:$password "http://localhost:8983/solr/$collection/update?commit=true"
    curl -u $username:$password -X POST -H 'Content-type: application/json' -d '{"set-property":{"updateHandler.autoSoftCommit.maxTime":1500}}' http://localhost:8983/solr/$collection/config
done