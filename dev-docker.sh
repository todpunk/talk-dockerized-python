#!/usr/bin/env bash
set -e

MYUID="$(id -u $(whoami))"
MYGID="$(id -g $(whoami))"

# Build it first, so we can see if anything fails
docker build --build-arg UID=${MYUID} --build-arg GID=${MYGID} --tag coolappdev:localonly -f Dockerfile.dev .
echo "Built localonly docker, now running it"
docker run --user "$MYUID":"$MYGID" -p 127.0.0.1:5000:5000 --mount type=bind,source="$(pwd)"/,target=/home/cooluser/workspace --name coolappdev	--rm -it coolappdev:localonly /bin/bash
	
