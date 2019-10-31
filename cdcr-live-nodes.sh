#!/bin/bash
while [ -n "$1" ]
do
case "$1" in
-s) solr_nodes_list="$2"
shift 
break ;;
esac
shift
done

solr_nodes=$(sed 's/,/ /g' <<< $solr_nodes_list)
zk=$(awk -F "[,=]" '{if ($1=="ZK_HOST") print  $2}' /etc/default/solr.in.sh)

for solr_node in $solr_nodes
do
  /opt/solr/bin/solr zk mkroot /live_nodes/$solr_node:8983_solr -z $zk
done
exit 0