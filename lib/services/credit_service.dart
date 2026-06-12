import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Convenience wrapper around AuthService.useCredit
/// Use this OR AuthService.useCredit — both work the same way.
class CreditService {
  static Future<int> getRemaining() async {
    return AuthService.getRemaining();
  }

  static Future<bool> useCredit(
    BuildContext context, {
    required int amount,
    required String featureName,
  }) async {
    return AuthService.useCredit(
      context,
      amount: amount,
      featureName: featureName,
    );
  }
}