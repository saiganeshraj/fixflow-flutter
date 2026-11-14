import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../../bookings/models.dart';
import '../catalog_state.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late final TextEditingController _searchController;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(catalogFiltersProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(catalogFiltersProvider);
    final actions = ref.read(catalogFiltersProvider.notifier);
    final categories = ref.watch(categoriesProvider);
    final services = ref.watch(filteredServicesProvider);
    final persona = ref.watch(currentPersonaProvider);
    ref.listen(catalogFiltersProvider.select((state) => state.query), (
      _,
      query,
    ) {
      if (_searchController.text != query) _searchController.text = query;
    });
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 600 ? 20.0 : 36.0;
            final contentWidth = (constraints.maxWidth - pad * 2).clamp(
              0.0,
              1120.0,
            );
            final cols = contentWidth >= 940
                ? 3
                : contentWidth >= 570
                ? 2
                : 1;
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 30),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Eyebrow('Your home, your space'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hello, ${persona.name.split(' ').first}.',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.8,
                                      color: ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: const Color(0xFFE9EBDC),
                              foregroundColor: ink,
                              child: Text(
                                persona.name.substring(0, 1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Container(
                            color: ink,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      contentWidth < 500 ? 24 : 32,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Eyebrow(
                                          'One less thing to worry about',
                                          color: lime,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'A little help.\nA happier home.',
                                          style: TextStyle(
                                            fontSize: contentWidth < 500
                                                ? 32
                                                : 39,
                                            height: 1.12,
                                            letterSpacing: -1.3,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Find the right service. We’ll take it from there.',
                                          style: TextStyle(
                                            color: Color(0xFFD3DED6),
                                            height: 1.6,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (contentWidth >= 800)
                                  const Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 260,
                                      child: ServiceArtwork(room: true),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _BookingOverviewCard(),
                        const SizedBox(height: 32),
                        const Eyebrow('A fix for every corner'),
                        const SizedBox(height: 8),
                        const Text(
                          'What can we help with?',
                          style: TextStyle(
                            fontSize: 25,
                            color: ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _searchController,
                          onChanged: actions.search,
                          decoration: InputDecoration(
                            hintText: 'Search services…',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: mutedInk,
                            ),
                            suffixIcon: filters.query.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => actions.search(''),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        categories.when(
                          data: (cats) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: filters.categoryId == null,
                                onSelected: (_) => actions.selectCategory(null),
                              ),
                              for (final cat in cats)
                                FilterChip(
                                  avatar: Icon(serviceIcon(cat.id), size: 17),
                                  label: Text(cat.name),
                                  selected: filters.categoryId == cat.id,
                                  onSelected: (_) => actions.selectCategory(
                                    filters.categoryId == cat.id
                                        ? null
                                        : cat.id,
                                  ),
                                ),
                            ],
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => TextButton(
                            onPressed: () => ref.invalidate(categoriesProvider),
                            child: const Text('Retry categories'),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(
                              '${services.valueOrNull?.length ?? '—'} services to make life easier',
                              style: const TextStyle(
                                color: mutedInk,
                                fontSize: 13,
                              ),
                            ),
                            PopupMenuButton<ServiceSort>(
                              tooltip: 'Sort services',
                              initialValue: filters.sort,
                              onSelected: actions.sortBy,
                              itemBuilder: (_) => [
                                for (final sort in ServiceSort.values)
                                  PopupMenuItem(
                                    value: sort,
                                    child: Text(sort.label),
                                  ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.sort_rounded,
                                      size: 18,
                                      color: ink,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      filters.sort.label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ink,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.expand_more,
                                      size: 16,
                                      color: ink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (filters.hasFilters)
                              TextButton.icon(
                                onPressed: actions.reset,
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('Clear filters'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        services.when(
                          data: (items) => items.isEmpty
                              ? EmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: 'No services found',
                                  subtitle: 'Try a different search or browse all categories.',
                                  action: ElevatedButton(
                                    onPressed: actions.reset,
                                    child: const Text('Show all services'),
                                  ),
                                )
                              : Wrap(
                                  spacing: 18,
                                  runSpacing: 18,
                                  children: [
                                    for (final service in items)
                                      SizedBox(
                                        width:
                                            (contentWidth - (cols - 1) * 18) /
                                            cols,
                                        height:
                                            374 *
                                            MediaQuery.textScalerOf(context)
                                                .scale(1)
                                                .clamp(1.0, 2.0),
                                        child: _ServiceCard(service: service),
                                      ),
                                  ],
                                ),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(40),
                            child: LoadingState(
                              message: 'Finding a little help…',
                            ),
                          ),
                          error: (error, _) => ErrorState(
                            message: error.toString(),
                            onRetry: () => ref.invalidate(servicesProvider),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: mutedInk,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fictional services for this portfolio demo. Prices shown are fixed; no real payment or dispatch takes place.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedInk,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingOverviewCard extends ConsumerWidget {
  const _BookingOverviewCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(bookingOverviewProvider)
      .when(
        data: (overview) => Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.go(
              overview.nextBooking == null
                  ? AppRoutes.myBookings
                  : AppRoutes.bookingDetailPath(overview.nextBooking!.id),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lime.withAlpha(100),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.event_available_outlined,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overview.nextBooking == null
                              ? 'Room for a fresh start'
                              : 'Your next home visit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          overview.nextBooking == null
                              ? 'Your bookings will appear here.'
                              : formatSlot(overview.nextBooking!.slotStartUtc),
                          style: const TextStyle(fontSize: 12, color: mutedInk),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${overview.upcomingCount} upcoming · ${overview.completedCount} completed',
                          style: const TextStyle(fontSize: 11, color: mutedInk),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: ink, size: 20),
                ],
              ),
            ),
          ),
        ),
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (_, __) => TextButton(
          onPressed: () => ref.invalidate(
            customerBookingsProvider(ref.read(bookingCustomerIdProvider)),
          ),
          child: const Text('Retry booking overview'),
        ),
      );
}

class _ServiceCard extends StatefulWidget {
  final Service service;
  const _ServiceCard({required this.service});
  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: ink.withAlpha(_hovered ? 22 : 5),
              blurRadius: _hovered ? 22 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(AppRoutes.serviceDetailPath(service.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ServiceArtwork(categoryId: service.categoryId),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                serviceIcon(service.categoryId),
                                size: 13,
                                color: ink,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${service.durationMinutes} min',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: mutedInk,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              formatPaise(service.pricePaise),
                              style: const TextStyle(
                                fontSize: 20,
                                color: ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'fixed price',
                                style: TextStyle(color: mutedInk, fontSize: 10),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _hovered ? ink : const Color(0xFFEDF0E6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 18,
                                color: _hovered ? Colors.white : ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
