#!/usr/bin/env bash

set -e

echo "Cleaning up any previous k3s installation ..."

if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
fi


echo "Updating packages..."

apt update
apt upgrade -y


echo "Installing dependencies..."

apt install -y curl


echo "Installing K3s server..."

curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
--node-ip=192.168.56.110 \
--tls-san=192.168.56.110 \
--write-kubeconfig-mode=644" \
sh -


echo "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


echo "Configuring kubectl"

mkdir -p /home/vagrant/.kube

cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config

sed -i 's/127.0.0.1/192.168.56.110/g' /home/vagrant/.kube/config

chown -R vagrant:vagrant /home/vagrant/.kube


echo "S: K3s server ready !"