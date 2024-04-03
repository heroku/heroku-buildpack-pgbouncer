#!/usr/bin/env bash

set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 STACK"; exit 1; }

STACK="${1}"
BASE_IMAGE="heroku/${STACK/-/:}-build"
OUTPUT_IMAGE="pgbouncer-test-${STACK}"

echo "Building buildpack on stack ${STACK}..."

docker build \
    --build-arg STACK="$STACK" \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    -t "$OUTPUT_IMAGE" \
    .

echo "Checking pgbouncer presence and version..."

START_BOUNCER="bin/start-pgbouncer psql postgres://:6000/pgbouncer?host=/tmp -tc 'SHOW VERSION;' > bouncer.log 2>&1"
TEST_COMMAND="$START_BOUNCER && grep 'listening on 127.0.0.1:6000' bouncer.log && grep ' PgBouncer' bouncer.log"

docker run \
    --rm \
    -t "$OUTPUT_IMAGE" \
    bash -c "$TEST_COMMAND" && \
    echo "Success!"
