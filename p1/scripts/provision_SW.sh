#!/usr/bin/env bash

set -e


if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-agent-uninstall.sh
fi


apt update
apt upgrade -y

apt install -y curl


# Waiting for node token to be ready
echo "Waiting for server token..."

while [ ! -f /vagrant/node-token ]; do
    sleep 5
done

# Read the cluster join token from the shared folder
# The token was created by the server and saved to /vagrant/node-token
TOKEN=$(cat /vagrant/node-token)


# Install K3s in agent/worker mode
echo "Intsalling K3S agent..."

# K3S_URL tells the installer to connect to the server at this address
# K3S_TOKEN provides authentication to join the cluster
# INSTALL_K3S_EXEC explicitly sets agent mode
curl -sfL https://get.k3s.io | \
K3S_URL=https://192.168.56.110:6443 \
K3S_TOKEN=$TOKEN \
INSTALL_K3S_EXEC="agent \
--node-ip=192.168.56.111" \
sh -


echo "Waiting for K3s agent..."

until systemctl is-active --quiet k3s-agent; do
    echo "Waiting for k3s-agent service..."
    sleep 5
done


echo "SW: Worker ready"
