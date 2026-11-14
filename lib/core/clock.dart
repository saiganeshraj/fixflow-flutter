import 'package:flutter/foundation.dart';

/// Injected clock so business logic is testable with controlled time.
abstract class Clock {
  DateTime get now;
}

/// Real wall-clock implementation.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime get now => DateTime.now().toUtc();
}

/// Test/demo clock with a fixed or controllable time.
class FakeClock implements Clock {
  DateTime _now;

  FakeClock(this._now);

  @override
  DateTime get now => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  void setNow(DateTime dt) {
    _now = dt;
  }
}

/// Service timezone: Asia/Kolkata = UTC+5:30.
const Duration kServiceTimezoneOffset = Duration(hours: 5, minutes: 30);

/// Convert a UTC [DateTime] to the service timezone (IST).
DateTime toServiceTimezone(DateTime utc) {
  final u = utc.toUtc();
  return u.add(kServiceTimezoneOffset);
}

/// Convert a service-timezone [DateTime] to UTC.
DateTime fromServiceTimezone(DateTime ist) {
  // Read civil fields, independent of the device's local timezone.
  return DateTime.utc(
    ist.year,
    ist.month,
    ist.day,
    ist.hour,
    ist.minute,
    ist.second,
    ist.millisecond,
    ist.microsecond,
  ).subtract(kServiceTimezoneOffset);
}

/// Returns true if [utc] is in the past relative to [now].
bool isPast(DateTime utc, DateTime now) => utc.isBefore(now);

/// Format a UTC DateTime as "Wed, 15 Nov · 10:00 AM IST".
String formatSlot(DateTime utcSlot) {
  final ist = toServiceTimezone(utcSlot);
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  final day = days[ist.weekday - 1];
  final month = months[ist.month - 1];
  final hour = ist.hour == 0
      ? 12
      : ist.hour > 12
      ? ist.hour - 12
      : ist.hour;
  final ampm = ist.hour < 12 ? 'AM' : 'PM';
  final min = ist.minute.toString().padLeft(2, '0');
  return '$day, ${ist.day} $month · $hour:$min $ampm IST';
}

/// Format a UTC DateTime as short date "15 Nov 2026".
String formatDate(DateTime utcSlot) {
  final ist = toServiceTimezone(utcSlot);
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
  return '${ist.day} ${months[ist.month - 1]} ${ist.year}';
}

/// Format paise as "₹1,250".
String formatPaise(int paise) {
  final sign = paise < 0 ? '-' : '';
  final amount = paise.abs();
  final fraction = amount % 100;
  final decimal = fraction == 0
      ? ''
      : '.${fraction.toString().padLeft(2, '0')}';
  return '$sign₹${_formatNumber(amount ~/ 100)}$decimal';
}

String _formatNumber(int n) {
  if (n < 1000) return n.toString();
  final s = n.toString();
  final len = s.length;
  final buf = StringBuffer();
  for (var i = 0; i < len; i++) {
    final posFromRight = len - 1 - i;
    if (i > 0) {
      if (posFromRight == 2 ||
          (posFromRight > 2 && (posFromRight - 2) % 2 == 0)) {
        buf.write(',');
      }
    }
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Generate available 60-minute slots for a service within the next 7 days,
/// 09:00–17:00 IST, excluding slots before [now].
List<DateTime> generateSlots(DateTime now) {
  final slots = <DateTime>[];
  final nowIst = toServiceTimezone(now);
  final todayIst = DateTime.utc(nowIst.year, nowIst.month, nowIst.day);

  for (int d = 0; d < 7; d++) {
    final dayIst = todayIst.add(Duration(days: d));
    for (int h = 9; h < 17; h++) {
      final slotIst = DateTime.utc(dayIst.year, dayIst.month, dayIst.day, h, 0);
      final slotUtc = fromServiceTimezone(slotIst);
      if (slotUtc.isAfter(now)) {
        slots.add(slotUtc);
      }
    }
  }
  return slots;
}

@immutable
class TimeSlot {
  final DateTime startUtc;
  final DateTime endUtc;

  const TimeSlot({required this.startUtc, required this.endUtc});

  bool overlaps(TimeSlot other) {
    return startUtc.isBefore(other.endUtc) && endUtc.isAfter(other.startUtc);
  }

  @override
  bool operator ==(Object other) =>
      other is TimeSlot && startUtc == other.startUtc && endUtc == other.endUtc;

  @override
  int get hashCode => Object.hash(startUtc, endUtc);
}
