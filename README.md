Heroku buildpack: pgbouncer
=========================

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows one to run pgbouncer and stunnel in a dyno alongside application code.
It is meant to be used inconjunction with other buildpacks as part of a
[multi-buildpack](https://github.com/ddollar/heroku-buildpack-multi).

The primary use of this buildpack is to allow for transaction pooling of a
PostgreSQL connection among multiple workers in a dyno. For example, 10 unicorn
workers would be able to share a single database connection, avoiding connection
limits and Out Of Memory errors Postgres from too many connections. 

It uses [stunnel](http://stunnel.org/) and [pgbouncer](http://wiki.postgresql.org/wiki/PgBouncer).

Usage
-----

Example usage:

    $ ls -a
    .buildpacks  Gemfile  Gemfile.lock  Procfile  config/  config.ru

    $ heroku config:add BUILDPACK_URL=https://github.com/ddollar/heroku-buildpack-multi.git

    $ cat .buildpacks
    https://github.com/heroku/heroku-buildpack-pgbouncer.git
    https://github.com/heroku/heroku-buildpack-ruby.git

    $ cat Procfile
    web:    bin/pgbouncer-stunnel.sh && DATABASE_URL=$PGBOUNCER_URI bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

    $ git push heroku master
    ...
    -----> Fetching custom git buildpack... done
    -----> Multipack app detected
    =====> Downloading Buildpack: https://github.com/gregburek/heroku-buildpack-pgbouncer.git
    =====> Detected Framework: pgbouncer
           Using pgbouncer version: 1.5.4
           Using stunnel version: 4.56
    -----> Fetching and vendoring pgbouncer into slug
    -----> Fetching and vendoring stunnel into slug
    -----> Generating the configuration generation script
    -----> Generating the startup script
    -----> pgbouncer/stunnel done
    =====> Downloading Buildpack: https://github.com/heroku/heroku-buildpack-ruby.git
    =====> Detected Framework: Ruby/Rack
    -----> Using Ruby version: ruby-1.9.3
    -----> Installing dependencies using Bundler version 1.3.2
    ...

The buildpack will install and configure pgbouncer and stunnel to connect to
`DATABASE_URL` over a SSL connection. Prepend `bin/pgbouncer-stunnel.sh && DATABASE_URL=$PGBOUNCER_URI `
to any process in the Procfile to run pgbouncer and stunnel alongside that process.

Parameters available for override
-----
Some settings are configurable through app config vars. Refer to the appropriate
documentation for
[pgbouncer](http://pgbouncer.projects.pgfoundry.org/doc/config.html#_generic_settings)
and [stunnel](http://linux.die.net/man/8/stunnel) configuration.

- `PGBOUNCER_DEFAULT_POOL_SIZE` Default is 1

For more info, see [CONTRIBUTING.md](CONTRIBUTING.md)
