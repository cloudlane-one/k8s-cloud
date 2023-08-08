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

## Setup

> How to setup a k8s production cluster on bare Linux hosts in under 15 minutes.

The Ansible playbook code in here is meant to be run from a Linux workstation. On Windows you may use WSL.

Make sure your workstation can connect and authenticate as a privileged user via ssh to all of the remote hosts, which are to be setup as the nodes of your cluster.

These system dependencies are to be installed on your local machine.

- [Python](https://www.python.org/downloads/)
- [Poetry](https://python-poetry.org)

Then clone this repo to your workstation, copy the playbook template `playbooks/_managed_cluster` and switch dirs into it:

```bash
cp ./playbooks/_managed_cluster ./playbooks/$CLUSTER_NAME
cd ./playbooks/$CLUSTER_NAME
```

Replace `$CLUSTER_NAME` with an arbitrary alphanumeric name for your cluster.
Continue with the steps described in the template's README.

## Operations

For cluster operations, which do not change the set of nodes, the Ansible playbook isn't required. You can use `kubectl` or specific CLI tools relying on `kubectl` to perform these operations.

These CLI tools are installed automatically on all control hosts:

- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/docs/helm/)
- [flux](https://fluxcd.io/flux/cmd/)
- [velero](https://velero.io/)
- [vcluster](https://www.vcluster.com/)

Best just `ssh` into one of the control hosts and perform operations from there.

## Troubleshooting

### UPGRADE FAILED: another operation (install/upgrade/rollback) is in progres

Likely a previous helm operation was interrupted, leaving it in an intermediate state. See [this StackOverflow response](https://stackoverflow.com/a/71663688) for possible solutions.
