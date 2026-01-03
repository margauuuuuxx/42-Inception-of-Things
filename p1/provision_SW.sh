#!/usr/bin/env bash

# K3s Agent (Worker) Installation Script
# This script waits for the server to be ready, then joins the cluster as a worker node

# Wait for the server to create the join token file
# Loop continues while the token file does NOT exist (!-f)
while [ ! -f /vagrant/node-token ]; do
    echo "SW: Waiting for server token .."
    sleep 5
done

# Read the cluster join token from the shared folder
# The token was created by the server and saved to /vagrant/node-token
TOKEN=$(cat /vagrant/node-token)

# Install K3s in agent/worker mode
# K3S_URL tells the installer to connect to the server at this address
# K3S_TOKEN provides authentication to join the cluster
# These environment variables trigger agent mode instead of server mode
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh -

echo "SW: K3s agent joined cluster !"