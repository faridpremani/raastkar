import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/tr.dart';

// ─── Currency Service ───
class CurrencyService {
  static const Map<String, Map<String, dynamic>> _currencies = {
    'PK': {'code': 'PKR', 'symbol': '₨', 'rate': 280.0, 'name': 'Pakistani Rupee'},
    'US': {'code': 'USD', 'symbol': '\$', 'rate': 1.0, 'name': 'US Dollar'},
    'GB': {'code': 'GBP', 'symbol': '£', 'rate': 0.79, 'name': 'British Pound'},
    'AE': {'code': 'AED', 'symbol': 'د.إ', 'rate': 3.67, 'name': 'UAE Dirham'},
    'SA': {'code': 'SAR', 'symbol': '﷼', 'rate': 3.75, 'name': 'Saudi Riyal'},
    'AU': {'code': 'AUD', 'symbol': 'A\$', 'rate': 1.53, 'name': 'Australian Dollar'},
    'CA': {'code': 'CAD', 'symbol': 'C\$', 'rate': 1.36, 'name': 'Canadian Dollar'},
    'IN': {'code': 'INR', 'symbol': '₹', 'rate': 83.0, 'name': 'Indian Rupee'},
    'BD': {'code': 'BDT', 'symbol': '৳', 'rate': 110.0, 'name': 'Bangladeshi Taka'},
    'EU': {'code': 'EUR', 'symbol': '€', 'rate': 0.92, 'name': 'Euro'},
  };

  static Map<String, dynamic> getCurrencyForCountry(String countryCode) {
    return _currencies[countryCode] ?? _currencies['PK']!;
  }

  static String convertFromUSD(double usdAmount, String countryCode) {
    final currency = getCurrencyForCountry(countryCode);
    final rate = currency['rate'] as double;
    final symbol = currency['symbol'] as String;
    final converted = usdAmount * rate;
    if (countryCode == 'US') return '\$${usdAmount.toStringAsFixed(0)}';
    if (converted >= 1000) return '$symbol${converted.toStringAsFixed(0)}';
    return '$symbol${converted.toStringAsFixed(1)}';
  }
}

// ─── Coupon Service ───
class CouponService {
  static const String baseUrl = 'https://raastkar-backend.vercel.app';
  static const List<String> _fallbackCoupons = [
    'RAAST70', 'FARM70', 'WELCOME70', 'KISAN70', 'GREEN70',
  ];

