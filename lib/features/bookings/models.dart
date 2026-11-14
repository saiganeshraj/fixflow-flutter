import 'package:equatable/equatable.dart';

/// Booking status state machine values.
enum BookingStatus {
  requested,
  accepted,
  enRoute,
  inProgress,
  completed,
  cancelled;

  bool get isTerminal => this == completed || this == cancelled;

  bool get isActive =>
      this == accepted || this == enRoute || this == inProgress;

  String get displayLabel => switch (this) {
    requested => 'Requested',
    accepted => 'Accepted',
    enRoute => 'En Route',
    inProgress => 'In Progress',
    completed => 'Completed',
    cancelled => 'Cancelled',
  };

  String get serialized => switch (this) {
    requested => 'requested',
    accepted => 'accepted',
    enRoute => 'en_route',
    inProgress => 'in_progress',
    completed => 'completed',
    cancelled => 'cancelled',
  };

  static BookingStatus fromString(String s) => switch (s) {
    'requested' => BookingStatus.requested,
    'accepted' => BookingStatus.accepted,
    'en_route' => BookingStatus.enRoute,
    'in_progress' => BookingStatus.inProgress,
    'completed' => BookingStatus.completed,
    'cancelled' => BookingStatus.cancelled,
    _ => throw ArgumentError('Unknown status: $s'),
  };
}

/// A service category.
class ServiceCategory extends Equatable {
  final String id;
  final String name;
  final String iconName; // Material icon name as string

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.iconName,
  });

  @override
  List<Object?> get props => [id, name, iconName];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconName': iconName,
  };

  factory ServiceCategory.fromJson(Map<String, dynamic> j) => ServiceCategory(
    id: j['id'] as String,
    name: j['name'] as String,
    iconName: j['iconName'] as String,
  );
}

/// A bookable service.
class Service extends Equatable {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final List<String> inclusions;
  final int pricePaise; // integer paise, no floating point
  final int durationMinutes; // always 60 for v1
  final bool active;

  const Service({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.inclusions,
    required this.pricePaise,
    this.durationMinutes = 60,
    this.active = true,
  });

  @override
  List<Object?> get props => [
    id,
    categoryId,
    title,
    description,
    inclusions,
    pricePaise,
    durationMinutes,
    active,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'title': title,
    'description': description,
    'inclusions': inclusions,
    'pricePaise': pricePaise,
    'durationMinutes': durationMinutes,
    'active': active,
  };

  factory Service.fromJson(Map<String, dynamic> j) => Service(
    id: j['id'] as String,
    categoryId: j['categoryId'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    inclusions: List<String>.from(j['inclusions'] as List),
    pricePaise: j['pricePaise'] as int,
    durationMinutes: j['durationMinutes'] as int? ?? 60,
    active: j['active'] as bool? ?? true,
  );
}

/// A technician in the demo.
class Technician extends Equatable {
  final String id;
  final String name;
  final String avatarInitials;
  final List<String> serviceIds; // which services they can handle

  const Technician({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.serviceIds,
  });

  @override
  List<Object?> get props => [id, name, avatarInitials, serviceIds];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarInitials': avatarInitials,
    'serviceIds': serviceIds,
  };

  factory Technician.fromJson(Map<String, dynamic> j) => Technician(
    id: j['id'] as String,
    name: j['name'] as String,
    avatarInitials: j['avatarInitials'] as String,
    serviceIds: List<String>.from(j['serviceIds'] as List),
  );
}

/// A single customer or technician persona for demo switching.
class DemoPersona extends Equatable {
  final String id;
  final String name;
  final bool isTechnician;
  final String? technicianId; // only set when isTechnician

  const DemoPersona({
    required this.id,
    required this.name,
    required this.isTechnician,
    this.technicianId,
  });

  @override
  List<Object?> get props => [id, name, isTechnician, technicianId];
}

/// A booking record.
class Booking extends Equatable {
  final String id;
  final String customerId;
  final String technicianId;
  final String serviceId;
  final DateTime slotStartUtc;
  final DateTime slotEndUtc;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String pincode;
  final String? notes;
  final int pricePaise; // snapshot at booking time
  final BookingStatus status;
  final String idempotencyKey;
  final DateTime createdAt;
  final List<BookingEvent> events;
  final Review? review;

  Booking({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.serviceId,
    required this.slotStartUtc,
    required this.slotEndUtc,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.pincode,
    this.notes,
    required this.pricePaise,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    required List<BookingEvent> events,
    this.review,
  }) : events = List.unmodifiable(events);

