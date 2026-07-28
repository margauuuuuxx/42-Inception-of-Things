# Inception of Things - Setup Guide

## Prerequisites

- First install vagrant
- **For Mac Silicon (M1/M2/M3):** Install VMware Fusion and vagrant-vmware-desktop plugin

---

## Scope

This repository is the 42 "Inception-of-Things" project: a progressive
introduction to Kubernetes, built in three mandatory parts plus an optional
bonus, done in order:

- **p1 — K3s and Vagrant**: 2 VMs (`marloncoS` server, `marloncoSW` agent),
  provisioned entirely by Vagrant, running a 2-node K3s cluster.
- **p2 — K3s and three simple applications**: 1 VM, single-node K3s, three
  web apps routed through one Ingress by HTTP `Host` header.
- **p3 — K3d and Argo CD**: no Vagrant, K3d on the VM directly, GitOps
  deployment via Argo CD watching a public GitHub repo.
- **bonus — GitLab**: a locally-running GitLab instance added to the p3
  cluster, only attempted once p1-p3 are flawless.

Everything runs inside a VM; each part's deliverables live in its own
`p<N>/` folder at the repo root, each with a `scripts/` and `confs/`
subfolder by convention.

---

## Global Concepts

Concepts and mechanics that apply across more than one part — part-specific
plans and test commands live further down, under **Ex p1** / **Ex p2**.

### The Vagrant/VMware toolchain (nobody clicks "New VM")

It's easy to assume Kubernetes-on-a-VM projects start with opening VMware
Fusion and clicking through a "create new virtual machine" wizard. **That
never happens here.** Every VM in this repo is created, booted, networked and
torn down entirely by Vagrant, driven by a single `Vagrantfile` per part.

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
the contractor shouts instructions into dead air:

```
Connection refused ... 127.0.0.1:9922
```

That is not a sign anything about the VMs or the project itself is broken —
the dispatcher daemon just needs to be told to pick up again:

```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/com.vagrant.vagrant-vmware-utility.plist
# older macOS syntax, if bootstrap doesn't apply:
sudo launchctl load -w /Library/LaunchDaemons/com.vagrant.vagrant-vmware-utility.plist
```

Once the building (VM) is actually standing, you don't commute to the job
site to work in it. You open a live window straight into the finished office
from your own desk — that's **VS Code's Remote-SSH**.

#### Day-to-day coding workflow

1. `cd p1 && vagrant up` (or `p2`) — Vagrant relays the blueprint through the
   dispatcher to Fusion, which creates/boots the VM(s) from the cached box.
   No manual VM setup, every time reproducible from the `Vagrantfile` alone.
2. `vagrant ssh-config marloncoS` — prints the `Host` / `HostName` /
   `IdentityFile` block Vagrant generated for passwordless SSH into that VM.
3. Add that block to `~/.ssh/config` (or `vagrant ssh-config marloncoS >>
   ~/.ssh/config`), then in VS Code: Command Palette → **Remote-SSH: Connect
   to Host** → pick `marloncoS`. VS Code re-opens with the *guest's*
   filesystem as the workspace — real terminal, real extensions, but every
   keystroke executes inside the Linux VM, not on the Mac.
