import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tr.dart';

class LanguageService extends ChangeNotifier {
  Locale _locale = const Locale('en');
  String _currentLangName = 'English';

  Locale get locale => _locale;
  String get currentLangName => _currentLangName;

  static const List<Map<String, dynamic>> supportedLanguages = [
    {
      'name': 'English',
      'nativeName': 'English',
      'locale': Locale('en'),
      'flag': '🇺🇸',
    },
    {
      'name': 'Urdu',
      'nativeName': 'اردو',
      'locale': Locale('ur'),
      'flag': '🇵🇰',
    },
    {
      'name': 'Sindhi',
      'nativeName': 'سنڌي',
      'locale': Locale('ur'),
      'flag': '🇵🇰',
    },
    {
      'name': 'Punjabi',
      'nativeName': 'ਪੰਜਾਬੀ',
      'locale': Locale('en'),
      'flag': '🇵🇰',
    },
    {
      'name': 'Pashto',
      'nativeName': 'پښتو',
      'locale': Locale('ur'),
      'flag': '🇵🇰',
    },
    {
      'name': 'Arabic',
      'nativeName': 'العربية',
      'locale': Locale('ar'),
      'flag': '🇸🇦',
    },
  ];

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode =
        prefs.getString('language_code') ?? 'en';
    final langName =
        prefs.getString('lang_name') ?? 'English';
    _locale = Locale(langCode);
    _currentLangName = langName;
    Tr.setLanguage(langName);
    notifyListeners();
  }

  Future<void> loadSavedLanguageFull() async {
    await loadSavedLanguage();
  }

  Future<void> changeLanguage(
      Locale locale, String langName) async {
    _locale = locale;
    _currentLangName = langName;
    Tr.setLanguage(langName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'language_code', locale.languageCode);
    await prefs.setString('lang_name', langName);
    notifyListeners();
  }

  bool get isRTL =>
      _locale.languageCode == 'ur' ||
      _locale.languageCode == 'ar';
}