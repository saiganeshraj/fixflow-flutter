import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../../../core/widgets/status_chip.dart';
import '../models.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BookingStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerId = ref.watch(bookingCustomerIdProvider);
    final bookingsAsync = ref.watch(customerBookingsProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _statusFilter == null
              ? 'My Bookings'
              : 'Bookings · ${_statusFilter!.displayLabel}',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter booking status',
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(
              () => _statusFilter = value == 'all'
                  ? null
                  : BookingStatus.fromString(value),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All statuses')),
              ...BookingStatus.values.map(
                (status) => PopupMenuItem(
                  value: status.serialized,
                  child: Text(status.displayLabel),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh bookings',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(customerBookingsProvider(customerId)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          bookings = bookings
              .where(
                (booking) =>
                    _statusFilter == null || booking.status == _statusFilter,
              )
              .toList();
          final upcoming =
              bookings
                  .where(
                    (b) =>
                        b.status == BookingStatus.requested ||
                        b.status == BookingStatus.accepted ||
                        b.status == BookingStatus.enRoute ||
                        b.status == BookingStatus.inProgress,
                  )
                  .toList()
                ..sort((a, b) => a.slotStartUtc.compareTo(b.slotStartUtc));

          final history =
              bookings
                  .where(
                    (b) =>
                        b.status == BookingStatus.completed ||
                        b.status == BookingStatus.cancelled,
                  )
                  .toList()
                ..sort((a, b) => b.slotStartUtc.compareTo(a.slotStartUtc));

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(
                bookings: upcoming,
                emptyIcon: Icons.event_available_rounded,
                emptyTitle: 'No upcoming bookings',
                emptySubtitle: 'Book a service to get started!',
                emptyAction: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.catalog),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Browse Services'),
                ),
              ),
              _BookingList(
                bookings: history,
                emptyIcon: Icons.history_rounded,
                emptyTitle: 'No booking history',
                emptySubtitle:
                    'Completed and cancelled bookings will appear here.',
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Loading bookings…'),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(customerBookingsProvider(customerId)),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget? emptyAction;

  const _BookingList({
    required this.bookings,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        action: emptyAction,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {}, // Stream already updates
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(servicesProvider);
    final techsAsync = ref.watch(technicianListProvider);

    final serviceName =
        servicesAsync.valueOrNull
            ?.where((s) => s.id == booking.serviceId)
            .firstOrNull
            ?.title ??
        'Service';

    final techName =
        techsAsync.valueOrNull
            ?.where((t) => t.id == booking.technicianId)
            .firstOrNull
            ?.name ??
        'Technician';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.bookingDetailPath(booking.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      serviceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formatSlot(booking.slotStartUtc),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.engineering_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      techName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    formatPaise(booking.pricePaise),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF007A7A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
