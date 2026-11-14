# Explain FixFlow in your own words

This is a personal portfolio project continued from an AI-assisted Antigravity scaffold. Describe the behavior you have inspected and can explain; do not present unexecuted live security checks as evidence.

| Topic | Concrete code example | Tradeoff or alternative |
| --- | --- | --- |
| Repository contracts | `AppRepository` in `lib/features/catalog/repository.dart` groups catalog, customer and technician contracts. `DemoRepository` and `LiveRepository` implement them. | The aggregate contract keeps this small app simple; a larger app could inject narrower interfaces separately. |
| Riverpod | `servicesProvider`, `availableSlotsProvider`, `customerBookingsProvider` expose async state; screens render data/loading/error. `repositoryProvider` chooses the adapter. | A revision signal refreshes details and availability after mutations. Dedicated controllers could further reduce mutation orchestration in widgets. |
| Navigation | `router.dart` defines welcome/catalog/booking routes, a responsive shell and unknown-route handling. | Path parameters are strings, not generated typed routes. Web retains hash routing for static hosting. |
| Demo persistence | `LocalStorage` validates a schema and JSON shape. `_mutate` serializes local writes and rolls back memory on failed persistence. | Preferences suit small fictional data, not secrets, SQL experience or cross-tab transactions. SQLite would suit larger mobile datasets. |
| UTC and service time | `generateSlots` constructs civil dates with UTC constructors, then subtracts the fixed India offset. UI formats explicit IST. | Asia/Kolkata has a fixed current offset. Multi-zone/DST scheduling would need a timezone database. Live SQL uses the named zone and server clock. |
| Money | `Service.pricePaise` and booking snapshots are integers; `formatPaise` displays rupees without floating-point arithmetic. | Tax, payment settlement and dynamic prices are excluded. |
| Idempotency | Demo `_mutate` protects concurrent requests and customer/key lookup returns the original. SQL uses a scoped advisory lock and unique customer/key constraint. | Keys intentionally return the original even if retry fields differ. Persistent request fingerprints could instead reject changed payloads. |
| Reservations | Demo checks all services assigned to a technician. SQL locks candidates in order and enforces a partial unique slot index. | Hourly fixed durations make equality enough; arbitrary duration work needs interval exclusion constraints. Database concurrency still requires real multi-session verification. |
| Authorization | SQL grants reads plus explicit RPC execution, with participant RLS. Functions derive Auth identity and catalog price. | HTTP-fake adapter tests cannot prove RLS. Run pgTAP and independent authenticated sessions before making security claims. |
| State machine | Repository methods and `transition_booking` enforce each expected stage and assignment. Events append only for real transitions. | Duplicate action retry is safe at the target state; old actions retried after later stages are rejected. |
| Isolation and sessions | Demo personas share one local sandbox. Live mode resolves a trusted profile and has no persona switch; repositories rebuild when the profile changes. | Different tabs in one browser share local storage. Live updates are mutation/revisit/manual refresh, not realtime subscriptions. |
| Tests | `recovery_and_races_test.dart` tests competing writes and storage failure rollback. `demo_journey_test.dart` exercises form input and all roles. | Widget tests are not proof of browser or Android device behavior. CI and real devices are separately recorded in TESTING.md. |

## Trace one booking

1. The booking screen reads service and available slots through providers, validates trimmed fields, and keeps one request key for retries.
2. Confirm disables duplicate submission and calls the selected repository with a `BookingRequest`.
3. Demo checks availability and rules, snapshots price, appends a requested event, persists and notifies. Live calls `create_booking`; the server derives actor, technician and price inside its transaction.
4. Confirmation loads the resulting ID. Technician actions update status through the same repository boundary.
5. Customer detail refreshes, shows the timeline, and allows one review only after completion.

Practice explaining: Why does disabling a button not prevent database races? What if saving fails after memory changes? Why can't a customer choose a technician role at signup? How would you add varying appointment durations? What does a passing fake HTTP test fail to prove? How would the timezone code behave on a device in London? What is the difference between compiling an APK and testing an Android app?

## First five files to read

1. `lib/features/bookings/models.dart` — the data and status vocabulary.
2. `lib/features/catalog/repository.dart` — what the UI can ask the data layer to do.
3. `lib/demo/demo_repository.dart` — local business rules and durable mutations.
4. `lib/app/providers.dart` — dependency selection, state and refresh.
5. `lib/features/bookings/screens/booking_form_screen.dart` — inputs through submission and navigation.

Then compare `live_repository.dart` with `supabase/migrations/202611120001_fixflow.sql`.
