# k8s-baseline

production-ready, provider-independent & easily manageable k8s cluster setup

## Prior knowledge

To make proper use of this repository, you will need basic understanding of multiple IT domains and tools. Below you find lists of these along with recommended tutorials.

> Order matters here!

1. Linux Servers

- [How to interact with Linux via a terminal?](https://www.digitalocean.com/community/tutorials/an-introduction-to-linux-basics)
- [How to use SSH?](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-to-connect-to-a-remote-server)

2. Containers

- [What are containers and why are they needed?](https://www.docker.com/resources/what-container/)

3. Kubernetes

- [What is Kubernetes and why is it needed?](https://kubernetes.io/docs/concepts/overview/)
- [How to deploy and manage a simple web app with k8s?](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Which common k8s distributions exist?](https://kubernetes.io/partners/#conformance)
- [What is k3s and how is it different from other distributions?](https://docs.k3s.io/)
- [Which open standards is Kubernetes built on?](https://medium.com/devops-mojo/kubernetes-open-standards-oci-cri-cni-csi-smi-cpi-overview-what-is-k8s-open-standards-introduction-a860905af6f7)
- [What is Helm and why is it useful for managing deployments in Kubernetes?](https://tanzu.vmware.com/developer/guides/helm-what-is/)

4. DevOps

- [What is Ansible and what is it used for?](https://dev.to/grayhat/devops-101-introduction-to-ansible-1n64)
- [How to use Ansible playbooks?](https://www.tutorialworks.com/ansible-run-playbook/)
- [What is GitOps?](https://www.weave.works/blog/what-is-gitops-really)

## What is included

The cluster set up by this repo consists of a multitude of open-source projects, which all work together to make the cluster production-ready:

- Kubernetes distribution: [k3s](https://github.com/k3s-io/k3s)
- Container Networking Interface (CNI): [Cilium](https://github.com/cilium/cilium) with encrypted [WireGuard](https://github.com/WireGuard) tunneling
- Container Storage Interface (CSI): [Longhorn](https://github.com/longhorn/longhorn)
- Ingress Controller: [Ingress-NGINX](https://github.com/kubernetes/ingress-nginx)
- Certificate Management: [CertManager](https://github.com/cert-manager/cert-manager)
- DNS Management: [External-DNS](https://github.com/kubernetes-sigs/external-dns)
- Single Sign-On: [Dex](https://github.com/dexidp/dex) as OIDC broker + [OAuth2-Proxy](https://github.com/oauth2-proxy/oauth2-proxy)
- Observability: [Kubernetes-Dashboard](https://github.com/kubernetes/dashboard) + [Prometheus](https://github.com/prometheus/prometheus) + [AlertManager](https://github.com/prometheus/alertmanager) + [Node-Exporter](https://github.com/prometheus/node_exporter) + [Loki](https://github.com/grafana/loki) + [Grafana](https://github.com/grafana/grafana)
- Cluster Backups: [Velero](https://github.com/vmware-tanzu/velero)
- GitOps: [FluxCD](https://github.com/fluxcd/flux2) + [Weave Gitops](https://github.com/weaveworks/weave-gitops)

## Installation

> How to setup a cluster on bare linux hosts

### Install binary dependencies

These are to be installed on your local machine.

- [Python](https://www.python.org/downloads/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)

### Install Ansible role dependencies

```bash
ansible-galaxy install -r requirements.yaml
```

### Provide configuration

First copy the configuration template file `inventory.template.yaml` to `inventory.yaml`. Then edit the config options in the file to your liking.

### Setup the cluster

> Please either manually make sure that all you nodes are listed as trusted in `known_hosts` or set `auto_trust_remotes` to `true` in `inventory.yaml`, otherwise you will have to type `yes` and hit Enter for each of your hosts at the beginning of the playbook run.

To setup all you provided hosts as kubernetes nodes and join them into a single cluster, run:

```bash
ansible-playbook setup.yaml -i inventory.yaml
```

> If you want to restore from a cluster backup, simply append `-e restore_from_backup=<BACKUP-NAME>` to the command. In that case you only need to supply `s3` in `helm_values` and all else will be restored from the backup. Note that the `BACKUP-NAME` must correspond to an existing backup in the location supplied with `s3s`.

If you recently rebuilt the OS on any of the hosts and thereby lost its public key, make sure to also update (or at least delete) its `known_hosts` entry, otherwise Ansible will throw an error. There exists a helper playbook `utils/clear_known_hosts.yaml`, which you can run to delete the `known_hosts` entries for all hosts in the inventory at once.

## Cluster Operations

### Not altering the node pool

For cluster operations, which do not change the set of nodes, this playbook isn't required. You can use `kubectl` or specific CLI tools relying on `kubectl` to perform these operations.

`kubectl` is automatically installed and configured on all master nodes of the cluster. So best just ssh into one of them and perform below operations from there.

#### Kubernetes Version Upgrade

This playbook installs Rancher's [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller). In order to perform an upgrade via this controller, you need to create and apply one or more `Plan` CRDs. Please follow the official [Rancher instructions](https://docs.k3s.io/upgrades/automated#configure-plans) to learn how to do this.

#### Manual Full-Cluster Backups

This playbook installs [Velero](https://velero.io/) for managing full-cluster backups including persistent volumes. By default, a full backup is performed once a day and saved to the dafault backup location provided via infrastructure chart values. Nevertheless you might want to manually perform such a backup in between, for instance to migrate the cluster.

To do so, first [install the velero CLI](https://velero.io/docs/v1.9/basic-install/#install-the-cli) (just the CLI!) on a machine with kubectl-access to the cluster (e.g. one of the masters) and then simply type `velero backup create <BACKUP-NAME>`. The backup will then be saved under given name in the default backup storage location along with all automatic backups.

### Altering the node pool

For any operation, which adds or removes nodes, this playbook has to be used, as it contains certain steps which are required for installing, configuring and cleanly removing kubernetes from node hosts.

#### Extending the cluster

Please refer to [these docs](https://github.com/PyratLabs/ansible-role-k3s/blob/main/documentation/operations/extending-a-cluster.md)

#### Shrinking the cluster

Please refer to [these docs](https://github.com/PyratLabs/ansible-role-k3s/blob/main/documentation/operations/shrinking-a-cluster.md)

## Troubleshooting

### UPGRADE FAILED: another operation (install/upgrade/rollback) is in progres

Likely a previous helm operation was interrupted, leaving it in an intermediate state. See [this StackOverflow response](https://stackoverflow.com/a/71663688) for possible solutions.

### Re-running the playbook after errors

If the error occured within the play "Install k3s on all cluster nodes and bootstrap infrastructure", then re-run the entire playbook, otherwise it suffices to run the infrastructure part via appending `--tags infra` to the command.
