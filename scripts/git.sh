#!/usr/bin/env bash

LOG_COMMIT=$1
ROOT_DIR="/home/mosheng/nix-dev-envs"

if [[ -z "$LOG_COMMIT" ]]; then
    LOG_COMMIT="update"
fi


cd "$ROOT_DIR" || exit 1



git add . && git commit -m "$LOG_COMMIT" && git push

