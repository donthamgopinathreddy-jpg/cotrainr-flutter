import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    
    _locale = Locale(languageCode);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('❌ [LANGUAGE] Error saving language: $e');
    }
    
    // Notify listeners after saving to ensure state is persisted
    notifyListeners();
    print('✅ [LANGUAGE] Language changed to: $languageCode');
  }

  String getLanguageName(String code) {
    const languageNames = {
      'en': 'English',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'te': 'Telugu',
      'mr': 'Marathi',
      'ta': 'Tamil',
      'ur': 'Urdu',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'or': 'Odia',
      'pa': 'Punjabi',
      'ml': 'Malayalam',
      'as': 'Assamese',
      'ne': 'Nepali',
      'si': 'Sinhala',
      'sa': 'Sanskrit',
      'kok': 'Konkani',
      'mai': 'Maithili',
      'mni': 'Manipuri',
      'sat': 'Santali',
    };
    return languageNames[code] ?? 'English';
  }
}



