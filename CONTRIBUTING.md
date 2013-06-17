## Compiling new versions of pgbouncer and stunnel using Vulcan

Install [vulcan](https://github.com/heroku/vulcan) and create your own build server. Use any
app name you want and vulcan will remember it in a `~/.vulcan` config file.

```
gem install vulcan
vulcan create builder-bob
```

Store your S3 credentials in `~/.aws/`

```
mkdir -p ~/.aws
echo 'YOUR_AWS_KEY' > ~/.aws/key-pgbouncer.access
echo 'YOUR_AWS_SECRET' > ~/.aws/key-pgbouncer.secret
```

Add a credentials exporter to your `.bash_profile` or `.bashrc`

```
setup_pgbouncer_env () {
  export AWS_ID=$(cat ~/.aws/key-pgbouncer.access)
  export AWS_SECRET=$(cat ~/.aws/key-pgbouncer.secret)
  export S3_BUCKET="heroku-buildpack-pgbouncer"
}
```

Build:

```
setup_pgbouncer_env
support/package_pgbouncer <pgbouncer-version>
support/package_stunnel <stunnel-version>
```

## Publishing buildpack updates

```
heroku plugins:install https://github.com/heroku/heroku-buildpacks

cd heroku-buildpack-pgbouncer
git checkout master
heroku buildpacks:publish gregburek/pgbouncer
```