4. The part's folder is also live-synced into the guest at `/vagrant`
   (Vagrant's default shared folder), so editing files from the host directly
   (without Remote-SSH) also reflects instantly inside the VM.
5. Inside the VM (via the Remote-SSH terminal or `vagrant ssh`), `kubectl` is
   run directly against the local cluster — see **Ex p1** / **Ex p2** below.
6. When done: `vagrant halt` (keep the VM for next time) or `vagrant destroy`
   (remove it — rebuildable any time from the `Vagrantfile` alone).

### Kubernetes object model

The object kinds used across this project, and how they relate:

- **Deployment** — manages Pods indirectly, via an auto-created **ReplicaSet**
  (you never write a ReplicaSet by hand; `spec.replicas` + `spec.template` on
  the Deployment is what drives it).
- **Service (`ClusterIP`)** — finds its backing Pods purely through a label
  **selector** matching the Deployment's Pod-template labels. That selector
  match is the *entire* wiring mechanism — no other magic connects them. A
  Service load-balances traffic across all Pods it selects (e.g. p2's app2
  spreads requests across its 3 replicas) — this is a different layer from
  Ingress routing (see below).
- **Ingress** — implements HTTP **host-based virtual hosting**: one IP and
  port serving multiple distinct apps, where the `Host` header text in the
  request is the *only* thing that decides which app answers (the same
  mechanism as classic shared web hosting / nginx `server_name` blocks). K3s
  ships **Traefik** as its Ingress controller by default, so no separate
  controller install is needed. A rule with no `host:` value acts as a
  catch-all/default route.
- **ConfigMap** — used here to override a container's default file (e.g.
  nginx's `index.html`) via a volume mount, without baking custom content
  into the image itself.

`kubectl` itself is just a client talking to the cluster's API server via a
kubeconfig — it isn't tied to running on any particular node, and has no
relationship to Pods or Nodes beyond that config file.

### Host-header testing: curl vs. browser

Two independent, alternative ways to set the same `Host` header — not used
together:

- **curl**: sets it explicitly and directly, no DNS involved:
  ```bash
  curl -H "Host: app1.com" http://<ip>/
  ```
- **Browser**: cannot send a custom Host header manually. It sends whatever
  hostname you typed in the address bar. To make a browser send
  `Host: app1.com`, that hostname must actually *resolve* to the target IP
  first — via a local hosts-file entry (`sudo nano /etc/hosts` on macOS):
  ```
  192.168.56.110  app1.com
  192.168.56.110  app2.com
  ```
  Browsing to the bare IP directly sends the IP itself as the Host header,
  which matches no specific rule and falls through to the Ingress's default
  backend.

---

## Useful Commands

### Vagrant Commands

#### Basic VM Operations

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
| `vagrant reload --provision` | Restart VM and force provisioning scripts to re-run |
| `vagrant destroy` | Delete VM completely |
| `vagrant destroy -f` | Destroy VM completely (force delete without confirmation) |
| `vagrant ssh` | SSH into the running VM |
| `vagrant ssh-config` | Outputs OpenSSH valid config to connect to the VMs via SSH |
| `vagrant provision` | Re-run provisioning scripts |
| `vagrant package` | Packages a running virtual env into a reusable box |
| `vagrant up && vagrant ssh` | Start and immediately SSH in |
| `vagrant halt && vagrant destroy -f` | Stop and delete |

#### Snapshot Management

> Snapshot location: `~/.vagrant/machines/<machine name>/<snapshot name>`

| Command | Description |
|---------|-------------|
| `vagrant snapshot save NAME` | Create a snapshot |
| `vagrant snapshot list` | List all snapshots |
| `vagrant snapshot restore NAME` | Restore a snapshot |
| `vagrant snapshot delete NAME` | Delete a snapshot |

#### Box Management

> Boxes stored in `~/.vagrant.d/boxes`

| Command | Description |
|---------|-------------|
| `vagrant box list` | List all boxes |
| `vagrant box add` | Adds a box to local box repo |
| `vagrant box remove <box name>` | Remove the wrong box from cache |
| `vagrant box outdated` | Checks if any boxes in local repo is outdated |
| `vagrant box prune` | Remove old box versions |
| `vagrant box repackage` | Repackages a box with a new name & metadata |

#### Plugin Management

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

### VMware CLI Commands

| Command | Description |
|---------|-------------|
| `vmrun list` | List all running VMware VMs |
| `vmrun start <path-to-vmx>` | Start a VM |
| `vmrun stop <path-to-vmx>` | Stop a VM |
| `vmrun pause <path-to-vmx>` | Pause a VM |
| `vmrun unpause <path-to-vmx>` | Unpause a VM |
| `vmrun listSnapshots <path-to-vmx>` | List snapshots |
| `vmrun snapshot <path-to-vmx> NAME` | Create snapshot |

### kubectl Command Reference

| Command | Description |
|---------|-------------|
| `kubectl get pods -o wide` | List Pods, with node/IP columns |
| `kubectl get all` | List all resources (Pods, Services, Deployments, etc.) in the current namespace |
| `kubectl get nodes -o wide` | List cluster nodes with extra details |
| `kubectl get svc` | List Services |
| `kubectl get endpoints` | List every Service's backing Pod IPs in one table — faster than `describe svc` per Service |
| `kubectl get ingress` | List Ingress objects (summary view only — no default-backend column) |
| `kubectl get configmap` | List ConfigMap resources |
| `kubectl get secret` | List Secret resources |
| `kubectl apply -f <file or dir>` | Create/update the resource(s) defined in the file(s) — idempotent, safe to re-run |
| `kubectl apply --dry-run=client -f <file>` | Validate YAML locally, no cluster contact at all |
| `kubectl apply --dry-run=server -f <file>` | Validate against the real API server's schema without persisting — catches required-field errors client-side dry-run misses |
| `kubectl describe <resource type> <instance name>` | Show full details of a specific resource instance (for a Service, check the `Endpoints:` line to confirm selector wiring) |
| `kubectl logs <pod name>` | Show logs for a Pod |
| `kubectl create deployment <name> --image=<img> --dry-run=client -o yaml` | Scaffold a Deployment manifest without applying it |
| `kubectl expose -f <file>.yaml --port=<p> --target-port=<p> --type=ClusterIP --dry-run=client -o yaml` | Scaffold a matching Service directly from a local (not-yet-applied) Deployment file |

> **Apply order matters.** When a component depends on another (e.g. a webapp
> that needs a database), apply the dependency first — `kubectl apply -f`
> does not resolve creation order across files automatically.

### Checking Port Forwarding

#### On the Host

| Method | Command |
|--------|---------|
| Using curl | `curl http://localhost:<port>` |
| Using lsof | `sudo lsof -iTCP:8080 -sTCP:LISTEN` |

#### On the Guest

```bash
sudo systemctl status apache2
```

### Storage Locations

| Path | Description |
|------|-------------|
| `~/.vagrant.d/boxes/` | Where Vagrant stores downloaded boxes |
| `~/.vagrant.d/` | Plugins location |
| `.vagrant/` | Local VM metadata (in project directory) |
| `~/.vagrant/machines/<machine name>/<snapshot name>` | Snapshot location |

### Troubleshooting Mac Silicon

If you encounter errors with VirtualBox on Mac Silicon:

1. Install **VMware Fusion** (free for personal use)
2. Install VMware utility: `brew install vagrant-vmware-utility`
3. Install Vagrant plugin: `vagrant plugin install vagrant-vmware-desktop`
4. Use an ARM64-compatible box (e.g. `bento/ubuntu-24.04`)
5. Remove lock files if needed: `rm -rf ~/.vagrant.d/boxes/*/lck`

### Additional Tools

#### Vagrantfile Generator

Easily generate a Vagrantfile: https://vagrantfile-generator.vercel.app/

---

## Ex p1 — K3s and Vagrant

### Plan / Architecture

- **2 VMs**, 1 CPU / 512MB RAM each, defined in one `p1/Vagrantfile`:
  `marloncoS` (`192.168.56.110`) and `marloncoSW` (`192.168.56.111`).
- **`marloncoS` runs `provision_S.sh`**: installs K3s in **server** mode
  (`INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --tls-san=192.168.56.110"`),
  installs `kubectl`, configures a working kubeconfig for the `vagrant` user,
  then copies the cluster's `node-token` into the Vagrant-synced `/vagrant`
  folder so the worker can read it.
- **`marloncoSW` runs `provision_SW.sh`**: waits for `/vagrant/node-token` to
  exist, reads the token, then installs K3s in **agent** mode
  (`K3S_URL=https://192.168.56.110:6443`, `K3S_TOKEN=$TOKEN`), joining the
  cluster as a worker.
- Both scripts uninstall any previous K3s install first (`k3s-uninstall.sh` /
  `k3s-agent-uninstall.sh`), making `vagrant reload --provision` safe to
  re-run without leftover state.
- SSH access is passwordless by default — Vagrant auto-generates and injects
  an SSH keypair per VM, no extra configuration needed for that requirement.

### Testing p1

**On the server node:**
```bash
systemctl status k3s              # expect: Active: active (running)
kubectl get nodes -o wide
```
Expected:
```
NAME        STATUS   ROLES           AGE    VERSION
marloncoS   Ready    control-plane   5m3s   v1.34.3+k3s1
marloncoSW  Ready    <none>          3m2s   v1.34.3+k3s1
```
(`control-plane` role confirms the server; `<none>` confirms the agent joined
correctly rather than running its own separate control plane.)

**On the agent node:**
```bash
sudo systemctl status k3s-agent
curl -k https://192.168.56.110:6443/version   # confirms it can reach the server's API
```

**Passwordless SSH check:**
```bash
vagrant ssh marloncoS      # no password prompt = passwordless working
vagrant ssh marloncoSW
```

---

## Ex p2 — K3s and three simple applications

### Plan / Architecture

- **1 VM**, K3s in **server** mode only (no agent, no second node) —
  `p2/provision_S.sh` installs K3s, `kubectl`, then waits for the API to
  report the node `Ready` before continuing:
  ```bash
  until kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes | grep -q " Ready"; do
      sleep 2
  done
  ```
  (the wait matters: right after install the API server isn't necessarily
  up yet, and applying manifests too early can fail on a fresh `vagrant up`).
- The script finishes by applying every manifest in `p2/confs/` in one shot:
  ```bash
  kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml apply -f /vagrant/confs/
  ```
  Applying the whole directory (rather than listing filenames) means any new
  manifest dropped into `confs/` is picked up automatically with zero script
  changes.
- **`confs/app1.yaml` / `app2.yaml` / `app3.yaml`** — one file per app, each
  bundling a `ConfigMap` (custom `index.html`, so each app is visibly
  distinguishable), a `Deployment` (mounting that ConfigMap over nginx's
  default `index.html` via `subPath`, so only that one file is overridden),
  and a matching `ClusterIP` `Service` — three YAML documents per file,
  separated by `---`. `app2` sets `replicas: 3`; `app1`/`app3` stay at 1.
- **`confs/ingress.yaml`** — a single Ingress (`apps-ingress`) routing by
  `Host` header: `app1.com` → `app1` Service, `app2.com` → `app2` Service,
  and a **hostless rule** (no `host:` key) → `app3` Service as the catch-all
  default. A hostless rule was used instead of the Ingress spec's native
  `defaultBackend` field, because this K3s's bundled Traefik version doesn't
  reliably translate `defaultBackend` into an actual router — the hostless
  `rules` entry is the more portable mechanism and is confirmed working.
- All content differentiation and routing were verified end-to-end against
  the live cluster before being considered done — see the test commands
  below.

### Testing p2

**Cluster / resource state:**
```bash
kubectl get pods -o wide          # expect 5 pods: app1 x1, app2 x3, app3 x1
kubectl get deployments           # expect READY 1/1, 3/3, 1/1
kubectl get svc                   # expect app1/app2/app3, each with a real CLUSTER-IP
kubectl get endpoints             # expect app1: 1 IP, app2: 3 IPs, app3: 1 IP
kubectl get configmaps            # expect app1-html, app2-html, app3-html
kubectl get ingress               # HOSTS column only lists app1.com,app2.com — the
                                   # hostless default-route rule has no host, so it never
                                   # appears there; use `describe` to see it explicitly
kubectl describe ingress apps-ingress
```

**Direct Service test (bypassing Ingress), from inside the VM:**
```bash
kubectl get svc app1 -o jsonpath='{.spec.clusterIP}'
curl http://<clusterIP>:80        # expect the app's custom "Hello from appN" page
```

**Ingress routing test — same IP and port for all three, only the Host header changes:**
```bash
curl http://192.168.56.110/                             # expect app3 (default)
curl -H "Host: app1.com" http://192.168.56.110/          # expect app1
curl -H "Host: app2.com" http://192.168.56.110/          # expect app2
```
These work from inside the VM over SSH *or* directly from the host Mac's
terminal — unlike the ClusterIP test above, the Ingress listens on the node's
externally-reachable IP.

**Browser test from the host Mac:**
- `http://192.168.56.110` works immediately (app3, the default).
- `app1.com` / `app2.com` need a local hosts-file entry first — see
  [Host-header testing](#host-header-testing-curl-vs-browser) above.

**Final acceptance test** — proves the whole part reproduces from nothing,
with no manual `kubectl` commands needed after boot:
```bash
vagrant destroy -f && vagrant up
# then re-run the resource-state and curl checks above
```

---

## Learning Resources

- YouTube Playlist for Vagrant: https://www.youtube.com/playlist?list=PLhW3qG5bs-L9S272lwi9encQOL9nMOnRa
- Kubernetes for beginners: https://www.youtube.com/watch?v=s_o8dwzRlu4
- Kubernetes Ingress Rules: Path & Host-Based Routing Tutorial for Beginners: https://www.youtube.com/watch?v=FX4ORdJm9ms
- Ingress Explained: Kubernetes Load Balancing Demystified: https://www.youtube.com/watch?v=PRjKjAvBswk
- Kubernetes ReplicaSets Explained: https://www.youtube.com/watch?v=HB8FdWiXz28
- Kubernetes Pods, ReplicaSets & Deployments Explained in 10 Minutes: https://www.youtube.com/watch?v=S4ai6fJSFqs
- Ingressing with k3s: https://www.youtube.com/watch?v=QcC-5fRhsM8
- Rancher K3S Ingress Demo with Traefik: https://www.youtube.com/watch?v=12taKl5iCpA
