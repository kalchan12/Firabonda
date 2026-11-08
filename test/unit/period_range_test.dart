import 'package:firabonda/core/utils/clock.dart';
import 'package:firabonda/core/utils/period_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodRange calendar boundaries', () {
    test('Today encompasses exactly local 00:00:00 to tomorrow 00:00:00', () {
      final now = DateTime(2026, 11, 8, 14, 30, 0);
      final range = PeriodRange.today(now: now);

      // Same day start
      expect(range.contains(DateTime(2026, 11, 8, 0, 0, 0)), isTrue);
      // Same day end
      expect(range.contains(DateTime(2026, 11, 8, 23, 59, 59)), isTrue);
      // Previous day boundary 23:59:59
      expect(range.contains(DateTime(2026, 11, 7, 23, 59, 59)), isFalse);
      // Next day boundary 00:00:00
      expect(range.contains(DateTime(2026, 11, 9, 0, 0, 0)), isFalse);
    });

    test(
      'Yesterday encompasses exactly yesterday 00:00:00 to today 00:00:00',
      () {
        final now = DateTime(2026, 11, 8, 14, 30, 0);
        final range = PeriodRange.yesterday(now: now);

        expect(range.contains(DateTime(2026, 11, 7, 0, 0, 0)), isTrue);
        expect(range.contains(DateTime(2026, 11, 7, 23, 59, 59)), isTrue);
        expect(range.contains(DateTime(2026, 11, 6, 23, 59, 59)), isFalse);
        expect(range.contains(DateTime(2026, 11, 8, 0, 0, 0)), isFalse);
      },
    );

    test('Week start Monday correctly groups Monday to next Monday', () {
      // 2026-11-08 is Sunday (weekday 7). Monday of this week was 2026-11-02.
      final nowSunday = DateTime(2026, 11, 8, 18, 0, 0);
      final range = PeriodRange.week(
        now: nowSunday,
        firstDayOfWeek: DateTime.monday,
      );

      // Monday 00:00
      expect(range.contains(DateTime(2026, 11, 2, 0, 0, 0)), isTrue);
      // Sunday 23:59:59
      expect(range.contains(DateTime(2026, 11, 8, 23, 59, 59)), isTrue);
      // Previous Sunday 23:59:59
      expect(range.contains(DateTime(2026, 11, 1, 23, 59, 59)), isFalse);
      // Next Monday 00:00:00
      expect(range.contains(DateTime(2026, 11, 9, 0, 0, 0)), isFalse);
    });

    test('Week start Sunday correctly groups Sunday to next Sunday', () {
      // 2026-11-08 is Sunday (weekday 7). With Sunday start, this is day 0 of the new week!
      final nowSunday = DateTime(2026, 11, 8, 18, 0, 0);
      final range = PeriodRange.week(
        now: nowSunday,
        firstDayOfWeek: DateTime.sunday,
      );

      // Sunday 00:00
      expect(range.contains(DateTime(2026, 11, 8, 0, 0, 0)), isTrue);
      // Next Saturday 23:59:59
      expect(range.contains(DateTime(2026, 11, 14, 23, 59, 59)), isTrue);
      // Previous Saturday 23:59:59 (belongs to previous week)
      expect(range.contains(DateTime(2026, 11, 7, 23, 59, 59)), isFalse);
    });

    test('Month boundaries handle 1st to 1st including leap year February', () {
      // Leap year 2024 February
      final leapFeb = DateTime(2024, 2, 15, 12, 0);
      final febRange = PeriodRange.month(now: leapFeb);

      expect(febRange.contains(DateTime(2024, 2, 1, 0, 0, 0)), isTrue);
      expect(febRange.contains(DateTime(2024, 2, 29, 23, 59, 59)), isTrue);
      expect(febRange.contains(DateTime(2024, 3, 1, 0, 0, 0)), isFalse);
      expect(febRange.contains(DateTime(2024, 1, 31, 23, 59, 59)), isFalse);

      // Non-leap year 2025 February
      final nonLeapFeb = DateTime(2025, 2, 15, 12, 0);
      final nonLeapRange = PeriodRange.month(now: nonLeapFeb);
      expect(nonLeapRange.contains(DateTime(2025, 2, 28, 23, 59, 59)), isTrue);
      expect(nonLeapRange.contains(DateTime(2025, 3, 1, 0, 0, 0)), isFalse);
    });

    test('stepPrevious and stepNext step through calendar units cleanly', () {
      final now = DateTime(2026, 11, 8, 10, 0);
      final today = PeriodRange.today(now: now);
      final prevDay = today.stepPrevious();
      expect(prevDay.contains(DateTime(2026, 11, 7, 12, 0)), isTrue);
      expect(prevDay.contains(DateTime(2026, 11, 8, 12, 0)), isFalse);

      final nextDay = prevDay.stepNext();
      expect(nextDay.contains(DateTime(2026, 11, 8, 12, 0)), isTrue);
    });
  });

  group('FakeAppClock injection', () {
    test('clock can be frozen and advanced deterministically', () {
      final clock = FakeAppClock(DateTime(2026, 11, 8, 23, 59, 58));
      final today = PeriodRange.today(now: clock.now());
      expect(today.contains(clock.now()), isTrue);

      // Advance by 3 seconds past midnight
      clock.advance(const Duration(seconds: 3));
      expect(today.contains(clock.now()), isFalse);

      final newToday = PeriodRange.today(now: clock.now());
      expect(newToday.contains(clock.now()), isTrue);
      expect(newToday.label, 'Today');
    });
  });
}
