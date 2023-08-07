# k8s-cloud

production-ready, provider-independent & easily manageable k8s cloud setup

## Prior knowledge

To make proper use of this repository, you will need basic understanding of multiple IT domains and tools. Below you find lists of these along with recommended tutorials.

> Order matters here!

1. Linux Servers

   - [How to interact with Linux via a terminal](https://www.digitalocean.com/community/tutorials/an-introduction-to-linux-basics)
   - [How to use SSH](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-to-connect-to-a-remote-server)

2. Containers

   - [What are containers and why are they needed](https://www.docker.com/resources/what-container/)

3. Kubernetes

   - [What is Kubernetes and why is it needed](https://kubernetes.io/docs/concepts/overview/)
   - [How to deploy and manage a simple web app with k8s](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
   - [Which common k8s distributions exist](https://kubernetes.io/partners/#conformance)
   - [What is k3s and how is it different from other distributions](https://docs.k3s.io/)
   - [Which open standards is Kubernetes built on](https://medium.com/devops-mojo/kubernetes-open-standards-oci-cri-cni-csi-smi-cpi-overview-what-is-k8s-open-standards-introduction-a860905af6f7)
   - [What is Helm and why is it useful for managing deployments in Kubernetes](https://tanzu.vmware.com/developer/guides/helm-what-is/)

4. DevOps

   - [What is Ansible and what is it used for](https://dev.to/grayhat/devops-101-introduction-to-ansible-1n64)
   - [How to use Ansible playbooks](https://www.tutorialworks.com/ansible-run-playbook/)
   - [What is GitOps](https://www.weave.works/blog/what-is-gitops-really)

## What is included

The cluster set up by this repo consists of a multitude of open-source projects, which all work together to make the cluster production-ready:

- Kubernetes distribution: [k3s](https://github.com/k3s-io/k3s)
  - CNI configured for dual-stack, wireguard-encrypted networking
  - Optionally configured for HA via embedded etcd
- Container Storage Interface (CSI): [Longhorn](https://github.com/longhorn/longhorn)
- Ingress Controller: [Ingress-NGINX](https://github.com/kubernetes/ingress-nginx)
- Certificate Management: [CertManager](https://github.com/cert-manager/cert-manager)
- DNS Management: [External-DNS](https://github.com/kubernetes-sigs/external-dns)
- Single Sign-On: [Keycloak](https://github.com/keycloak/keycloak) as IDP + [OAuth2-Proxy](https://github.com/oauth2-proxy/oauth2-proxy)
- Observability: [Kubernetes-Dashboard](https://github.com/kubernetes/dashboard) + [Prometheus](https://github.com/prometheus/prometheus) + [AlertManager](https://github.com/prometheus/alertmanager) + [Node-Exporter](https://github.com/prometheus/node_exporter) + [Loki](https://github.com/grafana/loki) + [Grafana](https://github.com/grafana/grafana)
- Cluster Backups: [Velero](https://github.com/vmware-tanzu/velero)
- GitOps: [FluxCD](https://github.com/fluxcd/flux2) + [Weave Gitops](https://github.com/weaveworks/weave-gitops)
- Automatic, rolling k8s upgrades: [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller)

## Required resources

- One or more linux machines managed by systemd, to which you have root access
- A domain managed by Digitalocean and an access token for the Digitalocean API (more providers to be supported in the future)
- Credentials to an SMTP server to send automatic emails from
- Credentials to an existing, empty S3 bucket
- Optional: Tailscale account and credentials

## Setup

> How to setup a k8s production cluster on bare Linux hosts in under 15 minutes.

The Ansible playbook code in here is meant to be run from a Linux workstation. On Windows you may use WSL.

Make sure your workstation can connect and authenticate via ssh to all of the remote hosts, which are to be setup as the nodes of your cluster.

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

For cluster operations, which do not change the set of nodes, this playbook isn't required. You can use `kubectl` or specific CLI tools relying on `kubectl` to perform these operations.

`kubectl` is automatically installed and configured on all master nodes of the cluster. So best just `ssh` into one of them and perform below operations from there.

### Manual Full-Cluster Backups

This playbook installs [Velero](https://velero.io/) for managing full-cluster backups including persistent volumes. By default, a full backup is performed once a day and saved to the dafault backup location provided via cluster chart values. Nevertheless you might want to manually perform such a backup in between, for instance to migrate the cluster.

To do so, first [install the velero CLI](https://velero.io/docs/v1.9/basic-install/#install-the-cli) (just the CLI!) on a machine with kubectl-access to the cluster (e.g. one of the masters) and then simply type `velero backup create <BACKUP-NAME>`. The backup will then be saved under given name in the default backup storage location along with all automatic backups.

## Troubleshooting

### UPGRADE FAILED: another operation (install/upgrade/rollback) is in progres

Likely a previous helm operation was interrupted, leaving it in an intermediate state. See [this StackOverflow response](https://stackoverflow.com/a/71663688) for possible solutions.
