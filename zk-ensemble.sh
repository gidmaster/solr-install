#!/bin/bash

# Arguments - Zookeeper node names
nodes=$@
host=$(ip route get 1 | awk '{print $NF;exit}')
dataDir=$(awk -F"=" '{if ($1 == "dataDir") print $2 }' /opt/zookeeper/conf/zoo.cfg)

if [[ $@ =~ (^|[[:space:]])$host($|[[:space:]]) ]]
then
    echo "self address is $host"
else
    echo "self address is not found in arguments list."
    exit 1
fi

i=1
for node in $nodes
do
    grep "^server\.$i" /opt/zookeeper/conf/zoo.cfg && \
    sed -i "s@^server\.$i.*@server.$i=$node:2888:3888@g" /opt/zookeeper/conf/zoo.cfg || \
    echo "server.$i=$node:2888:3888" >>  /opt/zookeeper/conf/zoo.cfg
    if [ "$node" == "$host" ] 
    then
        echo "$i" > "$dataDir/myid"
    fi
    ((i++))
done

systemctl restart zk