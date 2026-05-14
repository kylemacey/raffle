# Coolify Staging Deployment

This runbook deploys the staging app to the local Coolify instance at
`https://deploy.ktm.dev/`. Coolify runs on the Tantive VM at `192.168.50.105`
and is served through Cloudflare.

The target application URL is `https://raffle-staging.ktm.dev`.

## Deployment Shape

Use Coolify Nixpacks resources instead of the repo Dockerfile. The app requires
Ruby `3.1.7`, and Nixpacks can build from `.ruby-version`/`Gemfile` while the
current Dockerfile is not the staging deployment source of truth.

Create these resources in the Coolify `raffle` project and `staging`
environment:

| Resource | Type | Public URL | Notes |
|---|---|---|---|
| `raffle-staging-db` | PostgreSQL | none | Staging-only database and GoodJob storage. |
| `raffle-staging-redis` | Redis | none | Staging-only Action Cable Redis. |
| `raffle-staging-web` | Application, Nixpacks | `https://raffle-staging.ktm.dev` | Rails web process on port `3000`. |
| `raffle-staging-worker` | Application, Nixpacks | none | GoodJob worker process. |

Configure both application resources from `kylemacey/raffle`, branch `main`.
Keep auto-deploy enabled only after the first successful manual deploy.

## Web Resource

Coolify settings:

- Build Pack: `Nixpacks`
- Branch: `main`
- Base Directory: `/`
- Port Exposes: `3000`
- Domain: `https://raffle-staging.ktm.dev`
- Health check path: `/up`
- Start command:

```sh
bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
```

The `/up` endpoint checks Rails and PostgreSQL. Coolify should return traffic
only after this endpoint is healthy.

## Worker Resource

Coolify settings:

- Build Pack: `Nixpacks`
- Branch: `main`
- Base Directory: `/`
- Domain: none
- Public port: none
- Health checks: disabled unless Coolify requires one for non-HTTP resources
- Start command:

```sh
bundle exec good_job start
```

The worker must share the same `RAILS_ENV`, `DATABASE_URL`, `REDIS_URL`, Stripe
test credentials, and GoodJob tuning values as the web resource.

## Environment Variables

Set these on both `raffle-staging-web` and `raffle-staging-worker`. Coolify's
default environment-variable behavior makes values available at build and
runtime; keep that default unless a later deploy proves a variable is strictly
runtime-only.

```env
RAILS_ENV=staging
SECRET_KEY_BASE=<generated staging secret>
DATABASE_URL=<Coolify PostgreSQL internal URL>
REDIS_URL=<Coolify Redis internal URL>
STRIPE_SECRET_KEY=sk_test_...
STRIPE_ENDPOINT_SECRET=whsec_...
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
GOOD_JOB_QUEUES=*
GOOD_JOB_MAX_THREADS=5
GOOD_JOB_POLL_INTERVAL=10
GOOD_JOB_SHUTDOWN_TIMEOUT=30
```

Use only Stripe test-mode secrets in staging. The app rejects live-mode
`sk_live_...` or `rk_live_...` credentials when `RAILS_ENV=staging`.

Generate `SECRET_KEY_BASE` from a local trusted shell with:

```sh
bin/rails secret
```

Do not commit real secrets to this repo.

## Stripe Webhook

In the Stripe Dashboard test-mode workspace, create a webhook endpoint:

```text
https://raffle-staging.ktm.dev/webhooks/stripe
```

Subscribe it to the events handled by the app:

```text
terminal.reader.action_succeeded
terminal.reader.action_failed
invoice.finalized
invoice.sent
invoice.paid
invoice.payment_failed
invoice.finalization_failed
invoice.voided
```

Copy the endpoint signing secret into `STRIPE_ENDPOINT_SECRET` on both Coolify
application resources, then redeploy web and worker.

## Initial Bootstrap

After the web resource deploys successfully, open a Coolify terminal for
`raffle-staging-web` and run this once. Replace the PIN before running.

