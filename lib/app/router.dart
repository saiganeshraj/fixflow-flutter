import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/catalog/screens/welcome_screen.dart';
import '../features/catalog/screens/catalog_screen.dart';
import '../features/catalog/screens/service_detail_screen.dart';
import '../features/bookings/screens/booking_form_screen.dart';
import '../features/bookings/screens/booking_confirmation_screen.dart';
import '../features/bookings/screens/my_bookings_screen.dart';
import '../features/bookings/screens/booking_detail_screen.dart';
import '../features/technician/screens/technician_dashboard_screen.dart';
import '../app/shell_scaffold.dart';
import 'config.dart';

// Route names as constants for type-safe navigation.
class AppRoutes {
  static const welcome = '/';
  static const catalog = '/catalog';
  static const serviceDetail = '/service/:serviceId';
  static const bookingForm = '/book/:serviceId';
  static const bookingConfirmation = '/booking-confirmed/:bookingId';
  static const myBookings = '/my-bookings';
  static const bookingDetail = '/booking/:bookingId';
  static const technicianDashboard = '/technician';
  static const about = '/about';

  static String serviceDetailPath(String id) => '/service/$id';
  static String bookingFormPath(String id) => '/book/$id';
  static String bookingConfirmationPath(String id) => '/booking-confirmed/$id';
  static String bookingDetailPath(String id) => '/booking/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: false,
    redirect: (context, state) =>
        AppConfig.isLive && state.uri.path == '/' ? AppRoutes.catalog : null,
    errorBuilder: (context, state) => _NotFoundScreen(state.uri.toString()),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.catalog,
            name: 'catalog',
            builder: (context, state) => const CatalogScreen(),
          ),
          GoRoute(
            path: AppRoutes.serviceDetail,
            name: 'serviceDetail',
            builder: (context, state) {
              final id = state.pathParameters['serviceId']!;
              return ServiceDetailScreen(serviceId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.bookingForm,
            name: 'bookingForm',
            builder: (context, state) {
              final id = state.pathParameters['serviceId']!;
              return BookingFormScreen(serviceId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.bookingConfirmation,
            name: 'bookingConfirmation',
            builder: (context, state) {
              final id = state.pathParameters['bookingId']!;
              return BookingConfirmationScreen(bookingId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.myBookings,
            name: 'myBookings',
            builder: (context, state) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.bookingDetail,
            name: 'bookingDetail',
            builder: (context, state) {
              final id = state.pathParameters['bookingId']!;
              return BookingDetailScreen(bookingId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.technicianDashboard,
            name: 'technicianDashboard',
            builder: (context, state) => const TechnicianDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            name: 'about',
            builder: (context, state) => const _AboutScreen(),
          ),
        ],
      ),
    ],
  );
});

class _NotFoundScreen extends StatelessWidget {
  final String path;
  const _NotFoundScreen(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(path, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.welcome),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutScreen extends ConsumerWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About FixFlow')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.build_circle_rounded,
            size: 64,
            color: Color(0xFF007A7A),
          ),
          const SizedBox(height: 16),
          Text(
            'FixFlow',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A Flutter portfolio project demonstrating home service booking with '
            'a complete customer and technician workflow.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: AppConfig.isLive ? 'Live Mode' : 'Demo Mode',
            body: AppConfig.isLive
                ? 'This build uses real Supabase accounts and database access. Services remain fictional portfolio examples; no payments or real service dispatch occur.'
                : 'This is a self-contained demonstration using fictional data. '
                      'All bookings are stored locally in your browser — no server, '
                      'no account, no real payments.',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Technology Stack',
            body:
                'Flutter 3 · Dart · Material 3 · Riverpod · go_router · '
                'SharedPreferences · Supabase (opt-in live mode)',
            icon: Icons.code_rounded,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'State management with Riverpod',
            body:
                'An immutable Notifier controls catalog search, category and sorting. '
                'Derived providers filter cached services and summarize scoped booking streams. '
                'Loading and errors stay explicit with AsyncValue. Repository changes refresh '
                'booking details and availability; provider overrides make the same flows testable.',
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Portfolio Project',
            body:
                'Built by a junior Flutter developer as a skills demonstration. '
                'Architecture: feature-oriented with repository pattern and '
                'Riverpod dependency injection.',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.catalog),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Browse Services'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF007A7A), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
