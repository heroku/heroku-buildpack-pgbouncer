#!/usr/bin/env bash

DB=$(echo $DATABASE_URL | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^postgres:\/\/([^:]+):([^@]+)@(.*?):(.*?)\/(.*?)(\\?.*)?$/')
DB_URI=( $DB )
USER=${DB_URI[0]}
PASS=${DB_URI[1]}
HOST=${DB_URI[2]}
PORT=${DB_URI[3]}
DBNAME=${DB_URI[4]}

export PGBOUNCER_URI=postgres://$USER:$PASS@127.0.0.1:6000/$DBNAME

mkdir -p /app/vendor/stunnel/var/run/stunnel/
cat >> /app/vendor/stunnel/stunnel-pgbouncer.conf << EOFEOF
foreground = yes

options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH

[heroku-postgres]
client = yes
protocol = pgsql
accept  = localhost:6002
connect = $HOST:$PORT
retry = yes

EOFEOF

cat >> /app/vendor/pgbouncer/users.txt << EOFEOF
"$USER" "$PASS"
EOFEOF

cat >> /app/vendor/pgbouncer/pgbouncer.ini << EOFEOF
[databases]
$DBNAME = host=localhost port=6002
[pgbouncer]
listen_addr = localhost
listen_port = 6000
auth_type = md5
auth_file = /app/vendor/pgbouncer/users.txt

; When server connection is released back to pool:
;   session      - after client disconnects
;   transaction  - after transaction finishes
;   statement    - after statement finishes
pool_mode = transaction
server_reset_query =
max_client_conn = 100
default_pool_size = ${PGBOUNCER_DEFAULT_POOL_SIZE:-1}
reserve_pool_size = ${PGBOUNCER_RESERVE_POOL_SIZE:-1}
reserve_pool_timeout = ${PGBOUNCER_RESERVE_POOL_TIMEOUT:-5.0}
EOFEOF

