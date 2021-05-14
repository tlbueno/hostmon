#!/usr/bin/env bash

set -e

MONITORING_NETWORK_NAME="monitoring"

if ! podman network exists ${MONITORING_NETWORK_NAME} ; then
    echo "${MONITORING_NETWORK_NAME} network does not exist, creating"
    podman network create ${MONITORING_NETWORK_NAME}
    echo ""
fi

echo "running prometheus"
if [[ ! -e "prometheus/prometheus.yml" ]]; then
    echo "prometheus config file not found"
    mkdir -p prometheus
    echo "creating a dummy prometheus container"
    podman create --name prometheus_dummy prom/prometheus
    echo "copy default prometheus config file"
    podman cp prometheus_dummy:/etc/prometheus/prometheus.yml prometheus/
    echo "removing dummy prometheus container"
    podman rm prometheus_dummy
fi

echo "starting prometheus container"
podman run --rm --detach --name prometheus --publish 9090:9090 --network ${MONITORING_NETWORK_NAME} --volume "${PWD}/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:Z" prom/prometheus
echo ""

echo "running grafana"
if [[ ! -d "grafana/etc" ]]; then
    echo "grafana config directory not found"
    mkdir -p grafana/etc
    echo "creating a dummy grafana container"
    podman create --name grafana_dummy grafana/grafana
    echo "copy default grafana config directory"
    podman cp grafana_dummy:/etc/grafana/. grafana/etc
    echo "removing dummy grafana container"
    podman rm grafana_dummy
fi

if [[ ! -d "grafana/data" ]]; then
    echo "grafana data directory not found"
    mkdir -p grafana/data
    echo "creating a dummy grafana container"
    podman create --name grafana_dummy grafana/grafana
    echo "copy default grafana data directory"
    podman cp grafana_dummy:/var/lib/grafana/. grafana/data
    echo "removing dummy grafana container"
    podman rm grafana_dummy
fi

echo "starting grafana container"
podman run --rm --detach --name grafana --publish 3000:3000 --user root:root --network ${MONITORING_NETWORK_NAME} --volume "${PWD}/grafana/etc:/etc/grafana:Z" --volume "${PWD}/grafana/data:/var/lib/grafana:Z" grafana/grafana
echo ""

echo "running node_export"
if [[ ! -d "node_exporter" ]]; then
    mkdir -p node_exporter
    cd node_exporter
    NODE_EXPORTER_VERSION=$(curl --silent "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | \
        grep '"tag_name":' |                                           
        sed -E 's/.*"([^"]+)".*/\1/')
    
    NODE_EXPORTER_FILENAME="node_exporter-${NODE_EXPORTER_VERSION:1}.linux-amd64.tar.gz"

    wget "https://github.com/prometheus/node_exporter/releases/download/${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_FILENAME}"
    tar  --strip-components=1 -zxvf "${NODE_EXPORTER_FILENAME}"
    cd ..
fi
nohup node_exporter/node_exporter --collector.textfile.directory="${PWD}/vmstat_collector" > node_exporter/node_exporter.log &
echo ""

echo "running vmstat_collector"
nohup vmstat_collector/vmstat_collector_runner.sh > vmstat_collector/vmstat_collector.log &
echo ""

