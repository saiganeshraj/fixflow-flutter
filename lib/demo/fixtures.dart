import '../features/bookings/models.dart';
import '../core/clock.dart';

/// Fictional demo data for FixFlow.
/// All data is relative to [now] so it never becomes stale.
class DemoFixtures {
  static const String customerAId = 'customer-priya';
  static const String customerBId = 'customer-ravi';
  static const String technicianRajId = 'tech-raj';
  static const String technicianMeeraId = 'tech-meera';
  static const String technicianSamirId = 'tech-samir';

  // ─── Personas ───────────────────────────────────────────────────────────────

  static List<DemoPersona> get personas => [
    const DemoPersona(
      id: customerAId,
      name: 'Priya Sharma',
      isTechnician: false,
    ),
    const DemoPersona(
      id: technicianRajId,
      name: 'Raj Kumar (Technician)',
      isTechnician: true,
      technicianId: technicianRajId,
    ),
    const DemoPersona(
      id: technicianSamirId,
      name: 'Samir Singh (Technician)',
      isTechnician: true,
      technicianId: technicianSamirId,
    ),
    const DemoPersona(
      id: technicianMeeraId,
      name: 'Meera Patel (Technician)',
      isTechnician: true,
      technicianId: technicianMeeraId,
    ),
  ];

  // ─── Categories ─────────────────────────────────────────────────────────────

  static const List<ServiceCategory> categories = [
    ServiceCategory(id: 'cat-plumbing', name: 'Plumbing', iconName: 'plumbing'),
    ServiceCategory(
      id: 'cat-electrical',
      name: 'Electrical',
      iconName: 'electrical_services',
    ),
    ServiceCategory(
      id: 'cat-cleaning',
      name: 'Cleaning',
      iconName: 'cleaning_services',
    ),
  ];

  // ─── Services ───────────────────────────────────────────────────────────────

  static const List<Service> services = [
    Service(
      id: 'svc-pipe-repair',
      categoryId: 'cat-plumbing',
      title: 'Pipe Leak Repair',
      description:
          'Fix leaking pipes under sinks, behind walls, or at joints. '
          'Our certified plumber diagnoses the leak, replaces faulty sections, '
          'and tests water pressure to ensure a lasting seal.',
      inclusions: [
        'Leak diagnosis',
        'Replacement of up to 1 m of pipe',
        'Joint sealing and pressure test',
        'Cleanup of work area',
      ],
      pricePaise: 149900, // ₹1,499
      durationMinutes: 60,
    ),
    Service(
      id: 'svc-drain-unclog',
      categoryId: 'cat-plumbing',
      title: 'Drain Unclogging',
      description:
          'Clear blocked kitchen, bathroom, or floor drains using professional '
          'tools. We remove build-up without damaging your pipes and leave drains '
          'flowing freely.',
      inclusions: [
        'Manual and mechanical drain clearing',
        'Up to 2 drain points',
        'Drain health check',
        'Post-service flush test',
      ],
      pricePaise: 99900, // ₹999
      durationMinutes: 60,
    ),
    Service(
      id: 'svc-fan-install',
      categoryId: 'cat-electrical',
      title: 'Ceiling Fan Installation',
      description:
          'Professional installation of a new or replacement ceiling fan. '
          'Includes wiring, mounting, and a safety test. Bring your own fan or '
          'ask us about our supply options.',
      inclusions: [
        'Mounting bracket installation',
        'Electrical wiring connection',
        'Fan balancing',
        'Safety test and cleanup',
      ],
      pricePaise: 79900, // ₹799
      durationMinutes: 60,
    ),
    Service(
      id: 'svc-switchboard',
      categoryId: 'cat-electrical',
      title: 'Switchboard Repair',
      description:
          'Diagnose and repair faulty switches, sockets, MCBs, and distribution '
          'boards. Qualified electricians only — your safety is our priority.',
      inclusions: [
        'Electrical fault diagnosis',
        'Switch or socket replacement (up to 3 units)',
        'Wiring inspection',
        'Earth continuity check',
      ],
      pricePaise: 129900, // ₹1,299
      durationMinutes: 60,
    ),
    Service(
      id: 'svc-deep-clean',
      categoryId: 'cat-cleaning',
      title: 'Deep Home Cleaning',
      description:
          'Full-home deep clean covering kitchen, bathrooms, bedrooms, and '
          'living areas. We bring eco-friendly products and professional equipment '
          'for a thorough result.',
      inclusions: [
        'Kitchen degreasing and appliance wipe-down',
        'Bathroom scrubbing and descaling',
        'Floor mopping and vacuuming',
        'Dustbin sanitisation',
      ],
      pricePaise: 199900, // ₹1,999
      durationMinutes: 60,
    ),
    Service(
      id: 'svc-sofa-clean',
      categoryId: 'cat-cleaning',
      title: 'Sofa & Upholstery Cleaning',
      description:
          'Steam-clean sofas, chairs, and fabric upholstery to remove stains, '
          'odours, and allergens. Safe for all standard fabric types; specialist '
          'materials flagged before treatment.',
      inclusions: [
        'Pre-treatment stain inspection',
        'Steam extraction cleaning (up to 3-seater)',
        'Deodorising spray',
        'Drying time guidance',
      ],
      pricePaise: 159900, // ₹1,599
      durationMinutes: 60,
    ),
  ];

