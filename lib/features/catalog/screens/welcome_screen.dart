import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/brand.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: paper,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 22 : 56,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    child: Row(
                      children: [
                        const BrandMark(),
                        const Spacer(),
                        if (MediaQuery.sizeOf(context).width > 600)
                          TextButton(
                            onPressed: () => context.go(AppRoutes.about),
                            child: const Text('The project'),
                          ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD4DDCF)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PORTFOLIO DEMO',
                            style: TextStyle(
                              fontSize: 10,
                              color: ink,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 52),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 850;
                      return wide
                          ? Row(
                              children: [
                                Expanded(child: _Intro(wide: wide)),
                                const SizedBox(width: 48),
                                const Expanded(child: _HeroScene(height: 480)),
                              ],
                            )
                          : Column(
                              children: [
                                _Intro(wide: wide),
                                const SizedBox(height: 36),
                                const _HeroScene(height: 355),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFDDE2D6)),
                        bottom: BorderSide(color: Color(0xFFDDE2D6)),
                      ),
                    ),
                    child: const Wrap(
                      spacing: 38,
                      runSpacing: 20,
                      children: [
                        _Promise(
                          Icons.receipt_long_outlined,
                          'Clear, fixed prices',
                        ),
                        _Promise(
                          Icons.schedule_rounded,
                          'A time that suits you',
                        ),
                        _Promise(Icons.route_outlined, 'Every step, in view'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  const Eyebrow('A little care goes a long way'),
                  const SizedBox(height: 12),
                  Text(
                    'Less on your list.\nMore life in your home.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 700 ? 3 : 1;
                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          for (final item in const [
                            (
                              '01',
                              'Find your fix',
                              'Explore plumbing, electrical and cleaning services with clear, fixed prices.',
                              Icons.search_rounded,
                            ),
                            (
                              '02',
                              'Make it your time',
                              'Choose an available hour and add your address. We assign an eligible technician.',
                              Icons.calendar_month_outlined,
                            ),
                            (
                              '03',
                              'Follow every step',
                              'Follow your booking from request to completion, then leave a review.',
                              Icons.task_alt_rounded,
                            ),
                          ])
                            SizedBox(
                              width:
                                  (constraints.maxWidth - (columns - 1) * 18) /
                                  columns,
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE2E7DD),
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(item.$4, color: ink),
                                        const Spacer(),
                                        Eyebrow(item.$1),
                                      ],
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      item.$2,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.$3,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: mutedInk,
                                        height: 1.65,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF0E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.science_outlined, color: ink, size: 22),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Made for exploring. This is a portfolio demo with fictional services. No account or payment is needed. Your demo bookings stay on this device.',
                            style: TextStyle(color: mutedInk, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'A little less hassle. A little more home.',
                            style: TextStyle(color: mutedInk, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.about),
                          child: const Text('About this Project'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Intro extends StatelessWidget {
  final bool wide;
  const _Intro({required this.wide});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('Home care, without the hassle'),
      const SizedBox(height: 22),
      Text(
        'Good homes.\nGreat care.\nAll sorted.',
        style: TextStyle(
          fontSize: wide ? 70 : 49,
          fontWeight: FontWeight.w700,
          height: 1.03,
          letterSpacing: -2.8,
          color: ink,
        ),
      ),
      const SizedBox(height: 24),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: const Text(
          'From that dripping tap to a fresh start. Book a service, pick your time, and get back to what feels like home.',
          style: TextStyle(fontSize: 16, color: mutedInk, height: 1.7),
        ),
      ),
      const SizedBox(height: 28),
      ElevatedButton.icon(
        onPressed: () => context.go(AppRoutes.catalog),
        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        iconAlignment: IconAlignment.end,
        label: const Text('Try the Demo'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'No sign-up. No payments. Just try it.',
        style: TextStyle(fontSize: 12, color: mutedInk),
      ),
    ],
  );
}

class _HeroScene extends StatelessWidget {
  final double height;
  const _HeroScene({required this.height});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: const ServiceArtwork(room: true),
          ),
        ),
        const Positioned(
          top: 25,
          left: 25,
          right: 25,
          child: Eyebrow('A happier home starts here', color: ink),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: ink.withAlpha(12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: lime,
                  foregroundColor: ink,
                  child: Icon(Icons.check_rounded),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your home, handled.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Book · Track · Relax',
                        style: TextStyle(fontSize: 12, color: mutedInk),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.north_east_rounded, color: ink),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Promise extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Promise(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: ink),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
    ],
  );
}
