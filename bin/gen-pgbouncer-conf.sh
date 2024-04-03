#!/usr/bin/env bash

POSTGRES_URLS=${PGBOUNCER_URLS:-DATABASE_URL}
POOL_MODE=${PGBOUNCER_POOL_MODE:-transaction}
SERVER_RESET_QUERY=${PGBOUNCER_SERVER_RESET_QUERY}
CONFIG_DIR=${PGBOUNCER_CONFIG_DIR:-/app/vendor/pgbouncer}
n=1

set -eo pipefail

# if the SERVER_RESET_QUERY and pool mode is session, pgbouncer recommends DISCARD ALL be the default
# http://pgbouncer.projects.pgfoundry.org/doc/faq.html#_what_should_my_server_reset_query_be
if [ -z "${SERVER_RESET_QUERY}" ] &&  [ "$POOL_MODE" == "session" ]; then
  echo "SERVER_RESET_QUERY EMPTY"
  SERVER_RESET_QUERY="DISCARD ALL;"
fi

cat >> "$CONFIG_DIR/pgbouncer.ini" << EOFEOF
[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6000
auth_type = md5
auth_file = $CONFIG_DIR/users.txt
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
log_connections = ${PGBOUNCER_LOG_CONNECTIONS:-1}
log_disconnections = ${PGBOUNCER_LOG_DISCONNECTIONS:-1}
log_pooler_errors = ${PGBOUNCER_LOG_POOLER_ERRORS:-1}
stats_period = ${PGBOUNCER_STATS_PERIOD:-60}
ignore_startup_parameters = ${PGBOUNCER_IGNORE_STARTUP_PARAMETERS}
query_wait_timeout = ${PGBOUNCER_QUERY_WAIT_TIMEOUT:-120}

[databases]
EOFEOF

for POSTGRES_URL in $POSTGRES_URLS
do
  eval POSTGRES_URL_VALUE="\$$POSTGRES_URL"

  if [ -z "$POSTGRES_URL_VALUE" ]
  then
    echo "$POSTGRES_URL is empty. Exiting..."
    exit 1
  fi

  IFS=':' read -r DB_USER DB_PASS DB_HOST DB_PORT DB_NAME <<< "$(echo "$POSTGRES_URL_VALUE" | perl -lne 'print "$1:$2:$3:$4:$5" if /^postgres(?:ql)?:\/\/([^:]*):([^@]*)@(.*?):(.*?)\/(.*?)$/')"

  # We can ignore DB_NAME as this isn't strictly required.
  CONN_STRING_PARTS=("$DB_USER" "$DB_PASS" "$DB_HOST" "$DB_PORT")
  for CONN_STRING_PART in "${CONN_STRING_PARTS[@]}"
  do
    if [ -z "$CONN_STRING_PART" ]
    then
      # Don't dump the config variable value, only refer to it.
      echo "$POSTGRES_URL is not a valid PostgresSQL connection string. Exiting..."
      exit 1
    fi
  done

  DB_MD5_PASS="md5"$(echo -n "${DB_PASS}""${DB_USER}" | md5sum | awk '{print $1}')

  CLIENT_DB_NAME="db${n}"

  echo "Setting ${POSTGRES_URL}_PGBOUNCER config var"

  if [ "$PGBOUNCER_PREPARED_STATEMENTS" == "false" ]
  then
    export "${POSTGRES_URL}"_PGBOUNCER=postgres://"$DB_USER":"$DB_PASS"@127.0.0.1:6000/$CLIENT_DB_NAME?prepared_statements=false
  else
    export "${POSTGRES_URL}"_PGBOUNCER=postgres://"$DB_USER":"$DB_PASS"@127.0.0.1:6000/$CLIENT_DB_NAME
  fi

  cat >> "$CONFIG_DIR/users.txt" << EOFEOF
"$DB_USER" "$DB_MD5_PASS"
EOFEOF

  CONNECT_QUERY_PARAM=''
  if [[ "$PGBOUNCER_CONNECT_QUERY" ]]; then
    CONNECT_QUERY_PARAM="connect_query='${PGBOUNCER_CONNECT_QUERY//\'/\'\'}'"
  fi

  cat >> "$CONFIG_DIR/pgbouncer.ini" << EOFEOF
$CLIENT_DB_NAME= host=$DB_HOST dbname=$DB_NAME port=$DB_PORT $CONNECT_QUERY_PARAM
EOFEOF

  (( n += 1 ))
done

chmod go-rwx "$CONFIG_DIR"/*
