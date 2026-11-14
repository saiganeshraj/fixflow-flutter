# FixFlow product specification

Source: the user-supplied FixFlow Flutter playbook, 12 November 2026. The Antigravity report is a handoff claim; repository inspection and executed checks determine completion.

## Purpose and boundaries

A personal Flutter portfolio app where a fictional customer schedules fixed-price plumbing, electrical or cleaning work, a technician advances the job, and the customer reviews completion. Web and Android are the targets. Material 3, Riverpod, go_router and repository contracts are used. Payments, OTP, maps, chat, notifications, refunds, admin portals and marketplace operations are excluded.

Demo is the default. It requires no registration, credentials or backend. One browser profile/device owns a local fictional workspace; switching personas simulates participants in that workspace, not authentication. Refresh retains JSON data. Reset removes exactly the demo booking, schema and persona keys. Separate browser profiles do not share the workspace. Tabs in the same profile share storage; simultaneous independent tabs are not a transactional database.

Live mode is an explicit build choice. It uses Supabase email/password sessions, trusted profiles, RLS and RPC transactions. Public registration creates customers only; technicians require administrative provisioning. Demo storage and live sessions have separate providers and keys. No demo persona switch or reset is available in live mode. Missing live configuration produces a setup state and never prevents a demo build from starting.

## Screens

| Route | Purpose |
| --- | --- |
| `/` | Welcome, Try the Demo, walkthrough, fictional-data notice |
| `/catalog` | Personal booking overview, combined search/category filters and price sorting; six services |
| `/service/:serviceId` | Description, inclusions, fixed price, booking CTA |
| `/book/:serviceId` | Date, future available slot, address, notes and total |
| `/booking-confirmed/:bookingId` | Confirmation and links to details/bookings |
| `/my-bookings` | Upcoming and historical work |
| `/booking/:bookingId` | Appointment, assigned technician, timeline, cancellation and review |
| `/technician` | Assigned pending, active and completed/cancelled work |
| `/about` | Project explanation and stack |

Live authentication is a gate around all routes. Unknown routes and IDs show recoverable states. Mobile uses bottom navigation; wide viewports use a navigation rail. Layout targets: 360, 768 and 1440 logical pixels. Visible controls use Flutter widgets, focus and text semantics, with icon + text status chips.

The 14 November design refresh uses a full desktop sidebar at 1100px and above,
a compact rail from 720px, and bottom navigation below that. Welcome/catalog and
service details share local vector illustrations and a forest/ivory/lime theme.
Catalog controls share immutable Riverpod state and derive their results from
cached catalog data. The booking overview derives from the scoped booking stream.

## Business rules

* Three categories, six fictional services, three eligible technicians. Prices are integer paise, displayed as INR; booking price is a trusted snapshot.
* Appointments last 60 minutes. Slots start at 09:00 through 16:00, finishing by 17:00 Asia/Kolkata, for today and the following six service dates. Past/current instants are excluded. UTC is persisted. Demo uses an injected clock; live availability and booking validation use server time.
* Assign the first eligible free technician deterministically. Different services must respect the same technician's reservation. Completed appointments retain their reservation; cancellation releases it.
* Trim required address/city fields. Address line 1: 5–200 characters; address line 2: up to 200; city: 1–80; pincode: six digits with a nonzero first digit; optional notes: up to 500.
* Booking creation is idempotent per customer and request key. A retry returns the original booking, including if its input changes. Concurrent local writes are serialized. Live writes use transaction locks plus unique database constraints.

| State | Action | Actor | Result |
| --- | --- | --- | --- |
| requested | accept | assigned technician | accepted |
| requested or accepted | cancel | owning customer | cancelled |
| accepted | mark en route | assigned technician | en_route |
| en_route | start | assigned technician | in_progress |
| in_progress | complete | assigned technician | completed |
| completed | review once | owning customer | completed |

No skipping or reversing stages. Completed/cancelled work is terminal. Repeating the current technician action or cancellation is safe and creates no extra event. Events record previous/new states, actor and UTC time. Reviews do not add a status event; rating is integer 1–5, optional comment up to 500 characters. Provider rating aggregation is excluded.

## Acceptance and evidence

The acceptance journey is catalog → book → assigned technician accepts and completes all stages → customer reviews. Refresh restores the booking. Double submit, slot conflicts, illegal actors/transitions, invalid fields and failed saves are covered by meaningful tests. Corrupt storage offers explicit reset recovery.

Live acceptance additionally requires two customer sessions and two technician sessions against an actual development database: scoped reads/writes, no role/price tampering, race-safe assignment, scoped retries and one-time reviews. HTTP fakes cannot prove database authorization.

Portfolio delivery requires an inspected public HTTPS URL, a published repository with passing CI, an Android build actually exercised on a device/emulator, screenshots and a recorded backup walkthrough. Build success alone does not satisfy device or publication acceptance. See PROGRESS.md for evidence and open items.
