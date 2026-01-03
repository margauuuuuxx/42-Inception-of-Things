# Inception of Things - Setup Guide

## Prerequisites
first install vagrant
For Mac Silicon (M1/M2/M3): Install VMware Fusion and vagrant-vmware-desktop plugin

## Vagrant Commands - VM Management

### Basic VM Operations
- vagrant init --> create a new Vagrantfile (ruby)
- vagrant status --> show status of the VMs in the current Vagrantfile 
- vagrant global-status --> show status of all Vagrant VMs on the system
- vagrant up --> creates all VMS
- vagrant up --provider=vmware_desktop --> start vagrant with VMWare (for mac silicon compatibility)
- vagrant halt --> stop/shutdown VM gracefully
- vagrant suspend --> pause/suspend VM (saves state)
- vagrant resume --> resume a suspended VM
- vagrant reload --> restart VM (halt + up)
- vagrant destroy --> delete VM completely
- vagrant destroy -f --> destroy broken VM completely (force delete without confirmation)
- vagrant ssh --> SSH into the running VM
- vagrant provision --> re-run provisioning scripts

### Snapshot Management
- vagrant snapshot save NAME --> create a snapshot
- vagrant snapshot list --> list all snapshots
- vagrant snapshot restore NAME --> restore a snapshot

### Box Management
- vagrant box list --> list all boxes
- vagrant box remove <box name> --> remove the wrong box from cache
- vagrant box prune --> remove old box versions

### Useful Combinations
- vagrant up && vagrant ssh --> start and immediately SSH in
- vagrant halt && vagrant destroy -f --> stop and delete
- vagrant global-status --prune --> clean up stale Vagrant entries

## VMware CLI Commands - Direct VMware Control
- vmrun list --> list all running VMware VMs
- vmrun start <path-to-vmx> --> start a VM
- vmrun stop <path-to-vmx> --> stop a VM
- vmrun pause <path-to-vmx> --> pause a VM
- vmrun unpause <path-to-vmx> --> unpause a VM
- vmrun listSnapshots <path-to-vmx> --> list snapshots
- vmrun snapshot <path-to-vmx> NAME --> create snapshot

## VM Storage Locations
- ~/.vagrant.d/boxes/ --> where Vagrant stores downloaded boxes
- .vagrant/ --> local VM metadata (in project directory)

## Troubleshooting Mac Silicon
If you encounter errors with VirtualBox on Mac Silicon:
1. Install VMware Fusion (free for personal use)
2. Install VMware utility: brew install vagrant-vmware-utility
3. Install Vagrant plugin: vagrant plugin install vagrant-vmware-desktop
4. Use ARM64 compatible box (e.g., starboard/ubuntu-arm64-20.04.5)
5. Remove lock files if needed: rm -rf ~/.vagrant.d/boxes/*/lck

