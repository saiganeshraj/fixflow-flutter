import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/config.dart';
import '../../../core/clock.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../features/bookings/models.dart';

class TechnicianDashboardScreen extends ConsumerStatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  ConsumerState<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState
    extends ConsumerState<TechnicianDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(currentPersonaProvider);

    if (!persona.isTechnician || persona.technicianId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Technician Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.engineering_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Technician View',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.isLive
                      ? 'This is a customer account. Only provisioned technician accounts can open assigned jobs.'
                      : 'Switch to a technician demo persona to see this dashboard.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF007A7A).withAlpha(80),
                    ),
                  ),
                  child: Text(
                    AppConfig.isLive
                        ? 'Sign in with your provisioned technician account.'
                        : 'Use Switch on mobile or the customer control in the navigation rail.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF007A7A), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final techId = persona.technicianId!;
    final bookingsAsync = ref.watch(technicianBookingsProvider(techId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${persona.name.split(' ').first}\'s Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh jobs',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(technicianBookingsProvider(techId)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007A7A).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppConfig.isLive ? 'Live accounts' : 'Demo Mode',
                style: TextStyle(
                  color: Color(0xFF007A7A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final pending = bookings
              .where((b) => b.status == BookingStatus.requested)
              .toList();
          final active =
              bookings
                  .where(
                    (b) =>
                        b.status == BookingStatus.accepted ||
                        b.status == BookingStatus.enRoute ||
                        b.status == BookingStatus.inProgress,
                  )
                  .toList()
                ..sort((a, b) => a.slotStartUtc.compareTo(b.slotStartUtc));
          final done =
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
              _TechBookingList(
                bookings: pending,
                techId: techId,
                emptyTitle: 'No pending offers',
                emptySubtitle: 'New booking requests will appear here.',
                emptyIcon: Icons.inbox_rounded,
              ),
              _TechBookingList(
                bookings: active,
                techId: techId,
                emptyTitle: 'No active jobs',
                emptySubtitle: 'Accept a pending booking to start a job.',
                emptyIcon: Icons.work_outline_rounded,
              ),
              _TechBookingList(
                bookings: done,
                techId: techId,
                emptyTitle: 'No completed jobs',
                emptySubtitle: 'Completed and cancelled jobs will appear here.',
                emptyIcon: Icons.history_rounded,
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Loading jobs…'),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(technicianBookingsProvider(techId)),
        ),
      ),
    );
  }
}

class _TechBookingList extends ConsumerWidget {
  final List<Booking> bookings;
  final String techId;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _TechBookingList({
    required this.bookings,
    required this.techId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) =>
          _TechBookingCard(booking: bookings[i], techId: techId),
    );
  }
}

class _TechBookingCard extends ConsumerStatefulWidget {
  final Booking booking;
  final String techId;
  const _TechBookingCard({required this.booking, required this.techId});

  @override
  ConsumerState<_TechBookingCard> createState() => _TechBookingCardState();
}

class _TechBookingCardState extends ConsumerState<_TechBookingCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(servicesProvider);
    final b = widget.booking;

    final serviceName =
        servicesAsync.valueOrNull
            ?.where((s) => s.id == b.serviceId)
            .firstOrNull
            ?.title ??
        'Service';

    final actions = _availableActions(b.status);

    return Card(
      clipBehavior: Clip.antiAlias,
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
                StatusChip(status: b.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatSlot(b.slotStartUtc),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${b.addressLine1}, ${b.city}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatPaise(b.pricePaise),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF007A7A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (b.notes != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: actions.map((action) {
                  return ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _performAction(context, action, b),
                    icon: Icon(action.icon, size: 16),
                    label: Text(action.label),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(color: Color(0xFF007A7A)),
            ],
          ],
        ),
      ),
    );
  }

  List<_TechAction> _availableActions(BookingStatus status) {
    return switch (status) {
      BookingStatus.requested => [
        const _TechAction(
          label: 'Accept Job',
          icon: Icons.check_circle_outline_rounded,
          type: _ActionType.accept,
        ),
      ],
      BookingStatus.accepted => [
        const _TechAction(
          label: 'Mark En Route',
          icon: Icons.directions_car_outlined,
          type: _ActionType.enRoute,
        ),
      ],
      BookingStatus.enRoute => [
        const _TechAction(
          label: 'Start Service',
          icon: Icons.build_circle_outlined,
          type: _ActionType.start,
        ),
      ],
      BookingStatus.inProgress => [
        const _TechAction(
          label: 'Mark Complete',
          icon: Icons.task_alt_rounded,
          type: _ActionType.complete,
        ),
      ],
      _ => [],
    };
  }

  Future<void> _performAction(
    BuildContext context,
    _TechAction action,
    Booking b,
  ) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      switch (action.type) {
        case _ActionType.accept:
          await repo.acceptBooking(b.id, widget.techId);
        case _ActionType.enRoute:
          await repo.markEnRoute(b.id, widget.techId);
        case _ActionType.start:
          await repo.startService(b.id, widget.techId);
        case _ActionType.complete:
          await repo.completeService(b.id, widget.techId);
      }
      ref.invalidate(technicianBookingsProvider);
      ref.invalidate(customerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${action.label} successful.')));
      }
    } on AppError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

enum _ActionType { accept, enRoute, start, complete }

class _TechAction {
  final String label;
  final IconData icon;
  final _ActionType type;

  const _TechAction({
    required this.label,
    required this.icon,
    required this.type,
  });
}
