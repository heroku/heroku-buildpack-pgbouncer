#!/usr/bin/env bats

load helper

setup_file() {
    export PGBOUNCER_CONFIG_DIR=$(mktemp -d run-test-pgbouncer.XXXXXXXXXX)
}

teardown_file() {
    unset PGBOUNCER_URLS
    unset DATABASE_URL
    unset DATABASE_2_URL
    rm -rf "$PGBOUNCER_CONFIG_DIR"
}

@test "returns exit code of 1 when PGBOUNCER_URLS is empty" {
    run bash bin/gen-pgbouncer-conf.sh
    assert_failure
    assert_line 'DATABASE_URL is empty. Exiting...'
}

@test "returns exit code of 1 if a value in PGBOUNCER_URLS is invalid" {
    export DATABASE_URL="foobar"
    run bash bin/gen-pgbouncer-conf.sh
    assert_failure
    assert_line 'DATABASE_URL is not a valid PostgresSQL connection string. Exiting...'
}

@test "successfully writes the config" {
    export DATABASE_URL="postgres://user:pass@host:5432/name?query"
    export DATABASE_2_URL="postgresql://user2:pass@host2:7777/dbname"
    export PGBOUNCER_URLS="DATABASE_URL DATABASE_2_URL"
    run bash bin/gen-pgbouncer-conf.sh
    assert_success
    cat "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert_line 'Setting DATABASE_URL_PGBOUNCER config var'
    assert grep "server_tls_sslmode = prefer" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "db1= host=host dbname=name?query port=5432" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "db2= host=host2 dbname=dbname port=7777" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "user" "$PGBOUNCER_CONFIG_DIR/users.txt"
    assert grep "user2" "$PGBOUNCER_CONFIG_DIR/users.txt"
}
