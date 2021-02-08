#!/usr/bin/env bash

POSTGRES_URLS=${PGBOUNCER_URLS:-DATABASE_URL}
POOL_MODE=${PGBOUNCER_POOL_MODE:-transaction}
SERVER_RESET_QUERY=${PGBOUNCER_SERVER_RESET_QUERY}
n=1

# if the SERVER_RESET_QUERY and pool mode is session, pgbouncer recommends DISCARD ALL be the default
# http://pgbouncer.projects.pgfoundry.org/doc/faq.html#_what_should_my_server_reset_query_be
if [ -z "${SERVER_RESET_QUERY}" ] &&  [ "$POOL_MODE" == "session" ]; then
  SERVER_RESET_QUERY="DISCARD ALL;"
fi

mkdir -p /app/vendor/pgbouncer
cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
[pgbouncer]
listen_addr = ${PGBOUNCER_LISTEN_ADDR:-127.0.0.1}
listen_port = 6000
auth_type = md5
auth_file = /app/vendor/pgbouncer/users.txt
server_tls_sslmode = prefer
server_tls_protocols = secure
server_tls_ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH

; When server connection is released back to pool:
;   session      - after client disconnects
;   transaction  - after transaction finishes
;   statement    - after statement finishes
pool_mode = ${POOL_MODE}
server_reset_query = ${SERVER_RESET_QUERY}
max_client_conn = ${PGBOUNCER_MAX_CLIENT_CONN:-100}
default_pool_size = ${PGBOUNCER_DEFAULT_POOL_SIZE:-1}
min_pool_size = ${PGBOUNCER_MIN_POOL_SIZE:-0}
reserve_pool_size = ${PGBOUNCER_RESERVE_POOL_SIZE:-1}
reserve_pool_timeout = ${PGBOUNCER_RESERVE_POOL_TIMEOUT:-5.0}
server_lifetime = ${PGBOUNCER_SERVER_LIFETIME:-3600}
server_idle_timeout = ${PGBOUNCER_SERVER_IDLE_TIMEOUT:-600}
server_connect_timeout = ${PGBOUNCER_SERVER_CONNECT_TIMEOUT:-15}
log_connections = ${PGBOUNCER_LOG_CONNECTIONS:-1}
log_disconnections = ${PGBOUNCER_LOG_DISCONNECTIONS:-1}
log_pooler_errors = ${PGBOUNCER_LOG_POOLER_ERRORS:-1}
stats_period = ${PGBOUNCER_STATS_PERIOD:-60}
ignore_startup_parameters = ${PGBOUNCER_IGNORE_STARTUP_PARAMETERS}
query_wait_timeout = ${PGBOUNCER_QUERY_WAIT_TIMEOUT:-120}

; Low-level network settings, defaults as per pgbouncer:
;
;   https://pgbouncer.github.io/config.html#low-level-network-settings
;
; tcp_keepcnt, tcp_keepidle, and tcp_keepidle, supported with defaults
; for Linux as documented above.
;
; These defaults match both pgbouncer 1.7 and pgbouncer HEAD.
;
;   https://github.com/pgbouncer/pgbouncer/blob/pgbouncer_1_7/etc/pgbouncer.ini
;   https://github.com/pgbouncer/pgbouncer/blob/master/etc/pgbouncer.ini
;
pkt_buf = ${PGBOUNCER_PKT_BUF:-4096}
max_packet_size = ${PGBOUNCER_MAX_PACKET_SIZE:-2147483647}
listen_backlog = ${PGBOUNCER_LISTEN_BACKLOG:-128}
sbuf_loopcnt = ${PGBOUNCER_SBUF_LOOPCNT:-5}
suspend_timeout = ${PGBOUNCER_SUSPEND_TIMEOUT:-10}
tcp_defer_accept = ${PGBOUNCER_TCP_DEFER_ACCEPT:-45}
tcp_keepalive = ${PGBOUNCER_TCP_KEEPALIVE:-1}
tcp_keepcnt = ${PGBOUNCER_TCP_KEEPCNT:-9}
tcp_keepidle = ${PGBOUNCER_TCP_KEEPIDLE:-7200}
tcp_keepintvl = ${PGBOUNCER_TCP_KEEPINTVL:-75}
EOFEOF

# If PGBOUNCER_STATS_USERNAME and PGBOUNCER_STATS_PASSWORD are
# defined, enable SHOW commands from pgbouncer with those credentials.
#
rm -f /app/vendor/pgbouncer/users.txt
if [ -n "$PGBOUNCER_STATS_USERNAME" ] && [ -n "$PGBOUNCER_STATS_PASSWORD" ]
then
    STATS_MD5_PASS="md5"`echo -n ${PGBOUNCER_STATS_PASSWORD}${PGBOUNCER_STATS_USERNAME} | md5sum | awk '{print $1}'`
    cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
stats_users = $PGBOUNCER_STATS_USERNAME
EOFEOF
    cat >> /app/vendor/pgbouncer/users.txt << EOFEOF
"$PGBOUNCER_STATS_USERNAME" "$STATS_MD5_PASS"
EOFEOF
fi

cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
[databases]
EOFEOF

for POSTGRES_URL in $POSTGRES_URLS
do
  eval POSTGRES_URL_VALUE=\$$POSTGRES_URL
  IFS=':' read DB_USER DB_PASS DB_HOST DB_PORT DB_NAME <<< $(echo $POSTGRES_URL_VALUE | perl -lne 'print "$1:$2:$3:$4:$5" if /^postgres(?:ql)?:\/\/([^:]*):([^@]*)@(.*?):(.*?)\/(.*?)$/')

  DB_MD5_PASS="md5"`echo -n ${DB_PASS}${DB_USER} | md5sum | awk '{print $1}'`

  CLIENT_DB_NAME="db${n}"

  echo "Setting ${POSTGRES_URL}_PGBOUNCER config var"

  if [ "$PGBOUNCER_PREPARED_STATEMENTS" == "false" ]
  then
    export ${POSTGRES_URL}_PGBOUNCER=postgres://$DB_USER:$DB_PASS@127.0.0.1:6000/$CLIENT_DB_NAME?prepared_statements=false
  else
    export ${POSTGRES_URL}_PGBOUNCER=postgres://$DB_USER:$DB_PASS@127.0.0.1:6000/$CLIENT_DB_NAME
  fi

  cat >> /app/vendor/pgbouncer/users.txt << EOFEOF
"$DB_USER" "$DB_MD5_PASS"
EOFEOF

  cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
$CLIENT_DB_NAME= host=$DB_HOST dbname=$DB_NAME port=$DB_PORT
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/pgbouncer/*
