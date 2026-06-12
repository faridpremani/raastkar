// ── Remote Config Service ──
// File: C:\Users\rahim\raastkar2\lib\services\remote_config_service.dart
// This fetches config from backend on app start and caches it

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfig {
  static const String _baseUrl = 'https://raastkar-backend.vercel.app';
  static Map<String, dynamic> _config = {};
  static bool _loaded = false;

  // ── Fetch on app startup ──
  static Future<void> fetch() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/remote-config'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['config'] != null) {
          _config = data['config'] as Map<String, dynamic>;
          _loaded = true;
          // Cache locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('remote_config', json.encode(_config));
        }
      }
    } catch (e) {
      // Use cached config if network fails
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('remote_config');
        if (cached != null) {
          _config = json.decode(cached) as Map<String, dynamic>;
          _loaded = true;
        }
      } catch (_) {}
    }
  }

  // ── Getters ──

  static bool get appEnabled =>
      _config['app_enabled'] as bool? ?? true;

  static bool get maintenanceMode =>
      _config['maintenance_mode'] as bool? ?? false;

  static String get maintenanceMessage =>
      _config['maintenance_message'] as String? ??
      'App is under maintenance. Back soon!';

  static bool get showAnnouncement =>
      _config['show_announcement'] as bool? ?? false;

  static String get announcementTitle =>
      _config['announcement_title'] as String? ?? '';

  static String get announcementMessage =>
      _config['announcement_message'] as String? ?? '';

  static String get announcementColorHex =>
      _config['announcement_color'] as String? ?? '#2E7D52';

  static Color get announcementColor {
    try {
      final hex = announcementColorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2E7D52);
    }
  }

  static bool isFeatureEnabled(String feature) {
    final features = _config['features'] as Map<String, dynamic>?;
    return features?[feature] as bool? ?? true;
  }

  static int getCreditCost(String feature) {
    final costs = _config['credit_costs'] as Map<String, dynamic>?;
    return (costs?[feature] as num?)?.toInt() ?? 1;
  }

  static String get appTagline =>
      _config['app_tagline'] as String? ?? 'AgriGPT for Farmers';

  static String get supportPhone =>
      _config['support_phone'] as String? ?? '03002678621';

  static bool get forceUpdate =>
      _config['force_update'] as bool? ?? false;

  static String get minVersion =>
      _config['min_version'] as String? ?? '1.0.0';

  static String get updateUrl =>
      _config['update_url'] as String? ??
      'https://play.google.com/store/apps/details?id=com.raastkar.farming';

  static String get updateMessage =>
      _config['update_message'] as String? ??
      'A new version is available. Please update to continue.';
}