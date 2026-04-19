import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _storageService;

  ThemeModeNotifier(this._storageService) : super(ThemeMode.light) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _storageService.getThemeMode();
    switch (saved) {
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
        state = ThemeMode.system;
        break;
      case 'light':
      default:
        state = ThemeMode.light;
        break;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;
    await _storageService.saveThemeMode(_serialize(themeMode));
  }

  static String _serialize(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }
}
