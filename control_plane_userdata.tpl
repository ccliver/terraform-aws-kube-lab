#!/bin/bash
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/

apt update
apt install -y awscli yamllint jq containerd

hostnamectl set-hostname ${hostname}


cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i.bak 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=${kubernetes_version} kubeadm=${kubernetes_version} kubectl=${kubernetes_version}
apt-mark hold kubelet kubeadm kubectl

kubeadm init
mkdir /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
echo "export KUBECONFIG=$HOME/.kube/config" >> /etc/bash.bashrc
echo "set -o vi" >> /etc/bash.bashrc

aws ssm put-parameter --region ${region} --name /kube-lab/kubeadm/join-string --value "$(kubeadm token create --print-join-command)" --overwrite

kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "syntax on" > /home/ubuntu/.vimrc
echo "set tabstop=4" >> /home/ubuntu/.vimrc
echo "set shiftwidth=4" >> /home/ubuntu/.vimrc
echo "set expandtab" >> /home/ubuntu/.vimrc
echo "autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab" >> /home/ubuntu/.vimrc
chown ubuntu:ubuntu /home/ubuntu/.vimrc
