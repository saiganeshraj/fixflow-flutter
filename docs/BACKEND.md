# Supabase development setup

For local Windows commands, use `tools/flutter.cmd` / `tools/dart.cmd`, or open `tools/dev-shell.cmd` first; keep tools, caches and temporary files on D: per WORKSPACE.md.

The backend is opt-in. Use a disposable development project; no existing production database has been modified. The migration, adapters and tests are implemented, but database execution and multi-account integration must be verified before describing live mode as secure or complete.

## Local database

Install the official Supabase CLI and Docker Desktop, then from the repository:

```powershell
supabase init
supabase start
supabase db reset
supabase test db
```

`supabase init` creates the environment-specific config. Migrations are in `supabase/migrations`, catalog data in `supabase/seed.sql`, and pgTAP authorization tests in `supabase/tests`. Use a separate development database if local containers are unavailable. Do not run `db reset` against a valued database. The Flutter live configuration currently requires HTTPS; use a development hosted project for the app session checks, or explicitly adapt configuration for a trusted local HTTP endpoint during development.

For a hosted development project, apply the SQL migration using Supabase's migration workflow, then seed the catalog. Run SQL tests in a disposable test database. The migration is a first migration, not an idempotent SQL script to paste repeatedly.

## Accounts and trusted technicians

Enable email/password authentication and configure email confirmation. The app tells new users to check their email. Configure your development URL in Auth Site URL and allow redirects to the exact origin you deploy; email verification can return to the origin, then the user signs in with their password. OAuth and password reset are outside this version.

Register two customer test accounts and two or three technician test accounts using controlled email addresses. Verify their emails. Every signup is a customer regardless of metadata. In the development project's SQL editor, use actual Auth user UUIDs to provision technicians:

```sql
begin;
update public.profiles set role = 'technician', display_name = 'Raj Kumar'
where id = 'REPLACE_WITH_TECHNICIAN_AUTH_UUID';
insert into public.technician_services(technician_id, service_id) values
('REPLACE_WITH_TECHNICIAN_AUTH_UUID', 'svc-pipe-repair'),
('REPLACE_WITH_TECHNICIAN_AUTH_UUID', 'svc-drain-unclog');
commit;
```

Repeat for an electrical technician (`svc-fan-install`, `svc-switchboard`) and cleaner (`svc-deep-clean`, `svc-sofa-clean`). This trusted setup is never exposed in the public client. Without eligibility mappings, availability correctly remains empty.

Copy `config/live.example.json` to ignored `config/live.json`; supply the project URL and **publishable** key only:

```powershell
flutter run -d chrome --dart-define-from-file=config/live.json
flutter build web --release --dart-define-from-file=config/live.json
```

Build configuration is visible in shipped clients. It does not hide secrets. Never use a service-role key, secret key or database password in app config. The default build does not initialize Supabase or restore live sessions.

## Database design and authorization

The partial unique index `technician_slot_reservation` enforces `(technician_id, slot_start_utc)` uniqueness for every non-cancelled booking. Because only hourly 60-minute appointments can be created, this also prevents overlap. Customer/key advisory locks serialize retries. Technician row locks in deterministic UUID order serialize assignment across services, while the unique index remains a final race guard. Cancellation changes the indexed status in the same transaction as its event.

Authenticated clients receive SELECT grants and scoped RLS, with no direct booking/profile/event/review mutation grants. Four explicit RPCs expose availability, booking creation, transitions and reviews. SECURITY DEFINER functions have empty search paths, qualified tables, explicit Auth checks where mutation occurs, and restricted execution grants. Public catalog reads contain fictional service data only. Profile visibility is self plus the technician assigned to the customer's bookings.

`create_booking` accepts no price, customer or technician ID. `transition_booking` checks ownership/assignment under a booking row lock. `submit_review` locks that row and enforces a unique review. The signup trigger always chooses `customer`.

## Required live verification

Run the SQL tests, then test with isolated browser profiles/accounts:

1. Customer A books; customer B sees no A booking, events or review, including direct API queries by A's ID.
2. Assigned technician advances the job; another technician receives authorization errors for every mutation.
3. Attempt direct profile role updates, price/owner/status changes and forged event/review inserts. All must fail.
4. Replay one creation request ten times concurrently with one customer/key: one booking, same returned ID.
5. Submit two different keys concurrently for one technician/slot, including different eligible services: one reservation succeeds, the other fails without partial events.
6. Test legal cancellation and reuse of the freed slot; terminal-state restrictions; duplicate review and invalid ratings/comments.
7. Sign out/in and switch accounts; confirm no private previous-user data remains. Simulate network failure and verify errors, retry and explicit refresh.
8. Verify session restoration and the email-confirmation flow on the actual deployed origin.

Single-session pgTAP tests do not prove simultaneous database race behavior. Steps 4–5 require independent authenticated requests and inspection of resulting rows. These checks remain pending until real development access is available.

The unique `reviews.booking_id` relationship embeds as an object or null in booking responses. The adapter and HTTP fixtures use that shape, with a regression for a completed booking's review. See [PostgREST's one-to-one embedding rules](https://docs.postgrest.org/en/stable/references/api/resource_embedding.html).

Implementation references: [Supabase Flutter setup](https://supabase.com/docs/guides/getting-started/quickstarts/flutter), [database functions and grants](https://supabase.com/docs/guides/database/functions), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Auth state changes](https://supabase.com/docs/reference/dart/auth-onauthstatechange).
