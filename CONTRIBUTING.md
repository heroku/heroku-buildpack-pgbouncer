## Compiling new versions of pgbouncer and stunnel

This repository is itself a heroku app, which will build binaries of postgres
on each start of the web dyno.

Using the Heroku Command Line you can clone this repo locally, then create a
new python heroku application.

By setting the `PGBOUNCER_VERSION` and `STUNNEL_VERSION` configs you can set
which version of the binary is generated.

```
heroku apps:create your-app-name
heroku buildpacks:set heroku/python
heroku config:set PGBOUNCER_VERSION=1.7
heroku config:set STUNNEL_VERSION=5.28
git push heroku master
```

To monitor the logs of your build, type in `heroku logs -t`

Once this is finished you can go to https://your-app-name.herokuapp.com to
pull the compiled binaries.

While not required, it's probably courtious to scale down the Heroku app after
you've downloaded the binaries. To do that, use `heroku scale web=0`


## Publishing buildpack updates

```
heroku plugins:install https://github.com/heroku/heroku-buildpacks

cd heroku-buildpack-pgbouncer
git checkout master
heroku buildpacks:publish gregburek/pgbouncer
```
