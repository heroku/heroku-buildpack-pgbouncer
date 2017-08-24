#!/usr/bin/env bats

load test/helper

@test "returns exit code of 1 with nothing to parse" {
  run bin/use-pgbouncer "printenv"
  assert_failure
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=mutating-DATABASE_URL'
  refute_line 'buildpack=pgbouncer at=adding-one-to-5432'
}

@test "mutates DATABASE_URL" {
  export DATABASE_URL='postgres://user:pass@host:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=mutating-DATABASE_URL'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgres://user:pass@host:5433/name?query'
}

@test "substitutes postgres for postgresql in scheme" {
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=mutating-DATABASE_URL'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgres://user:pass@host:5433/name?query'
}

@test "does not mutate other config vars not listed in PGBOUNCER_URLS" {
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export OTHER_URL='postgresql://user:pass@host2:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=mutating-DATABASE_URL'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgres://user:pass@host:5433/name?query'
  assert_line 'OTHER_URL=postgresql://user:pass@host2:5432/name?query'
}

@test "mutates all config vars listed in PGBOUNCER_URLS" {
  export PGBOUNCER_URLS="DATABASE_URL OTHER_URL"
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export OTHER_URL='postgresql://user:pass@host2:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=mutating-DATABASE_URL'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgres://user:pass@host:5433/name?query'
  assert_line 'OTHER_URL=postgres://user:pass@host2:5433/name?query'
}




























