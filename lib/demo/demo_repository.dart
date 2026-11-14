import 'dart:async';

import 'package:uuid/uuid.dart';

import '../core/errors/app_error.dart';
import '../core/clock.dart';
import '../core/storage.dart';
import '../demo/fixtures.dart';
import '../features/bookings/models.dart';
import '../features/catalog/repository.dart';

const _uuid = Uuid();

/// In-memory + locally-persisted implementation of all repositories for demo mode.
/// All data is visitor-local and isolated. Shared singleton per app session.
class DemoRepository implements AppRepository {
  final Clock _clock;
  final LocalStorage _storage;

  /// In-memory bookings (source of truth for this session).
  List<Booking> _bookings = [];
  bool _initialized = false;
  Future<void>? _initialization;
  Future<void> _pending = Future.value();
  final _changes = StreamController<void>.broadcast(sync: true);

  void dispose() => _changes.close();

  /// Serialize mutations, persist before notifying, and roll back failed saves.
  Future<T> _mutate<T>(Future<T> Function() action) {
    final result = _pending.then((_) async {
      await initialize();
      final before = List<Booking>.of(_bookings);
      try {
        final value = await action();
        await _persist();
        _notifyListeners();
        return value;
      } catch (_) {
        _bookings = before;
        rethrow;
      }
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  DemoRepository({required this._clock, required this._storage});

  // ─── Initialization ───────────────────────────────────────────────────────

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_initialized) return;
    final raw = _storage.loadBookingsRaw();
    if (raw == null) {
      // First visit — seed with demo data.
      _bookings = DemoFixtures.seedBookings(_clock.now);
    } else {
      // Restore from storage.
      try {
        _bookings = raw.map(Booking.fromJson).toList();
      } catch (_) {
        throw const PersistenceError(
          'Saved bookings are invalid. Reset demo to recover.',
        );
      }
    }
    await _persist();
    _initialized = true;
  }

  Future<void> reset() async {
    await _pending;
    await _storage.resetDemoData();
    _bookings = DemoFixtures.seedBookings(_clock.now);
    _initialized = true;
    await _persist();
    _initialization = Future.value();
    _notifyListeners();
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _persist() async {
    await _storage.saveBookingsRaw(_bookings.map((b) => b.toJson()).toList());
  }

  // ─── Listeners (simple reactive layer) ───────────────────────────────────

  final List<void Function()> _listeners = [];

  @override
  void addListener(void Function() listener) => _listeners.add(listener);
  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notifyListeners() {
    _changes.add(null);
    for (final l in _listeners) {
      l();
    }
  }

  // ─── CatalogRepository ────────────────────────────────────────────────────

  @override
  Future<List<ServiceCategory>> fetchCategories() async =>
      List.unmodifiable(DemoFixtures.categories);

  @override
  Future<List<Service>> fetchServices() async =>
      List.unmodifiable(DemoFixtures.services.where((s) => s.active).toList());

  @override
  Future<Service?> fetchService(String serviceId) async =>
      DemoFixtures.services.where((s) => s.id == serviceId).firstOrNull;

  @override
  Future<List<Service>> fetchServicesByCategory(String categoryId) async =>
      DemoFixtures.services
          .where((s) => s.categoryId == categoryId && s.active)
          .toList();

  @override
  Future<List<Service>> searchServices(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return fetchServices();
    return DemoFixtures.services
        .where(
          (s) =>
              s.active &&
              (s.title.toLowerCase().contains(q) ||
                  s.description.toLowerCase().contains(q) ||
                  s.inclusions.any((i) => i.toLowerCase().contains(q))),
        )
        .toList();
  }

  @override
  Future<List<Technician>> fetchTechnicians() async =>
      List.unmodifiable(DemoFixtures.technicians);

  // ─── Slot generation and availability ────────────────────────────────────

  List<DateTime> availableSlotsForService(
    String serviceId,
    String? excludeBookingId,
  ) {
    final allSlots = generateSlots(_clock.now);
    // Find technicians eligible for this service.
    final eligible = DemoFixtures.technicians
        .where((t) => t.serviceIds.contains(serviceId))
        .toList();

    return allSlots.where((slot) {
      final slotEnd = slot.add(const Duration(hours: 1));
      final slotRange = TimeSlot(startUtc: slot, endUtc: slotEnd);
      // A slot is available if at least one eligible technician is free.
      return eligible.any((tech) {
        final conflicts = _bookings.where(
          (b) =>
              b.technicianId == tech.id &&
              b.id != excludeBookingId &&
              b.status != BookingStatus.cancelled &&
              TimeSlot(
                startUtc: b.slotStartUtc,
                endUtc: b.slotEndUtc,
              ).overlaps(slotRange),
        );
        return conflicts.isEmpty;
      });
    }).toList();
  }

  @override
  Future<List<DateTime>> fetchAvailableSlots(String serviceId) async {
    await initialize();
    return availableSlotsForService(serviceId, null);
  }

  /// Deterministically assign an eligible, available technician for a service + slot.
  Technician? _assignTechnician(
    String serviceId,
    DateTime slotStart, {
    String? excludeBookingId,
  }) {
    final slotEnd = slotStart.add(const Duration(hours: 1));
    final slotRange = TimeSlot(startUtc: slotStart, endUtc: slotEnd);

    final eligible = DemoFixtures.technicians
        .where((t) => t.serviceIds.contains(serviceId))
        .toList();

    for (final tech in eligible) {
      final conflicts = _bookings.where(
        (b) =>
            b.technicianId == tech.id &&
            b.id != excludeBookingId &&
            b.status != BookingStatus.cancelled &&
            TimeSlot(
              startUtc: b.slotStartUtc,
              endUtc: b.slotEndUtc,
            ).overlaps(slotRange),
      );
      if (conflicts.isEmpty) return tech;
    }
    return null;
  }

  // ─── BookingRepository ────────────────────────────────────────────────────

  @override
  Future<Booking> createBooking(BookingRequest request, String customerId) =>
      _mutate(() => _createBooking(request, customerId));

  Future<Booking> _createBooking(
    BookingRequest request,
    String customerId,
  ) async {
    // Idempotency check.
    final existing = _bookings
        .where(
          (b) =>
              b.customerId == customerId &&
              b.idempotencyKey == request.idempotencyKey,
        )
        .firstOrNull;
    if (existing != null) {
      if (existing.customerId != customerId) {
        throw const UnauthorisedError();
      }
      return existing;
    }

    // Validate fields.
    final addr = request.addressLine1.trim();
    final city = request.city.trim();
    final pin = request.pincode.trim();
    if (customerId.trim().isEmpty || request.idempotencyKey.trim().isEmpty) {
      throw const ValidationError('Customer and request key are required.');
    }
    if (addr.isEmpty) {
      throw const ValidationError('Address line 1 is required.');
    }
    if (city.isEmpty) throw const ValidationError('City is required.');
    if (addr.length < 5 ||
        addr.length > 200 ||
        request.addressLine2.trim().length > 200 ||
        city.length > 80) {
      throw const ValidationError(
        'Use an address of 5–200 characters and city up to 80 characters.',
      );
    }
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)) {
      throw const ValidationError('Enter a valid 6-digit pincode.');
    }

    // Notes max length.
    final notes = request.notes?.trim();
    if (notes != null && notes.length > 500) {
      throw const ValidationError('Notes must be 500 characters or fewer.');
    }

    // Slot must be in the future.
    if (!generateSlots(_clock.now).contains(request.slotStartUtc.toUtc())) {
      throw const ValidationError(
        'Choose a future hourly slot within the next seven service days, 09:00–17:00 IST.',
      );
    }

    // Fetch service (for price snapshot).
    final service = await fetchService(request.serviceId);
    if (service == null || !service.active) {
      throw const NotFoundError('Service not found.');
    }

    // Assign technician.
    final tech = _assignTechnician(request.serviceId, request.slotStartUtc);
    if (tech == null) throw const NoAvailabilityError();

    // Check slot is still available (race condition guard).
    final slotEnd = request.slotStartUtc.add(const Duration(hours: 1));
    final slotRange = TimeSlot(startUtc: request.slotStartUtc, endUtc: slotEnd);
    final conflict = _bookings.any(
      (b) =>
          b.technicianId == tech.id &&
          b.status != BookingStatus.cancelled &&
          TimeSlot(
            startUtc: b.slotStartUtc,
            endUtc: b.slotEndUtc,
          ).overlaps(slotRange),
    );
    if (conflict) throw const SlotUnavailableError();

    final bookingId = _uuid.v4();
    final now = _clock.now;

    final booking = Booking(
      id: bookingId,
      customerId: customerId,
      technicianId: tech.id,
      serviceId: request.serviceId,
      slotStartUtc: request.slotStartUtc.toUtc(),
      slotEndUtc: slotEnd,
      addressLine1: addr,
      addressLine2: request.addressLine2.trim(),
      city: city,
      pincode: pin,
      notes: notes?.isEmpty == true ? null : notes,
      pricePaise: service.pricePaise, // snapshot from trusted source
      status: BookingStatus.requested,
      idempotencyKey: request.idempotencyKey,
      createdAt: now,
      events: [
        BookingEvent(
          id: _uuid.v4(),
          bookingId: bookingId,
          newStatus: BookingStatus.requested,
          actorId: customerId,
          occurredAt: now,
        ),
      ],
    );

    _bookings.add(booking);
    return booking;
  }

