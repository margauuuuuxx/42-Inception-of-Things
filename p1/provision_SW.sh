#!/usr/bin/env bash

# K3s Agent (Worker) Installation Script
# This script waits for the server to be ready, then joins the cluster as a worker node

# Clean up any previous k3s installation
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
fi
if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-agent-uninstall.sh
fi

TIMEOUT=120
INTERVAL=5
ELAPSED=0

# Wait for the server to create the join token file
# Loop continues while the token file does NOT exist (!-f)
while [ ! -f /vagrant/node-token ]; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "SW: Timeout reached. File not found."
        exit 1
    fi
    echo "SW: Waiting for server token .."
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

# Read the cluster join token from the shared folder
# The token was created by the server and saved to /vagrant/node-token
TOKEN=$(cat /vagrant/node-token)

# Install K3s in agent/worker mode
# K3S_URL tells the installer to connect to the server at this address
# K3S_TOKEN provides authentication to join the cluster
# INSTALL_K3S_EXEC explicitly sets agent mode
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="agent" sh -

# Configure kubectl to use server's API
mkdir -p /home/vagrant/.kube
sudo cp /vagrant/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

echo "SW: K3s agent joined cluster !"