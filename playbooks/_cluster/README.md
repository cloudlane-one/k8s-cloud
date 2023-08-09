# Managed Cluster Playbook

## Setup

First activate the poetry env via:

```bash
poetry shell
```

### Provide configuration

#### Hosts

Edit the hosts file `hosts.yaml` to add all host machines, which are to be setup as the nodes of your cluster.

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

Then copy the default cluster config file `./roles/cluster-config/values.yaml` to `values.yaml` and the cluster secrets template file `./roles/cluster-config/secrets.yaml` to `secrets.yaml`. Fill in the required values and change or delete the optional ones to your liking.

### Setup the cluster

> Please either manually make sure that all your nodes are listed as trusted in `known_hosts` or append `-e auto_trust_remotes=true` to below command, otherwise you will have to type `yes` and hit Enter for each of your hosts at the beginning of the playbook run.

To setup all you provided hosts as kubernetes nodes and join them into a single cluster, run:

```bash
ansible-playbook setup.yaml -i hosts.yaml
```

> If you recently rebuilt the OS on any of the hosts and thereby lost its public key, make sure to also update (or at least delete) its `known_hosts` entry, otherwise Ansible will throw an error. You can also append `-e clear_known_hosts=true` to above command to delete the `known_hosts` entries for all hosts in the inventory before executing the setup.

## Adding nodes

Simply add new node hosts to your `inventory.yaml` and re-run the setup playbook.

> **Attention:** Adding new control nodes is currently untested and could leave your cluster in a failed state!

## Removing nodes

### Manual steps for each node

1. *Via Longhorn Web UI*: [Request eviction](https://longhorn.io/docs/1.5.1/volumes-and-nodes/disks-or-nodes-eviction/#select-disks-or-nodes-for-eviction) of the associated Longhorn storage node.
2. Wait for all volumes to be evicted.
3. *Via terminal on any control node*: [`kubectl drain` the k8s node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#use-kubectl-drain-to-remove-a-node-from-service) to evict all running pods from it and disable scheduling.
4. Wait for all pods to be evicted.
5. **For control nodes**:
   - [Install etcdctl](https://docs.k3s.io/advanced#using-etcdctl) on one of the control nodes.
   - [Remove the etcd node](https://etcd.io/docs/v3.5/tutorials/how-to-deal-with-membership/) via `etcdctl member remove`.

### Batch removal

Create a copy of your `hosts.yaml` containing all the hosts, **that you want to be removed**. Name this copy `destroy-hosts.yaml`. Then run this command:

```bash
ansible-playbook destroy.yaml -i destroy-hosts.yaml
```
