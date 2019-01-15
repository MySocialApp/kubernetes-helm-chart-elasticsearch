#!/usr/bin/env bash

#set -x

num_nodes_set() {
    echo "Ensure number of nodes is set: $NUM_NODES"
    [ ! -z $NUM_NODES ]
}

num_nodes_are_labeled_as_node() {
    label='node-role.kubernetes.io/node=true'
    for i in $(seq 1 $NUM_NODES) ; do
        if [ $(kubectl get nodes --show-labels | grep kube-node-$i | grep $label | wc -l) == 0 ] ; then
            kubectl label nodes kube-node-$i node-role.kubernetes.io/node=true --overwrite
        fi
    done
}

check_cluster_is_green() {
    CLUSTER_STATUS='unknow'
    while [ "$CLUSTER_STATUS" != "green" ] ; do
        sleep 5
        CLUSTER_STATUS=$(curl -s "http://elasticsearch.observability.svc.4tech-c01fr.local:9200/_cluster/health" | jq --raw-output '.status')
        echo "Current cluster status: $CLUSTER_STATUS. Waiting for green..." >&3
    done
}

check_pod_is_running() {
    ROLE=$1
    POD_FILTERS="$2"
    CURRENT_NODES=0
    READY_NODES=0
    NUM_NODES=$(kubectl get statefulset $POD_FILTERS | tail -1 | awk '{ print $2 }')

    # Ensure the number of desired pod has been bootstraped
    while [ "$CURRENT_NODES" != "$NUM_NODES" ] ; do
        sleep 15
        CURRENT_NODES=$(kubectl get pod $POD_FILTERS | grep Running | wc -l)
        echo "Elasticsearch $ROLE running nodes: $CURRENT_NODES/$NUM_NODES, waiting..." >&3
    done

    # Ensure the state of each pod is fully ready
    while [ "$READY_NODES" != "$NUM_NODES" ] ; do
        sleep 15
        READY_NODES=$(kubectl get po $POD_FILTERS | awk '{ print $2 }' | grep -v READY | awk -F'/' '{ print ($1 == $2) ? "true" : "false" }' | grep true | wc -l)
        echo "Elasticsearch $ROLE running ready nodes: $READY_NODES/$NUM_NODES, waiting..." >&3
    done
}

check_masters_pods_are_running() {
    POD_FILTERS="-l app=elasticsearch -l role=master"
    check_pod_is_running master "$POD_FILTERS"
}

check_data_pods_are_running() {
    POD_FILTERS="-l app=elasticsearch -l role=data"
    check_pod_is_running data "$POD_FILTERS"
}

check_cluster_is_deployed() {
    check_masters_pods_are_running
    check_data_pods_are_running
}