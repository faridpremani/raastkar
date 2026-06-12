import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PricingService {
  static const String _baseUrl =
      'https://raastkar-backend.vercel.app';

  static Map<String, dynamic>? _cache;
  static DateTime? _lastFetch;

  static Future<Map<String, dynamic>> getPricing() async {
    final lastFetch = _lastFetch;
    final cache = _cache;
    if (cache != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch).inMinutes < 30) {
      return cache;
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/pricing'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['success'] == true &&
            decoded['pricing'] != null) {
          final pricingData = Map<String, dynamic>.from(
              decoded['pricing'] as Map<String, dynamic>);
          _cache = pricingData;
          _lastFetch = DateTime.now();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_pricing', json.encode(pricingData));
          return pricingData;
        }
      }
    } catch (e) {
      debugPrint('PricingService network error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_pricing');
      if (cached != null && cached.isNotEmpty) {
        final decoded = json.decode(cached);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('PricingService local cache error: $e');
    }

    return _defaultPricing();
  }

  static Future<Map<String, dynamic>> getPaymentInfo() async {
    try {
      final pricing = await getPricing();
      final info = pricing['payment_info'];
      if (info is Map<String, dynamic>) {
        return info;
      }
    } catch (e) {
      debugPrint('getPaymentInfo error: $e');
    }
    return _defaultPaymentInfo();
  }

  static Future<int> getCreditCost(String feature) async {
    try {
      final pricing = await getPricing();
      final costs = pricing['credit_costs'];
      if (costs is Map) {
        final cost = costs[feature];
        if (cost is int) return cost;
        if (cost is num) return cost.toInt();
      }
    } catch (e) {
      debugPrint('getCreditCost error: $e');
    }
    return 1;
  }

  static Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final pricing = await getPricing();
      final plansRaw = pricing['plans'];
      if (plansRaw is! Map) {
        return _defaultPlans();
      }

      final List<Map<String, dynamic>> plans = [];

      plansRaw.forEach((key, value) {
        if (value is! Map) return;
        final active = value['active'] ?? true;
        if (active == false) return;

        final pricePkr = (value['price_pkr'] as num?)?.toInt() ?? 0;
        final credits = (value['credits'] as num?)?.toInt() ?? 0;
        final days = (value['days'] as num?)?.toInt() ?? 30;

        plans.add({
          'key': key.toString(),
          'name': value['name']?.toString() ?? key.toString(),
          'credits': credits,
          'price_pkr': pricePkr,
          'days': days,
          'popular': value['popular'] ?? false,
          'isFree': pricePkr == 0,
          'description': value['description']?.toString() ?? '',
        });
      });

      if (plans.isEmpty) return _defaultPlans();

      plans.sort((a, b) {
        if (a['isFree'] == true) return -1;
        if (b['isFree'] == true) return 1;
        return (a['price_pkr'] as int).compareTo(b['price_pkr'] as int);
      });

      return plans;
    } catch (e) {
      debugPrint('getPlans error: $e');
      return _defaultPlans();
    }
  }

  static void clearCache() {
    _cache = null;
    _lastFetch = null;
  }

  static Map<String, dynamic> _defaultPricing() {
    return {
      'plans': {
        'free_trial': {
          'name': 'Free Trial',
          'credits': 5,
          'price_pkr': 0,
          'days': 30,
          'active': true,
          'popular': false,
          'description': '5 credits one time only',
        },
        'starter': {
          'name': 'Starter',
          'credits': 40,
          'price_pkr': 500,
          'days': 30,
          'active': true,
          'popular': false,
          'description': '40 credits per month',
        },
        'standard': {
          'name': 'Standard',
          'credits': 90,
          'price_pkr': 1000,
          'days': 30,
          'active': true,
          'popular': true,
          'description': '90 credits per month',
        },
        'pro': {
          'name': 'Pro',
          'credits': 200,
          'price_pkr': 2000,
          'days': 30,
          'active': true,
          'popular': false,
          'description': '200 credits per month',
        },
      },
      'credit_costs': {
        'crop_planner': 1,
        'dr_crop_diagnosis': 2,
        'dr_crop_photo': 3,
        'weather_ai': 1,
        'mandi_prices': 1,
        'carbon_credits': 1,
        'esg_score': 1,
        'roi_calculator': 1,
      },
      'payment_info': _defaultPaymentInfo(),
      'app_settings': {
        'free_trial_enabled': true,
        'maintenance_mode': false,
        'contact_email': 'support@raastkar.com',
        'app_version': '1.0.0',
      },
    };
  }

  static Map<String, dynamic> _defaultPaymentInfo() {
    return {
      'easypaisa_number': '03002678621',
      'jazzcash_number': '03002678621',
      'account_name': 'ACEM Pakistan',
      'bank_name': 'Bank Makramah Limited (Former Summit Bank Ltd)',
      'bank_account': '0236586002000049',
      'whatsapp': '03002678621',
    };
  }

  static List<Map<String, dynamic>> _defaultPlans() {
    return [
      {
        'key': 'free_trial',
        'name': 'Free Trial',
        'credits': 5,
        'price_pkr': 0,
        'days': 30,
        'popular': false,
        'isFree': true,
        'description': '5 credits one time only',
      },
      {
        'key': 'starter',
        'name': 'Starter',
        'credits': 40,
        'price_pkr': 500,
        'days': 30,
        'popular': false,
        'isFree': false,
        'description': '40 credits per month',
      },
      {
        'key': 'standard',
        'name': 'Standard',
        'credits': 90,
        'price_pkr': 1000,
        'days': 30,
        'popular': true,
        'isFree': false,
        'description': '90 credits per month',
      },
      {
        'key': 'pro',
        'name': 'Pro',
        'credits': 200,
        'price_pkr': 2000,
        'days': 30,
        'popular': false,
        'isFree': false,
        'description': '200 credits per month',
      },
    ];
  }
}