# FixFlow design refresh — 14 November 2026

## Direction

A calm, illustrated home-care product: forest green, warm ivory, pale lime,
terracotta details, strong type hierarchy and generous space. Original vector
room artwork is drawn in Flutter, so the demo adds no image-hosting dependency.
There are no invented customer ratings, testimonials, availability promises,
payment actions or notification controls.

## Delivered

* A responsive welcome page with a clear primary action, illustrated room,
  three-step explanation and visible fictional-demo disclosure.
* A service workspace with a personal greeting, next-booking overview, coherent
  search/category/sort controls, and illustrated cards with fixed prices.
* A desktop sidebar, compact tablet rail and existing mobile bottom navigation.
  Demo persona switching remains available on every layout.
* Matching service-detail illustrations, a desktop booking summary, and shared
  theme changes for the remaining booking and technician screens.
* Unified Riverpod catalog state, cached derived filtering/sorting, and a booking
  overview derived from the customer-scoped stream. See STATE_MANAGEMENT.md.

## Verification

The 51-test Flutter suite passes, including the customer/technician/review journey,
provider composition/error/stream tests, and route layouts at 360, 768 and 1440
logical pixels. Welcome, catalog and scrolled service-card captures are saved in
`docs/screenshots` and were visually reviewed. Build and browser-startup results
are recorded in PROGRESS.md after the release rebuild.

## Next priorities

1. Validate the real backend and separate customer/technician sessions.
2. Complete stable Android and manual keyboard/text-scale acceptance.
3. Publish the owner-selected repository and hosted demo, then record the journey.

These acceptance tasks remain separate from a visual refresh. The local preview
still uses release mode to avoid the unresolved Chrome debug handshake.
