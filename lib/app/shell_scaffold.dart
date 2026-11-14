import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../demo/fixtures.dart';
import '../features/bookings/models.dart';
import '../features/auth/live_providers.dart';
import 'config.dart';
import '../core/widgets/brand.dart';

/// Responsive shell with bottom nav (mobile) and navigation rail (desktop).
class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  static const _breakpoint = 720.0;

  static const _destinations = [
    _NavItem(
      label: 'Services',
      icon: Icons.home_repair_service_outlined,
      activeIcon: Icons.home_repair_service_rounded,
      route: AppRoutes.catalog,
    ),
    _NavItem(
      label: 'My Bookings',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      route: AppRoutes.myBookings,
    ),
    _NavItem(
      label: 'Technician',
      icon: Icons.engineering_outlined,
      activeIcon: Icons.engineering_rounded,
      route: AppRoutes.technicianDashboard,
    ),
    _NavItem(
      label: 'About',
      icon: Icons.info_outlined,
      activeIcon: Icons.info_rounded,
      route: AppRoutes.about,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(currentPersonaProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _breakpoint;
    final idx = _selectedIndex(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _buildRail(context, idx, persona),
            const VerticalDivider(width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!AppConfig.isLive)
            _PersonaSwitcher(persona: persona)
          else
            const _LiveAccountBar(),
          NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(_destinations[i].route),
            destinations: _destinations
                .map(
                  (d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.activeIcon),
                    label: d.label,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context, int idx, DemoPersona persona) {
    if (MediaQuery.sizeOf(context).width >= 1100) {
      return Container(
        width: 224,
        color: ink,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: BrandMark(inverse: true),
                ),
                const SizedBox(height: 44),
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Eyebrow('Your workspace', color: Color(0xFFA7BEB0)),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: idx == i ? lime : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        leading: Icon(
                          idx == i
                              ? _destinations[i].activeIcon
                              : _destinations[i].icon,
                          size: 21,
                          color: idx == i ? ink : const Color(0xFFCAD8CF),
                        ),
                        title: Text(
                          _destinations[i].label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: idx == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: idx == i ? ink : const Color(0xFFCAD8CF),
                          ),
                        ),
                        onTap: () => context.go(_destinations[i].route),
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.spa_outlined, color: lime),
                      SizedBox(height: 14),
                      Text(
                        'A little more\npeace of home.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 19,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Care for every corner.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA7BEB0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (!AppConfig.isLive)
                  _PersonaSwitcherRail(persona: persona)
                else
                  const _LiveAccountBar(),
                const SizedBox(height: 12),
                Text(
                  persona.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA7BEB0),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return NavigationRail(
      selectedIndex: idx,
      onDestinationSelected: (i) => context.go(_destinations[i].route),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const _FixFlowLogo(),
            const SizedBox(height: 16),
            if (!AppConfig.isLive)
              _PersonaSwitcherRail(persona: persona)
            else
              const _LiveAccountBar(),
          ],
        ),
      ),
      destinations: _destinations
          .map(
            (d) => NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
              label: Text(d.label),
            ),
          )
          .toList(),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _FixFlowLogo extends StatelessWidget {
  const _FixFlowLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.build_circle_rounded,
          color: Color(0xFF007A7A),
          size: 24,
        ),
        const SizedBox(width: 6),
        Text(
          'FixFlow',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF007A7A),
          ),
        ),
      ],
    );
  }
}

/// Compact persona switcher shown above bottom nav on mobile.
class _PersonaSwitcher extends ConsumerWidget {
  final DemoPersona persona;
  const _PersonaSwitcher({required this.persona});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: const Color(0xFFF0F9F9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              size: 16,
              color: Color(0xFF007A7A),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Demo · ${persona.name}',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: const Color(0xFF007A7A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _showPersonaSheet(context, ref),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Switch', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonaSheet(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PersonaSheet(
        currentPersonaId: persona.id,
        ref: ref,
        parentContext: parentContext,
      ),
    );
  }
}

class _PersonaSwitcherRail extends ConsumerWidget {
  final DemoPersona persona;
  const _PersonaSwitcherRail({required this.persona});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showPersonaSheet(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: 'Switch demo view',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF007A7A).withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                persona.isTechnician
                    ? Icons.engineering_rounded
                    : Icons.person_outline_rounded,
                size: 16,
                color: const Color(0xFF007A7A),
              ),
              const SizedBox(width: 4),
              Text(
                persona.isTechnician ? 'Tech' : 'Customer',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: const Color(0xFF007A7A)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonaSheet(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PersonaSheet(
        currentPersonaId: persona.id,
        ref: ref,
        parentContext: parentContext,
      ),
    );
  }
}

class _PersonaSheet extends StatelessWidget {
  final String currentPersonaId;
  final WidgetRef ref;
  final BuildContext parentContext;

  const _PersonaSheet({
    required this.currentPersonaId,
    required this.ref,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_outlined, color: Color(0xFF007A7A)),
                const SizedBox(width: 8),
                Text(
                  'Demo View Switch',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'This is a simulation — switching views represents different fictional users in the same demo workspace.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...DemoFixtures.personas.map((persona) {
              final isActive = persona.id == currentPersonaId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF007A7A).withAlpha(30),
                  child: Icon(
                    persona.isTechnician
                        ? Icons.engineering_rounded
                        : Icons.person_outline_rounded,
                    color: const Color(0xFF007A7A),
                  ),
                ),
                title: Text(persona.name),
                subtitle: Text(
                  persona.isTechnician ? 'Technician view' : 'Customer view',
                ),
                trailing: isActive
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF007A7A),
                      )
                    : null,
                selected: isActive,
                onTap: () {
                  ref.read(activePersonaProvider.notifier).switchTo(persona);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.refresh_rounded, color: Colors.red),
              title: const Text(
                'Reset Demo',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Restore fictional data for this visitor'),
              onTap: () {
                Navigator.pop(context);
                _confirmReset(parentContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo?'),
        content: const Text(
          'This will restore the original fictional dataset for your browser session. '
          'Your demo bookings will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(demoRepositoryProvider).reset();
                ref.invalidate(activePersonaProvider);
                ref.invalidate(bookingDetailProvider);
                ref.invalidate(availableSlotsProvider);
                ref.invalidate(customerBookingsProvider);
                ref.invalidate(technicianBookingsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo reset to original data.'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not reset demo storage. Please retry.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _LiveAccountBar extends ConsumerWidget {
  const _LiveAccountBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    icon: const Icon(Icons.logout, size: 16),
    label: const Text('Sign out'),
    onPressed: () async {
      try {
        final client = await ref.read(supabaseClientProvider.future);
        await client.auth.signOut();
        ref.invalidate(repositoryProvider);
        ref.invalidate(repoInitProvider);
        ref.invalidate(customerBookingsProvider);
        ref.invalidate(technicianBookingsProvider);
        ref.invalidate(bookingDetailProvider);
        ref.invalidate(technicianListProvider);
        ref.invalidate(liveProfileProvider);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign out. Please retry.')),
          );
        }
      }
    },
  );
}
