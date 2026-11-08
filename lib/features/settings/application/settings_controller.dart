import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _showSizeFieldKey = 'settings.show_size_field';
const _lowStockDefaultKey = 'settings.low_stock_default';
const _weekStartsOnKey = 'settings.week_starts_on';
const _targetProfitKey = 'settings.target_profit_percent';

final class SettingsController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_showSizeFieldKey) ?? false;
  }

  Future<void> setShowSizeField(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSizeFieldKey, value);
  }
}

final showSizeFieldProvider = NotifierProvider<SettingsController, bool>(
  SettingsController.new,
);

final class LowStockThresholdController extends Notifier<int> {
  @override
  int build() => 3;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_lowStockDefaultKey) ?? 3;
  }

  Future<void> setThreshold(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lowStockDefaultKey, value);
  }
}

final lowStockThresholdProvider =
    NotifierProvider<LowStockThresholdController, int>(
      LowStockThresholdController.new,
    );

/// Week start day: Monday (DateTime.monday = 1) or Sunday (DateTime.sunday = 7).
final class WeekStartsOnController extends Notifier<int> {
  @override
  int build() => DateTime.monday;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_weekStartsOnKey) ?? DateTime.monday;
  }

  Future<void> setWeekStartsOn(int day) async {
    state = day;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekStartsOnKey, day);
  }
}

final weekStartsOnProvider = NotifierProvider<WeekStartsOnController, int>(
  WeekStartsOnController.new,
);

/// Target profit percentage markup on cost (default 100%).
final class TargetProfitPercentController extends Notifier<int> {
  @override
  int build() => 100;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_targetProfitKey) ?? 100;
  }

  Future<void> setTargetProfit(int percent) async {
    state = percent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetProfitKey, percent);
  }
}

final targetProfitPercentProvider =
    NotifierProvider<TargetProfitPercentController, int>(
      TargetProfitPercentController.new,
    );
