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
