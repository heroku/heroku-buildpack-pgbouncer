FROM heroku/cedar:14
MAINTAINER gregburek

RUN apt-get -q update
RUN apt-get -q -y install curl gcc g++ make wget unzip

RUN wget -q https://github.com/rlmcpherson/s3gof3r/releases/download/v0.3.2/gof3r_0.3.2_linux_amd64.tar.gz
RUN tar zxf gof3r_0.3.2_linux_amd64.tar.gz
RUN mv gof3r_0.3.2_linux_amd64/gof3r .
RUN rm -rf gof3r_0.3.2_linux_amd64*

ADD pgbouncer-build pgbouncer-build
ADD pgbouncer-1.5.4-sigterm.diff pgbouncer-patch

CMD ./pgbouncer-build

