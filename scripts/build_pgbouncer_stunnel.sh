#!/bin/bash
# Build pgbouncer and stunnel on Heroku.
# Based entirely on how the nginix-buildpack is compiled
# You'll need to use `heroku buildpacks:set heroku/python` before pushing this

# This program is designed to run in a web dyno provided by Heroku.
# We would like to build a stunnel & pgbouncer binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the pgbouncer binary.


PGBOUNCER_VERSION=${PGBOUNCER_VERSION-1.7}
STUNNEL_VERSION=${STUNNEL_VERSION-5.28}

pgbouncer_tarball_url=https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz
stunnel_tarball_url=https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &


echo "Downloading $pgbouncer_tarball_url"
curl -L $pgbouncer_tarball_url | tar xzv

(
    cd pgbouncer-${PGBOUNCER_VERSION}
    ./configure \
        --prefix=/tmp/pgbouncer
    make install
)

echo "Downloading $stunnel_tarball_url"
curl -L $stunnel_tarball_url | tar xzv

(
    cd stunnel-${STUNNEL_VERSION}
    ./configure \
        --prefix=/tmp/stunnel
    make install
)

while true
do
    sleep 1
    echo "."
done
