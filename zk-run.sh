#!/bin/sh
sudo bash zk-install.sh $1
shift
sudo bash zk-ensemble.sh $@
