import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _showSizeFieldKey = 'settings.show_size_field';
const _lowStockDefaultKey = 'settings.low_stock_default';

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