  static Future<Map<String, dynamic>> validateCoupon(String code) async {
    final upperCode = code.trim().toUpperCase();
    if (upperCode.isEmpty) return {'success': false, 'error': 'Please enter a coupon code'};
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final response = await http.post(
        Uri.parse('$baseUrl/api/coupon/validate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': upperCode, 'userId': userId}),
      ).timeout(const Duration(seconds: 8));
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return {
          'success': true,
          'discount': (data['discount'] as num?)?.toDouble() ?? 0.0,
          'dollarOff': (data['dollarOff'] as num?)?.toDouble() ?? 0.0,
          'discountType': data['discountType'] ?? 'percent',
          'code': upperCode,
          'dealName': data['dealName'] ?? 'Special Offer',
          'message': data['message'] ?? 'Coupon applied!',
        };
      } else {
        return _validateFallback(upperCode);
      }
    } catch (e) {
      return _validateFallback(upperCode);
    }
  }

  static Future<Map<String, dynamic>> _validateFallback(String upperCode) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCoupons = prefs.getStringList('used_coupons') ?? [];
    if (!_fallbackCoupons.contains(upperCode)) return {'success': false, 'error': 'Invalid coupon code'};
    if (usedCoupons.contains(upperCode)) return {'success': false, 'error': 'You have already used this coupon'};
    return {
      'success': true, 'discount': 70.0, 'dollarOff': 0.0,
      'discountType': 'percent', 'code': upperCode,
      'dealName': 'Special Discount', 'message': '🎉 70% discount applied!',
    };
  }

  static Future<void> markCouponUsed(String code) async {
    final upperCode = code.toUpperCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      await http.post(
        Uri.parse('$baseUrl/api/coupon/use'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': upperCode, 'userId': userId}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) { debugPrint('markCouponUsed error: $e'); }
    final prefs = await SharedPreferences.getInstance();
    final usedCoupons = prefs.getStringList('used_coupons') ?? [];
    if (!usedCoupons.contains(upperCode)) {
      usedCoupons.add(upperCode);
      await prefs.setStringList('used_coupons', usedCoupons);
    }
  }
}

// ─── Subscription Screen ───
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnnual = false;
  int _creditsUsed = 0;
  int _creditsTotal = 10;
  String _planName = 'Free Trial';
  int _daysLeft = 30;
  String _userCountry = 'PK';
  Map<String, dynamic> _currency = {};
  bool _loadingCurrency = true;

  static const String baseUrl = 'https://raastkar-backend.vercel.app';

  List<Map<String, dynamic>> _plans = [
    {
      'key': 'individual', 'name': 'Individual',
      'subtitle': 'Solo entrepreneurs under 10 acres',
      'farmSize': 'Under 10 acres', 'credits': 30,
      'price_monthly': 5.0, 'price_annual': 50.0,
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF2E7D52), const Color(0xFF4CAF50)],
      'emoji': '🌱', 'popular': false,
      'features': ['30 credits per month', 'AI Crop Planner', 'Dr Crop Diagnosis', 'Weather forecasts', 'Mandi prices', 'Email support'],
    },
    {
      'key': 'midsize', 'name': 'Mid Size',
      'subtitle': 'Mid size farmers 10-30 acres',
      'farmSize': '10 - 30 acres', 'credits': 50,
      'price_monthly': 10.0, 'price_annual': 100.0,
      'color': const Color(0xFF2196F3),
      'gradient': [const Color(0xFF1565C0), const Color(0xFF2196F3)],
      'emoji': '🚜', 'popular': true,
      'features': ['50 credits per month', 'All Individual features', 'Carbon Credits calculator', 'ESG Score tracking', 'ROI Calculator', 'Priority WhatsApp support'],
    },
    {
      'key': 'large', 'name': 'Large',
      'subtitle': 'Large farmers 30-100 acres',
      'farmSize': '30 - 100 acres', 'credits': 100,
      'price_monthly': 20.0, 'price_annual': 200.0,
      'color': const Color(0xFFFF9800),
      'gradient': [const Color(0xFFE65100), const Color(0xFFFF9800)],
      'emoji': '🌾', 'popular': false,
      'features': ['100 credits per month', 'All Mid Size features', 'Multiple farm profiles', 'Advanced analytics', 'Export reports PDF', 'Dedicated account manager'],
    },
    {
      'key': 'mega', 'name': 'Mega',
      'subtitle': 'Mega farmers 100+ acres',
      'farmSize': '100+ acres', 'credits': 200,
      'price_monthly': 50.0, 'price_annual': 500.0,
      'color': const Color(0xFF9C27B0),
      'gradient': [const Color(0xFF4A148C), const Color(0xFF9C27B0)],
      'emoji': '🏆', 'popular': false,
      'features': ['200 credits per month', 'All Large features', 'API access', 'Custom integrations', 'Bulk data export', 'Priority dedicated support', 'Custom reports'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString('user_country') ?? 'PK';
    final currency = CurrencyService.getCurrencyForCountry(country);
    setState(() {
      _creditsUsed  = prefs.getInt('credits_used')  ?? 0;
      _creditsTotal = prefs.getInt('credits_total') ?? 10;
      _planName     = prefs.getString('plan_name')  ?? 'Free Trial';
      _daysLeft     = prefs.getInt('days_left')     ?? 30;
      _userCountry  = country;
      _currency     = currency;
      _loadingCurrency = false;
    });
    _loadPricingFromServer();
  }

  Future<void> _loadPricingFromServer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/pricing'))
          .timeout(const Duration(seconds: 10));
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        List<dynamic>? serverPlans;
        if (data['plans'] != null) {
          serverPlans = data['plans'] as List<dynamic>;
        } else if (data['pricing'] != null) {
          final pricingData = data['pricing'] as Map<String, dynamic>;
          final plansMap = pricingData['plans'] as Map<String, dynamic>? ?? {};
          final keyMap = {'starter': 'individual', 'standard': 'midsize', 'pro': 'large'};
          serverPlans = plansMap.entries.map((e) {
            final mappedKey = keyMap[e.key] ?? e.key;
            final plan = e.value as Map<String, dynamic>;
            return {
              'key': mappedKey,
              'credits': plan['credits'],
              'monthly': plan['price_pkr'] != null ? (plan['price_pkr'] as num) / 280.0 : null,
            };
          }).toList();
        }
        if (serverPlans != null) {
          for (final serverPlan in serverPlans) {
            final key = serverPlan['key'] as String?;
            if (key == null) continue;
            final idx = _plans.indexWhere((p) => p['key'] == key);
            if (idx >= 0) {
              setState(() {
                if (serverPlan['credits'] != null) _plans[idx]['credits'] = (serverPlan['credits'] as num).toInt();
                if (serverPlan['monthly'] != null) _plans[idx]['price_monthly'] = (serverPlan['monthly'] as num).toDouble();
                if (serverPlan['annual']  != null) _plans[idx]['price_annual']  = (serverPlan['annual']  as num).toDouble();
              });
            }
          }
        }
      }
    } catch (e) { debugPrint('Pricing load error: $e'); }
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _showPaymentSheet(Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _PaymentSheet(
          plan: plan, isAnnual: _isAnnual, userCountry: _userCountry,
          currency: _currency, baseUrl: baseUrl, scrollController: scrollController,
          onSuccess: (String couponCode) async {
            if (couponCode.isNotEmpty) await CouponService.markCouponUsed(couponCode);
            Navigator.pop(context);
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 70, height: 70,
                      decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, color: Color(0xFF2E7D52), size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text('Payment Submitted!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCC02)),
                      ),
                      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.access_time, color: Color(0xFFFF8F00), size: 18),
                          SizedBox(width: 8),
                          Text('Verification Pending',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8F00))),
                        ]),
                        SizedBox(height: 6),
                        Text(
                          'Our team will verify your payment and add credits within 15-30 minutes.',
                          style: TextStyle(color: Color(0xFF795548), fontSize: 12),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('What happens next:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(height: 6),
                        Text('1. Admin verifies your transaction ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('2. Credits are added to your account', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('3. You can start using all features!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text('Need help? WhatsApp: 03002678621',
                        style: TextStyle(color: Color(0xFF2E7D52), fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D52),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('OK, I Will Wait',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF071F10), Color(0xFF1B6B3A), Color(0xFF2E7D52)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('RaastKar Credits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              Text('AgriGPT for Farmers', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
      body: Column(children: [
        _buildCreditsMeter(),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2E7D52),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2E7D52),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: 'Buy Credits'), Tab(text: 'My Account')],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabController, children: [_buildPlansTab(), _buildAccountTab()])),
      ]),
    );
  }

  Widget _buildCreditsMeter() {
    final int remaining = _creditsTotal - _creditsUsed;
    final double progress = _creditsTotal > 0 ? remaining / _creditsTotal : 0;
    Color meterColor = progress > 0.5 ? const Color(0xFF2E7D52) : progress > 0.2 ? Colors.orange : Colors.red;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_planName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$_daysLeft days remaining', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: meterColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: meterColor.withValues(alpha: 0.3))),
            child: Text('$remaining credits', style: TextStyle(color: meterColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(meterColor), minHeight: 12)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$_creditsUsed used', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text('$_creditsTotal total', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildPlansTab() {
    if (_loadingCurrency) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D52)));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        // Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: !_isAnnual ? const Color(0xFF2E7D52) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text('Monthly', textAlign: TextAlign.center, style: TextStyle(color: !_isAnnual ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: _isAnnual ? const Color(0xFF2E7D52) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Annual', style: TextStyle(color: _isAnnual ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _isAnnual ? Colors.orange : Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text('Save 17%', style: TextStyle(color: _isAnnual ? Colors.white : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 12),

        // Free Trial
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2E7D52).withValues(alpha: 0.3))),
          child: const Row(children: [
            Text('🎁', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Free Trial — 10 Credits', style: TextStyle(color: Color(0xFF2E7D52), fontWeight: FontWeight.bold, fontSize: 13)),
              Text('New users get 10 free credits to try all features!', style: TextStyle(color: Color(0xFF2E7D52), fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // ── PLANS: 4 side-by-side on web, 1 per row on mobile ──
        if (kIsWeb)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _plans.map((plan) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PlanCard(
                  plan: plan,
                  isCurrentPlan: _planName == plan['name'],
                  isAnnual: _isAnnual,
                  userCountry: _userCountry,
                  currency: _currency,
                  onSelect: () => _showPaymentSheet(plan),
                ),
              ),
            )).toList(),
          )
        else
          ..._plans.map((plan) => _PlanCard(
            plan: plan,
            isCurrentPlan: _planName == plan['name'],
            isAnnual: _isAnnual,
            userCountry: _userCountry,
            currency: _currency,
            onSelect: () => _showPaymentSheet(plan),
          )),
        const SizedBox(height: 8),

        // Coupon hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
          child: const Row(children: [
            Icon(Icons.local_offer, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('🎟️ Have a coupon code? Apply it when selecting a plan for discounts!', style: TextStyle(color: Colors.orange, fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 16),

        // Payment Methods
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.payment, color: Color(0xFF2E7D52), size: 18),
              SizedBox(width: 8),
              Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            _paymentTile(emoji: '📱', name: 'EasyPaisa', number: '03002678621', accountName: 'ACEM Pakistan', color: Colors.green),
            const SizedBox(height: 8),
            _paymentTile(emoji: '📲', name: 'JazzCash', number: '03002678621', accountName: 'ACEM Pakistan', color: Colors.red),
            const SizedBox(height: 8),
            _paymentTile(emoji: '🏦', name: 'Bank Transfer', number: '0236586002000049', accountName: 'Bank Makramah Limited', color: Colors.blue, extra: 'Account: ACEM Pakistan'),

            const SizedBox(height: 8),
            _paymentTile(emoji: '🪙', name: 'USDT (TRC20)', number: 'TVDyxYnsgnyuoALC1J8N7kxPX5kgnSK5Lc', accountName: 'TRC20 network only', color: Colors.orange, extra: 'Send payment screenshot after transfer'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.chat, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('After payment send screenshot to WhatsApp: 03002678621', style: TextStyle(color: Colors.green, fontSize: 12))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _paymentTile({required String emoji, required String name, required String number, required String accountName, required Color color, String? extra}) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: number));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📋 $name copied!'), backgroundColor: const Color(0xFF2E7D52)));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(number, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold)),
            Text(accountName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (extra != null) Text(extra, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Icon(Icons.copy, color: color, size: 16),
        ]),
      ),
    );
  }

  Widget _buildAccountTab() {
    final int remaining = _creditsTotal - _creditsUsed;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Profile Card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D52)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text(_planName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatBadge(label: 'Remaining', value: '$remaining', color: remaining > 0 ? Colors.greenAccent : Colors.redAccent),
            _StatBadge(label: 'Used', value: '$_creditsUsed', color: Colors.white),
            _StatBadge(label: 'Total', value: '$_creditsTotal', color: Colors.white),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // Credits Per Feature
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💡 Credits Per Feature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...['🌾 Crop Planner AI = 1 credit', '🔬 Dr Crop Diagnosis = 2 credits', '📸 Photo Analysis = 3 credits', '🌤️ Weather AI = Free', '🏪 Mandi Prices = 1 credit', '🌿 Carbon Credits = 1 credit', '📊 ESG Score = 1 credit', '💰 ROI Calculator = 1 credit']
              .map((t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13)))),
        ]),
      ),
      const SizedBox(height: 16),

      // Plan Comparison
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📊 Plan Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
            children: [
              TableRow(decoration: const BoxDecoration(color: Color(0xFF2E7D52)), children: [_tableCell('Plan', isHeader: true), _tableCell('Credits', isHeader: true), _tableCell('Monthly', isHeader: true), _tableCell('Annual', isHeader: true)]),
              TableRow(children: [_tableCell('Free Trial'), _tableCell('10'), _tableCell('\$0'), _tableCell('\$0')]),
              TableRow(children: [_tableCell('Individual\n<10 acres'), _tableCell('30'), _tableCell('\$5'), _tableCell('\$50')]),
              TableRow(children: [_tableCell('Mid Size\n10-30 acres'), _tableCell('50'), _tableCell('\$10'), _tableCell('\$100')]),
              TableRow(children: [_tableCell('Large\n30-100 acres'), _tableCell('100'), _tableCell('\$20'), _tableCell('\$200')]),
              TableRow(children: [_tableCell('Mega\n100+ acres'), _tableCell('200'), _tableCell('\$50'), _tableCell('\$500')]),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Payment & Support
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.support_agent, color: Color(0xFF2E7D52)), SizedBox(width: 8), Text('Payment & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D52)))]),
          const SizedBox(height: 12),
          _paymentTile(emoji: '📱', name: 'EasyPaisa / JazzCash', number: '03002678621', accountName: 'ACEM Pakistan', color: Colors.green),
          const SizedBox(height: 8),
          _paymentTile(emoji: '🏦', name: 'Bank Transfer', number: '0236586002000049', accountName: 'Bank Makramah Limited', color: Colors.blue, extra: 'Account: ACEM Pakistan'),
          const SizedBox(height: 8),
          _paymentTile(emoji: '💬', name: 'WhatsApp Support', number: '03002678621', accountName: 'Send payment screenshot here', color: const Color(0xFF2E7D52)),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: isHeader ? Colors.white : Colors.black87)),
    );
  }
}

