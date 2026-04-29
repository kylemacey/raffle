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

The app is still transitioning away from a single `users.admin` Boolean. New
RBAC tables and user-role assignment scaffolding exist, but legacy admin checks
are intentionally left in place until route-by-route permission checks are added.
