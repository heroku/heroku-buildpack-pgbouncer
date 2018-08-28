## Compiling new versions of pgbouncer using Docker

Install [docker](https://www.docker.com/). Use the Get Started button at the
top of the page, which autodetects your OS and presents the appropriate
instructions.

Build:

```
$ cd support
$ docker-compose build
$ docker-compose up
```

## Publishing buildpack updates

```
heroku plugins:install https://github.com/heroku/heroku-buildpacks

cd heroku-buildpack-pgbouncer
git checkout master
heroku buildpacks:publish heroku/pgbouncer
```
