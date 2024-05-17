ARG BASE_IMAGE
FROM --platform=linux/amd64 $BASE_IMAGE

ARG STACK
USER root
RUN mkdir -p /app /cache /env
COPY . /buildpack
# Sanitize the environment seen by the buildpack, to prevent reliance on
# environment variables that won't be present when it's run by Heroku CI.
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/detect /app
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/compile /app /cache /env

ENV DATABASE_URL=postgres://user:pass@example.com:5432/postgres
WORKDIR /app
RUN bash bin/gen-pgbouncer-conf.sh
RUN sed -i -e :a -e '$d;N;2,2ba' -e 'P;D' vendor/pgbouncer/pgbouncer.ini
RUN useradd pgbouncer
RUN chown pgbouncer -R /app
USER pgbouncer
