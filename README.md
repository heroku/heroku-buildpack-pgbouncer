Heroku buildpack: pgbouncer
=========================

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that supplies pgbouncer and is meant to be used as a [multi-buildpack](https://github.com/ddollar/heroku-buildpack-multi) 
It uses [stunnel](http://stunnel.org/).

Usage
-----

Example usage:

    $ ls -a
    Procfile  package.json  web.js  .buildpacks

    $ heroku config:add BUILDPACK_URL=https://github.com/ddollar/heroku-buildpack-multi.git

    $ cat .buildpacks
    https://github.com/heroku/heroku-buildpack-pgbouncer.git
    https://github.com/heroku/heroku-buildpack-nodejs.git

    $ cat Procfile
    web: bin/pgbouncer-stunnel.sh && node web.js

    $ git push heroku master
    ...
    -----> Heroku receiving push
    -----> Fetching custom buildpack
    -----> Multipack app detected
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-pgbouncer.git
    =====> Detected Framework: pgbouncer
           Using pgbouncer version: 1.5.4
           Using stunnel version: 4.56
    -----> Fetching and vendoring pgbouncer into slug
    -----> Fetching and vendoring stunnel into slug
    -----> Generating the configuration generation script
    -----> Generating the startup script
    -----> pgbouncer/stunnel done
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-nodejs
    =====> Detected Framework: Node.js
    -----> Node.js app detected
    -----> Vendoring node 0.4.7
    -----> Installing dependencies with npm 1.0.8
           express@2.1.0 ./node_modules/express
           ├── mime@1.2.2
           ├── qs@0.3.1
           └── connect@1.6.2
           Dependencies installed

The buildpack will install and configure pgbouncer and stunnel to connect to `DATABASE_URL` over a secure connection. Add `bin/pgbouncer-stunnel.sh && ` to any process in the Procfile to run pgbouncer and stunnel alongside that process. 

For more info, see [CONTRIBUTING.md](CONTRIBUTING.md)
