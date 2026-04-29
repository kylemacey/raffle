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
