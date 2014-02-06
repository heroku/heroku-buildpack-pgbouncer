#!/usr/bin/env bash

POSTGRES_URLS=${PGBOUNCER_URLS:-DATABASE_URL}
n=1

mkdir -p /app/vendor/stunnel/var/run/stunnel/
cat >> /app/vendor/stunnel/stunnel-pgbouncer.conf << EOFEOF
foreground = yes

options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
EOFEOF

cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
[pgbouncer]
listen_addr = localhost
listen_port = 6000
auth_type = md5
auth_file = /app/vendor/pgbouncer/users.txt

; When server connection is released back to pool:
;   session      - after client disconnects
;   transaction  - after transaction finishes
;   statement    - after statement finishes
pool_mode = ${PGBOUNCER_POOL_MODE:-transaction}
server_reset_query =
max_client_conn = 100
default_pool_size = ${PGBOUNCER_DEFAULT_POOL_SIZE:-1}
reserve_pool_size = ${PGBOUNCER_RESERVE_POOL_SIZE:-1}
reserve_pool_timeout = ${PGBOUNCER_RESERVE_POOL_TIMEOUT:-5.0}
log_connections = ${PGBOUNCER_LOG_CONNECTIONS:-1}
log_disconnections = ${PGBOUNCER_LOG_DISCONNECTIONS:-1}
log_pooler_errors = ${PGBOUNCER_LOG_POOLER_ERRORS:-1}
stats_period = ${PGBOUNCER_STATS_PERIOD:-60}
[databases]
EOFEOF

for POSTGRES_URL in $POSTGRES_URLS
do
  eval POSTGRES_URL_VALUE=\$$POSTGRES_URL
  DB=$(echo $POSTGRES_URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^postgres:\/\/([^:]+):([^@]+)@(.*?):(.*?)\/(.*?)(\\?.*)?$/')
  DB_URI=( $DB )
  DB_USER=${DB_URI[0]}
  DB_PASS=${DB_URI[1]}
  DB_HOST=${DB_URI[2]}
  DB_PORT=${DB_URI[3]}
  DB_NAME=${DB_URI[4]}
  DB_MD5_PASS="md5"`echo -n ${DB_PASS}${DB_USER} | md5sum | awk '{print $1}'`

  if [ "$PGBOUNCER_PREPARED_STATEMENTS" == "false" ]
  then
    export ${POSTGRES_URL}_PGBOUNCER=postgres://$DB_USER:$DB_PASS@127.0.0.1:6000/$DB_NAME?prepared_statements=false
  else
    export ${POSTGRES_URL}_PGBOUNCER=postgres://$DB_USER:$DB_PASS@127.0.0.1:6000/$DB_NAME
  fi

  cat >> /app/vendor/stunnel/stunnel-pgbouncer.conf << EOFEOF
[$POSTGRES_URL]
client = yes
protocol = pgsql
accept  = /tmp/.s.PGSQL.610${n}
connect = $DB_HOST:$DB_PORT
retry = ${PGBOUNCER_CONNECTION_RETRY:-"no"}
EOFEOF

  cat >> /app/vendor/pgbouncer/users.txt << EOFEOF
"$DB_USER" "$DB_MD5_PASS"
EOFEOF

  cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
$DB_NAME= port=610${n}
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/pgbouncer/*
chmod go-rwx /app/vendor/stunnel/*
