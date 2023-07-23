# How to remove cluster nodes

1. *Via Longhorn Web UI*: [Request eviction](https://longhorn.io/docs/1.5.1/volumes-and-nodes/disks-or-nodes-eviction/#select-disks-or-nodes-for-eviction) of the associated Longhorn storage node.
2. Wait for all volumes to be evicted.
3. *Via terminal on any control node*: [`kubectl drain` the k8s node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#use-kubectl-drain-to-remove-a-node-from-service) to evict all running pods from it and disable scheduling.
4. Wait for all pods to be evicted.
5. **For control nodes**:
   - [Install etcdctl](https://docs.k3s.io/advanced#using-etcdctl) on one of the control nodes.
   - [Remove the etcd node](https://etcd.io/docs/v3.5/tutorials/how-to-deal-with-membership/) via `etcdctl member remove`.
6. *Via terminal on the node to be removed*: [Uninstall k3s](https://docs.k3s.io/installation/uninstall)
7. *Optional*: `kubectl delete` the node.
