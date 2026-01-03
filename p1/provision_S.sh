#!/usr/bin/env bash

# K3s Server (Controller) Installation Script
# This script installs K3s in server mode and prepares it for worker nodes to join

# Clean up any previous k3s installation
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
fi
if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-agent-uninstall.sh
fi

# Download and install K3s in server/controller mode
# INSTALL_K3S_EXEC explicitly sets server mode
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

# Wait for K3s to be fully operational
TIMEOUT=120
INTERVAL=5
ELAPSED=0

# Keep checking if K3s is ready by attempting to query the cluster nodes
until sudo k3s kubectl get nodes 2>/dev/null; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "S: Timeout reached. K3s server failed to start."
        exit 1
    fi
    echo "S: Waiting for K3s server .."
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

# Configure kubectl access for the vagrant user (non-root access)
# Create .kube directory in vagrant's home directory
mkdir -p /home/vagrant/.kube

# Copy the K3s kubeconfig file to vagrant's .kube directory
# This file contains cluster connection info and credentials
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config

# Change ownership of the entire .kube directory to vagrant user
# This allows vagrant to read/write kubectl config without sudo
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Save the cluster join token to shared folder for worker node to use
# bash -c ensures the entire command (including redirection) runs with sudo
sudo bash -c "cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token"

# Copy kubeconfig to shared folder for worker node
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo sed -i 's/127.0.0.1/192.168.56.110/g' /vagrant/k3s.yaml

echo "S: K3s server ready and token saved!"