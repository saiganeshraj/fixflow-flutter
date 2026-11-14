import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../../bookings/models.dart';
import '../../../core/widgets/brand.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceProvider(serviceId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return serviceAsync.when(
      data: (service) {
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Service')),
            body: const ErrorState(message: 'Service not found.'),
          );
        }
        final catName =
            categoriesAsync.valueOrNull
                ?.where((c) => c.id == service.categoryId)
                .firstOrNull
                ?.name ??
            '';
        return _ServiceDetailBody(service: service, categoryName: catName);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const LoadingState(message: 'Loading service…'),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(serviceProvider(serviceId)),
        ),
      ),
    );
  }
}

class _ServiceDetailBody extends ConsumerWidget {
  final Service service;
  final String categoryName;

  const _ServiceDetailBody({required this.service, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1100;
    final slots = ref.watch(availableSlotsProvider(service.id));
    final hasAvailability = slots.valueOrNull?.isNotEmpty ?? false;
    if (slots.isLoading) {
      return const Scaffold(
        body: LoadingState(message: 'Checking availability…'),
      );
    }
    if (slots.hasError) {
      return Scaffold(
        body: ErrorState(
          message: slots.error.toString(),
          onRetry: () => ref.invalidate(availableSlotsProvider(service.id)),
        ),
      );
    }

    final content = SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: ServiceArtwork(categoryId: service.categoryId),
            ),
          ),
          const SizedBox(height: 24),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF007A7A).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              categoryName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF007A7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title + price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPaise(service.pricePaise),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF007A7A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Fixed price',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${service.durationMinutes} min appointment',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Description
          Text(
            'About this service',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            service.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),

          const SizedBox(height: 24),

          // Inclusions
          Text(
            'What\'s included',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...service.inclusions.map<Widget>(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Availability notice
          if (!hasAvailability)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF856404),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No technicians are available in the next 7 days. '
                      'Please check back later.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(service.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.catalog),
        ),
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: content),
                Expanded(
                  flex: 2,
                  child: _BookingPanel(
                    serviceId: service.id,
                    pricePaise: service.pricePaise,
                    hasAvailability: hasAvailability,
                  ),
                ),
              ],
            )
          : content,
      bottomNavigationBar: isWide
          ? null
          : _BookingBar(
              serviceId: service.id,
              hasAvailability: hasAvailability,
            ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  final String serviceId;
  final bool hasAvailability;

  const _BookingBar({required this.serviceId, required this.hasAvailability});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          onPressed: hasAvailability
              ? () => context.go(AppRoutes.bookingFormPath(serviceId))
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(hasAvailability ? 'Book Now' : 'No Availability'),
        ),
      ),
    );
  }
}

class _BookingPanel extends StatelessWidget {
  final String serviceId;
  final int pricePaise;
  final bool hasAvailability;

  const _BookingPanel({
    required this.serviceId,
    required this.pricePaise,
    required this.hasAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E6DC)),
          borderRadius: BorderRadius.circular(26),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('A little help, all sorted'),
            const SizedBox(height: 22),
            Text(
              formatPaise(pricePaise),
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -1,
              ),
            ),
            const Text(
              'Fixed price · 60-minute appointment',
              style: TextStyle(color: mutedInk, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Ready to book?',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'An eligible technician will be assigned at the time you select.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: hasAvailability
                  ? () => context.go(AppRoutes.bookingFormPath(serviceId))
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(hasAvailability ? 'Book Now' : 'No Availability'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Choose your time on the next step. No payment is collected in this demo.',
              style: TextStyle(fontSize: 12, color: mutedInk, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
