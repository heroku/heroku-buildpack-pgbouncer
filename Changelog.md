## v0.3.2 (October 2, 2014)

* Adds support for dbs with the same db name, such as leaders and followers

## v0.3.1 (August 13, 2014)

* Adds support for cedar-14 Heroku stack
* Adds Octopus info to README

## v0.3.0 (April 24, 2014)

* Adds PGBOUNCER_MAX_CLIENT_CONN, PGBOUNCER_CONNECTION_RETRY,
 PGBOUNCER_CONNECTION_RETRY, PGBOUNCER_LOG_DISCONNECTIONS,
 PGBOUNCER_LOG_POOLER_ERRORS, PGBOUNCER_STATS_PERIOD and
 PGBOUNCER_SERVER_RESET_QUERY configs (thanks to khamaileon and jhorman)
* Uses an MD5 hashed password in the filesystem
* Waits until dyno boot to generate configs
* Uses a patched pgbouncer 1.5.4 to not eagerly exit on SIGTERMs
* Better signal handling allows app code to clean up before exiting stunnel and
 pgbouncer (thanks to agriffis)
* Replaces vulcan with docker for compiling stunnel and pgbouncer binaries for
 heroku
* Upgrades to stunnel v5.01

## v0.2.2 (November 26, 2013)

* Uses `PGBOUNCER_URLS` to connect to multiple databases
* Uses unix sockets for pgbouncer to stunnel in-dyno communication

## v0.2.1 (July 15, 2013)

* Added `PGBOUNCER_PREPARED_STATEMENTS` config var to append
`?prepared_statements=false` to `PGBOUNCER_URI` when set to `false`

## v0.2 (July 10, 2013)

* Now using bash fifos to crash dyno on any subprocess exit
* Updated README

## v0.1 (June 24, 2013)

* initial release
