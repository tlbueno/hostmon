#!/usr/bin/env bash

scrap="${PWD}/vmstat_collector/metrics"

function log {
    echo "$(date +"%m/%d/%Y %H:%M:%S") - $*"
}

log "Starting...";
while true ; do 
    log "Waiting until next execution..."
    sleep 2

    ./vmstat_collector/vmstat.sh > "$scrap.temp" 

    log "Moving temp metrics to final metrics so prometheus can scrap it..."
    mv "$scrap.temp" "$scrap.prom"

    log "Done!" 
done
