#!/bin/bash

repo_name="registry.bright.pro"
repo_port=8088
repo_crt=domain.crt

count=$(grep ${repo_name} /etc/hosts|wc -l)

if [ $count -eq 0 ]
then
    echo "210.16.188.152 ${repo_name}" >> /etc/hosts
fi

echo "register private repo $repo_name"
if [ -d /etc/docker/certs.d/$repo_name:$repo_port ]
then
    rm -r /etc/docker/certs.d/$repo_name:$repo_port
fi
sudo mkdir -p /etc/docker/certs.d/$repo_name:$repo_port
sudo cp $repo_crt /etc/docker/certs.d/$repo_name:$repo_port/
