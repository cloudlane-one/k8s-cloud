# k8s-cloud

[![Build](https://github.com/cloudlane-one/k8s-cloud/actions/workflows/release.yaml/badge.svg)](https://github.com/cloudlane-one/k8s-cloud/actions/workflows/release.yaml)
[![CodeFactor](https://www.codefactor.io/repository/github/cloudlane-one/k8s-cloud/badge)](https://www.codefactor.io/repository/github/cloudlane-one/k8s-cloud)

production-ready, provider-independent & easily manageable k8s cloud setup

## Purpose and scope

This project is intended to help beginner-to-intermediate **Kubernetes hobbyists and freelancers** with the mammoth task of **setting up, maintaining and updating a production k8s cloud setup**.

It builds on the idea that today you can find a tool for automating almost any given DevOps task. Therefore, the challenge lies less in learning to do any one of these tasks manually, and more in *finding the correct automation tools for the task at hand, separating the good from the bad, and making them work in unison*. Also, to be a functioning human in this automation loop, you should have a basic understanding of the underlying ideas and technologies at play.

While every DevOps engineer likely needs to put their own, manual learning work into the latter point, the former one can definitely be outsourced into a pre-made toolbox / system to save all of us a ton of time. This is what this project aims to do.

> As for the learning part: These docs point to a few, third-party resources to get newcomers started on each of the required basics, but this is by no means the focus of this work.

## Prior knowledge

To make proper use of this repository, you will need basic understanding of multiple IT domains and tools. Please have a look at the [Prior Knowledge Reference](./docs/ref-prior-knowledge.md) for an overview of relevant topics with further links to get you started learning.

## What's in the box

This repo contains the following components:

- `/roles`: Ansible roles for setting up a production-ready Kubernetes cluster.
- `/charts`: Helm charts, which can be deployed into the cluster.
  - `/charts/system`: System-level charts (storage, DNS, backup, etc.), which are deployed as part of the cluster setup.
  - `/charts/apps`: Helm charts for user applications (Nextcloud, Wordpress, etc.), which can be deployed on demand.
  - `/charts/config`: Supporting charts, which are depended upon by other charts in this repo.
- `/setup.yaml`: Ansible playbook to set up a cluster on a given inventory of nodes
- `/clusters`: Configuration for deployed clusters. The repo only contains one sub-directory as a template, which you need to copy to create your own cluster config.

## Cluster infrastructure

The following system / infrastructure components can be deployed via `setup.yaml`:

> Some of these can be disabled via the cluster config.

- Kubernetes:
  - [k3s](https://github.com/k3s-io/k3s) distribution
  - CNI configured for dual-stack, wireguard-encrypted networking
  - Alternatively: encrypted networking via [Tailscale](https://tailscale.com/) VPN to support nodes without static public IP
  - HA via embedded [etcd](https://github.com/etcd-io/etcd)
  - [Kubernetes-Dashboard](https://github.com/kubernetes/dashboard)
  - Other production config for k3s: Secrets encryption, metrics, OIDC auth, reserved resources, ...
- Storage:
  - [Longhorn](https://github.com/longhorn/longhorn) as storage provider
  - Multiple storage classes for different volume types
  - Local volumes or cross-node replication
  - Optional encryption via LUKS
  - Backup to and restore from S3 storage
  - Web UI for storage management
- Ingress:
  - [Ingress-NGINX](https://github.com/kubernetes/ingress-nginx) as ingress controller
  - Expose services via configurable pool of ingress nodes
  - Provides default ingress class
  - [CertManager](https://github.com/cert-manager/cert-manager) with preconfigured Letsencrypt ACME issuer to auto-provision (& renew) certificates
  - [External-DNS](https://github.com/kubernetes-sigs/external-dns) to auto-configure and continuously sync DNS records
- Authentication:
  - [Keycloak](https://github.com/keycloak/keycloak) as identity provider
  - Cluster-internal Single-Sign-On via OIDC or SAML
  - [OAuth2-Proxy](https://github.com/oauth2-proxy/oauth2-proxy) for proxy header auth
  - Web UI for user management etc.
- Telemetry System:
  - [Prometheus](https://github.com/prometheus/prometheus) for metrics collection
  - [Loki](https://github.com/grafana/loki) for logs collection
  - [Grafana](https://github.com/grafana/grafana) for dashboards and alerts
  - [Node-Exporter](https://github.com/prometheus/node_exporter)
  - [AlertManager](https://github.com/prometheus/alertmanager)
  - Auto-provisioned dashboards and email alerts for common cases / faults
- Backups:
  - [Velero](https://github.com/vmware-tanzu/velero)
  - Nightly full-cluster backups of all API resources and PV contents
  - Easy manual backing up and restoring
- GitOps System:
  - [FluxCD](https://github.com/fluxcd/flux2)
  - Continuous, rolling updates of deployed apps based on semver ranges
  - [Weave Gitops](https://github.com/weaveworks/weave-gitops) as Web UI
- Cluster Upgrades:
  - [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller)
  - Automatic, non-disruptive upgrades from k3s stable channel
  - Upgrades both master and worker nodes
- Virtual Clusters:
  - [VCluster](https://github.com/loft-sh/vcluster)
  - Create virtual sub-clusters, which are constrained to a specific namespace and subset of nodes
  - Each vcluster has a full k8s API and either reuses the infrastructure components of its host cluster (e.g. Longhorn) or deploys its own set internally
  - Useful for test environments or providing multi-tenancy with limited resources

## How to deploy a cluster

### Required resources

- One or more **linux machines managed by systemd**, to which you have root access
  - You can use your own hardware or rent dedicated / virtual machines in a datacenter.
  - [Strato](https://www.strato.de/server/linux-vserver/) and [Hetzner](https://www.hetzner.com/cloud) offer affordable VPS options
- A **domain** managed by one of the [providers supported by external-dns](https://github.com/kubernetes-sigs/external-dns#status-of-providers) with API access
  - Both [Digitalocean](https://www.digitalocean.com) and [Cloudflare](https://www.cloudflare.com) offer free DNS plans and have been tested with this setup.
- Credentials to an **SMTP server** to send automatic emails from
  - [Strato](https://www.strato.de/mail/) offers very affordable mail packages
- Credentials to an existing, empty **S3 bucket**
  - [OVH](https://www.ovhcloud.com/de/public-cloud/object-storage/) offers low-priced S3-compatible storage
- Optional: Free [Tailscale](https://tailscale.com/) account and credentials

### Workstation setup

The Ansible playbook code in here is meant to be run from a Linux workstation. On Windows you may use WSL.

These system dependencies are to be installed on your local machine.

- [Python](https://www.python.org/downloads/)
- [Poetry](https://python-poetry.org)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux)
- [Kubelogin](https://github.com/int128/kubelogin)

Clone the repo, `cd` to the cloned folder, and run following bash code to install all Python deps into a virtual environment:

```bash
poetry install
poetry shell
```

Then run this to install Ansible-specific dependencies:

```bash
ansible-galaxy install -r requirements.yaml
```

### About VClusters

Once you have gone through below setup steps to create a host cluster, you may repeat the same steps with a subset of the original nodes and different configuration to create a vcluster on top. Note that you have to set `cluster.components.k8s.virtual=true` in `./clusters/$CLUSTER_NAME/group_vars/cluster/configmap.yaml` for a vcluster to be created.

> ⚠️ You have to include at least one of the host cluster control nodes in the subset and mark it with `control=true`. This is required as certain setup steps have to be performed via ssh on a control node.
---
> Note that some config options are not available for vclusters. This is mentioned in the respective configmap template comments.
---
> Storage is managed fully by the host cluster, including backups of PVs

### Configuration

Copy the cluster inventory template `clusters/_example`:

```bash
cp ./clusters/_example ./clusters/$CLUSTER_NAME
```

Replace `$CLUSTER_NAME` with an arbitrary alphanumeric name for your cluster.

#### Hosts

Edit the hosts file `./clusters/$CLUSTER_NAME/hosts.yaml` to add all host machines, which are to be setup as the nodes of your cluster.

> Make sure your workstation can connect and authenticate as a privileged user via ssh to all of the remote hosts.

#### Backbone hosts

Backbone hosts are node hosts which have a direct and strong connection to the internet backbone, e.g. data centers,  and thus have low latency and high bandwith among them. This is important especially for distributed storage. Latency between all backbone nodes should be 100ms or less and bandwidth should be at least 1Gbps (up and down).

By default, nodes are assigned to the region `backbone` and the zone `default`. You may set `backbone=false` on a node in `hosts.yaml` to assign it to the `edge` region instead (disabling its participation in HA control plane and default distributed storage). You may additionally define a custom `zone` for each node.

> To only include a subset of hosts into the backbone, set `backbone=true` on the subset, and all other nodes will be assigned `backbone=false` automatically.

#### Control plane hosts

By default, the first backbone host is taken as the sole control plane host. If you want to change this bevavior, set the value `control=true` on a subset of hosts.

> It is recommended to have either one or at least 3 control plane nodes. Make sure you store the hosts file somewhere safe.
> Please also set `control nodes` for vclusters. This has no effect on where the control plane pods run, but it tells Ansible on which machines it can execute administrative tasks via ssh.

#### Ingress hosts

By default, the first backbone host is taken as the sole ingress host. If you want to change this bevavior, set the value `ingress=true` on a subset of hosts.

#### Storage hosts

By default, all hosts are taken as storage hosts, yet non-backbone hosts are excluded from distributed storage for performance reasons, hence they can only host single-replica, local volumes. To exclude hosts from being used for storage at all, set `storage=false` on them, or to only include a subset of hosts for storage, set `storage=true` on the subset.

#### Cluster config and secrets

Copy the default cluster config file `./roles/cluster-config/configmap.yaml` to `./clusters/$CLUSTER_NAME/group_vars/cluster/configmap.yaml` and the cluster secrets template file `./roles/cluster-config/secrets.yaml` to `./clusters/$CLUSTER_NAME/group_vars/cluster/secrets.yaml`. Fill in the required values and change or delete the optional ones to your liking.

### Cluster setup

> Please either manually make sure that all your nodes are listed as trusted in `known_hosts` or append `-e auto_trust_remotes=true` to below command, otherwise you will have to type `yes` and hit Enter for each of your hosts at the beginning of the playbook run.

To setup all you provided hosts as Kubernetes nodes and join them into a single cluster, run:

```bash
ansible-playbook setup.yaml -i clusters/$CLUSTER_NAME
```

> If you recently rebuilt the OS on any of the hosts and thereby lost its public key, make sure to also update (or at least delete) its `known_hosts` entry, otherwise Ansible will throw an error. You can also append `-e clear_known_hosts=true` to above command to delete the `known_hosts` entries for all hosts in the inventory before executing the setup.

## How to do cluster operations

### Dashboards

As already mentioned above, this Kubernetes setup includes multiple web dashboards, which allow you to do various maintenance tasks and are available under different subdomains of the domain you supplied in the cluster config:

- `id.yourdomain.org`
  - Keycloak Web UI
  - Manage your Single-Sign-On users, groups and OIDC/SAML clients
  - Manage your own admin credentials
- `kubectl.yourdomain.org`
  - Kubernetes Dashboard
  - List k8s API resources with their attributes, events and some metrics
  - Manually create, mutate and delete any resource
  - Deploy new GitOps resources
  - View most recent logs of pods or shell into their containers
- `gitops.yourdomain.org`
  - Weave GitOps Dashboard
  - List all deployed GitOps resources with their attributes and state
  - Sync, pause and resume resources
- `telemetry.yourdomain.org`
  - Grafana Dashboard UI
  - View and search logs of the past few days
  - Query and visualize in-depth metrics
  - Check the state of (preconfigured) alert rules
- `longhorn.yourdomain.org`
  - Longhorn UI
  - Manage and monitor persistent storage nodes, volumes and backups
  - Only available in a host cluster

> All these dashboards are secured via OIDC authentication

### CLI / API operations

For most cluster operations the Ansible playbook isn't required. You can instead use `kubectl` or specific CLI tools relying on `kubectl` (or the k8s API directly). These CLI tools are installed automatically on all control hosts:

- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/docs/helm/)
- [flux](https://fluxcd.io/flux/cmd/)
- [velero](https://velero.io/)
- [vcluster](https://www.vcluster.com/)

> Best just `ssh` into one of the control hosts and perform operations from the terminal there.

#### Removing nodes

1. *Via Longhorn Web UI_:\
   [Request eviction](https://longhorn.io/docs/1.5.1/volumes-and-nodes/disks-or-nodes-eviction/#select-disks-or-nodes-for-eviction) of the associated Longhorn storage node.
2. Wait for all volumes to be evicted.
3. *Via terminal on any control node_:\
   [`kubectl drain` the k8s node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#use-kubectl-drain-to-remove-a-node-from-service) to evict all running pods from it and disable scheduling.
   > You will probably want to run `kubectl drain` with these flags: `--ignore-daemonsets --delete-emptydir-data`
4. Wait for all pods to be evicted.
5. *Via terminal on the node to be removed_:\
   Execute [uninstall script](https://docs.k3s.io/installation/uninstall):
   - For agents: `/usr/local/bin/k3s-agent-uninstall.sh`
   - For servers: `/usr/local/bin/k3s-uninstall.sh`
6. *Via kubectl on control node or k8s-dashboard_:\
   Delete the `Node` resource object.

### Ansible operations

#### Adding nodes

Simply add new node hosts **to the end** of your cluster's `hosts.yaml` and re-run the setup playbook.

> ⚠️ Adding new control nodes is currently untested and could leave your cluster in a failed state!

## How to deploy apps

While you are free to deploy any containerized app into your cluster, a few select ones have been optimized to work well with the specific storage / networking / authentication infrastructure of this project. Concretely, these are custom helm charts (partly based on the official helm charts of these apps), which are contained in the folder `/charts/apps`. To deploy any of these custom helm charts, follow these steps:

> Note that this is one way to do it. If you have experience with k8s and GitOps, feel free to use your own tools.

1. Open up the Kubernetes Dashboard UI under `kubectl.yourdomain.org`.
2. Open up the form for creating a new resource via the `+` button at the top right.
3. Paste this template for a FluxCD helm release into the form:

    ```yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: "" # Custom name of your release
      namespace: "" # Name of an existing namespace (best create a new one)
    spec:
      chart:
        spec:
          chart: "" # Name of the chart in /charts/apps
          sourceRef:
            kind: HelmRepository
            name: base-app-repo
            namespace: flux-system
          version: "" # Semver version constraint (use the latest version)
      interval: 1h
      values: {} # Custom values. See the chart's values.yaml file.
    ```

4. Fill in the missing values and hit `Upload`.
5. Monitor the release's progress via `gitops.yourdomain.org`.

> You can also find a list of all deployed HelmReleases in the Kubernetes Dashboard.

## Troubleshooting

### UPGRADE FAILED: another operation (install/upgrade/rollback) is in progres

Likely a previous helm operation was interrupted, leaving it in an intermediate state. See [this StackOverflow response](https://stackoverflow.com/a/71663688) for possible solutions.

### Persistent Volume Claim is stuck being deleted

Have a look at the field `metadata.finalizers` of the PVC in question. If it contains [`snapshot.storage.kubernetes.io/pvc-as-source-protection`](https://kubernetes.io/docs/concepts/storage/volume-snapshots/#persistent-volume-claim-as-snapshot-source-protection), then there exists an unfinished volume snapshot of this PVC. This could mean that a snapshot is being created right now, in which case the finalizer should be removed within the next few minutes (depending on volume size) and then the PVC deleted, but it could also mean that there exists a failed snapshot, in which case k8s unfortunately leaves the finalizer indefinitely.

If you do not care about the integrity of the PVC's snapshots (because you don't want to keep backups) then you can remove the finalizer entry manually and thereby trigger immediate deletion. Otherwise best wait for about an hour and only then remove the finalizer manually.
