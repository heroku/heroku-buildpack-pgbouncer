# Heroku Buildpack: pgBouncer


| Branch         | Test Result                                                                                                                                                                                                                                           |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `main` | [![Tests](https://github.com/healthsherpa/heroku-buildpack-pgbouncer/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/healthsherpa/heroku-buildpack-pgbouncer/actions/workflows/tests.yml)                                      |
| `current` | [![Tests](https://github.com/healthsherpa/heroku-buildpack-pgbouncer/actions/workflows/tests.yml/badge.svg?branch=kig%2Fstart-pgbouncer-as-service)](https://github.com/healthsherpa/heroku-buildpack-pgbouncer/actions/workflows/tests.yml)        | 

---

> 🚨 This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks)
that allows one to run pgbouncer in a dyno alongside application code. It is meant
to be [used in conjunction with other buildpacks](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).

> 🔫 The primary use of this buildpack is to allow for transaction pooling of
PostgreSQL database connections among multiple workers in a dyno. For example,
10 unicorn workers would be able to share a single database connection, avoiding
connection limits and Out Of Memory errors on the Postgres server.

## BuildPack Scripts and Executables

The following are the list of scripts in the `bin` folder on this branch:

We marked the scripts that are either modified or new as compared to the Heroku Original Repo by a checkmark. 

```bash
bin/compile
bin/detect
bin/gen-pgbouncer-conf.sh
bin/release
bin/start-pgbouncer             ✅
bin/start-pgbouncer-as-service  ✅
bin/start-pgbouncer-stunnel
bin/use-client-pgbouncer        ✅
bin/use-server-pgbouncer        ✅
```

### Original Buildpack: Good Intentions, But ... 

AKA — How you were supposed to use this.

The build-pack authors intended for you to run your application like so:

```bash
bin/start-pgbouncer bundle exec puma -C config/puma.rb
bin/start-pgbouncer bundle exec sidekiq -C config/sidekiq/hole-digger.yml
```

The script would then use the variable `PGBOUNCER_URLS` to determine which env variables contain database credentials, and create a version of each variable with the suffix `_PGBOUNCER`. 

More over, the original scripts were also mutating the original `DATABASE_URL` variable, which we felt was a bad idea.

# HealthSherpa Buildpack: Client-Side pgBouncer

We thoght that we'd want to:

 1. Start pgBouncer so that it keeps on running on the background, and
 2. Take each database connection variable and, without mutating it, create another one with the `_PGBOUNCER` suffix.

## Using This Buildpack

To use this buildpack:

 1. Set the env variables:
    * `PGBOUNCER_URLS` — a space-separated list of database connection variables to use with pgBouncer.
    * `PGBOUNCER_URL_NAMES` — a space-separated list of database names corresponding to the connections vars.
    * `PGBOUNCER_ENABLED` — set to `true` to enable the buildpack.
    * `PGBOUNCER_OUTPUT_URLS` — set to `true` to output the connection URLs to the console with obfuscated passwords, for example:

        ```bash
      
        ❯ export PGBOUNCER_OUTPUT_URLS=true
        ❯ source bin/use-client-pgbouncer printenv
      
        INFO:  Client pgBouncer is enabled
        INFO:               DATABASE_URL_PGBOUNCER | postgres://user:********@127.0.0.1:6000/db-primary
        INFO:             DB_REPLICA_URL_PGBOUNCER | postgres://user:********@127.0.0.1:6000/db-replica
        INFO:  pgBouncer has been configured with 2 database(s).
      
        ```

 2. In some other buildpack (for the time being) which is added AFTER pgBouncer buildpack, execute the following code:


```bash
if [[ ${PGBOUNCER_ENABLED} == "true" ]]; then
  [[ -x bin/start-pgbouncer-as-service && -x bin/use-client-pgbouncer ]] && {
    bin/start-pgbouncer-as-service && source bin/use-client-pgbouncer
  } 
fi
```

## Computing the number of DB Connections

Bear in mind that Heroku allows maximum of 500 connections to the database total. 

Therefore you'd want to take the maximum number of dynos you may be running EVER, and divide 500 (or a bit less) by that number. That's what you want to set `PGBOUNCER_DEFAULT_POOL_SIZE` to.

## Globally Enabling or Disabling the Build pack

You must set the environment variable `PGBOUNCER_ENABLED=true` to activate the buildpack.

Without this variable, even if the application is started via the `bin/start-pgbouncer-as-service` script, the pgbouncer won't get used.

## Additional Features of this (HealthSherpa) Fork

This fork of the build pack by HealthSherpa adds the following features:

* Unlike the original project, we do not mutate the database connection
  variables.
* Instead, for each variable defined in the `PGBOUNCER_URLS` the build-pack
  creates another variable, eg `DATABASE_URL_PGBOUNCER`. We felt that it was
  important to leave the original `DATABASE_URL` intact to allow our
  developers and code to pick and choose either a direct connection,
  client-side pgBouncer, or server-side.
  * To connect directly, use the original `DATABASE_URL`
  * To connect via a server side pgBouncer, use `DATABASE_CONNECTION_POOL_URL`
  * To connect via a client-side pgBouncer, use `DATABASE_URL_PGBOUNCER`

The second change we introduced is the ability to name the server-side
connections in the pgBouncer configuration.

The original buildpack defaulted to `db1`, `db2`, etc, which is obviously
difficult to correlate to the actual Databases within the Datadog Metrics.

You can set another environment variable `POSTGRES_URL_NAMES`
or `PGBOUNCER_URL_NAMES` to a space-separated list of names to use for the
server-connections instead of "db1", "db2", etc. The names will be used in
the `pgbouncer.ini` file, and will be used in the Datadog metrics.

Good names will match what we use in Datadog already, eg:

```bash
export PGBOUNCER_URLS="DATABASE_URL OFFLOAD_DATABASE_URL DATABASE_REPLICA_01_URL DATABASE_REPLICA_02_URL" 
export PGBOUNCER_URL_NAMES="app-primary offload-primary app-replica-01 app-replica-02"
```

s## Running Tests

This build-pack uses [bats](https://bats-core.readthedocs.io/en/stable/installation.html) for testing BASH scripts. 

You can use the convenient `make` target to both install `bats` on OS-X and run the tests:

```bash
❯ make test
test/run_all.sh
1..10
ok 1 returns exit code of 1 when PGBOUNCER_URLS is empty
ok 2 returns exit code of 1 if a value in PGBOUNCER_URLS is invalid
ok 3 successfully writes the config
ok 4 uses custom database names are available via POSTGRES_URLS_NAMES
ok 5 uses custom database names are available via PGBOUNCER_URL_NAMES
ok 6 returns exit code of 1 with nothing to parse
ok 7 sets ups DATABASE_URL_PGBOUNCER
ok 8 substitutes postgres for postgresql in scheme
ok 9 does not mutate other config vars not listed in PGBOUNCER_URLS
ok 10 does not mutates config vars listed in PGBOUNCER_URLS
```

You can also run the test script directly: `test/run_all.sh`

︎████︎████︎████︎████︎████︎████︎████︎████︎████︎████︎████︎████

# FAQ

- Q: Why should I use transaction pooling?
- A: You have many workers per dyno that hold open idle Postgres connections and
  you want to reduce the number of unused
  connections. [This is a slightly more complete answer from stackoverflow](http://stackoverflow.com/questions/12189162/what-are-advantages-of-using-transaction-pooling-with-pgbouncer)

- Q: Why shouldn't I use transaction pooling?
- A: If you need to use named prepared statements, advisory locks,
  listen/notify, or other features that operate on a session level.
  Please refer to
  PGBouncer's [feature matrix](https://www.pgbouncer.org/features.html#sql-feature-map-for-pooling-modes)
  for all transaction pooling caveats.

## Disable Prepared Statements

With Rails 4.1, you can disable prepared statements by appending
`?prepared_statements=false` to the database's URI. Set the
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

```bash
$ ls -a
Gemfile  Gemfile.lock  Procfile  config/  config.ru

$ heroku buildpacks:add heroku/pgbouncer
Buildpack added. Next release on pgbouncer-test-app will use heroku/pgbouncer.
Run `git push heroku main` to create a new release using this buildpack.

$ heroku buildpacks:add heroku/ruby
Buildpack added. Next release on pgbouncer-test-app will use:
  1. https://github.com/healthsherpa/heroku-buildpack-pgbouncer
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
```

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

```
$ heroku config:add PGBOUNCER_URLS="DATABASE_URL DATABASE_REPLICA_URL"
$ heroku run bash

~ $ env | grep 'DATABASE_REPLICA_URL\|DATABASE_URL'
DATABASE_REPLICA_URL=postgres://u9dih9htu2t3ll:password@ec2-107-20-228-134.compute-1.amazonaws.com:5482/db6h3bkfuk5430
DATABASE_URL=postgres://uf2782hv7b3uqe:password@ec2-50-19-210-113.compute-1.amazonaws.com:5622/deamhhcj6q0d31

~ $ bin/start-pgbouncer env # filtered for brevity
DATABASE_REPLICA_URL_PGBOUNCER=postgres://u9dih9htu2t3ll:password@127.0.0.1:6000/db2
DATABASE_URL_PGBOUNCER=postgres://uf2782hv7b3uqe:password@127.0.0.1:6000/db1
```

> ⚠️ A referenced configuration variable in `PGBOUNCER_URLS` must not be empty,
> and must be a valid PostgreSQL connection string.

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

Some settings are configurable through app config vars at runtime. Refer to the
appropriate documentation for
[pgbouncer](https://pgbouncer.github.io/config.html) configurations to see what
settings are right for you.

| First Header                          | Second Header                                                                                                                                                                                                                                                                                                                                                                           |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `PGBOUNCER_POOL_MODE`                 | Default is transaction                                                                                                                                                                                                                                                                                                                                                                  |
| `PGBOUNCER_MAX_CLIENT_CONN`           | Default is 100                                                                                                                                                                                                                                                                                                                                                                          |
| `PGBOUNCER_DEFAULT_POOL_SIZE`         | Default is 1                                                                                                                                                                                                                                                                                                                                                                            |
| `PGBOUNCER_MIN_POOL_SIZE`             | Default is 0                                                                                                                                                                                                                                                                                                                                                                            |
| `PGBOUNCER_RESERVE_POOL_SIZE`         | Default is 1                                                                                                                                                                                                                                                                                                                                                                            |
| `PGBOUNCER_RESERVE_POOL_TIMEOUT`      | Default is 5.0 seconds                                                                                                                                                                                                                                                                                                                                                                  |
| `PGBOUNCER_SERVER_LIFETIME`           | Default is 3600.0 seconds                                                                                                                                                                                                                                                                                                                                                               |
| `PGBOUNCER_SERVER_IDLE_TIMEOUT`       | Default is 600.0 seconds                                                                                                                                                                                                                                                                                                                                                                |
| `PGBOUNCER_URLS`                      | Should contain all config variables that will be overridden to connect to pgbouncer. For example, set this to `AMAZON_RDS_URL` to send RDS connections through pgbouncer. The default is `DATABASE_URL`.                                                                                                                                                                                |
| `PGBOUNCER_URL_NAMES`                 | Should contain names of the server-side connections that correspond to the variables listed in `PGBOUNCER_URLS`. If not set, defaults to `db1`, `db2`, etc.                                                                                                                                                                                                                             |
| `PGBOUNCER_LOG_CONNECTIONS`           | Default is 1. If your app does not use persistent database connections, this may be noisy and should be set to 0.                                                                                                                                                                                                                                                                       |
| `PGBOUNCER_LOG_DISCONNECTIONS`        | Default is 1. If your app does not use persistent database connections, this may be noisy and should be set to 0.                                                                                                                                                                                                                                                                       |
| `PGBOUNCER_LOG_POOLER_ERRORS`         | Default is 1                                                                                                                                                                                                                                                                                                                                                                            |
| `PGBOUNCER_STATS_PERIOD`              | Default is 60                                                                                                                                                                                                                                                                                                                                                                           |
| `PGBOUNCER_SERVER_RESET_QUERY`        | Default is empty when pool mode is transaction, and "DISCARD ALL;" when session.                                                                                                                                                                                                                                                                                                        |
| `PGBOUNCER_IGNORE_STARTUP_PARAMETERS` | Adds parameters to ignore when pgbouncer is starting. Some postgres libraries, like Go's pq, append this parameter, making it impossible to use this buildpack. Default is empty and the most common ignored parameter is `extra_float_digits`. Multiple parameters can be seperated via commas.  Example: `PGBOUNCER_IGNORE_STARTUP_PARAMETERS="extra_float_digits, some_other_param`" |
| `PGBOUNCER_QUERY_WAIT_TIMEOUT`        | Default is 120 seconds, helps when the server is down or the database rejects connections for any reason. If this is disabled, clients will be queued infinitely.                                                                                                                                                                                                                       


For more info, see [CONTRIBUTING.md](CONTRIBUTING.md)

## Monitoring

You can set `PGBOUNCER_STATS_USER` and `PGBOUNCER_STATS_PASSWORD` to enable
Datadog (or other provider) monitoring.

## Using the edge version of the buildpack

The `heroku/pgbouncer` buildpack points to the latest stable version of the
buildpack published in
the [Buildpack Registry](https://devcenter.heroku.com/articles/buildpack-registry).
To use the latest version of the buildpack (the code in this repository, run the
following command:

    $ heroku buildpacks:add https://github.com/healthsherpa/heroku-buildpack-pgbouncer

## Notes

Currently, the connection string parsing requires the connection string to be in
a specific format:

```
postgres://<user>:<pass>@<host>:<port>/<database>
```

This corresponds to the regular
expression `^postgres(?:ql)?:\/\/([^:]*):([^@]*)@(.*?):(.*?)\/(.*?)$`. All
components must be present in order for the buildpack to correctly parse the
connection string.
