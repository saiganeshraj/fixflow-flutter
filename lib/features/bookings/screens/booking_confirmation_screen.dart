import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../../../core/widgets/status_chip.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: bookingAsync.when(
        data: (booking) {
          if (booking == null) {
            return ErrorState(
              message: 'Booking not found.',
              onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Success indicator
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4EDDA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Color(0xFF27AE60),
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 16),
                    Text(
                          'Booking Confirmed!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'A technician has been assigned to your slot.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Booking summary card
              Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking ID',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                booking.id.substring(0, 8).toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _SummaryRow(
                            icon: Icons.event_rounded,
                            label: 'Appointment',
                            value: formatSlot(booking.slotStartUtc),
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value:
                                '${booking.addressLine1}, ${booking.city} ${booking.pincode}',
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            icon: Icons.payments_outlined,
                            label: 'Amount',
                            value: formatPaise(booking.pricePaise),
                          ),
                          const SizedBox(height: 12),
                          StatusChip(status: booking.status),
                        ],
                      ),
                    ),
                  )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // Demo notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A7A).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: Color(0xFF007A7A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo mode: This is a fictional booking. Switch to Technician view '
                        'to accept and progress this booking.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF007A7A),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.bookingDetailPath(bookingId)),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Booking Details'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.myBookings),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('My Bookings'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.catalog),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Browse More Services'),
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Loading booking…'),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF007A7A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Colors.grey),
              ),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
