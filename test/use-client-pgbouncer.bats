#!/usr/bin/env bats

load helper

setup() {
  export PGBOUNCER_OUTPUT_URLS=true
  export PGBOUNCER_ENABLED=true
  export PGBOUNCER_URLS="DATABASE_URL YOUR_MOMS_URL"
  export PGBOUNCER_URL_NAMES="db-primary db-your-mom"
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export YOUR_MOMS_URL='postgresql://mom:password@neighbours:5432/house?query'
}

teardown() {
  unset PGBOUNCER_OUTPUT_URLS
  unset PGBOUNCER_ENABLED
  unset PGBOUNCER_URLS
  unset PGBOUNCER_URL_NAMES
  unset DATABASE_URL
  unset YOUR_MOMS_URL
  unset DATABASE_URL_PGBOUNCER
  unset YOUR_MOMS_URL_PGBOUNCER
}

@test "returns success and disables when PGBOUNCER_ENABLED is not true" {
  unset PGBOUNCER_ENABLED
  run source bin/use-client-pgbouncer printenv
  assert_success
  assert_line "INFO:  pgbouncer-disabled"
  assert_line "INFO:  pgbouncer-disabled"
  assert_line "ERROR: pgBouncer is not enabled, skipping..."
}

@test "returns success and enables when PGBOUNCER_URLS is blank" {
  unset PGBOUNCER_URLS
  run source bin/use-client-pgbouncer printenv
  assert_success
  assert_line "INFO:  Client pgBouncer is enabled"
}

@test "returns success when all variables are properly set" {
  run source bin/use-client-pgbouncer printenv
  assert_success
  assert_output <<EOF
INFO:  Client pgBouncer is enabled
INFO:               DATABASE_URL_PGBOUNCER | postgres://user:********@127.0.0.1:6000/db-primary
INFO:              YOUR_MOMS_URL_PGBOUNCER | postgres://mom:********@127.0.0.1:6000/db-your-mom
INFO:  pgBouncer has been configured with 2 database(s).
EOF
}

@test "sets *_PGBOUNCER variables" {
  set -e
  [ -z ${DATABASE_URL_PGBOUNCER} ]
  source bin/use-client-pgbouncer
  assert_equal $DATABASE_URL_PGBOUNCER "postgres://user:pass@host:5433/name?query"
}

@test "does not mutate original database URLs" {
  set -e

  [[ -z ${DATABASE_URL_PGBOUNCER} ]]
  [[ ${DATABASE_URL} == 'postgresql://user:pass@host:5432/name?query' ]]

  source bin/use-client-pgbouncer
  assert_equal $DATABASE_URL_PGBOUNCER "postgres://user:pass@host:5433/name?query"
  assert_equal $DATABASE_URL 'postgresql://user:pass@host:5432/name?query'
}

@test "when no arguments are passed to exec it sets PGBOUNCER_URLS and exits with 0" {
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export OTHER_URL='postgresql://user:pass@host2:5432/name?query'
  export PGBOUNCER_URLS="DATABASE_URL OTHER_URL"

  source bin/use-client-pgbouncer; main

  [[ -n "${DATABASE_URL_PGBOUNCER}" ]]
  [[ -n "${OTHER_URL_PGBOUNCER}" ]]
}
