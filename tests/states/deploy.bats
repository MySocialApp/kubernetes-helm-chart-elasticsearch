#!/usr/bin/env bats

load ../k8s-euft/env
load common

@test "Ensure number of nodes is set: $NUM_NODES" {
    num_nodes_set
}

@test "Ensure nodes has correct labels" {
    num_nodes_are_labeled_as_node
}

@test "Deploying Elasticsearch helm chart" {
    helm install kubernetes -n elasticsearch
}

@test "Check Elasticsearch cluster is deployed" {
    check_cluster_is_deployed
}

@test "Check Elasticsearch cluster status" {
    check_cluster_is_green
}

@test "Re-run deploy on the current version" {
    # Test upgrade of the current helm with same content to ensure there is no mistakes
    helm upgrade elasticsearch kubernetes
}