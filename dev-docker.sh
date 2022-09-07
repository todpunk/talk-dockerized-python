#!/usr/bin/env bash
MYID="$(id -u $(whoami))"

docker run --user "$MYID":"$MYID" --mount type=bind,source="$(pwd)"/,target=/workspace --name coolappdev --rm -it $(docker build -q -f Dockerfile.dev .) /bin/bash
