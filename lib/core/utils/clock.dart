import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable Clock interface to eliminate direct DateTime.now() calls.
abstract interface class AppClock {
  DateTime now();
}

/// System wall clock implementation.
final class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => DateTime.now();
}

/// Fake clock for deterministic unit and widget testing.
final class FakeAppClock implements AppClock {
  FakeAppClock(this._current);

  DateTime _current;

  @override
  DateTime now() => _current;

  void set(DateTime dt) => _current = dt;

  void advance(Duration duration) => _current = _current.add(duration);
}

final appClockProvider = Provider<AppClock>((ref) => const SystemAppClock());
