# k8s-cloud

production-ready, provider-independent & easily manageable k8s cloud setup

## Prior knowledge

To make proper use of this repository, you will need basic understanding of multiple IT domains and tools. Please have a look at the [Prior Knowledge Reference](./docs/ref-prior-knowledge.md) for an overview of relevant topics with further links to get you started learning.

## What is included

The cluster set up by this repo consists of a multitude of open-source projects, which all work together to make the cluster production-ready:

- Kubernetes distribution: [k3s](https://github.com/k3s-io/k3s)
  - CNI configured for dual-stack, wireguard-encrypted networking
  - Alternatively: networking via [Tailscale](https://tailscale.com/) VPN (to support nodes without static public IP)
  - HA via embedded [etcd](https://github.com/etcd-io/etcd)
  - [Kubernetes-Dashboard](https://github.com/kubernetes/dashboard)
- Storage System: [Longhorn](https://github.com/longhorn/longhorn)
  - Local and distributed volumes
  - Backup to and restore from S3 storage
  - Web UI for storage management
  - Provides default storage class for PVC provisioning
- Ingress Controller: [Ingress-NGINX](https://github.com/kubernetes/ingress-nginx)
  - Exposed via configurable pool of ingress nodes
  - Provides default ingress class
- Certificate Manager: [CertManager](https://github.com/cert-manager/cert-manager)
  - Letsencrypt ACME issuer to auto-provision certificates for ingresses
- DNS Manager: [External-DNS](https://github.com/kubernetes-sigs/external-dns)
  - Auto-configure and continuously sync DNS records for subdomains
  - Works with many major DNS providers
- Identity Provider: [Keycloak](https://github.com/keycloak/keycloak)
  - Single-Sign-On via OIDC or SAML
  - [OAuth2-Proxy](https://github.com/oauth2-proxy/oauth2-proxy) for header auth
  - Cluster-internal OIDC client is auto-provisioned
  - Web UI for user management etc.
- Telemetry System: [Prometheus](https://github.com/prometheus/prometheus) + [Loki](https://github.com/grafana/loki) + [Grafana](https://github.com/grafana/grafana)
  - [Node-Exporter](https://github.com/prometheus/node_exporter)
  - [AlertManager](https://github.com/prometheus/alertmanager)
  - Auto-provisioned dashboards and alerts
- Cluster Backup System: [Velero](https://github.com/vmware-tanzu/velero)
  - Nightly full-cluster backups
  - Easy manual backing up and restoring
- GitOps System: [FluxCD](https://github.com/fluxcd/flux2)
  - Continuous, rolling updates of deployed apps based on semver ranges
  - [Weave Gitops](https://github.com/weaveworks/weave-gitops) as Web UI
- Upgrade System: [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller)
  - Automatic, non-disruptive upgrades from k3s stable channel
  - Upgrades both master and worker nodes

## Required resources

- One or more linux machines managed by systemd, to which you have root access
  - Cheapest tested option: [Strato VPS](https://www.strato.de/server/linux-vserver/)
  - Best value for money among tested: [Hetzner VPS](https://www.hetzner.com/cloud)
- A domain managed by one of the [providers supported by external-dns](https://github.com/kubernetes-sigs/external-dns#status-of-providers) with API access
  - Both [Digitalocean](https://www.digitalocean.com) and [Cloudflare](https://www.cloudflare.com) offer free DNS plans and have been tested with this setup.
- Credentials to an SMTP server to send automatic emails from
  - [Strato](https://www.strato.de/mail/) offers very affordable mail packages
- Credentials to an existing, empty S3 bucket
  - [OVH](https://www.ovhcloud.com/de/public-cloud/object-storage/) offers low-prices S3-compatible storage
- Optional: Free [Tailscale](https://tailscale.com/) account and credentials

### Workstation setup

The Ansible playbook code in here is meant to be run from a Linux workstation. On Windows you may use WSL.

These system dependencies are to be installed on your local machine.

- [Python](https://www.python.org/downloads/)
- [Poetry](https://python-poetry.org)
- [Kubelogin](https://github.com/int128/kubelogin)

Clone the repo, `cd` to the cloned folder, and run following bash code to install all Python deps into a virtual environment:

```bash
poetry install
```

Then run this to install Ansible-specific dependencies:

```bash
ansible-galaxy install -r requirements.yaml
```

## Cluster setup

> How to setup a k8s production cluster on bare Linux hosts in under 15 minutes.

First activate the poetry env via:

```bash
poetry shell
```

Copy the cluster inventory template `clusters/_example`:

```bash
cp ./clusters/_example_ ./clusters/$CLUSTER_NAME
```

Replace `$CLUSTER_NAME` with an arbitrary alphanumeric name for your cluster.

### Provide configuration

#### Hosts

Edit the hosts file `./clusters/$CLUSTER_NAME/hosts.yaml` to add all host machines, which are to be setup as the nodes of your cluster.

> Make sure your workstation can connect and authenticate as a privileged user via ssh to all of the remote hosts.

#### Backbone hosts

Backbone hosts are node hosts which have a direct and strong connection to the main network of your cluster and thus have low latency and high bandwith over that network. This is important especially for distributed storage.

This main network could either be the WAN, aka the public internet, or the LAN network, where the majority of your hosts reside. Latency between all backbone nodes should be 100ms or less and bandwidth should be at least 1Gbps (up and down).

> Note that `backbone` does not make any statement about failure domains or availability zones. If you want to build a hierarchy of zones, please add `region` and `zone` labels to your hosts.

By default, all hosts in `hosts.yaml` are taken to be backbone nodes. To exclude hosts with slower connections, set `backbone=false` on them, or to only include a subset of hosts into the backbone, set `backbone=true` on the subset.

#### Control plane hosts

By default, the first backbone host is taken as the sole control plane host. If you want to change this bevavior, set the value `control=true` on a subset of hosts.

> It is recommended to have either one or at least 3 control plane nodes. Make sure you store the hosts file somewhere safe.
> Please also set `control nodes` for vclusters. This has no effect on where the control plane pods run, but it tells Ansible on which machines it can execute administrative tasks.

#### Ingress hosts

By default, the first backbone host is taken as the sole ingress host. If you want to change this bevavior, set the value `ingress=true` on a subset of hosts.

#### Storage hosts

By default, all hosts are taken as storage hosts, yet non-backbone hosts are excluded from distributed storage for performance reasons, hence they can only host single-replica, local volumes. To exclude hosts from being used for storage at all, set `storage=false` on them, or to only include a subset of hosts for storage, set `storage=true` on the subset.

#### Cluster config and secrets

Then copy the default cluster config file `./roles/cluster-config/configmap.yaml` to `./clusters/$CLUSTER_NAME/group_vars/cluster/configmap.yaml` and the cluster secrets template file `./roles/cluster-config/secrets.yaml` to `./clusters/$CLUSTER_NAME/group_vars/cluster/secrets.yaml`. Fill in the required values and change or delete the optional ones to your liking.

### Setup the cluster

> Please either manually make sure that all your nodes are listed as trusted in `known_hosts` or append `-e auto_trust_remotes=true` to below command, otherwise you will have to type `yes` and hit Enter for each of your hosts at the beginning of the playbook run.

To setup all you provided hosts as kubernetes nodes and join them into a single cluster, run:

```bash
ansible-playbook setup.yaml -i clusters/$CLUSTER_NAME
```

> If you recently rebuilt the OS on any of the hosts and thereby lost its public key, make sure to also update (or at least delete) its `known_hosts` entry, otherwise Ansible will throw an error. You can also append `-e clear_known_hosts=true` to above command to delete the `known_hosts` entries for all hosts in the inventory before executing the setup.

## Operations

For cluster operations, which do not change the set of nodes, the Ansible playbook isn't required. You can use `kubectl` or specific CLI tools relying on `kubectl` to perform these operations.

These CLI tools are installed automatically on all control hosts:

- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/docs/helm/)
- [flux](https://fluxcd.io/flux/cmd/)
- [velero](https://velero.io/)
- [vcluster](https://www.vcluster.com/)

Best just `ssh` into one of the control hosts and perform operations from there.

### Adding nodes

Simply add new node hosts to your cluster's `hosts.yaml` and re-run the setup playbook.

> **Attention:** Adding new control nodes is currently untested and could leave your cluster in a failed state!

### Removing nodes

#### Manual steps for each node

1. *Via Longhorn Web UI*: [Request eviction](https://longhorn.io/docs/1.5.1/volumes-and-nodes/disks-or-nodes-eviction/#select-disks-or-nodes-for-eviction) of the associated Longhorn storage node.
2. Wait for all volumes to be evicted.
3. *Via terminal on any control node*: [`kubectl drain` the k8s node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#use-kubectl-drain-to-remove-a-node-from-service) to evict all running pods from it and disable scheduling.
4. Wait for all pods to be evicted.
5. **For control nodes**:
   - [Install etcdctl](https://docs.k3s.io/advanced#using-etcdctl) on one of the control nodes.
   - [Remove the etcd node](https://etcd.io/docs/v3.5/tutorials/how-to-deal-with-membership/) via `etcdctl member remove`.

#### Batch removal

Create a copy of your `./clusters/$CLUSTER_NAME` directory named `./clusters/$CLUSTER_NAME-unprovision` and only keep hosts in `hosts.yaml`, **that you want to be removed**. Then run:

```bash
ansible-playbook destroy.yaml -i clusters/$CLUSTER_NAME-unprovision
```

## Troubleshooting

### UPGRADE FAILED: another operation (install/upgrade/rollback) is in progres

Likely a previous helm operation was interrupted, leaving it in an intermediate state. See [this StackOverflow response](https://stackoverflow.com/a/71663688) for possible solutions.
