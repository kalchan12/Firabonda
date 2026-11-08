import 'package:intl/intl.dart';

import 'business_logic.dart';

/// Represents a calendar period with exact local-calendar boundaries
/// converted to UTC instants for stable, deterministic queries.
final class PeriodRange {
  const PeriodRange({
    required this.period,
    required this.startUtc,
    required this.endUtc,
    required this.label,
    this.stepOffset = 0,
    this.firstDayOfWeek = DateTime.monday,
    this.referenceDate,
  });

  final Period period;
  final DateTime startUtc;
  final DateTime endUtc;
  final String label;
  final int stepOffset;
  final int firstDayOfWeek;
  final DateTime? referenceDate;

  /// Returns true if [instant] falls within [startUtc, endUtc).
  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(startUtc) && utc.isBefore(endUtc);
  }

  /// Constructs a calendar day period (Today, Yesterday, or offset days).
  factory PeriodRange.day({
    required DateTime now,
    int offsetDays = 0,
    bool isYesterday = false,
  }) {
    final local = now.toLocal();
    final effectiveOffset = isYesterday ? -1 : offsetDays;
    final startLocal = DateTime(
      local.year,
      local.month,
      local.day + effectiveOffset,
    );
    final endLocal = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day + 1,
    );

    final String label;
    if (effectiveOffset == 0) {
      label = 'Today';
    } else if (effectiveOffset == -1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(startLocal);
    }

    return PeriodRange(
      period: isYesterday ? Period.yesterday : Period.today,
      startUtc: startLocal.toUtc(),
      endUtc: endLocal.toUtc(),
      label: label,
      stepOffset: effectiveOffset,
      referenceDate: now,
    );
  }

  factory PeriodRange.today({required DateTime now}) {
    return PeriodRange.day(now: now, offsetDays: 0);
  }

  factory PeriodRange.yesterday({required DateTime now}) {
    return PeriodRange.day(now: now, isYesterday: true);
  }

  /// Constructs a calendar week period from the week's start day (Mon or Sun)
  /// to the start of the next week.
  factory PeriodRange.week({
    required DateTime now,
    int firstDayOfWeek = DateTime.monday,
    int offsetWeeks = 0,
  }) {
    final local = now.toLocal();
    final daysSinceStart = firstDayOfWeek == DateTime.sunday
        ? (local.weekday % 7)
        : ((local.weekday - firstDayOfWeek) % 7);

    final baseStartLocal = DateTime(
      local.year,
      local.month,
      local.day - daysSinceStart,
    );
    final startLocal = DateTime(
      baseStartLocal.year,
      baseStartLocal.month,
      baseStartLocal.day + (offsetWeeks * 7),
    );
    final endLocal = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day + 7,
    );

    final lastDayOfWeek = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day + 6,
    );

    final String label;
    if (offsetWeeks == 0) {
      label = 'This Week';
    } else {
      label =
          '${DateFormat('MMM d').format(startLocal)} - ${DateFormat('MMM d').format(lastDayOfWeek)}';
    }

    return PeriodRange(
      period: Period.week,
      startUtc: startLocal.toUtc(),
      endUtc: endLocal.toUtc(),
      label: label,
      stepOffset: offsetWeeks,
      firstDayOfWeek: firstDayOfWeek,
      referenceDate: now,
    );
  }

  /// Constructs a calendar month period (from 1st of month to 1st of next month).
  factory PeriodRange.month({required DateTime now, int offsetMonths = 0}) {
    final local = now.toLocal();
    final startLocal = DateTime(local.year, local.month + offsetMonths, 1);
    final endLocal = DateTime(startLocal.year, startLocal.month + 1, 1);

    final String label;
    if (offsetMonths == 0) {
      label = DateFormat('MMMM yyyy').format(startLocal);
    } else {
      label = DateFormat('MMMM yyyy').format(startLocal);
    }

    return PeriodRange(
      period: Period.month,
      startUtc: startLocal.toUtc(),
      endUtc: endLocal.toUtc(),
      label: label,
      stepOffset: offsetMonths,
      referenceDate: now,
    );
  }

  /// Constructs an unbounded All-time period.
  factory PeriodRange.all() {
    return PeriodRange(
      period: Period.all,
      startUtc: DateTime.utc(1970, 1, 1),
      endUtc: DateTime.utc(3000, 1, 1),
      label: 'All time',
    );
  }

  /// Constructs a custom date range [startDate, endDate] inclusive of endDate.
  factory PeriodRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final startLocal = DateTime(startDate.year, startDate.month, startDate.day);
    final endLocal = DateTime(endDate.year, endDate.month, endDate.day + 1);

    final label =
        '${DateFormat('MMM d, y').format(startLocal)} - ${DateFormat('MMM d, y').format(endDate)}';

    return PeriodRange(
      period: Period.custom,
      startUtc: startLocal.toUtc(),
      endUtc: endLocal.toUtc(),
      label: label,
    );
  }

  /// Steps backward to previous calendar unit (previous day, week, month).
  PeriodRange stepPrevious() {
    final now = referenceDate ?? DateTime.now();
    switch (period) {
      case Period.today:
      case Period.yesterday:
        return PeriodRange.day(now: now, offsetDays: stepOffset - 1);
      case Period.week:
        return PeriodRange.week(
          now: now,
          firstDayOfWeek: firstDayOfWeek,
          offsetWeeks: stepOffset - 1,
        );
      case Period.month:
        return PeriodRange.month(now: now, offsetMonths: stepOffset - 1);
      case Period.all:
      case Period.custom:
        return this;
    }
  }

  /// Steps forward to next calendar unit (next day, week, month).
  PeriodRange stepNext() {
    final now = referenceDate ?? DateTime.now();
    switch (period) {
      case Period.today:
      case Period.yesterday:
        return PeriodRange.day(now: now, offsetDays: stepOffset + 1);
      case Period.week:
        return PeriodRange.week(
          now: now,
          firstDayOfWeek: firstDayOfWeek,
          offsetWeeks: stepOffset + 1,
        );
      case Period.month:
        return PeriodRange.month(now: now, offsetMonths: stepOffset + 1);
      case Period.all:
      case Period.custom:
        return this;
    }
  }
}
