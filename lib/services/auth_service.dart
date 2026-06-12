import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl = 'https://raastkar-backend.vercel.app';

  static Map<String, dynamic>? currentUser;
  static String? authToken;

  // ── No serverClientId — fixes error code 10 ──
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userStr = prefs.getString('auth_user');
      if (token != null && userStr != null && userStr.isNotEmpty) {
        authToken = token;
        currentUser = json.decode(userStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadFromStorage error: $e');
    }
  }

  static Future<void> saveToStorage(String token, Map<String, dynamic> user, {bool isNewUser = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_user', json.encode(user));
      await prefs.setString('plan_name', user['plan']?.toString() ?? 'Free Trial');
      await prefs.setString('user_country', user['country']?.toString() ?? 'PK');

      final existingUserId = prefs.getString('user_id') ?? '';
      final newUserId = user['id']?.toString() ?? '';
      final bool isSameUser = existingUserId == newUserId && existingUserId.isNotEmpty;
      await prefs.setString('user_id', newUserId);

      final serverTotal = (user['credits'] as num?)?.toInt() ?? 10;

      if (isNewUser) {
        await prefs.setInt('credits_total', serverTotal);
        await prefs.setInt('credits_used', 0);
      } else if (!isSameUser) {
        await prefs.setInt('credits_total', serverTotal);
        await prefs.setInt('credits_used', 0);
      } else {
        final existingTotal = prefs.getInt('credits_total') ?? 0;
        if (serverTotal > existingTotal) {
          await prefs.setInt('credits_total', serverTotal);
        }
      }

      authToken = token;
      currentUser = user;
    } catch (e) {
      debugPrint('saveToStorage error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      if (await _googleSignIn.isSignedIn()) await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
      await prefs.setString('plan_name', 'Free Trial');
      authToken = null;
      currentUser = null;
    } catch (e) {
      debugPrint('logout error: $e');
    }
  }

  static bool get isLoggedIn => authToken != null && currentUser != null;

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String country,
    String idType = '',
    String idNumber = '',
    String idImage = '',
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
        'name': name.trim(),
        'country': country,
      };
      if (idType.isNotEmpty) body['idType'] = idType;
      if (idNumber.isNotEmpty) body['idNumber'] = idNumber;
      if (idImage.isNotEmpty) body['idImage'] = idImage;

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null && data['user'] != null) {
        await saveToStorage(data['token'] as String, data['user'] as Map<String, dynamic>, isNewUser: true);
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim().toLowerCase(), 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404 || response.body.trimLeft().startsWith('<')) {
        return {'success': false, 'error': 'Server error. Please check your connection.'};
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null && data['user'] != null) {
        await saveToStorage(data['token'] as String, data['user'] as Map<String, dynamic>, isNewUser: false);
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ── Google Login — no serverClientId needed ──
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      debugPrint('🔄 Starting Google Sign-In...');
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in cancelled'};
      }

      debugPrint('✅ Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Use accessToken first — works without serverClientId
      final String tokenToSend = googleAuth.accessToken ?? googleAuth.idToken ?? '';
      if (tokenToSend.isEmpty) {
        return {'success': false, 'error': 'Google authentication failed — no token received'};
      }

      final prefs = await SharedPreferences.getInstance();
      final country = prefs.getString('user_country') ?? 'PK';

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken':     googleAuth.idToken ?? '',
          'accessToken': googleAuth.accessToken ?? '',
          'email':       googleUser.email,
          'name':        googleUser.displayName ?? '',
          'picture':     googleUser.photoUrl ?? '',
          'country':     country,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Google Backend: ${response.statusCode} ${response.body.substring(0, 100)}');

      if (response.statusCode == 404 || response.body.isEmpty || response.body.trimLeft().startsWith('<')) {
        return {'success': false, 'error': 'Server error. Please try again.'};
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null && data['user'] != null) {
        await saveToStorage(
          data['token'] as String,
          data['user'] as Map<String, dynamic>,
          isNewUser: data['isNewUser'] == true,
        );
      }
      return data;
    } catch (e) {
      debugPrint('❌ loginWithGoogle error: $e');
      return {'success': false, 'error': 'Google login error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      if (authToken == null) return {'success': false, 'error': 'Not logged in'};
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        final serverTotal = (user['credits_total'] as num?)?.toInt() ?? (user['credits'] as num?)?.toInt() ?? 0;
        final existingTotal = prefs.getInt('credits_total') ?? 0;
        if (serverTotal > existingTotal) await prefs.setInt('credits_total', serverTotal);
        currentUser = user;
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String country,
    required String farmLocation,
  }) async {
    try {
      if (authToken == null) return {'success': false, 'error': 'Not logged in'};
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: authHeaders,
        body: json.encode({'name': name, 'phone': phone, 'country': country, 'farmLocation': farmLocation}),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['user'] != null) {
        currentUser = data['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', json.encode(currentUser));
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (authToken == null) return {'success': false, 'error': 'Not logged in'};
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/change-password'),
        headers: authHeaders,
        body: json.encode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 15));
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  static Future<bool> useCredit(BuildContext context, {int amount = 1, String featureName = 'this feature'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getInt('credits_used') ?? 0;
      final total = prefs.getInt('credits_total') ?? 0;
      final remaining = total - used;

      if (remaining < amount) {
        if (context.mounted) _showNoCreditsDialog(context, amount, remaining, featureName: featureName);
        return false;
      }
      await prefs.setInt('credits_used', used + amount);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getRemaining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getInt('credits_total') ?? 0) - (prefs.getInt('credits_used') ?? 0);
    } catch (e) {
      return 0;
    }
  }

  static Future<void> addCredits(int amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('credits_total', (prefs.getInt('credits_total') ?? 0) + amount);
    } catch (e) {
      debugPrint('addCredits error: $e');
    }
  }

  static void _showNoCreditsDialog(BuildContext context, int required, int remaining, {String featureName = 'this feature'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFFFEBEE), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.credit_card_off, size: 44, color: Colors.red)),
              const SizedBox(height: 12),
              const Text('Credits Finished!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              Text(remaining == 0 ? 'You have no credits left' : 'Need $required but have $remaining',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Text('$featureName needs $required credit${required > 1 ? 's' : ''}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/credits'); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D52),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Buy Credits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              )),
            ]),
          ])),
        ]),
      ),
    );
  }
}