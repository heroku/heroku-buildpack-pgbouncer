FROM heroku/heroku:16-build
MAINTAINER gregburek

ADD pgbouncer-build pgbouncer-build
ADD 0001-Disable-SIGTERM.patch pgbouncer-patch

CMD ./pgbouncer-build
