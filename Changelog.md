## Unreleased
* Converted our remaining CircleCI tests to Github Actions
* Add validation for PGBOUNCER_URLS
* Add stack tests

## v0.13.0 (September 9, 2022)
* Update pgbouncer to v1.17.0 for Heroku-18 and Heroku-20 (for parity with Heroku-22)

## v0.12.0 (September 6, 2022)
* Add missing `SIGTERM` patch for v1.17.0 (corrects shutdown behaviour on Heroku-22)

## v0.11.0 (June 20, 2022)
* Update to pgbouncer v1.17.0 on Heroku-22, to fix OpenSSL 3 related crashes

## v0.10.0 (May 19, 2022)
* Add support for Heroku-22
* Add codeowners

## v0.9.0 (June 4, 2021)
* remove heroku-16
* revert back to pgbouncer 1.14

## v0.8.0 (May 31, 2021)
* pgbouncer 1.15
* streamline bin/compile
* moving to CircleCI
* remove support for Cedar 14

## v0.7.0 (August 7, 2020)
* Change default branch name from master to main

## v0.6.0 (June 12, 2020)
* Add support for Heroku-20
* Updates pgbouncer to 1.14 for Heroku-20
* Updates pgbouncer to 1.14 for Heroku-18
* Updates pgbouncer to 1.14 for Heroku-16

## v0.5.0 (May 18, 2020)
* Updates pgbouncer to 1.13 for Heroku-18
* Updates pgbouncer to 1.13 for Heroku-16
* Updates to Buildpack tooling

## v0.4.0 (October 8, 2018)
* Support for Heroku-18

## v0.3.4 (January 2, 2015)

* Updates binary versions to pgbouncer 1.7 and stunnel 5.28
* Uses `docker-compose up` for building binaries
* Vendors binaries directly into this repo instead of pulling from s3
* Removes cedar-10 version switch as that stack is EOL
* Adds README warning of excessive logging if non-persistent database
  connections are used
* Options at the end of connection url are now kept on purpose, but are still
  discouraged

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
