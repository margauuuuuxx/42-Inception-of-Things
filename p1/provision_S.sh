#!/usr/bin/env bash

# K3s Server (Controller) Installation Script
# This script installs K3s in server mode and prepares it for worker nodes to join

set -e

# Clean up any previous k3s installation
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
fi
if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-agent-uninstall.sh
fi

# Packages update 
echo "Updating packages..."

apt update
apt upgrade -y


echo "Installing dependencies..."

apt install -y curl


echo "Installing K3s server..."

# Download and install K3s in server/controller mode
# INSTALL_K3S_EXEC explicitly sets server mode
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
--node-ip=192.168.56.110 \
--tls-san=192.168.56.110 \
--write-kubeconfig-mode=644" \
sh -

# echo "Ensuring k3s waits for clock sync before starting ..."

# mkdir -p /etc/systemd/system/k3s.service.d
# cat <<EOF > /etc/systemd/system/k3s.service.d/wait-for-time-sync.conf
# [Unit]
# After=time-sync.target
# Wants=time-sync.target
# EOF

# systemctl daemon-reload


echo "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


# Configure kubectl access for the vagrant user (non-root access)
echo "Configuring kubectl"

# Create .kube directory in vagrant's home directory
mkdir -p /home/vagrant/.kube

# Copy the K3s kubeconfig file to vagrant's .kube directory
# This file contains cluster connection info and credentials
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config

# Modify the kubeconfig so that kubectl connects to the correct K3S server IP instead of localhost
sed -i 's/127.0.0.1/192.168.56.110/g' /home/vagrant/.kube/config

# Change ownership of the entire .kube directory to vagrant user
# This allows vagrant to read/write kubectl config without sudo
chown -R vagrant:vagrant /home/vagrant/.kube


# Sharing the token with worker
echo "Sharing token with worker"

# Save the cluster join token to shared folder for worker node to use
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token


# Checking cluster readiness
echo "Checking cluster readiness"

until sudo -u vagrant kubectl get nodes; do
    echo "Waiting for Kubernetes API..."
    sleep 5
done

echo "S: K3s server ready and token saved!"