#!/usr/bin/env bats

load helper

setup_file() {
    export START_BOUNCER_TEST=1
}

teardown_file() {
    unset START_PGBOUNCER_TEST
    unset PGBOUNCER_ENABLED
    unset PGBOUNCER_URLS
    unset DATABASE_URL
    unset DATABASE_2_URL
}

@test "returns exit code of 1 when PGBOUNCER_URLS is empty" {
    run bash bin/start-pgbouncer "printenv"
    assert_failure
    assert_line 'DATABASE_URL is empty. Exiting...'
}

@test "does not start up pgbouncer when PGBOUNCER_ENABLED is set to 0" {
    export PGBOUNCER_ENABLED=0
    run bash bin/start-pgbouncer "printenv"
    assert_success
    assert_line "buildpack=pgbouncer at=pgbouncer-disabled"
}

@test "does not start up pgbouncer when a SCRAM-auth using database is detected" {
    export DATABASE_URL="postgres://utestuser:p1b1f7bc7b296294c96b3d6e5443f2d7a7826f7d73ac5a4d3f560c488799757e7@c1234567891234.cluster-foo.example.com:5432/d1234567891234"
    run bash bin/start-pgbouncer "printenv"
    assert_success
    assert_line "buildpack=pgbouncer at=pgbouncer-disabled-scram"
    assert_line "DATABASE_URL uses SCRAM authentication, which is currently unsupported. pgbouncer will not be enabled."
}

@test "does not start up pgbouncer when a SCRAM-auth using database is detected in the set of PGBOUNCER_URLS" {
    export DATABASE_URL="postgres://utestuser:p1b1f7bc7b296294c96b3d6e5443f2d7a7826f7d73ac5a4d3f560c488799757e7@c1234567891234.cluster-foo.example.com:5432/d1234567891234"
    export DATABASE_2_URL="postgres://utestuser:p1b1f7bc7b296294c96b3d6e5443f2d7a7826f7d73ac5a4d3f560c488799757e7@example.com:5432/d1234567891234"
    export PGBOUNCER_URLS="DATABASE_2_URL DATABASE_URL"
    run bash bin/start-pgbouncer "printenv"
    assert_success
    assert_line "buildpack=pgbouncer at=pgbouncer-disabled-scram"
    assert_line "DATABASE_URL uses SCRAM authentication, which is currently unsupported. pgbouncer will not be enabled."
}
