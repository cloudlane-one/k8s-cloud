# Managed Cluster Playbook

## Install dependencies

From the repo folder run following bash code to install all Python deps into a virtual environment:

```bash
poetry install
```

Then run this to install Ansible-specific dependencies:

```bash
ansible-galaxy install -r requirements.yaml
```

## Provide configuration

### Hosts

Edit the hosts file `hosts.yaml` .

### Backbone hosts

Backbone hosts are node hosts which have a direct and strong connection to the main network of your cluster and thus have low latency and high bandwith over that network. This is important especially for distributed storage.

This main network could either be the WAN, aka the public internet, or the LAN network, where the majority of your hosts reside. Latency between all backbone nodes should be 100ms or less and bandwidth should be at least 1Gbps (up and down).

> Note that `backbone` does not make any statement about failure domains or availability zones. If you want to build a hierarchy of zones, please add `region` and `zone` labels to your hosts.

By default, all hosts in `hosts.yaml` are taken to be backbone nodes. To exclude hosts with slower connections, set `backbone=false` on them, or to only include a subset of hosts into the backbone, set `backbone=true` on the subset.

### Control plane hosts

By default, the first backbone host is taken as the sole control plane host. If you want to change this bevavior, set the value `control=true` on a subset of hosts.

> It is recommended to have either one or at least 3 control plane nodes. Make sure you store the hosts file somewhere safe.
> Please also set `control nodes` for vclusters. This has no effect on where the control plane pods run, but it tells Ansible on which machines it can execute administrative tasks.

### Ingress hosts

By default, the first backbone host is taken as the sole ingress host. If you want to change this bevavior, set the value `ingress=true` on a subset of hosts.

### Storage hosts

By default, all hosts are taken as storage hosts, yet non-backbone hosts are excluded from distributed storage for performance reasons, hence they can only host single-replica, local volumes. To exclude hosts from being used for storage at all, set `storage=false` on them, or to only include a subset of hosts for storage, set `storage=true` on the subset.

### Cluster config and secrets

Then copy the default cluster config file `./roles/cluster/vars/config.yaml` to `config.yaml` and the cluster secrets template file `./roles/cluster/vars/secrets.yaml` to `secrets.yaml`. Fill in the required values and change or delete the optional ones to your liking.

## Setup the cluster

> Please either manually make sure that all your nodes are listed as trusted in `known_hosts` or append `-e auto_trust_remotes=true` to below command, otherwise you will have to type `yes` and hit Enter for each of your hosts at the beginning of the playbook run.

To setup all you provided hosts as kubernetes nodes and join them into a single cluster, run:

```bash
ansible-playbook setup.yaml
```

> If you recently rebuilt the OS on any of the hosts and thereby lost its public key, make sure to also update (or at least delete) its `known_hosts` entry, otherwise Ansible will throw an error. You can also append `-e clear_known_hosts=true` to above command to delete the `known_hosts` entries for all hosts in the inventory before executing the setup.

### Extend the cluster

Simply add new node hosts to your `inventory.yaml` and re-run the setup playbook.
