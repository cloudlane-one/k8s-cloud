# Cluster Infrastructure

This chart can be used to bootstrap the infrastructure of an existing kubernetes cluster (usually k3s). It assumes an existing runtime (CRI), storage (CSI), and networking (CNI) solution, as would be the case e.g. when running a vcluster inside a host cluster. If you want to bootstrap the host cluster itself, use the `host-cluster-infra` chart instead.

This chart is not supposed to be installed directly, but rather via the associated Ansible playbook.
