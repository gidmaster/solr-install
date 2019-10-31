#!/bin/bash

while [ -n "$1" ]
do
case "$1" in
-p) solrPassword="$2"
shift ;;
--) shift
break ;;
#  *) echo "$1 is not an option";;
esac
shift
done

/opt/solr/bin/solr auth enable -credentials solr:$solrPassword -z $1:2181

curl --user solr:$solrPassword "http://localhost:8983/solr/admin/authentication" \
-d '{
  "set-user": {"monitor" : "monitor" }
}' 

curl --user solr:$solrPassword "http://localhost:8983/solr/admin/authorization" \
-d '{ 
  "delete-permission": 1,
  "set-permission": {
	"collection": null,
    "path":"/admin/ping",
	"role":"monitoring"
  },
  "set-permission": {
    "name":"all",
	"role":"admin"
  },
  "set-user-role" : {"monitor": "monitoring"},
  "set-user-role" : {"solr": ["admin","monitoring"]}
}'


/opt/solr/bin/solr auth enable -credentials solr:$solrPassword -z $1:2181

systemctl restart solr