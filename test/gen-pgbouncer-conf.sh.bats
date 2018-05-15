#!/usr/bin/env bats

load helper

@test "generates /app/vendor/stunnel/stunnel-pgbouncer.conf" {
  rm -f /app/vendor/stunnel/stunnel-pgbouncer.conf
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert test -f /app/vendor/stunnel/stunnel-pgbouncer.conf
}

@test "generates /app/vendor/pgbouncer/pgbouncer.ini" {
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert test -f /app/vendor/pgbouncer/pgbouncer.ini
}

@test "generates /app/vendor/pgbouncer/users.txt" {
  rm -f /app/vendor/pgbouncer/users.txt
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert test -f /app/vendor/pgbouncer/users.txt
}

@test "env overrides for pgbouncer low-level network settings" {
  export PGBOUNCER_PKT_BUF=XXX_PKT_BUF
  export PGBOUNCER_MAX_PACKET_SIZE=XXX_MAX_PACKET_SIZE
  export PGBOUNCER_LISTEN_BACKLOG=XXX_LISTEN_BACKLOG
  export PGBOUNCER_SBUF_LOOPCNT=XXX_SBUF_LOOPCNT
  export PGBOUNCER_SUSPEND_TIMEOUT=XXX_SUSPEND_TIMEOUT
  export PGBOUNCER_TCP_DEFER_ACCEPT=XXX_TCP_DEFER_ACCEPT
  export PGBOUNCER_TCP_KEEPALIVE=XXX_TCP_KEEPALIVE
  export PGBOUNCER_TCP_KEEPCNT=XXX_TCP_KEEPCNT
  export PGBOUNCER_TCP_KEEPIDLE=XXX_TCP_KEEPIDLE
  export PGBOUNCER_TCP_KEEPINTVL=XXX_TCP_KEEPINTVL
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert grep 'pkt_buf = XXX_PKT_BUF' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'max_packet_size = XXX_MAX_PACKET_SIZE' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'listen_backlog = XXX_LISTEN_BACKLOG' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'sbuf_loopcnt = XXX_SBUF_LOOPCNT' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'suspend_timeout = XXX_SUSPEND_TIMEOUT' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'tcp_defer_accept = XXX_TCP_DEFER_ACCEPT' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'tcp_keepalive = XXX_TCP_KEEPALIVE' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'tcp_keepcnt = XXX_TCP_KEEPCNT' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'tcp_keepidle = XXX_TCP_KEEPIDLE' /app/vendor/pgbouncer/pgbouncer.ini
  assert grep 'tcp_keepintvl = XXX_TCP_KEEPINTVL' /app/vendor/pgbouncer/pgbouncer.ini
}

@test "no stats_users if not configured" {
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert grep -v stats_users /app/vendor/pgbouncer/pgbouncer.ini
}

@test "no stats_users if half-configured" {
  export PGBOUNCER_STATS_USERNAME=cognoscente
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert grep -v cognoscente /app/vendor/pgbouncer/pgbouncer.ini
}

@test "no stats_users if other half-configured" {
  export PGBOUNCER_STATS_PASSWORD=arcanus
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert grep -v arcanus /app/vendor/pgbouncer/pgbouncer.ini
}

@test "stats_users if fully configured" {
  export PGBOUNCER_STATS_USERNAME=cognoscente
  export PGBOUNCER_STATS_PASSWORD=arcanus
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  #
  # pgbouncer.ini should contain the username but no form of the
  # password.
  #
  assert grep    cognoscente    /app/vendor/pgbouncer/pgbouncer.ini
  assert grep -v arcanus        /app/vendor/pgbouncer/pgbouncer.ini
  assert grep -v 'md5e98.*12d3' /app/vendor/pgbouncer/users.txt
  #
  # user.txt should contain the username and the hashed form of the
  # password but not the plaintext password.
  #
  assert grep    cognoscente    /app/vendor/pgbouncer/users.txt
  assert grep -v arcanus        /app/vendor/pgbouncer/users.txt
  assert grep    'md5e98.*12d3' /app/vendor/pgbouncer/users.txt
}

@test "specific known-good username password pair" {
  export PGBOUNCER_STATS_USERNAME=pgbouncer-stats
  export PGBOUNCER_STATS_PASSWORD=naked
  rm -f /app/vendor/pgbouncer/pgbouncer.ini
  run bash bin/gen-pgbouncer-conf.sh
  assert_success
  assert grep 'md572c.*693' /app/vendor/pgbouncer/users.txt
}
