#!/bin/bash

log() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a duplicate_remover.log
}