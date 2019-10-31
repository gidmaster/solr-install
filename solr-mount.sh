#!/bin/bash
if vgdisplay | grep -q 'vg_data'; then
    echo "Already mounted."
else
    pvcreate /dev/disk/azure/scsi1/*
    vgcreate vg_data /dev/disk/azure/scsi1/*
    lvcreate -n lv_data -l 100%FREE vg_data
    mkdir -p /data && mkfs -t xfs /dev/vg_data/lv_data && echo "/dev/mapper/vg_data-lv_data /data xfs defaults,nofail 0 2" >> /etc/fstab
    mount /dev/vg_data/lv_data /data
fi
