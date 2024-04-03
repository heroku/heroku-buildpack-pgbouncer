# Heroku buildpack: pgbouncer

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows one to run pgbouncer in a dyno alongside application code.  It is meant
to be [used in conjunction with other
buildpacks](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).

The primary use of this buildpack is to allow for transaction pooling of
PostgreSQL database connections among multiple workers in a dyno. For example,
10 unicorn workers would be able to share a single database connection, avoiding
connection limits and Out Of Memory errors on the Postgres server.

## FAQ
- Q: Why should I use transaction pooling?
- A: You have many workers per dyno that hold open idle Postgres connections and you want to reduce the number of unused connections. [This is a slightly more complete answer from stackoverflow](http://stackoverflow.com/questions/12189162/what-are-advantages-of-using-transaction-pooling-with-pgbouncer)

- Q: Why shouldn't I use transaction pooling?
- A: If you need to use named prepared statements, advisory locks, listen/notify, or other features that operate on a session level.
Please refer to PGBouncer's [feature matrix](https://www.pgbouncer.org/features.html#sql-feature-map-for-pooling-modes) for all transaction pooling caveats.


## Disable Prepared Statements
With Rails 4.1, you can disable prepared statements by appending
`?prepared_statements=false` to the database's URI.  Set the
`PGBOUNCER_PREPARED_STATEMENTS` config var to `false` for the buildpack to do
that for you.

Rails versions 4.0.0 - 4.0.3, reportedly can't disable prepared statements at
all. Make sure your framework is up to date before troubleshooting prepared
statements failures.

Rails 3.2 - 4.0 also requires an initializer to properly cast the
prepared_statements configuration string as a boolean. This initializer is
adapted from [this
commit](https://github.com/rails/rails/commit/e54acf1308e2e4df047bf90798208e03e1370098).
In file config/initializers/database_connection.rb insert the following:

```ruby
require "active_record/connection_adapters/postgresql_adapter"

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  alias initialize_without_config_boolean_coercion initialize
  def initialize(connection, logger, connection_parameters, config)
    if config[:prepared_statements] == 'false'
      config = config.merge(prepared_statements: false)
    end
    initialize_without_config_boolean_coercion(connection, logger, connection_parameters, config)
  end
end
```


## Usage

Example usage:

    $ ls -a
    Gemfile  Gemfile.lock  Procfile  config/  config.ru

    $ heroku buildpacks:add heroku/pgbouncer
    Buildpack added. Next release on pgbouncer-test-app will use heroku/pgbouncer.
    Run `git push heroku main` to create a new release using this buildpack.

    $ heroku buildpacks:add heroku/ruby
    Buildpack added. Next release on pgbouncer-test-app will use:
      1. https://github.com/heroku/heroku-buildpack-pgbouncer
      2. https://github.com/heroku/heroku-buildpack-ruby
    Run `git push heroku main` to create a new release using these buildpacks.

    $ cat Procfile
    web:    bin/start-pgbouncer bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

    $ git push heroku main
    ...
    -----> Multipack app detected
    -----> Fetching custom git buildpack... done
    -----> pgbouncer app detected
           Using pgbouncer version: 1.7-heroku
    -----> Fetching and vendoring pgbouncer into slug
    -----> Moving the configuration generation script into app/bin
    -----> Moving the start-pgbouncer script into app/bin
    -----> pgbouncer done
    -----> Fetching custom git buildpack... done
    ...


The buildpack will install and configure pgbouncer to connect to
`DATABASE_URL` over a TLS connection, where available. Prepend
`bin/start-pgbouncer` to any process in the Procfile to run pgbouncer alongside
that process.

## PgBouncer Version

- Heroku-18: `v1.17.0`
- Heroku-20: `v1.17.0`
- Heroku-22: `v1.17.0`

## Multiple Databases
It is possible to connect to multiple databases through pgbouncer by setting
`PGBOUNCER_URLS` to a list of config vars. Example:

    $ heroku config:add PGBOUNCER_URLS="DATABASE_URL HEROKU_POSTGRESQL_ROSE_URL"
    $ heroku run bash

    ~ $ env | grep 'HEROKU_POSTGRESQL_ROSE_URL\|DATABASE_URL'
    HEROKU_POSTGRESQL_ROSE_URL=postgres://u9dih9htu2t3ll:password@ec2-107-20-228-134.compute-1.amazonaws.com:5482/db6h3bkfuk5430
    DATABASE_URL=postgres://uf2782hv7b3uqe:password@ec2-50-19-210-113.compute-1.amazonaws.com:5622/deamhhcj6q0d31

    ~ $ bin/start-pgbouncer env # filtered for brevity
    HEROKU_POSTGRESQL_ROSE_URL=postgres://u9dih9htu2t3ll:password@127.0.0.1:6000/db2
    DATABASE_URL=postgres://uf2782hv7b3uqe:password@127.0.0.1:6000/db1

> ⚠️ A referenced configuration variable in `PGBOUNCER_URLS` must not be empty, and must be a valid PostgreSQL connection string.

## Follower Replica Databases
As of v0.3.2 of this buildpack, it is possible to use pgbouncer to connect to
multiple databases that share a database name, such as a leader and follower.
To use, add the follower's config var to `PGBOUNCER_URLS` as detailed in the
[Multiple Databases](#multiple-databases) section.

If you are using [Octopus](https://github.com/tchandy/octopus)
[Replication](https://github.com/tchandy/octopus#replication) to send reads to
a replica, make sure to include the color url of your leader in the
`SLAVE_DISABLED_FOLLOWERS` blacklist. Otherwise, Octopus will attempt to use
your leader as a read-only replica, potentially doubling your connection count.

## Tweak settings

Some settings are configurable through app config vars at runtime. Refer to the appropriate documentation for
[pgbouncer](https://pgbouncer.github.io/config.html) configurations to see what settings are right for you.

- `PGBOUNCER_POOL_MODE` Default is transaction
- `PGBOUNCER_MAX_CLIENT_CONN` Default is 100
- `PGBOUNCER_DEFAULT_POOL_SIZE` Default is 1
- `PGBOUNCER_MIN_POOL_SIZE` Default is 0
- `PGBOUNCER_RESERVE_POOL_SIZE` Default is 1
- `PGBOUNCER_RESERVE_POOL_TIMEOUT` Default is 5.0 seconds
- `PGBOUNCER_SERVER_LIFETIME` Default is 3600.0 seconds
- `PGBOUNCER_SERVER_IDLE_TIMEOUT` Default is 600.0 seconds
- `PGBOUNCER_URLS` should contain all config variables that will be overridden to connect to pgbouncer. For example, set this to `AMAZON_RDS_URL` to send RDS connections through pgbouncer. The default is `DATABASE_URL`.
- `PGBOUNCER_LOG_CONNECTIONS` Default is 1. If your app does not use persistent database connections, this may be noisy and should be set to 0.
- `PGBOUNCER_LOG_DISCONNECTIONS` Default is 1. If your app does not use persistent database connections, this may be noisy and should be set to 0.
- `PGBOUNCER_LOG_POOLER_ERRORS` Default is 1
- `PGBOUNCER_STATS_PERIOD` Default is 60
- `PGBOUNCER_SERVER_RESET_QUERY` Default is empty when pool mode is transaction, and "DISCARD ALL;" when session.
- `PGBOUNCER_IGNORE_STARTUP_PARAMETERS` Adds parameters to ignore when pgbouncer is starting. Some postgres libraries, like Go's pq, append this parameter, making it impossible to use this buildpack. Default is empty and the most common ignored parameter is `extra_float_digits`. Multiple parameters can be seperated via commas. Example: `PGBOUNCER_IGNORE_STARTUP_PARAMETERS="extra_float_digits, some_other_param"`
- `PGBOUNCER_QUERY_WAIT_TIMEOUT` Default is 120 seconds, helps when the server is down or the database rejects connections for any reason. If this is disabled, clients will be queued infinitely.
- `PGBOUNCER_CONNECT_QUERY` Query to be executed after a connection is established, but before allowing the connection to be used by any clients. If the query raises errors, they are logged but ignored otherwise.

For more info, see [CONTRIBUTING.md](CONTRIBUTING.md)

## Using the edge version of the buildpack

The `heroku/pgbouncer` buildpack points to the latest stable version of the buildpack published in the [Buildpack Registry](https://devcenter.heroku.com/articles/buildpack-registry). To use the latest version of the buildpack (the code in this repository, run the following command:

    $ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-pgbouncer

## Notes
Currently, the connection string parsing requires the connection string to be in a specific format:

```
postgres://<user>:<pass>@<host>:<port>/<database>
```

This corresponds to the regular expression `^postgres(?:ql)?:\/\/([^:]*):([^@]*)@(.*?):(.*?)\/(.*?)$`. All components must be present in order for the buildpack to correctly parse the connection string.
