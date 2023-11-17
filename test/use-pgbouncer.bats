#!/usr/bin/env bats

load helper

@test "returns exit code of 1 with nothing to parse" {
  run bin/use-pgbouncer "printenv"
  assert_failure
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=setting DATABASE_URL_PGBOUNCER'
  refute_line 'buildpack=pgbouncer at=adding-one-to-5432'
}

@test "sets ups DATABASE_URL_PGBOUNCER" {
  export PGBOUNCER_URLS="DATABASE_URL"
  export ORIGINAL_DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=setting DATABASE_URL_PGBOUNCER'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgresql://user:pass@host:5432/name?query'
}

@test "substitutes postgres for postgresql in scheme" {
  export PGBOUNCER_URLS="DATABASE_URL"
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=setting DATABASE_URL_PGBOUNCER'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgresql://user:pass@host:5432/name?query'
}

@test "does not mutate other config vars not listed in PGBOUNCER_URLS" {
  export PGBOUNCER_URLS="DATABASE_URL"
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export OTHER_URL='postgresql://user:pass@host2:5432/name?query'
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=setting DATABASE_URL_PGBOUNCER'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgresql://user:pass@host:5432/name?query'
  assert_line 'OTHER_URL=postgresql://user:pass@host2:5432/name?query'
}

@test "does not mutates config vars listed in PGBOUNCER_URLS" {
  export DATABASE_URL='postgresql://user:pass@host:5432/name?query'
  export OTHER_URL='postgresql://user:pass@host2:5432/name?query'
  export PGBOUNCER_URLS="DATABASE_URL OTHER_URL"
  run bin/use-pgbouncer "printenv"
  assert_success
  assert_line 'buildpack=pgbouncer at=pgbouncer-enabled'
  assert_line 'buildpack=pgbouncer at=setting DATABASE_URL_PGBOUNCER'
  assert_line 'buildpack=pgbouncer at=setting OTHER_URL_PGBOUNCER'
  assert_line 'buildpack=pgbouncer at=adding-one-to-5432'
  assert_line 'buildpack=pgbouncer at=starting-app'

  assert_line 'DATABASE_URL_PGBOUNCER=postgres://user:pass@host:5433/name?query'
  assert_line 'DATABASE_URL=postgresql://user:pass@host:5432/name?query'
  assert_line 'OTHER_URL=postgresql://user:pass@host2:5432/name?query'
}

