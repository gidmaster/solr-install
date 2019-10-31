#!/bin/bash
while [ -n "$1" ]
do
case "$1" in
-r) solr_vm_solr_user_password="$2"
shift ;;
-h) solr_heapSize="$2"
shift ;;
-p) solrPassword="$2"
shift ;;
-m) multiregional_setup="$2"
shift ;;
--) shift
break ;;
#  *) echo "$1 is not an option";;
esac
shift
done


echo "bash solr-mount.sh"
bash solr-mount.sh
echo "bash solr-install.sh -h $solr_heapSize -p $solr_vm_solr_user_password"
bash solr-install.sh -h $solr_heapSize -p $solr_vm_solr_user_password
echo "bash solr-cloud.sh $@"
bash solr-cloud.sh $@
if [ $multiregional_setup == "false" ]
then
    echo "bash solr-collection.sh"
    bash solr-collection.sh 
fi
echo "bash solr-sec.sh -p $solrPassword -- $@"
bash solr-sec.sh -p $solrPassword -- $@
