import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../../../core/widgets/status_chip.dart';
import '../models.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;
  bool _submittingReview = false;

  // Review state
  int _reviewRating = 5;
  final _reviewCommentController = TextEditingController();
  String? _reviewError;

  @override
  void dispose() {
    _reviewCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    final booking = bookingsAsync.valueOrNull;

    if (bookingsAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const LoadingState(message: 'Loading booking…'),
      );
    }

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: ErrorState(
          message: bookingsAsync.hasError
              ? bookingsAsync.error.toString()
              : 'Booking not found.',
          onRetry: () =>
              ref.invalidate(bookingDetailProvider(widget.bookingId)),
        ),
      );
    }

    return _buildDetail(context, booking);
  }

  Widget _buildDetail(BuildContext context, Booking booking) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(servicesProvider);
    final techsAsync = ref.watch(technicianListProvider);

    final service = servicesAsync.valueOrNull
        ?.where((s) => s.id == booking.serviceId)
        .firstOrNull;

    final tech = techsAsync.valueOrNull
        ?.where((t) => t.id == booking.technicianId)
        .firstOrNull;

    final isCustomer = !ref.watch(currentPersonaProvider).isTechnician;
    final canCancel =
        isCustomer &&
        (booking.status == BookingStatus.requested ||
            booking.status == BookingStatus.accepted);

    final canReview =
        isCustomer &&
        booking.status == BookingStatus.completed &&
        booking.review == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.myBookings),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh booking',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(bookingDetailProvider(widget.bookingId)),
          ),
          if (canCancel)
            TextButton(
              onPressed: _cancelling
                  ? null
                  : () => _confirmCancel(context, booking),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service?.title ?? 'Service',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      StatusChip(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.event_rounded,
                    label: 'Appointment',
                    value: formatSlot(booking.slotStartUtc),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: [
                      booking.addressLine1,
                      if (booking.addressLine2.isNotEmpty) booking.addressLine2,
                      '${booking.city} ${booking.pincode}',
                    ].join(', '),
                  ),
                  if (booking.notes != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: booking.notes!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value: formatPaise(booking.pricePaise),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Technician
          if (tech != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF007A7A).withAlpha(30),
                      child: Text(
                        tech.avatarInitials,
                        style: const TextStyle(
                          color: Color(0xFF007A7A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tech.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Assigned Technician',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Timeline
          _TimelineCard(events: booking.events),

          const SizedBox(height: 16),

          // Review section
          if (booking.status == BookingStatus.completed)
            _ReviewSection(
              booking: booking,
              canReview: canReview,
              rating: _reviewRating,
              commentController: _reviewCommentController,
              reviewError: _reviewError,
              submitting: _submittingReview,
              onRatingChanged: (r) => setState(() => _reviewRating = r),
              onSubmit: () => _submitReview(context, booking),
            ),

          const SizedBox(height: 16),

          // Cancellation warning
          if (booking.status == BookingStatus.enRoute ||
              booking.status == BookingStatus.inProgress)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF856404)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cancellation is not available after the technician is en route.',
                      style: TextStyle(color: Color(0xFF856404), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doCancel(context, booking);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _doCancel(BuildContext context, Booking booking) async {
    setState(() => _cancelling = true);
    try {
      final customerId = ref.read(bookingCustomerIdProvider);
      await ref.read(repositoryProvider).cancelBooking(booking.id, customerId);
      ref.invalidate(customerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      }
    } on AppError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _submitReview(BuildContext context, Booking booking) async {
    final comment = _reviewCommentController.text.trim();
    if (comment.length > 500) {
      setState(() => _reviewError = 'Comment must be 500 characters or fewer.');
      return;
    }

    setState(() {
      _submittingReview = true;
      _reviewError = null;
    });
    try {
      final customerId = ref.read(bookingCustomerIdProvider);
      await ref
          .read(repositoryProvider)
          .submitReview(
            bookingId: booking.id,
            customerId: customerId,
            rating: _reviewRating,
            comment: comment.isEmpty ? null : comment,
          );
      ref.invalidate(customerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted! Thank you.')),
        );
      }
    } on AppError catch (e) {
      if (mounted) setState(() => _reviewError = e.message);
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }
}

class _TimelineCard extends StatelessWidget {
  final List<BookingEvent> events;
  const _TimelineCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...events.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value;
              final isLast = i == events.length - 1;
              return _TimelineItem(event: event, isLast: isLast);
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BookingEvent event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ist = toServiceTimezone(event.occurredAt);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final timeStr =
        '${ist.day} ${months[ist.month - 1]} · ${_hour(ist)}:${ist.minute.toString().padLeft(2, '0')} ${ist.hour < 12 ? "AM" : "PM"} IST';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(event.newStatus),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFE5E0DB)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.newStatus.displayLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (event.note != null)
                    Text(
                      event.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _hour(DateTime dt) {
    return dt.hour == 0
        ? 12
        : dt.hour > 12
        ? dt.hour - 12
        : dt.hour;
  }

  Color _statusColor(BookingStatus s) => switch (s) {
    BookingStatus.requested => const Color(0xFFFFD700),
    BookingStatus.accepted => const Color(0xFF5BAFD6),
    BookingStatus.enRoute => const Color(0xFF4CAAA9),
    BookingStatus.inProgress => const Color(0xFFF39C12),
    BookingStatus.completed => const Color(0xFF27AE60),
    BookingStatus.cancelled => const Color(0xFFDC3545),
  };
}

class _ReviewSection extends StatelessWidget {
  final Booking booking;
  final bool canReview;
  final int rating;
  final TextEditingController commentController;
  final String? reviewError;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewSection({
    required this.booking,
    required this.canReview,
    required this.rating,
    required this.commentController,
    required this.reviewError,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (booking.review != null) {
      // Show submitted review.
      final r = booking.review!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Review',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF39C12),
                    size: 24,
                  ),
                ),
              ),
              if (r.comment != null) ...[
                const SizedBox(height: 8),
                Text(
                  r.comment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!canReview) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave a Review',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Rating: $rating out of 5 stars',
              child: Row(
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => onRatingChanged(i + 1),
                    child: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF39C12),
                      size: 36,
                      semanticLabel: '${i + 1} star',
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional, max 500 chars)',
                hintText: 'Share your experience…',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            if (reviewError != null) ...[
              const SizedBox(height: 8),
              Text(
                reviewError!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF007A7A)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