// ─── Plan Card ───
class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isCurrentPlan, isAnnual;
  final String userCountry;
  final Map<String, dynamic> currency;
  final VoidCallback onSelect;

  const _PlanCard({required this.plan, required this.isCurrentPlan, required this.isAnnual, required this.userCountry, required this.currency, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final Color color     = plan['color'] as Color;
    final bool isPopular  = plan['popular'] == true;
    final int credits     = plan['credits'] as int;
    final double monthlyUSD = plan['price_monthly'] as double;
    final double annualUSD  = plan['price_annual']  as double;
    final double displayUSD = isAnnual ? annualUSD / 12 : monthlyUSD;
    final double totalUSD   = isAnnual ? annualUSD : monthlyUSD;
    final String localPrice = CurrencyService.convertFromUSD(totalUSD, userCountry);
    final List<dynamic> gradient = plan['gradient'] as List<dynamic>;

    // On web use compact card layout
    final bool isWeb = kIsWeb;

    return Container(
      margin: EdgeInsets.only(bottom: isWeb ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCurrentPlan ? color : isPopular ? color.withValues(alpha: 0.5) : Colors.grey.shade200, width: isCurrentPlan || isPopular ? 2 : 1),
        boxShadow: [if (isPopular) BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        // Header gradient
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isWeb ? 12 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient.map((c) => c as Color).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                child: const Text('⭐ Popular', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            if (isCurrentPlan)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                child: const Text('✅ Current', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            Text(plan['emoji'] as String, style: TextStyle(fontSize: isWeb ? 28 : 40)),
            const SizedBox(height: 6),
            Text(plan['name'] as String, style: TextStyle(color: Colors.white, fontSize: isWeb ? 16 : 22, fontWeight: FontWeight.bold)),
            Text(plan['farmSize'] as String, style: TextStyle(color: Colors.white70, fontSize: isWeb ? 10 : 12)),
            const SizedBox(height: 4),
            Text('$credits credits/mo', style: TextStyle(color: Colors.white70, fontSize: isWeb ? 11 : 13)),
            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 10 : 20, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text('\$${displayUSD.toStringAsFixed(0)}', style: TextStyle(color: Colors.white, fontSize: isWeb ? 22 : 28, fontWeight: FontWeight.bold)),
                Text('per month', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                if (isAnnual)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                    child: Text('Save \$${(monthlyUSD * 12 - annualUSD).toStringAsFixed(0)}/yr', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                if (userCountry != 'US')
                  Text('≈ $localPrice', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          ]),
        ),

        // Features + button
        Padding(
          padding: EdgeInsets.all(isWeb ? 10 : 16),
          child: Column(children: [
            ...(plan['features'] as List<dynamic>).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(Icons.check_circle, color: color, size: isWeb ? 13 : 16),
                const SizedBox(width: 6),
                Expanded(child: Text(f.toString(), style: TextStyle(fontSize: isWeb ? 11 : 13))),
              ]),
            )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: isCurrentPlan
                  ? OutlinedButton(onPressed: null,
                      style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Current Plan', style: TextStyle(color: color, fontSize: isWeb ? 12 : 14)))
                  : ElevatedButton(onPressed: onSelect,
                      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Get ${plan['name']} — \$${totalUSD.toStringAsFixed(0)}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 11 : 14))),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Payment Sheet ───
class _PaymentSheet extends StatefulWidget {
  final Map<String, dynamic> plan;
  final bool isAnnual;
  final String userCountry;
  final Map<String, dynamic> currency;
  final String baseUrl;
  final ScrollController scrollController;
  final Function(String) onSuccess;

  const _PaymentSheet({required this.plan, required this.isAnnual, required this.userCountry, required this.currency, required this.baseUrl, required this.scrollController, required this.onSuccess});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _selectedMethod = 'EasyPaisa';
  final _txController     = TextEditingController();
  final _phoneController  = TextEditingController();
  final _couponController = TextEditingController();
  bool _isSubmitting = false, _isValidatingCoupon = false;
  String? _couponCode;
  double _discountPercent = 0, _dollarOff = 0;
  String _couponError = '', _couponDealName = '';
  Uint8List? _screenshotBytes;
  String? _screenshotBase64;
  final ImagePicker _picker = ImagePicker();

  double get _originalPriceUSD  => widget.isAnnual ? widget.plan['price_annual'] as double : widget.plan['price_monthly'] as double;
  double get _discountedPriceUSD {
    if (_discountPercent > 0) return _originalPriceUSD * (1 - _discountPercent / 100);
    if (_dollarOff > 0) return (_originalPriceUSD - _dollarOff).clamp(0, _originalPriceUSD);
    return _originalPriceUSD;
  }
  String get _localDiscountedPrice => CurrencyService.convertFromUSD(_discountedPriceUSD, widget.userCountry);
  String _getSavingsText() {
    if (_discountPercent > 0) return '${_discountPercent.toInt()}% off applied';
    if (_dollarOff > 0) return '\$${_dollarOff.toStringAsFixed(0)} off applied';
    return '';
  }

  final List<Map<String, dynamic>> _methods = [
    {'name': 'Credit / Debit Card', 'icon': Icons.credit_card,      'color': const Color(0xFF635BFF), 'popular': true},
    {'name': 'EasyPaisa',           'icon': Icons.phone_android,    'color': Colors.green,            'popular': true},
    {'name': 'JazzCash',            'icon': Icons.phone_android,    'color': Colors.red,              'popular': false},
    {'name': 'Bank Transfer',       'icon': Icons.account_balance,  'color': Colors.blue,             'popular': false},
    {'name': 'USDT Crypto',         'icon': Icons.currency_bitcoin, 'color': Colors.orange,           'popular': false},
  ];

  Future<void> _validateCoupon() async {
    if (_couponController.text.isEmpty) return;
    setState(() { _isValidatingCoupon = true; _couponError = ''; });
    final result = await CouponService.validateCoupon(_couponController.text);
    setState(() {
      _isValidatingCoupon = false;
      if (result['success'] == true) {
        _couponCode = result['code'] as String;
        _discountPercent = (result['discount'] as num?)?.toDouble() ?? 0.0;
        _dollarOff       = (result['dollarOff'] as num?)?.toDouble() ?? 0.0;
        _couponDealName  = result['dealName'] as String? ?? '';
        _couponError = '';
      } else {
        _couponCode = null; _discountPercent = 0; _dollarOff = 0;
        _couponError = result['error'] as String? ?? 'Invalid coupon';
      }
    });
  }

  Future<void> _pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() { _screenshotBytes = bytes; _screenshotBase64 = base64Encode(bytes); });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not access gallery'), backgroundColor: Colors.red));
    }
  }

  Future<void> _submitPayment() async {
    // ── Stripe Card Payment ──
    if (_selectedMethod == 'Credit / Debit Card') {
      await _payWithStripe();
      return;
    }

    // ── Manual Payment (EasyPaisa, JazzCash, Bank, USDT) ──
    if (_txController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Transaction ID'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      await http.post(Uri.parse('${widget.baseUrl}/api/payment/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId, 'planKey': widget.plan['key'], 'planName': widget.plan['name'],
          'billingCycle': widget.isAnnual ? 'annual' : 'monthly', 'method': _selectedMethod,
          'transactionId': _txController.text.trim(), 'phone': _phoneController.text.trim(),
          'amountUSD': _discountedPriceUSD, 'credits': widget.plan['credits'],
          'couponCode': _couponCode ?? '', 'discountPercent': _discountPercent, 'dollarOff': _dollarOff,
          'screenshot': _screenshotBase64 ?? '',
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) { debugPrint('Payment submit error: \$e'); }
    setState(() => _isSubmitting = false);
    widget.onSuccess(_couponCode ?? '');
  }

  Future<void> _payWithStripe() async {
    // flutter_stripe does NOT support web — show message instead
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💳 Card payment available on mobile app only. Please use EasyPaisa, JazzCash or Bank Transfer on web.'),
          backgroundColor: Color(0xFF1B5E20),
          duration: Duration(seconds: 4),
        ),
      );
      setState(() => _selectedMethod = 'EasyPaisa');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      // Step 1: Create payment intent on backend
      final intentResp = await http.post(
        Uri.parse('${widget.baseUrl}/api/stripe/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount':          _discountedPriceUSD,
          'currency':        'usd',
          'userId':          userId,
          'planKey':         widget.plan['key'],
          'planName':        widget.plan['name'],
          'billingCycle':    widget.isAnnual ? 'annual' : 'monthly',
          'couponCode':      _couponCode ?? '',
          'discountPercent': _discountPercent,
        }),
      ).timeout(const Duration(seconds: 15));

      final intentData = json.decode(intentResp.body) as Map<String, dynamic>;
      if (intentData['success'] != true) {
        throw Exception(intentData['error'] ?? 'Could not create payment');
      }

      final clientSecret    = intentData['clientSecret']    as String;
      final paymentIntentId = intentData['paymentIntentId'] as String;

      // Step 2: Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'RaastKar Smart Farming',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF1B5E20),
            ),
          ),
        ),
      );

      // Step 3: Show Stripe payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 4: Confirm payment on backend + add credits
      final confirmResp = await http.post(
        Uri.parse('${widget.baseUrl}/api/stripe/confirm-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'userId':          userId,
          'planKey':         widget.plan['key'],
          'planName':        widget.plan['name'],
          'billingCycle':    widget.isAnnual ? 'annual' : 'monthly',
          'credits':         widget.plan['credits'],
          'couponCode':      _couponCode ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      final confirmData = json.decode(confirmResp.body) as Map<String, dynamic>;
      if (confirmData['success'] == true) {
        setState(() => _isSubmitting = false);
        widget.onSuccess(_couponCode ?? '');
      } else {
        throw Exception(confirmData['error'] ?? 'Confirmation failed');
      }

    } on StripeException catch (e) {
      setState(() => _isSubmitting = false);
      if (e.error.code == FailureCode.Canceled) {
        // User cancelled — do nothing
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: \${e.error.localizedMessage}'), backgroundColor: Colors.red));
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color planColor = widget.plan['color'] as Color;
    return ListView(controller: widget.scrollController, padding: const EdgeInsets.all(16), children: [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),

      // Plan summary
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: (widget.plan['gradient'] as List<dynamic>).map((c) => c as Color).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Text(widget.plan['emoji'] as String, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.plan['name']} Plan', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.plan['farmSize'] as String, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text('${widget.plan['credits']} credits / month', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(widget.isAnnual ? 'Annual billing' : 'Monthly billing', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (_discountedPriceUSD < _originalPriceUSD) ...[
              Text('\$${_originalPriceUSD.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54, fontSize: 14, decoration: TextDecoration.lineThrough)),
              Text('\$${_discountedPriceUSD.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ] else
              Text('\$${_originalPriceUSD.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            if (widget.userCountry != 'US')
              Text('≈ $_localDiscountedPrice', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // Coupon
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _couponCode != null ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _couponCode != null ? Colors.green.shade300 : Colors.orange.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_couponCode != null ? Icons.local_offer : Icons.discount_outlined, color: _couponCode != null ? Colors.green : Colors.orange, size: 18),
            const SizedBox(width: 8),
            Text(_couponCode != null ? '🎉 Coupon Applied!' : '🎟️ Have a Coupon Code?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _couponCode != null ? Colors.green : Colors.orange)),
          ]),
          if (_couponCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text('${_getSavingsText()} — Code: $_couponCode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                GestureDetector(onTap: () => setState(() { _couponCode = null; _discountPercent = 0; _dollarOff = 0; _couponController.clear(); }), child: const Icon(Icons.close, color: Colors.white, size: 18)),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                controller: _couponController, textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: 'Enter coupon code', hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                onSubmitted: (_) => _validateCoupon(),
              )),
              const SizedBox(width: 8),
              SizedBox(height: 46, child: ElevatedButton(onPressed: _isValidatingCoupon ? null : _validateCoupon,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isValidatingCoupon ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
            if (_couponError.isNotEmpty) ...[const SizedBox(height: 6), Text(_couponError, style: const TextStyle(color: Colors.red, fontSize: 12))],
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // Payment method
      const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 10),
      ..._methods.map((m) => _methodTile(m, planColor)),
      const SizedBox(height: 12),

      if (_selectedMethod == 'EasyPaisa' || _selectedMethod == 'JazzCash')
        Container(
          padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.send_to_mobile, color: Colors.green, size: 16), const SizedBox(width: 8),
            Expanded(child: Text('Send $_selectedMethod to: 03002678621 (ACEM Pakistan)', style: const TextStyle(color: Colors.green, fontSize: 12))),
            GestureDetector(onTap: () { Clipboard.setData(const ClipboardData(text: '03002678621')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Number copied!'), backgroundColor: Color(0xFF2E7D52))); },
              child: const Icon(Icons.copy, color: Colors.green, size: 16)),
          ]),
        ),

      if (_selectedMethod == 'Bank Transfer')
        Container(
          padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bank Transfer Details:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 4),
            Text('Bank: Bank Makramah Limited', style: TextStyle(color: Colors.blue, fontSize: 12)),
            Text('Account: 0236586002000049', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('Name: ACEM Pakistan', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ]),
        ),



      // ── Stripe Card Payment ──
      if (_selectedMethod == 'Credit / Debit Card')
        Container(
          padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF635BFF).withValues(alpha: 0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.credit_card, color: Color(0xFF635BFF), size: 24),
              SizedBox(width: 8),
              Text('Pay by Card (Stripe)', style: TextStyle(color: Color(0xFF635BFF), fontWeight: FontWeight.bold, fontSize: 15)),
              Spacer(),
              Icon(Icons.lock, color: Color(0xFF635BFF), size: 14),
              SizedBox(width: 4),
              Text('Secure', style: TextStyle(color: Color(0xFF635BFF), fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            const Text('Accepted cards:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: const [
              _CardBadge('VISA'),
              SizedBox(width: 6),
              _CardBadge('Mastercard'),
              SizedBox(width: 6),
              _CardBadge('Amex'),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.info_outline, size: 14, color: Colors.grey), SizedBox(width: 6), Text('Your card is charged instantly', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                SizedBox(height: 4),
                Row(children: [Icon(Icons.check_circle, size: 14, color: Color(0xFF635BFF)), SizedBox(width: 6), Text('Credits added immediately after payment', style: TextStyle(color: Color(0xFF635BFF), fontSize: 12, fontWeight: FontWeight.w600))]),
              ]),
            ),
          ]),
        ),

      if (_selectedMethod == 'USDT Crypto')
        Container(
          padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Text('🪙', style: TextStyle(fontSize: 24)), SizedBox(width: 8), Text('USDT (TRC20)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
              child: const Row(children: [Icon(Icons.warning, color: Colors.red, size: 16), SizedBox(width: 6), Expanded(child: Text('Use TRC20 network ONLY! Wrong network = lost funds', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)))])),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Expanded(child: Text('TVDyxYnsgnyuoALC1J8N7kxPX5kgnSK5Lc', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
                GestureDetector(onTap: () { Clipboard.setData(const ClipboardData(text: 'TVDyxYnsgnyuoALC1J8N7kxPX5kgnSK5Lc')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ USDT address copied!'), backgroundColor: Colors.orange)); },
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.copy, color: Colors.white, size: 18))),
              ])),
          ]),
        ),

      // ── Screenshot Upload ──
      const Text('Upload Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickScreenshot,
        child: Container(
          width: double.infinity,
          height: _screenshotBytes != null ? 200 : 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _screenshotBytes != null ? const Color(0xFF2E7D52) : Colors.grey.shade300, width: _screenshotBytes != null ? 2 : 1)),
          child: _screenshotBytes != null
              ? Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.memory(_screenshotBytes!, width: double.infinity, height: 200, fit: BoxFit.cover)),
                  Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() { _screenshotBytes = null; _screenshotBase64 = null; }),
                    child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                  Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF2E7D52), borderRadius: BorderRadius.circular(6)),
                    child: const Text('✅ Screenshot uploaded', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.upload_file, color: Colors.grey.shade400, size: 32),
                  const SizedBox(height: 8),
                  Text('Tap to upload payment screenshot', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  Text('(Optional but recommended)', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ]),
        ),
      ),
      const SizedBox(height: 16),

      // Transaction ID
      const Text('Enter Transaction ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
      TextField(controller: _txController,
        decoration: InputDecoration(hintText: 'e.g., EP123456789', hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.receipt_long, color: Color(0xFF2E7D52)), filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)))),
      const SizedBox(height: 10),
      TextField(controller: _phoneController, keyboardType: TextInputType.phone,
        decoration: InputDecoration(hintText: 'Your phone number (optional)', hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.phone, color: Color(0xFF2E7D52)), filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)))),
      const SizedBox(height: 16),

      SizedBox(width: double.infinity, height: 54,
        child: ElevatedButton(onPressed: _isSubmitting ? null : _submitPayment,
          style: ElevatedButton.styleFrom(backgroundColor: planColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('✅ I Have Paid — Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('\$${_discountedPriceUSD.toStringAsFixed(0)} USD${_discountedPriceUSD < _originalPriceUSD ? ' (discount applied)' : ''}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]))),
      const SizedBox(height: 8),
      const Center(child: Text('🔒 Credits added after payment verification (15-30 min)', style: TextStyle(color: Colors.grey, fontSize: 11))),
      const SizedBox(height: 30),
    ]);
  }

  Widget _methodTile(Map<String, dynamic> method, Color planColor) {
    final bool selected = _selectedMethod == method['name'];
    final Color color   = method['color'] as Color;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method['name'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? color : Colors.grey.shade200, width: selected ? 2 : 1)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(method['icon'] as IconData, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Row(children: [
            Text(method['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (method['popular'] == true) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)), child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))],
          ])),
          if (selected) Icon(Icons.check_circle, color: color, size: 22),
        ]),
      ),
    );
  }
}

// ─── Card Badge (Stripe) ───
class _CardBadge extends StatelessWidget {
  final String label;
  const _CardBadge(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF635BFF).withValues(alpha: 0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF635BFF), fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Stat Badge ───
class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}