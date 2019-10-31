#!/bin/bash
while [ -n "$1" ]
do
case "$1" in
-r) solr-vm-solr-user-password="$2"
shift ;;
-h) solr_heapSize="$2"
shift ;;
--) shift
break ;;
#  *) echo "$1 is not an option";;
esac
shift
done


echo "solr-mount.sh"
bash solr-mount.sh
echo "solr-install.sh $solr-vm-solr-user-password"
bash solr-install.sh -h $solr_heapSize -p $solr-vm-solr-user-password
esho "solr-cloud.sh $@"
bash solr-cloud.sh  $@