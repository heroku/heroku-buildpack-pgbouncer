## v0.4.0 (December 23, 2015)

* Added `bin/start-pgbouncer`, allowing users to bypass stunnel
* Included pgbouncer and stunnel binaries in buildpack
* Moved to pgbouncer 1.7 and stunnel 5.28
* Removed support for legacy cedar platform. Only cedar-14 is supported
* Allowed building of pgbouncer and stunnel via heroku itself
* Put stunnel and pgbouncer binaries in `bin/` folder, and configs in `config/`
* Changed regex for URLs to support password-less postgres users
* Removed noisy per-client-connection and per-client-disconnection logging
 default, reducing log size for apps that connect to pgbouncer once per request


## v0.3.3 (December 18, 2014)

* Improves SIGTERM signal handling in wrapper script (thanks michaeldiscala)
* Adds ENABLE_STUNNEL_AMAZON_RDS_FIX (thanks edwardotis)
* Upgrades to stunnel v5.08

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
