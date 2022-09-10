#!/usr/bin/env bash
set -e

# We don't specify the UID because this is not for local, it's for wherever else, so those IDs should be set
# in stone so they're predictable on not-our-machine
docker build --tag coolappdev:localprod -f Dockerfile .
echo "Running coolapp production ready build"
docker run -p 127.0.0.1:5000:5000 --name coolapp --rm -d coolappdev:localprod

