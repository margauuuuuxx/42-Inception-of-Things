# 🚀 Inception of Things - Setup Guide

## 📋 Prerequisites

- First install vagrant
- **For Mac Silicon (M1/M2/M3):** Install VMware Fusion and vagrant-vmware-desktop plugin

---

## 🛠️ Vagrant Commands - VM Management

### Basic VM Operations

| Command | Description |
|---------|-------------|
| `vagrant init` | Create a new Vagrantfile (ruby) |
| `vagrant status` | Show status of the VMs in the current Vagrantfile |
| `vagrant global-status` | Show status of all Vagrant VMs on the system |
| `vagrant up` | Creates all VMs |
| `vagrant up --provider=vmware_desktop` | Start vagrant with VMWare (for Mac Silicon compatibility) |
| `vagrant halt` | Stop/shutdown VM gracefully |
| `vagrant suspend` | Pause/suspend VM (saves state) |
| `vagrant resume` | Resume a suspended VM |
| `vagrant reload` | Restart VM (halt + up) |
| `vagrant destroy` | Delete VM completely |
| `vagrant destroy -f` | Destroy broken VM completely (force delete without confirmation) |
| `vagrant ssh` | SSH into the running VM |
| `vagrant ssh-config` | Outputs OpenSSH valid config to connect to the VMs via SSH |
| `vagrant provision` | Re-run provisioning scripts |
| `vagrant package` | Packages a running virtual env into a reusable box |

### Snapshot Management

| Command | Description |
|---------|-------------|
| `vagrant snapshot save NAME` | Create a snapshot |
| `vagrant snapshot list` | List all snapshots |
| `vagrant snapshot restore NAME` | Restore a snapshot |

### Box Management

> 📦 Boxes stored in `~/.vagrant.d/boxes`

| Command | Description |
|---------|-------------|
| `vagrant box list` | List all boxes |
| `vagrant box remove <box name>` | Remove the wrong box from cache |
| `vagrant box prune` | Remove old box versions |
| `vagrant box add` | Adds a box to local box repo |
| `vagrant box outdated` | Checks if any boxes in local repo is outdated |
| `vagrant box repackage` | Repackages a box with a new name & metadata |

### Useful Combinations

| Command | Description |
|---------|-------------|
| `vagrant up && vagrant ssh` | Start and immediately SSH in |
| `vagrant halt && vagrant destroy -f` | Stop and delete |
| `vagrant global-status --prune` | Clean up stale Vagrant entries |

---

## ⚙️ VMware CLI Commands - Direct VMware Control

| Command | Description |
|---------|-------------|
| `vmrun list` | List all running VMware VMs |
| `vmrun start <path-to-vmx>` | Start a VM |
| `vmrun stop <path-to-vmx>` | Stop a VM |
| `vmrun pause <path-to-vmx>` | Pause a VM |
| `vmrun unpause <path-to-vmx>` | Unpause a VM |
| `vmrun listSnapshots <path-to-vmx>` | List snapshots |
| `vmrun snapshot <path-to-vmx> NAME` | Create snapshot |

---

## 📁 VM Storage Locations

| Path | Description |
|------|-------------|
| `~/.vagrant.d/boxes/` | Where Vagrant stores downloaded boxes |
| `.vagrant/` | Local VM metadata (in project directory) |

---

## 🔧 Troubleshooting Mac Silicon

If you encounter errors with VirtualBox on Mac Silicon:

1. Install **VMware Fusion** (free for personal use)
2. Install VMware utility: `brew install vagrant-vmware-utility`
3. Install Vagrant plugin: `vagrant plugin install vagrant-vmware-desktop`
4. Use ARM64 compatible box (e.g., `starboard/ubuntu-arm64-20.04.5`)
5. Remove lock files if needed: `rm -rf ~/.vagrant.d/boxes/*/lck`

