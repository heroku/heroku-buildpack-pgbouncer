# Heroku buildpack: pgbouncer

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) that
allows one to run pgbouncer and stunnel in a dyno alongside application code.
It is meant to be [used in conjunction with other buildpacks](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).

The primary use of this buildpack is to allow for transaction pooling of
PostgreSQL database connections among multiple workers in a dyno. For example,
10 unicorn workers would be able to share a single database connection, avoiding
connection limits and Out Of Memory errors on the Postgres server.

It uses [stunnel](http://stunnel.org/) and [pgbouncer](http://wiki.postgresql.org/wiki/PgBouncer).


## FAQ
- Q: Why should I use transaction pooling?
- A: You have many workers per dyno that hold open idle Postgres connections and
and you want to reduce the number of unused connections. [This is a slightly more complete answer from stackoverflow](http://stackoverflow.com/questions/12189162/what-are-advantages-of-using-transaction-pooling-with-pgbouncer)

- Q: Why shouldn't I use transaction pooling?
- A: If you need to use named prepared statements, advisory locks, listen/notify, or other features that operate on a session level.
Please refer to PGBouncer's [feature matrix](http://wiki.postgresql.org/wiki/PgBouncer#Feature_matrix_for_pooling_modes) for all transaction pooling caveats.


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

    $ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-pgbouncer
    Buildpack added. Next release on pgbouncer-test-app will use https://github.com/heroku/heroku-buildpack-pgbouncer.
    Run `git push heroku master` to create a new release using this buildpack.

    $ heroku buildpacks:add heroku/ruby
    Buildpack added. Next release on pgbouncer-test-app will use:
      1. https://github.com/heroku/heroku-buildpack-pgbouncer
      2. https://github.com/heroku/heroku-buildpack-ruby
    Run `git push heroku master` to create a new release using these buildpacks.

    $ cat Procfile
    web:    bin/start-pgbouncer-stunnel bundle exec unicorn -p $PORT -c ./config/unicorn.rb -E $RACK_ENV
    worker: bundle exec rake worker

    $ git push heroku master
    ...
    -----> Multipack app detected
    -----> Fetching custom git buildpack... done
    -----> pgbouncer-stunnel app detected
           Using pgbouncer version: 1.5.4-heroku
           Using stunnel version: 5.08
           Using stack version: cedar-14
    -----> Fetching and vendoring pgbouncer into slug
    -----> Fetching and vendoring stunnel into slug
    -----> Moving the configuration generation script into app/bin
    -----> Moving the start-pgbouncer-stunnel script into app/bin
    -----> pgbouncer/stunnel done
    -----> Fetching custom git buildpack... done
    ...

The buildpack will install and configure pgbouncer and stunnel to connect to
`DATABASE_URL` over a SSL connection. Prepend `bin/start-pgbouncer-stunnel`
to any process in the Procfile to run pgbouncer and stunnel alongside that process.


## Multiple Databases
It is possible to connect to multiple databases through pgbouncer by setting
`PGBOUNCER_URLS` to a list of config vars. Example:

    $ heroku config:add PGBOUNCER_URLS="DATABASE_URL HEROKU_POSTGRESQL_ROSE_URL"
    $ heroku run bash

    ~ $ env | grep 'HEROKU_POSTGRESQL_ROSE_URL\|DATABASE_URL'
    HEROKU_POSTGRESQL_ROSE_URL=postgres://u9dih9htu2t3ll:password@ec2-107-20-228-134.compute-1.amazonaws.com:5482/db6h3bkfuk5430
    DATABASE_URL=postgres://uf2782hv7b3uqe:password@ec2-50-19-210-113.compute-1.amazonaws.com:5622/deamhhcj6q0d31

    ~ $ bin/start-pgbouncer-stunnel env # filtered for brevity
    HEROKU_POSTGRESQL_ROSE_URL=postgres://u9dih9htu2t3ll:password@127.0.0.1:6000/db2
    DATABASE_URL=postgres://uf2782hv7b3uqe:password@127.0.0.1:6000/db1

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
[pgbouncer](https://pgbouncer.github.io/config.html)
and [stunnel](http://linux.die.net/man/8/stunnel) configurations to see what settings are right for you.

- `PGBOUNCER_POOL_MODE` Default is transaction
- `PGBOUNCER_MAX_CLIENT_CONN` Default is 100
- `PGBOUNCER_DEFAULT_POOL_SIZE` Default is 1
- `PGBOUNCER_MIN_POOL_SIZE` Default is 0
- `PGBOUNCER_RESERVE_POOL_SIZE` Default is 1
- `PGBOUNCER_RESERVE_POOL_TIMEOUT` Default is 5.0 seconds
- `PGBOUNCER_SERVER_LIFETIME` Default is 3600.0 seconds
- `PGBOUNCER_SERVER_IDLE_TIMEOUT` Default is 600.0 seconds
- `PGBOUNCER_URLS` should contain all config variables that will be overridden to connect to pgbouncer. For example, set this to `AMAZON_RDS_URL` to send RDS connections through pgbouncer. The default is `DATABASE_URL`.
- `PGBOUNCER_CONNECTION_RETRY` Default is no
- `PGBOUNCER_LOG_CONNECTIONS` Default is 1. If your app does not use persistent database connections, this may be noisy and should be set to 0.
- `PGBOUNCER_LOG_DISCONNECTIONS` Default is 1. If your app does not use persistent database connections, this may be noisy and should be set to 0.
- `PGBOUNCER_LOG_POOLER_ERRORS` Default is 1
- `PGBOUNCER_STATS_PERIOD` Default is 60
- `PGBOUNCER_SERVER_RESET_QUERY` Default is empty when pool mode is transaction, and "DISCARD ALL;" when session.
- `PGBOUNCER_STUNNEL_LOGLEVEL` Default is notice (5). Set this var to pass a syslog level name or number value to stunnel.  This corresponds to the stunnel global configuration option called "debug".
- `ENABLE_STUNNEL_AMAZON_RDS_FIX` Default is unset. Set this var if you are connecting to an Amazon RDS instance of postgres.
 Adds `options = NO_TICKET` which is documented to make stunnel work correctly after a dyno resumes from sleep. Otherwise, the dyno will lose connectivity to RDS.
- `PGBOUNCER_IGNORE_STARTUP_PARAMETERS` Adds parameters to ignore when pgbouncer is starting. Some postgres libraries, like Go's pq, append this parameter, making it impossible to use this buildpack. Default is empty and the most common ignored parameter is `extra_float_digits`. Multiple parameters can be seperated via commas. Example: `PGBOUNCER_IGNORE_STARTUP_PARAMETERS="extra_float_digits, some_other_param"`
- `PGBOUNCER_PKT_BUF` Default is 4096.
- `PGBOUNCER_MAX_PACKET_SIZE` Default is 2147483647.
- `PGBOUNCER_LISTEN_BACKLOG` Default is 128.
- `PGBOUNCER_SBUF_LOOPCNT` Default is 5.
- `PGBOUNCER_SUSPEND_TIMEOUT` Default is 10.
- `PGBOUNCER_TCP_DEFER_ACCEPT` Default is 45.
- `PGBOUNCER_TCP_KEEPALIVE` Default is 1.
- `PGBOUNCER_TCP_KEEPCNT` Default is 9.
- `PGBOUNCER_TCP_KEEPIDLE` Default is 7200.
- `PGBOUNCER_TCP_KEEPINTVL` Default is 75.
- `PGBOUNCER_STATS_USERNAME` and `PGBOUNCER_STATS_PASSWORD` Set these to enable stats_users SHOW access to pgbouncer.

For more info, see [CONTRIBUTING.md](CONTRIBUTING.md)