  @override
  Future<List<Booking>> fetchCustomerBookings(String customerId) async {
    return _bookings.where((b) => b.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Booking?> fetchBooking(String bookingId) async =>
      _bookings.where((b) => b.id == bookingId).firstOrNull;

  @override
  Future<Booking> cancelBooking(String bookingId, String customerId) =>
      _mutate(() => _cancelBooking(bookingId, customerId));

  Future<Booking> _cancelBooking(String bookingId, String customerId) async {
    final booking = await _fetchOrThrow(bookingId);

    if (booking.customerId != customerId) throw const UnauthorisedError();
    if (booking.status == BookingStatus.cancelled) return booking;
    if (booking.status == BookingStatus.completed) {
      throw InvalidTransitionError(booking.status.serialized, 'cancel');
    }
    if (booking.status == BookingStatus.enRoute ||
        booking.status == BookingStatus.inProgress) {
      throw InvalidTransitionError(
        booking.status.serialized,
        'cancel — cannot cancel after technician is en route',
      );
    }

    return _applyTransition(
      booking,
      BookingStatus.cancelled,
      customerId,
      note: 'Cancelled by customer',
    );
  }

  @override
  Future<Booking> submitReview({
    required String bookingId,
    required String customerId,
    required int rating,
    String? comment,
  }) => _mutate(
    () => _submitReview(
      bookingId: bookingId,
      customerId: customerId,
      rating: rating,
      comment: comment,
    ),
  );

  Future<Booking> _submitReview({
    required String bookingId,
    required String customerId,
    required int rating,
    String? comment,
  }) async {
    final booking = await _fetchOrThrow(bookingId);

    if (booking.customerId != customerId) throw const UnauthorisedError();
    if (booking.status != BookingStatus.completed) {
      throw const ValidationError(
        'Reviews can only be submitted for completed bookings.',
      );
    }
    if (booking.review != null) {
      throw const ValidationError(
        'A review has already been submitted for this booking.',
      );
    }
    if (rating < 1 || rating > 5) {
      throw const ValidationError('Rating must be between 1 and 5.');
    }
    final trimmedComment = comment?.trim();
    if (trimmedComment != null && trimmedComment.length > 500) {
      throw const ValidationError('Comment must be 500 characters or fewer.');
    }

    final review = Review(
      id: _uuid.v4(),
      bookingId: bookingId,
      customerId: customerId,
      rating: rating,
      comment: trimmedComment?.isEmpty == true ? null : trimmedComment,
      createdAt: _clock.now,
    );

    final updated = booking.copyWith(review: review);
    _replace(updated);
    return updated;
  }

  @override
  Stream<List<Booking>> watchCustomerBookings(String customerId) async* {
    await initialize();
    final subscription = StreamIterator(_changes.stream);
    try {
      yield await fetchCustomerBookings(customerId);
      while (await subscription.moveNext()) {
        yield await fetchCustomerBookings(customerId);
      }
    } finally {
      await subscription.cancel();
    }
  }

  // ─── TechnicianRepository ─────────────────────────────────────────────────

  @override
  Future<List<Booking>> fetchTechnicianBookings(String technicianId) async {
    return _bookings.where((b) => b.technicianId == technicianId).toList()
      ..sort((a, b) => a.slotStartUtc.compareTo(b.slotStartUtc));
  }

  @override
  Future<Booking> acceptBooking(String bookingId, String technicianId) =>
      _mutate(() => _acceptBooking(bookingId, technicianId));

  Future<Booking> _acceptBooking(String bookingId, String technicianId) async {
    final booking = await _fetchOrThrow(bookingId);
    _assertAssignedTechnician(booking, technicianId);
    if (booking.status == BookingStatus.accepted) return booking; // idempotent
    _assertTransition(booking, BookingStatus.requested, BookingStatus.accepted);
    return _applyTransition(booking, BookingStatus.accepted, technicianId);
  }

  @override
  Future<Booking> markEnRoute(String bookingId, String technicianId) =>
      _mutate(() => _markEnRoute(bookingId, technicianId));

  Future<Booking> _markEnRoute(String bookingId, String technicianId) async {
    final booking = await _fetchOrThrow(bookingId);
    _assertAssignedTechnician(booking, technicianId);
    if (booking.status == BookingStatus.enRoute) return booking;
    _assertTransition(booking, BookingStatus.accepted, BookingStatus.enRoute);
    return _applyTransition(booking, BookingStatus.enRoute, technicianId);
  }

  @override
  Future<Booking> startService(String bookingId, String technicianId) =>
      _mutate(() => _startService(bookingId, technicianId));

  Future<Booking> _startService(String bookingId, String technicianId) async {
    final booking = await _fetchOrThrow(bookingId);
    _assertAssignedTechnician(booking, technicianId);
    if (booking.status == BookingStatus.inProgress) return booking;
    _assertTransition(booking, BookingStatus.enRoute, BookingStatus.inProgress);
    return _applyTransition(booking, BookingStatus.inProgress, technicianId);
  }

  @override
  Future<Booking> completeService(String bookingId, String technicianId) =>
      _mutate(() => _completeService(bookingId, technicianId));

  Future<Booking> _completeService(
    String bookingId,
    String technicianId,
  ) async {
    final booking = await _fetchOrThrow(bookingId);
    _assertAssignedTechnician(booking, technicianId);
    if (booking.status == BookingStatus.completed) return booking;
    _assertTransition(
      booking,
      BookingStatus.inProgress,
      BookingStatus.completed,
    );
    return _applyTransition(booking, BookingStatus.completed, technicianId);
  }

  @override
  Stream<List<Booking>> watchTechnicianBookings(String technicianId) async* {
    await initialize();
    final subscription = StreamIterator(_changes.stream);
    try {
      yield await fetchTechnicianBookings(technicianId);
      while (await subscription.moveNext()) {
        yield await fetchTechnicianBookings(technicianId);
      }
    } finally {
      await subscription.cancel();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<Booking> _fetchOrThrow(String bookingId) async {
    final b = await fetchBooking(bookingId);
    if (b == null) throw const NotFoundError('Booking not found.');
    return b;
  }

  void _assertAssignedTechnician(Booking booking, String technicianId) {
    if (booking.technicianId != technicianId) {
      throw const UnauthorisedError('You are not assigned to this booking.');
    }
  }

  void _assertTransition(
    Booking booking,
    BookingStatus expected,
    BookingStatus next,
  ) {
    if (booking.status != expected) {
      throw InvalidTransitionError(booking.status.serialized, next.serialized);
    }
  }

  Booking _applyTransition(
    Booking booking,
    BookingStatus newStatus,
    String actorId, {
    String? note,
  }) {
    final event = BookingEvent(
      id: _uuid.v4(),
      bookingId: booking.id,
      previousStatus: booking.status,
      newStatus: newStatus,
      actorId: actorId,
      occurredAt: _clock.now,
      note: note,
    );
    final updated = booking.copyWith(
      status: newStatus,
      events: [...booking.events, event],
    );
    _replace(updated);
    return updated;
  }

  void _replace(Booking updated) {
    final idx = _bookings.indexWhere((b) => b.id == updated.id);
    if (idx >= 0) {
      _bookings[idx] = updated;
    }
  }
}
