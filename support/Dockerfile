FROM heroku/cedar:14
MAINTAINER gregburek

RUN apt-get -q update
RUN apt-get -q -y install curl gcc g++ make wget unzip

ADD pgbouncer-build pgbouncer-build
ADD 0001-Disable-SIGTERM.patch pgbouncer-patch

CMD ./pgbouncer-build

