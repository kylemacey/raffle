# Personas

This document records the working personas for the raffle and fundraising app.
It is intentionally broader than the first RBAC implementation. Personas describe
real people, motivations, anxieties, and jobs to be done. Roles and permissions
are a separate layer documented in [RBAC](rbac.md).

The current personas were inferred from the codebase, the event flows exposed in
the UI, and product context from the team. Some are "as-is" personas caused by
current design constraints. They should be treated as a starting point for better
features, not as proof that the current workflows are ideal.

## Persona Map

| Persona | Typical people | Core job | RBAC role in v1 |
| --- | --- | --- | --- |
| Cashier / Sales Volunteer | Event volunteers, temporary helpers | Sell raffle items quickly and avoid checkout mistakes | `cashier` |
| Event Lead / Board Member | Board members running Farley's Friends Gives Back or ForeForFour | Keep event operations, raffle integrity, and guest experience under control | `event_lead` |
| Config Admin | Technical board members such as Keith and Jared | Prepare the system before the event and rescue configuration problems | `config_admin` / Admin |
| Platform Admin | Developers or break-glass operators | Debug, recover, impersonate, and support live incidents | `platform_admin` / SuperAdmin |
| Board Reporter / Financial Analyst | Non-technical board leaders such as James | Understand fundraising health without handling raw exports casually | `board_reporter` / Financial Analyst |
| Buyer / Donor / RocStar | Event guests, raffle buyers, recurring supporters | Give money, buy entries, subscribe, or support without friction | Public surface, not assignable in v1 |

## Cashier / Sales Volunteer

### Context

Cashiers are casual volunteers operating a tablet and usually a Stripe S700
reader at a live event. They may be trained minutes before they start. They are
not trying to understand the full event database, Stripe configuration, or admin
screens. They need a narrow, reliable sales lane.

### Motivations

- Keep the line moving.
- Maximize contributions while the guest is ready to give.
- Avoid embarrassing mistakes in front of donors.
- Complete a sale without needing to find a board member.

### Fears

- Holding people up.
- Charging the wrong amount.
- Double charging a guest.
- Losing raffle entries or creating a state that cannot be fixed quickly.
- Being blamed for a technical problem they cannot diagnose.

### Jobs To Be Done

- Open the POS for the current event.
- Add raffle or event products to a cart.
- Capture buyer name and contact details when needed.
- Take cash or card payment.
- Know whether the sale completed.
- Recover from a declined card, missing reader, or interrupted checkout.

### UX Implications

- POS should be the first and only obvious surface for this persona.
- Cashier language should avoid internal labels such as "Agent."
- Reader status and payment availability need to be unmistakable.
- The interface should prevent impossible actions, especially completing a sale
  with an invalid cart or unavailable payment method.
- Error recovery copy should say what to do next, not just what failed.

## Event Lead / Board Member

### Context

Each board member may function as an event lead. At events like Farley's Friends
Gives Back and ForeForFour, the lead is also a host. They want to mingle, golf,
support donors, and keep the event premium rather than operate the app all day.

Farley's Friends Gives Back is a happy-hour style event with snacks, drinks,
raffle activity, and a single charity spotlight. ForeForFour is a charity golf
tournament supporting Farley's Friends plus three other charities, with raffle
sales, mulligans, and putt-for-prizes style fundraising.

### Motivations

- Run a smooth event with minimal live support calls.
- Keep volunteers confident.
- Make raffle drawings and prize claims feel fair and organized.
- See enough fundraising progress to make event decisions.
- Preserve a polished donor experience.

### Fears

- Having to leave hosting duties to fix a broken checkout state.
- Driving across a golf course to rescue a volunteer.
- Guests losing confidence in a digital raffle.
- Prize drawings appearing unfair, delayed, or disorganized.
- Operational details distracting from donor relationships.

### Jobs To Be Done

- Confirm that event setup is ready.
- Monitor sales and order status during the event.
- Help volunteers recover from common problems.
- Manage entries, drawings, winners, and prize claim status.
- Resolve event-level questions without platform-level access.

### UX Implications

- Event-level dashboards should separate "needs attention" from configuration.
- Drawing and winner flows should have strong confirmation and audit signals.
- Event leads need a controlled ability to inspect event orders, but not global
  system configuration.
- Recovery states should be visible enough to prevent support escalation.

## Config Admin

### Context

Config admins are trusted, technical board members. They prepare the software for
an event, connect Stripe-linked configuration, manage users and PINs, and adjust
products or subscription prices. This role exists because a small nonprofit team
needs capable operators who are not necessarily application developers.

### Motivations

- Reduce live-event bugs and support calls.
- Make the system ready before volunteers arrive.
- Keep payment and product setup consistent.
- Create users and assign the right event-day roles.

### Fears

