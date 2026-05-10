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

That starts the Rails web service on `127.0.0.1:3000` and a Stripe webhook
forwarder. The Rackmount HTTP router also maps `raffle.test` to the web service
on `127.0.0.1:18082`; configure local DNS for `raffle.test` if you want to use
that host name.

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
