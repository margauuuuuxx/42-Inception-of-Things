# 🚀 Inception of Things - Setup Guide

## 📋 Prerequisites

- First install vagrant
- **For Mac Silicon (M1/M2/M3):** Install VMware Fusion and vagrant-vmware-desktop plugin

---

## 🛠️ Vagrant Commands

### Basic VM Operations

| Command | Description |
|---------|-------------|
| `vagrant init` | Create a new Vagrantfile (ruby) |
| `vagrant validate` | Check Vagrantfile correctness |
| `vagrant status` | Show status of the VMs in the current Vagrantfile |
| `vagrant global-status` | Show status of all Vagrant VMs on the system |
| `vagrant global-status --prune` | Clean up stale Vagrant entries |
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
| `vagrant up && vagrant ssh` | Start and immediately SSH in |
| `vagrant halt && vagrant destroy -f` | Stop and delete |

### Snapshot Management

> 📂 Snapshot location: `~/.vagrant/machines/<machine name>/<snapshot name>`

| Command | Description |
|---------|-------------|
| `vagrant snapshot save NAME` | Create a snapshot |
| `vagrant snapshot list` | List all snapshots |
| `vagrant snapshot restore NAME` | Restore a snapshot |
| `vagrant snapshot delete NAME` | Delete a snapshot |

### Box Management

> 📦 Boxes stored in `~/.vagrant.d/boxes`

| Command | Description |
|---------|-------------|
| `vagrant box list` | List all boxes |
| `vagrant box add` | Adds a box to local box repo |
| `vagrant box remove <box name>` | Remove the wrong box from cache |
| `vagrant box outdated` | Checks if any boxes in local repo is outdated |
| `vagrant box prune` | Remove old box versions |
| `vagrant box repackage` | Repackages a box with a new name & metadata |

### Plugin Management

> 🔌 Finding plugins: https://github.com/hashicorp/vagrant/wiki/Available-Vagrant-Plugins  
> 📂 Plugins location: `~/.vagrant.d/`

| Command | Description |
|---------|-------------|
| `vagrant plugin list` | List installed plugins |
| `vagrant plugin install NAME` | Install a plugin |
| `vagrant NAME` | Use the plugin |
| `vagrant plugin update (NAME)` | Update plugin(s) |
| `vagrant plugin uninstall NAME` | Uninstall a plugin |
| `vagrant plugin expunge` | Delete all plugins |
| `vagrant plugin expunge --reinstall` | Reinstall all expunged plugins |

---

## ⚙️ VMware CLI Commands

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

## 🔍 Checking Port Forwarding

### On the Host

| Method | Command |
|--------|---------|
| Using curl | `curl http://localhost:<port>` |
| Using lsof | `sudo lsof -iTCP:8080 -sTCP:LISTEN` |

### On the Guest

```bash
sudo systemctl status apache2
```

---

## 📁 Storage Locations

| Path | Description |
|------|-------------|
| `~/.vagrant.d/boxes/` | Where Vagrant stores downloaded boxes |
| `~/.vagrant.d/` | Plugins location |
| `.vagrant/` | Local VM metadata (in project directory) |
| `~/.vagrant/machines/<machine name>/<snapshot name>` | Snapshot location |

---

## 🧰 Additional Tools

### Vagrantfile Generator

Easily generate a Vagrantfile: https://vagrantfile-generator.vercel.app/

---

## 🔧 Troubleshooting Mac Silicon

If you encounter errors with VirtualBox on Mac Silicon:

1. Install **VMware Fusion** (free for personal use)
2. Install VMware utility: `brew install vagrant-vmware-utility`
3. Install Vagrant plugin: `vagrant plugin install vagrant-vmware-desktop`
4. Use ARM64 compatible box (e.g., `starboard/ubuntu-arm64-20.04.5`)
5. Remove lock files if needed: `rm -rf ~/.vagrant.d/boxes/*/lck`

---

## 📚 Learning Resources

- YouTube Playlist for Vagrant: https://www.youtube.com/playlist?list=PLhW3qG5bs-L9S272lwi9encQOL9nMOnRa

---

## ✅ K3s Verification

### Checking K3s Installation

SSH into your VM and verify the service:

```bash
sudo systemctl status k3s
```

Expected output: `Active: active (running)`

### Viewing Cluster Status

**On Server Node:**
```bash
sudo k3s kubectl get nodes
```

Expected output:
```
NAME        STATUS   ROLES           AGE    VERSION
marloncos   Ready    control-plane   5m3s   v1.34.3+k3s1
```

**On Agent Node:**
```bash
k3s kubectl get nodes
``` 
