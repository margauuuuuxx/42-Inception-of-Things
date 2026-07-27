# Inception of Things - Setup Guide

## Prerequisites

- First install vagrant
- **For Mac Silicon (M1/M2/M3):** Install VMware Fusion and vagrant-vmware-desktop plugin

---

## How the VMs are actually managed (nobody clicks "New VM")

It's easy to assume Kubernetes-on-a-VM projects start with opening VMware
Fusion and clicking through a "create new virtual machine" wizard. **That
never happens here.** Every VM in this repo is created, booted, networked and
torn down entirely by Vagrant, driven by a single `Vagrantfile`. The role of
each moving piece:

**The chain, and the metaphor to hang it on:** think of yourself as an
**architect who never picks up a hammer**. You draw the blueprint
(`Vagrantfile`: which box/OS, how much RAM/CPU, which IP). You hand it to a
**general contractor** (`vagrant`), and say one sentence: `vagrant up`. The
contractor doesn't build anything either — they call the actual **construction
crew and machinery** that pours concrete and puts up walls: on Apple Silicon
that crew is **VMware Fusion** (Apple Silicon can't run VirtualBox reliably,
so Fusion + its ARM64 boxes is the crew we hire instead). Because the
contractor (Vagrant) and the crew (Fusion) speak different languages, there's
a **dispatcher radio** sitting between them: a small background service called
`vagrant-vmware-utility`, listening on `127.0.0.1:9922`. If that radio is off,
the contractor shouts instructions into dead air — which is exactly what
happened after months without touching this project: the dispatcher daemon
had gone quiet and had to be manually reconnected
(`sudo launchctl bootstrap system /Library/LaunchDaemons/com.vagrant.vagrant-vmware-utility.plist`)
before `vagrant up` could reach the crew again.

Once the building (VM) is actually standing, you don't commute to the job
site to work in it. You open a live window straight into the finished office
from your own desk — that's **VS Code's Remote-SSH**.

### Day-to-day coding workflow

1. `cd p1 && vagrant up` — Vagrant relays the blueprint through the dispatcher
   to Fusion, which creates/boots `marloncoS` and `marloncoSW` from the cached
   `starboard/ubuntu-arm64-20.04.5` box. No manual VM setup, every time
   reproducible from the `Vagrantfile`.
2. `vagrant ssh-config marloncoS` — prints the `Host` / `HostName` /
   `IdentityFile` block Vagrant generated for passwordless SSH into that VM.
3. Add that block to `~/.ssh/config` (or `vagrant ssh-config marloncoS >>
   ~/.ssh/config`), then in VS Code: Command Palette → **Remote-SSH: Connect
   to Host** → pick `marloncoS`. VS Code re-opens with the *guest's*
   filesystem as the workspace — real terminal, real extensions, but every
   keystroke executes inside the Linux VM, not on the Mac.
4. The repo folder is also live-synced into the guest at `/vagrant` (Vagrant's
   default shared folder), so editing files from the host directly (without
   Remote-SSH) also reflects instantly inside the VM — useful for quick edits
   without switching windows.
5. Inside the VM (via the Remote-SSH terminal or `vagrant ssh`), `kubectl` /
   `k3s kubectl` and `systemctl status k3s` are run directly against the local
   cluster — see the K3s Verification section below.
6. When done: `vagrant halt` (keep the VM for next time) or `vagrant destroy`
   (remove it — rebuildable any time from the `Vagrantfile` alone).

The one thing worth remembering after a long break: if `vagrant up` ever
fails with `Connection refused ... 127.0.0.1:9922`, the dispatcher radio
(`vagrant-vmware-utility`) just needs to be told to pick up again — it is not
a sign anything about the VMs or the project itself is broken.

---

## Vagrant Commands

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

> Snapshot location: `~/.vagrant/machines/<machine name>/<snapshot name>`

| Command | Description |
|---------|-------------|
| `vagrant snapshot save NAME` | Create a snapshot |
| `vagrant snapshot list` | List all snapshots |
| `vagrant snapshot restore NAME` | Restore a snapshot |
| `vagrant snapshot delete NAME` | Delete a snapshot |

### Box Management

> Boxes stored in `~/.vagrant.d/boxes`

| Command | Description |
|---------|-------------|
| `vagrant box list` | List all boxes |
| `vagrant box add` | Adds a box to local box repo |
| `vagrant box remove <box name>` | Remove the wrong box from cache |
| `vagrant box outdated` | Checks if any boxes in local repo is outdated |
| `vagrant box prune` | Remove old box versions |
| `vagrant box repackage` | Repackages a box with a new name & metadata |

### Plugin Management

> Finding plugins: https://github.com/hashicorp/vagrant/wiki/Available-Vagrant-Plugins  
> Plugins location: `~/.vagrant.d/`

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

## VMware CLI Commands

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

## Checking Port Forwarding

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

## Storage Locations

| Path | Description |
|------|-------------|
| `~/.vagrant.d/boxes/` | Where Vagrant stores downloaded boxes |
| `~/.vagrant.d/` | Plugins location |
| `.vagrant/` | Local VM metadata (in project directory) |
| `~/.vagrant/machines/<machine name>/<snapshot name>` | Snapshot location |

---

## Additional Tools

### Vagrantfile Generator

Easily generate a Vagrantfile: https://vagrantfile-generator.vercel.app/

---

## Troubleshooting Mac Silicon

If you encounter errors with VirtualBox on Mac Silicon:

1. Install **VMware Fusion** (free for personal use)
2. Install VMware utility: `brew install vagrant-vmware-utility`
3. Install Vagrant plugin: `vagrant plugin install vagrant-vmware-desktop`
4. Use ARM64 compatible box (e.g., `starboard/ubuntu-arm64-20.04.5`)
5. Remove lock files if needed: `rm -rf ~/.vagrant.d/boxes/*/lck`

---

## Learning Resources

- YouTube Playlist for Vagrant: https://www.youtube.com/playlist?list=PLhW3qG5bs-L9S272lwi9encQOL9nMOnRa
- Kubernetes for beginners: https://www.youtube.com/watch?v=s_o8dwzRlu4 

---

## K3s Verification

### Checking K3s Installation

SSH into your VM and verify the service:

```bash
systemctl status k3s
```

Expected output: `Active: active (running)`

### Viewing Cluster Status

**On Server Node:**
```bash
kubectl get nodes -o wide
```

Expected output:
```
NAME        STATUS   ROLES           AGE    VERSION
marloncoS   Ready    control-plane   5m3s   v1.34.3+k3s1
marloncoSW  Ready    <none>          3m2s   v1.34.3+k3s1  
```

**On Agent Node:**
```bash
sudo systemctl status k3s-agent 
curl -k https://192.168.56.110:6443/version
``` 


--- NEW INFO
kubectl get pod --> see all the existing Pods of the cluster
kubectl apply -f <config.yaml> --> creates the component defined in the config file 
    THERE'S AN ORDER in which they should be created depending on what component needs what (ex: webapp needs db)
kubectl get all --> gives all the components of the cluster
kubectl get configmap --> getting the ConfigMap components
kubectl get secret --> getting the Secret components 
kubectl describe <component_name> <component instance> --> retrieving all infos of a particular instanec of a particular component 
kubectl logs <pod name>
kubectl get node (-o wide) --> get node info
