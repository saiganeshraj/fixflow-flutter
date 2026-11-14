import 'package:flutter/material.dart';

import '../../features/bookings/models.dart';

/// Reusable status chip with accessible colour + icon — never color-alone.
class StatusChip extends StatelessWidget {
  final BookingStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config[status]!;
    return Semantics(
      label: 'Booking status: ${status.displayLabel}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 13, color: config.textColor),
            const SizedBox(width: 4),
            Text(
              status.displayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: config.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _config = {
    BookingStatus.requested: _ChipConfig(
      bgColor: Color(0xFFFFF3CD),
      borderColor: Color(0xFFFFD700),
      textColor: Color(0xFF7A5A00),
      icon: Icons.hourglass_top_rounded,
    ),
    BookingStatus.accepted: _ChipConfig(
      bgColor: Color(0xFFD0EAF7),
      borderColor: Color(0xFF5BAFD6),
      textColor: Color(0xFF1A5A7A),
      icon: Icons.check_circle_outline_rounded,
    ),
    BookingStatus.enRoute: _ChipConfig(
      bgColor: Color(0xFFE8F4F0),
      borderColor: Color(0xFF4CAAA9),
      textColor: Color(0xFF1A6060),
      icon: Icons.directions_car_outlined,
    ),
    BookingStatus.inProgress: _ChipConfig(
      bgColor: Color(0xFFFFF0E0),
      borderColor: Color(0xFFF39C12),
      textColor: Color(0xFF7A4A00),
      icon: Icons.build_circle_outlined,
    ),
    BookingStatus.completed: _ChipConfig(
      bgColor: Color(0xFFD4EDDA),
      borderColor: Color(0xFF27AE60),
      textColor: Color(0xFF1A6B40),
      icon: Icons.task_alt_rounded,
    ),
    BookingStatus.cancelled: _ChipConfig(
      bgColor: Color(0xFFF8D7DA),
      borderColor: Color(0xFFDC3545),
      textColor: Color(0xFF721C24),
      icon: Icons.cancel_outlined,
    ),
  };
}

class _ChipConfig {
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  const _ChipConfig({
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });
}
