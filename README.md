# README

This Rails app supports Farley's Friends raffle, event POS, and RocStar
fundraising workflows.

## Product Direction

The current persona and access-control work is documented in:

- [Personas](docs/personas.md)
- [RBAC Scaffold](docs/rbac.md)

These documents should guide feature decisions, user stories, interface design,
and future authorization work.

## Development Notes

Internal app authorization is enforced through database-backed RBAC permissions.
The legacy `users.admin` Boolean is retained only as migration source data for
backfilling existing admins into the `platform_admin` role.

## Rackmount Development

Rackmount is the default local process runner for this repo:

```sh
bin/dev
```

That starts the Rails web service on `127.0.0.1:3000`, the GoodJob worker, and a
Stripe webhook forwarder. The Rackmount HTTP router also maps `raffle.test` to
the web service on `127.0.0.1:18082`; configure local DNS for `raffle.test` if
you want to use that host name.

By default the Stripe webhook forwarder subscribes to the webhook types handled
by `WebhooksController`: Terminal reader action success/failure events and the
silent-auction invoice lifecycle events (`invoice.finalized`, `invoice.sent`,
`invoice.paid`, `invoice.payment_failed`, `invoice.finalization_failed`, and
`invoice.voided`). Override `STRIPE_WEBHOOK_EVENTS` only when you intentionally
want a narrower or broader local event set.

Create a local `.env` from `.env.example`. The Stripe webhook service uses
`STRIPE_API_KEY` when present, otherwise `STRIPE_SECRET_KEY`, and passes that
project-specific value to `stripe listen` with `--api-key`, so the CLI does not
fall back to another configured Stripe project. Rails uses `STRIPE_SECRET_KEY`,
or falls back to `STRIPE_API_KEY` when that is the only Stripe secret configured.

By default `bin/rackmount-web` resolves the Stripe webhook signing secret with:

```sh
stripe listen --api-key "${STRIPE_API_KEY:-$STRIPE_SECRET_KEY}" --print-secret
```

Set `RACKMOUNT_STRIPE_SYNC_ENDPOINT_SECRET=0` if you want Rails to use the
`STRIPE_ENDPOINT_SECRET` value from the environment exactly as provided.

For the database, Rackmount dev uses `DATABASE_URL`. The `.env.example` default
points to `postgres://postgres:password@127.0.0.1:55434/raffle_development`,
which matches the Compose `db` service published port. Change that connection
string if you want Rackmount Rails to use a different PostgreSQL server. Docker
Compose remains available as an optional deployment/development path and also
passes Rails a `DATABASE_URL`.

## Staging

Staging runs with `RAILS_ENV=staging` and inherits production Rails settings while
keeping staging-specific infrastructure. Set `DATABASE_URL` to a staging-only
PostgreSQL database, set `REDIS_URL` to staging Redis, and use the standard
`SECRET_KEY_BASE` Rails secret.

The Coolify staging deployment runbook is in
[Coolify Staging Deployment](docs/coolify-staging.md).

Stripe must use test-mode credentials in staging. Set `STRIPE_SECRET_KEY` or
`STRIPE_API_KEY` to a secret or restricted test key (`sk_test_...` or
`rk_test_...`). Rails and the Rackmount Stripe entrypoints fail on boot if
staging is missing Stripe credentials or if either Stripe key is live mode.
Set `STRIPE_ENDPOINT_SECRET` to the staging webhook signing secret unless
Rackmount is allowed to resolve it automatically.

Staging uses the `raffle_staging` GoodJob queue prefix and `raffle_staging`
Action Cable channel prefix. Tune worker throughput with `GOOD_JOB_QUEUES`,
`GOOD_JOB_MAX_THREADS`, `GOOD_JOB_POLL_INTERVAL`, and
`GOOD_JOB_SHUTDOWN_TIMEOUT` when needed.

## Background Jobs

ActiveJob uses GoodJob in development, staging, and production. GoodJob stores
jobs in PostgreSQL and runs them from a separate worker process, so async work
does not depend on the Rails web request lifecycle. The test environment uses
the Rails test adapter for predictable assertions.

Run the GoodJob migration before deploying or starting a worker against a fresh
database:

```sh
bin/rails db:migrate
```

Rackmount starts the worker from `Procfile`:

```Procfile
worker: bin/rackmount-worker
```

Useful local operations:

```sh
rackmount status
rackmount logs
rackmount restart
rackmount stop
```

The worker entrypoint accepts GoodJob environment settings when you need to tune
local, staging, or production throughput:

```sh
GOOD_JOB_QUEUES="*" GOOD_JOB_MAX_THREADS=5 GOOD_JOB_POLL_INTERVAL=10 bin/rackmount-worker
```

Inspect queued and recent jobs from Rails:

```sh
bin/rails runner 'puts GoodJob::Job.order(created_at: :desc).limit(20).pluck(:id, :queue_name, :job_class, :finished_at, :error).map { |row| row.join(" | ") }'
```

Clean preserved job history with:

```sh
bundle exec good_job cleanup_preserved_jobs
```