```sh
STAGING_ADMIN_PIN=2468 bundle exec rails runner '
  admin = User.find_or_initialize_by(pin: ENV.fetch("STAGING_ADMIN_PIN"))
  admin.name = "Staging Admin"
  admin.admin = true
  admin.save!

  platform_admin = Role.find_by!(key: "platform_admin")
  UserRole.find_or_create_by!(user: admin, role: platform_admin)

  Event.find_or_create_by!(name: "Staging Smoke Test")
  SilentAuctionSetting.current
  InvoiceSetting.current

  puts "Staging admin PIN: #{admin.pin}"
  puts "Smoke event ready"
'
```

Use a staging-only PIN. Rotate it after broad testing or if it is shared in a
ticket, chat, or screen recording.

## Deploy Order

1. Create PostgreSQL and Redis resources.
2. Create `raffle-staging-web`, set environment variables, and deploy.
3. Confirm `https://raffle-staging.ktm.dev/up` returns HTTP 200.
4. Run the initial bootstrap command.
5. Create the Stripe test webhook and set `STRIPE_ENDPOINT_SECRET`.
6. Redeploy the web resource.
7. Create `raffle-staging-worker`, copy the same environment variables, and
   deploy.
8. Confirm the worker logs show GoodJob started.

## Smoke Test

1. Visit `https://raffle-staging.ktm.dev/up`; expect HTTP 200 and
   `{"status":"ok"}`.
2. Sign in at `https://raffle-staging.ktm.dev/sign_in` with the staging admin
   PIN.
3. Open the `Staging Smoke Test` event.
4. Create a silent auction item with:
   - Name: `Staging Invoice Test`
   - Description: any staging-only text
   - Image URL: a public HTTPS image URL
   - Starting bid: `25.00`
5. Open the item for bidding.
6. Open the public auction URL in a private browser window and place at least
   three bids with different names, phones, emails, and increasing amounts.
7. Return to the admin item page and close bidding.
8. In Coolify worker logs, confirm `SilentAuction::CloseItemJob` ran and sent a
   Stripe invoice.
9. Open the hosted invoice from the admin item page or Stripe test dashboard.
10. Pay it with Stripe test card `4242 4242 4242 4242`, any future expiration
    date, and any CVC.
11. Confirm the Stripe `invoice.paid` webhook is delivered successfully.
12. Confirm the admin item page shows the invoice as paid and that local order
    and payment records exist for the paid invoice.

Useful Rails checks from the Coolify terminal:

```sh
bundle exec rails runner 'puts InvoiceRecord.order(created_at: :desc).limit(5).pluck(:stripe_invoice_id, :stripe_status, :paid_at, :last_error)'
bundle exec rails runner 'puts GoodJob::Job.order(created_at: :desc).limit(10).pluck(:id, :queue_name, :job_class, :finished_at, :error)'
```

## Operations

Health check:

```sh
curl -fsS https://raffle-staging.ktm.dev/up
```

Logs:

- Use Coolify logs for both `raffle-staging-web` and
  `raffle-staging-worker`.
- Check worker logs first when invoices are not created or paid webhooks do not
  update local records.

Restart:

- Restart web after environment-variable or domain changes.
- Restart worker after queue or Stripe environment changes.

Rollback:

- Use Coolify's rollback action on `raffle-staging-web` first.
- Roll back `raffle-staging-worker` to the matching image/version immediately
  after the web rollback.
- If a rollback crosses a migration boundary, inspect the staging database
  before retrying worker jobs.

Backups:

- Enable scheduled Coolify PostgreSQL backups for `raffle-staging-db`.
- A daily backup is enough for staging unless active payment-flow testing is in
  progress.

Data separation:

- Never point staging at development or production PostgreSQL.
- Never reuse production Redis.
- Keep staging Stripe credentials in test mode and keep the staging webhook
  endpoint separate from production.

## References

- Coolify Rails start command:
  <https://coolify.io/docs/applications/rails>
- Coolify application commands and Nixpacks:
  <https://coolify.io/docs/applications/index>
- Coolify environment variables:
  <https://coolify.io/docs/knowledge-base/environment-variables>
- Coolify health checks:
  <https://coolify.io/docs/knowledge-base/health-checks>
- Coolify domains and HTTPS:
  <https://coolify.io/docs/knowledge-base/domains>
- Coolify PostgreSQL backups:
  <https://coolify.io/docs/databases/backups>