  // ─── Technicians ────────────────────────────────────────────────────────────

  static const List<Technician> technicians = [
    Technician(
      id: technicianRajId,
      name: 'Raj Kumar',
      avatarInitials: 'RK',
      serviceIds: ['svc-pipe-repair', 'svc-drain-unclog'],
    ),
    Technician(
      id: technicianMeeraId,
      name: 'Meera Patel',
      avatarInitials: 'MP',
      serviceIds: ['svc-fan-install', 'svc-switchboard'],
    ),
    Technician(
      id: technicianSamirId,
      name: 'Samir Singh',
      avatarInitials: 'SS',
      serviceIds: ['svc-deep-clean', 'svc-sofa-clean'],
    ),
  ];

  /// Seed bookings relative to [now].
  /// Returns bookings that make sense at the demo's current moment.
  static List<Booking> seedBookings(DateTime now) {
    // A completed booking from yesterday for the review demo.
    final today = toServiceTimezone(now);
    final yesterdaySlotUtc = fromServiceTimezone(
      DateTime.utc(today.year, today.month, today.day - 1, 10),
    );

    // An upcoming booking: tomorrow at 10:00 IST
    final tomorrowSlotStart = fromServiceTimezone(
      DateTime.utc(today.year, today.month, today.day + 1, 10),
    );
    final tomorrowSlotEnd = tomorrowSlotStart.add(const Duration(hours: 1));

    final completedSlotStart = yesterdaySlotUtc;
    final completedSlotEnd = completedSlotStart.add(const Duration(hours: 1));

    return [
      // Completed booking (plumbing) — ready to review
      Booking(
        id: 'booking-demo-1',
        customerId: customerAId,
        technicianId: technicianRajId,
        serviceId: 'svc-pipe-repair',
        slotStartUtc: completedSlotStart,
        slotEndUtc: completedSlotEnd,
        addressLine1: '24, MG Road',
        addressLine2: 'Apt 3B',
        city: 'Bengaluru',
        pincode: '560001',
        notes: 'Kitchen sink leaking under the cabinet.',
        pricePaise: 149900,
        status: BookingStatus.completed,
        idempotencyKey: 'idem-demo-1',
        createdAt: completedSlotStart.subtract(const Duration(days: 2)),
        events: [
          BookingEvent(
            id: 'evt-demo-1-1',
            bookingId: 'booking-demo-1',
            newStatus: BookingStatus.requested,
            actorId: customerAId,
            occurredAt: completedSlotStart.subtract(const Duration(days: 2)),
          ),
          BookingEvent(
            id: 'evt-demo-1-2',
            bookingId: 'booking-demo-1',
            previousStatus: BookingStatus.requested,
            newStatus: BookingStatus.accepted,
            actorId: technicianRajId,
            occurredAt: completedSlotStart.subtract(const Duration(days: 1)),
          ),
          BookingEvent(
            id: 'evt-demo-1-3',
            bookingId: 'booking-demo-1',
            previousStatus: BookingStatus.accepted,
            newStatus: BookingStatus.enRoute,
            actorId: technicianRajId,
            occurredAt: completedSlotStart.subtract(
              const Duration(minutes: 30),
            ),
          ),
          BookingEvent(
            id: 'evt-demo-1-4',
            bookingId: 'booking-demo-1',
            previousStatus: BookingStatus.enRoute,
            newStatus: BookingStatus.inProgress,
            actorId: technicianRajId,
            occurredAt: completedSlotStart,
          ),
          BookingEvent(
            id: 'evt-demo-1-5',
            bookingId: 'booking-demo-1',
            previousStatus: BookingStatus.inProgress,
            newStatus: BookingStatus.completed,
            actorId: technicianRajId,
            occurredAt: completedSlotStart.add(const Duration(minutes: 55)),
          ),
        ],
        review: Review(
          id: 'review-demo-1',
          bookingId: 'booking-demo-1',
          customerId: customerAId,
          rating: 5,
          comment: 'Raj was professional and fixed the leak quickly. Highly recommended!',
          createdAt: completedSlotEnd.add(const Duration(minutes: 10)),
        ),
      ),

      // Upcoming accepted booking (electrical)
      Booking(
        id: 'booking-demo-2',
        customerId: customerAId,
        technicianId: technicianMeeraId,
        serviceId: 'svc-fan-install',
        slotStartUtc: tomorrowSlotStart,
        slotEndUtc: tomorrowSlotEnd,
        addressLine1: '24, MG Road',
        addressLine2: 'Apt 3B',
        city: 'Bengaluru',
        pincode: '560001',
        notes: 'Master bedroom fan. New fan already purchased.',
        pricePaise: 79900,
        status: BookingStatus.accepted,
        idempotencyKey: 'idem-demo-2',
        createdAt: now.subtract(const Duration(hours: 3)),
        events: [
          BookingEvent(
            id: 'evt-demo-2-1',
            bookingId: 'booking-demo-2',
            newStatus: BookingStatus.requested,
            actorId: customerAId,
            occurredAt: now.subtract(const Duration(hours: 3)),
          ),
          BookingEvent(
            id: 'evt-demo-2-2',
            bookingId: 'booking-demo-2',
            previousStatus: BookingStatus.requested,
            newStatus: BookingStatus.accepted,
            actorId: technicianMeeraId,
            occurredAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    ];
  }
}
