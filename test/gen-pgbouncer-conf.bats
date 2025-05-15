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
    export DATABASE_2_URL="postgresql://user2:pass2@host2:7777/dbname"
    export PGBOUNCER_URLS="DATABASE_URL DATABASE_2_URL"
    run bash bin/gen-pgbouncer-conf.sh
    assert_success
    cat "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert_line 'Setting DATABASE_URL_PGBOUNCER config var'
    assert grep "auth_type = scram-sha-256" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "server_tls_sslmode = require" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "db1= host=host dbname=name?query port=5432" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "db2= host=host2 dbname=dbname port=7777" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "\"user\" \"pass\"" "$PGBOUNCER_CONFIG_DIR/users.txt"
    assert grep "\"user2\" \"pass2\"" "$PGBOUNCER_CONFIG_DIR/users.txt"
}

@test "successfully allows changing of auth_type" {
    export DATABASE_URL="postgres://user:pass@host:5432/name?query"
    export PGBOUNCER_AUTH_TYPE="md5"
    run bash bin/gen-pgbouncer-conf.sh
    assert_success
    cat "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "auth_type = md5" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
}

@test "successfully allows changing of server_tls_sslmode" {
    export DATABASE_URL="postgres://user:pass@host:5432/name?query"
    export PGBOUNCER_SERVER_TLS_SSLMODE="prefer"
    run bash bin/gen-pgbouncer-conf.sh
    assert_success
    cat "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "server_tls_sslmode = prefer" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
}

@test "successfully allows changing of max_prepared_statements" {
    export DATABASE_URL="postgres://user:pass@host:5432/name?query"
    export PGBOUNCER_MAX_PREPARED_STATEMENTS="123"
    run bash bin/gen-pgbouncer-conf.sh
    assert_success
    cat "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
    assert grep "max_prepared_statements = 123" "$PGBOUNCER_CONFIG_DIR/pgbouncer.ini"
}

@test "successfully handles URI-encoded user/pass combinations" {
    export DATABASE_URL="postgresql://%22I+have+speci%40l+charcters%22:c00lp%40%25sword@host:5432/name?query"
    run bash bin/gen-pgbouncer-conf.sh
    assert_success
    assert grep '""I have speci@l charcters"" "c00lp@%sword"' "$PGBOUNCER_CONFIG_DIR/users.txt"
}
