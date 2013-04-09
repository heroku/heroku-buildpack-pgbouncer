## Testing buildpack changes using Anvil

[Anvil](https://github.com/ddollar/anvil) is a generic build server for Heroku.

```
gem install anvil-cli
```

The [heroku-anvil CLI plugin](https://github.com/ddollar/heroku-anvil) is a wrapper for anvil.

```
heroku plugins:install https://github.com/ddollar/heroku-anvil
```

The [ddollar/test buildpack](https://github.com/ddollar/buildpack-test) is for testing things: it runs `bin/test` on your app.

```
heroku build -b ddollar/test # -b can also point to a local directory
```

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
heroku buildpacks:publish heroku/pgbouncer
```

- Email [dos@heroku.com](mailto:dos@heroku.com) if changes are significant.
- Add a [changelog item](https://devcenter.heroku.com/admin/changelog_items/new).
- Update [pgbouncer Devcenter articles](https://devcenter.heroku.com/admin/articles/owned) as necessary.