  Booking copyWith({
    String? id,
    String? customerId,
    String? technicianId,
    String? serviceId,
    DateTime? slotStartUtc,
    DateTime? slotEndUtc,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? pincode,
    String? notes,
    int? pricePaise,
    BookingStatus? status,
    String? idempotencyKey,
    DateTime? createdAt,
    List<BookingEvent>? events,
    Review? review,
    bool clearReview = false,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      technicianId: technicianId ?? this.technicianId,
      serviceId: serviceId ?? this.serviceId,
      slotStartUtc: slotStartUtc ?? this.slotStartUtc,
      slotEndUtc: slotEndUtc ?? this.slotEndUtc,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      notes: notes ?? this.notes,
      pricePaise: pricePaise ?? this.pricePaise,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      events: events ?? this.events,
      review: clearReview ? null : (review ?? this.review),
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    technicianId,
    serviceId,
    slotStartUtc,
    slotEndUtc,
    addressLine1,
    addressLine2,
    city,
    pincode,
    notes,
    pricePaise,
    status,
    idempotencyKey,
    createdAt,
    events,
    review,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'technicianId': technicianId,
    'serviceId': serviceId,
    'slotStartUtc': slotStartUtc.toIso8601String(),
    'slotEndUtc': slotEndUtc.toIso8601String(),
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'pincode': pincode,
    'notes': notes,
    'pricePaise': pricePaise,
    'status': status.serialized,
    'idempotencyKey': idempotencyKey,
    'createdAt': createdAt.toIso8601String(),
    'events': events.map((e) => e.toJson()).toList(),
    'review': review?.toJson(),
  };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    customerId: j['customerId'] as String,
    technicianId: j['technicianId'] as String,
    serviceId: j['serviceId'] as String,
    slotStartUtc: DateTime.parse(j['slotStartUtc'] as String),
    slotEndUtc: DateTime.parse(j['slotEndUtc'] as String),
    addressLine1: j['addressLine1'] as String,
    addressLine2: j['addressLine2'] as String? ?? '',
    city: j['city'] as String,
    pincode: j['pincode'] as String,
    notes: j['notes'] as String?,
    pricePaise: j['pricePaise'] as int,
    status: BookingStatus.fromString(j['status'] as String),
    idempotencyKey: j['idempotencyKey'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    events:
        (j['events'] as List<dynamic>?)
            ?.map((e) => BookingEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    review: j['review'] != null
        ? Review.fromJson(j['review'] as Map<String, dynamic>)
        : null,
  );
}

/// An immutable event in the booking timeline.
class BookingEvent extends Equatable {
  final String id;
  final String bookingId;
  final BookingStatus? previousStatus;
  final BookingStatus newStatus;
  final String actorId;
  final DateTime occurredAt;
  final String? note;

  const BookingEvent({
    required this.id,
    required this.bookingId,
    this.previousStatus,
    required this.newStatus,
    required this.actorId,
    required this.occurredAt,
    this.note,
  });

  @override
  List<Object?> get props => [
    id,
    bookingId,
    previousStatus,
    newStatus,
    actorId,
    occurredAt,
    note,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'previousStatus': previousStatus?.serialized,
    'newStatus': newStatus.serialized,
    'actorId': actorId,
    'occurredAt': occurredAt.toIso8601String(),
    'note': note,
  };

  factory BookingEvent.fromJson(Map<String, dynamic> j) => BookingEvent(
    id: j['id'] as String,
    bookingId: j['bookingId'] as String,
    previousStatus: j['previousStatus'] != null
        ? BookingStatus.fromString(j['previousStatus'] as String)
        : null,
    newStatus: BookingStatus.fromString(j['newStatus'] as String),
    actorId: j['actorId'] as String,
    occurredAt: DateTime.parse(j['occurredAt'] as String),
    note: j['note'] as String?,
  );
}

/// A customer review for a completed booking.
class Review extends Equatable {
  final String id;
  final String bookingId;
  final String customerId;
  final int rating; // 1–5
  final String? comment; // max 500 chars
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    bookingId,
    customerId,
    rating,
    comment,
    createdAt,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'customerId': customerId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'] as String,
    bookingId: j['bookingId'] as String,
    customerId: j['customerId'] as String,
    rating: j['rating'] as int,
    comment: j['comment'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

/// Input for creating a new booking.
class BookingRequest {
  final String serviceId;
  final DateTime slotStartUtc;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String pincode;
  final String? notes;
  final String idempotencyKey;

  const BookingRequest({
    required this.serviceId,
    required this.slotStartUtc,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.pincode,
    this.notes,
    required this.idempotencyKey,
  });
}
