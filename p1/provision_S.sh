#!/usr/bin/env bash

# K3s Server (Controller) Installation Script
# This script installs K3s in server mode and prepares it for worker nodes to join

# Download and install K3s in server/controller mode
# The installation script is piped directly to shell for execution
curl -sfL https://get.k3s.io | sh -

# Wait for K3s to be fully operational
# Initial grace period to let K3s services start
sleep 10

# Keep checking if K3s is ready by attempting to query the cluster nodes
# Loop continues until the command succeeds (K3s API server is responding)
until sudo k3s kubectl get nodes 2>/dev/null; do
    echo "S: Waiting for K3s server .."
    sleep 5
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