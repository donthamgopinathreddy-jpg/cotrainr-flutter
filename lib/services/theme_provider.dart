import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModeKey = 'theme_mode';

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use system default
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
      
      // TODO: Optionally sync to Supabase profile
      // await _syncToSupabase(mode);
    } catch (e) {
      // Handle error silently, theme is already updated
    }
  }

  // Optional: Sync to Supabase
  // Future<void> _syncToSupabase(ThemeMode mode) async {
  //   try {
  //     final themeValue = mode == ThemeMode.system 
  //         ? 'system' 
  //         : mode == ThemeMode.light 
  //             ? 'light' 
  //             : 'dark';
  //     // await supabase.from('profiles').update({'theme_mode': themeValue});
  //   } catch (e) {
  //     // Handle error
  //   }
  // }
}
