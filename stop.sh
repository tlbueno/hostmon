#!/usr/bin/env bash

#set -e

echo "stopping vmstat_collector"
kill -TERM "$(pgrep -f vmstat_collector_runner.sh)"

echo "stopping node_export"
kill -TERM "$(pgrep -f "node_exporter --collector.textfile.directory=.*/vmstat_collector")"

echo "stopping grafana"
podman stop grafana

echo "stopping prometheus"
podman stop prometheus

