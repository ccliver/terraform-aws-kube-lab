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
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=${kubernetes_version} kubeadm=${kubernetes_version} kubectl=${kubernetes_version} etcd-client
apt-mark hold kubelet kubeadm kubectl

kubeadm init
useradd ssm-user -d /home/ssm-user
mkdir -p /home/ssm-user/.kube /home/ssm-user/pki
cp /etc/kubernetes/admin.conf /home/ssm-user/.kube/config
cp /etc/kubernetes/pki/apiserver-etcd-client.* /home/ssm-user/pki/
cp /etc/kubernetes/pki/etcd/ca.crt /home/ssm-user/pki/
chown -R ssm-user:ssm-user /home/ssm-user/.kube
echo "export KUBECONFIG=/home/ssm-user/.kube/config" >> /home/ssm-user/.bashrc
echo "set -o vi" >> /home/ssm-user/.bashrc
echo "export ETCDCTL_API=3" >> /home/ssm-user/.bashrc
echo "export ETCDCTL_CACERT=/home/ssm-user/pki/ca.crt" >> /home/ssm-user/.bashrc
echo "export ETCDCTL_CERT=/home/ssm-user/pki/apiserver-etcd-client.crt" >> /home/ssm-user/.bashrc
echo "export ETCDCTL_KEY=/home/ssm-user/pki/apiserver-etcd-client.key" >> /home/ssm-user/.bashrc
chown ubuntu:ubuntu /home/ssm-user/pki/*

aws ssm put-parameter --region ${region} --name /kube-lab/kubeadm/join-string --value "$(kubeadm token create --print-join-command)" --overwrite

kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "syntax on" > /home/ubuntu/.vimrc
echo "set tabstop=4" >> /home/ubuntu/.vimrc
echo "set shiftwidth=4" >> /home/ubuntu/.vimrc
echo "set expandtab" >> /home/ubuntu/.vimrc
echo "autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab" >> /home/ubuntu/.vimrc
chown ubuntu:ubuntu /home/ubuntu/.vimrc

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install helm

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
