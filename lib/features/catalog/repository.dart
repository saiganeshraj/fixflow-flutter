import '../bookings/models.dart';

abstract class AppRepository
    implements CatalogRepository, BookingRepository, TechnicianRepository {
  Future<void> initialize();
  Future<List<DateTime>> fetchAvailableSlots(String serviceId);
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
}

/// Repository interface for the service catalog.
/// Both demo and live implementations conform to this contract.
abstract class CatalogRepository {
  Future<List<ServiceCategory>> fetchCategories();
  Future<List<Service>> fetchServices();
  Future<Service?> fetchService(String serviceId);
  Future<List<Service>> fetchServicesByCategory(String categoryId);
  Future<List<Service>> searchServices(String query);
}

/// Repository interface for bookings (customer side).
abstract class BookingRepository {
  /// Create a new booking. Throws [SlotUnavailableError], [NoAvailabilityError],
  /// [DuplicateBookingError], or [ValidationError] on failure.
  Future<Booking> createBooking(BookingRequest request, String customerId);

  /// Fetch all bookings for a customer.
  Future<List<Booking>> fetchCustomerBookings(String customerId);

  /// Fetch a single booking by ID.
  Future<Booking?> fetchBooking(String bookingId);

  /// Cancel a booking. Enforces cancellation rules (not after en_route).
  Future<Booking> cancelBooking(String bookingId, String customerId);

  /// Submit a review for a completed booking.
  Future<Booking> submitReview({
    required String bookingId,
    required String customerId,
    required int rating,
    String? comment,
  });

  /// Fetch technicians (used by assignment logic).
  Future<List<Technician>> fetchTechnicians();

  /// Stream of booking updates (for reactive UI). May emit null to signal
  /// full refresh needed.
  Stream<List<Booking>> watchCustomerBookings(String customerId);
}

/// Repository interface for technician actions.
abstract class TechnicianRepository {
  /// Fetch all bookings assigned to a technician.
  Future<List<Booking>> fetchTechnicianBookings(String technicianId);

  /// Advance booking: requested → accepted.
  Future<Booking> acceptBooking(String bookingId, String technicianId);

  /// Advance booking: accepted → en_route.
  Future<Booking> markEnRoute(String bookingId, String technicianId);

  /// Advance booking: en_route → in_progress.
  Future<Booking> startService(String bookingId, String technicianId);

  /// Advance booking: in_progress → completed.
  Future<Booking> completeService(String bookingId, String technicianId);

  /// Stream of booking updates for a technician.
  Stream<List<Booking>> watchTechnicianBookings(String technicianId);
}