- A missing product, bad price, or reader issue surfacing after guests arrive.
- Overpowering casual volunteers with admin access because there is no narrower
  role.
- Breaking live event data while making a small configuration change.

### Jobs To Be Done

- Create and edit events.
- Configure POS products.
- Configure RocStar prices.
- Assign Stripe Terminal readers.
- Create users and assign roles.
- View broad order and reporting context for setup and support.

### UX Implications

- Configuration should be grouped away from event execution tasks.
- Role assignment should be explicit and explain what each role allows.
- Admin screens should make destructive or high-risk actions visually distinct.

## Platform Admin

### Context

Platform admins are the break-glass operators for live incidents and the people
who need developer/testing workflows. This persona exists to support the app
itself, not normal event operation.

### Motivations

- Diagnose and recover from unusual states.
- Test permission boundaries by impersonating roles.
- Keep the live event running when normal controls are insufficient.

### Fears

- Being unable to recover from a production incident.
- Accidentally exposing platform-level controls to a normal event operator.
- Losing the ability to validate behavior across roles.

### Jobs To Be Done

- Use all application surfaces.
- Recover from data or payment workflow incidents.
- Impersonate lower-privilege roles in development and support contexts.
- Access break-glass controls that should never be part of ordinary event work.

### UX Implications

- Platform-only controls should be isolated from normal event navigation.
- Impersonation must be obvious when active.
- Break-glass actions should be auditable and hard to invoke casually.

## Board Reporter

### Context

Board reporters are non-technical board leaders who need fundraising health and
supporter visibility. James is the current archetype. He wants to know how the
organization is doing without asking for raw CSVs over email or navigating
developer-oriented screens.

### Motivations

- Understand fundraising health.
- See MRR and RocStar supporter context.
- Compare cash, card, and online sales.
- Contact supporters appropriately.
- Keep PII secure while still usable by trusted board leadership.

### Fears

- The tool being too hard to use.
- Sensitive supporter data being passed around casually.
- Not having current numbers for board or donor conversations.
- Conflating event sales, recurring support, and manual cash activity.

### Jobs To Be Done

- View fundraising totals and trends.
- Inspect payment-method splits.
- View RocStar supporter and subscription context.
- See contact information when there is a real board need.

### UX Implications

- Reporting should be plain-language and scan-friendly.
- Contact information should be permissioned separately from aggregate totals.
- Export workflows, if added, should be designed around privacy and intent.

## Buyer / Donor / RocStar

### Context

Buyers include event guests, raffle buyers, donors, and recurring supporters.
RocStar is a recurring supporter state within this broader persona, not an
internal staff role. Phil Farley is the current archetype: an older donor who may
be on vacation in Florida, interested in golf and classic cars, happy to support
the mission, and uninterested in fussing with apps or credentials.

Terminal RocStar signup exists for people like Phil: someone is ready to give,
and the experience needs to let a volunteer help them subscribe without turning
the interaction into a technical support session.

### Motivations

- Support the charity.
- Participate in a raffle or event activity.
- Subscribe as a RocStar without creating an account.
- Finish quickly and return to the event.

### Fears

- Too many steps.
- Unclear recurring billing.
- Being asked to remember credentials.
- Losing trust because payment or raffle status feels ambiguous.

### Jobs To Be Done

- Buy entries or products at an event.
- Provide minimal contact details.
- Sign up for recurring support.
- Receive enough confirmation to trust the transaction.

### UX Implications

- Public checkout and assisted checkout should be low-friction.
- Recurring billing copy must be explicit.
- Buyer-facing flows should not expose internal role concepts.
- Buyer and RocStar are not assignable RBAC roles in the first implementation.

## Current UX Observations

These are starting points from the current app shape and initial browser review.
They should be revisited as each role becomes enforceable.

- The unauthenticated home exposes links into admin-like routes that then require
  sign-in or admin access. Future RBAC should drive visible navigation, not only
  controller redirects.
- POS currently has several payment-state edge cases that matter most to
  cashiers: subscription products disable cash, card depends on reader state, and
  the enabled/disabled state of sale completion needs to be obvious.
- User management exposes PINs and a single `admin` Boolean. The RBAC scaffold
  keeps that flag for compatibility but should replace it.
- Orders label the seller as "Agent." That may be accurate internally but is not
  friendly language for volunteers or event leads.
- RocStar checkout is intentionally simple, but recurring billing clarity should
  be reviewed through the Buyer persona.

## Decision Rules

When making future feature decisions:

- Start with the persona's event context, not the database table.
- Prefer narrower roles over expanding admin access.
- Separate setup/configuration from live event execution.
- Treat reporting and PII as separate capabilities.
- Keep Buyer/RocStar flows outside internal RBAC unless the person is also an
  internal operator.
- Design for interruption, noise, and low training during live events.
