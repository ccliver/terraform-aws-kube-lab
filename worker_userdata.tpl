#!/bin/bash

apt update
apt install -y awscli yamllint jq containerd

hostnamectl set-hostname ${hostname}

mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i.bak 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
