# Agent Notes

## Local Server

Use Rackmount to run this app locally. Do not start Rails directly with
`bin/rails server` or `bundle exec rails server`.

Preferred command:

```sh
PATH="$HOME/.rbenv/versions/3.1.7/bin:$PATH" RBENV_VERSION=3.1.7 bin/dev --headless
```

The explicit Ruby path matters in Codex shells where `/usr/bin/ruby` may appear
before rbenv. Without it, Rackmount can start the service scripts under macOS
system Ruby and fail to load Bundler or dotenv.

Useful Rackmount commands:

```sh
rackmount status
rackmount logs
rackmount stop
rackmount restart
```

Rackmount starts the Rails web process from `Procfile` via `bin/rackmount-web`,
which binds to `127.0.0.1:3000` and uses the repo's Rackmount environment setup.
