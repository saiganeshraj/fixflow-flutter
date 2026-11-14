/// Typed errors used throughout the app.
/// Business logic throws these; UI catches and renders them.
sealed class AppError implements Exception {
  final String message;
  const AppError(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// A slot is already reserved by another booking.
class SlotUnavailableError extends AppError {
  const SlotUnavailableError()
    : super('This time slot is no longer available. Please choose another.');
}

/// A booking with this idempotency key already exists; returns the original.
class DuplicateBookingError extends AppError {
  final String existingBookingId;
  const DuplicateBookingError(this.existingBookingId)
    : super('This booking was already submitted.');
}

/// An action is not allowed for the current status.
class InvalidTransitionError extends AppError {
  const InvalidTransitionError(String from, String action)
    : super('Cannot "$action" a booking in "$from" status.');
}

/// The actor is not authorised to perform this action.
class UnauthorisedError extends AppError {
  const UnauthorisedError([String? detail])
    : super(detail ?? 'You are not authorised to perform this action.');
}

/// A booking for this ID was not found.
class NotFoundError extends AppError {
  const NotFoundError([String? detail])
    : super(detail ?? 'The requested item was not found.');
}

/// General validation failure.
class ValidationError extends AppError {
  const ValidationError(super.message);
}

/// Something unexpected went wrong with persistence.
class PersistenceError extends AppError {
  const PersistenceError(super.message);
}

/// No technician is eligible for the requested slot.
class NoAvailabilityError extends AppError {
  const NoAvailabilityError()
    : super(
        'No technician is available for this service at the selected time. Please try another slot.',
      );
}
