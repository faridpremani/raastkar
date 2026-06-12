import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() =>
      _AdminCouponScreenState();
}

class _AdminCouponScreenState
    extends State<AdminCouponScreen> {
  final _dealNameCtrl = TextEditingController();
  final _couponCodeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();

  String _discountType = 'percent';
  bool _newCustomersOnly = true;
  bool _allCustomers = true;
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('admin_coupons') ?? '[]';
    setState(() {
      _coupons =
          List<Map<String, dynamic>>.from(json.decode(data));
    });
  }

  Future<void> _saveCoupon() async {
    if (_dealNameCtrl.text.isEmpty ||
        _couponCodeCtrl.text.isEmpty ||
        _discountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final coupon = {
      'dealName': _dealNameCtrl.text.trim(),
      'code': _couponCodeCtrl.text.trim().toUpperCase(),
      'discountType': _discountType,
      'discount': double.tryParse(_discountCtrl.text) ?? 0,
      'maxUses': int.tryParse(_maxUsesCtrl.text) ?? 100,
      'usedCount': 0,
      'newCustomersOnly': _newCustomersOnly,
      'allCustomers': _allCustomers,
      'active': true,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _coupons.add(coupon);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_coupons', json.encode(_coupons));

    _dealNameCtrl.clear();
    _couponCodeCtrl.clear();
    _discountCtrl.clear();
    _maxUsesCtrl.clear();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Coupon created successfully!'),
            backgroundColor: Color(0xFF2E7D52)),
      );
    }
  }

  Future<void> _toggleCoupon(int i) async {
    _coupons[i]['active'] = !(_coupons[i]['active'] as bool);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_coupons', json.encode(_coupons));
    setState(() {});
  }

  Future<void> _deleteCoupon(int i) async {
    _coupons.removeAt(i);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_coupons', json.encode(_coupons));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D52),
        title: const Text('Admin — Coupon Manager',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Create Coupon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_offer,
                          color: Color(0xFF2E7D52)),
                      SizedBox(width: 8),
                      Text('Create New Coupon',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E7D52))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Deal Name
                  _buildField(_dealNameCtrl,
                      'Deal Name *', Icons.star),
                  const SizedBox(height: 10),

                  // Coupon Code
                  _buildField(
                      _couponCodeCtrl,
                      'Coupon Code * (e.g. SAVE70)',
                      Icons.confirmation_number),
                  const SizedBox(height: 12),

                  // Discount Type Toggle
                  const Text('Discount Type',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _typeBtn(
                          label: '% Percentage Off',
                          value: 'percent',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeBtn(
                          label: '\$ Dollar Off',
                          value: 'dollar',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Discount Amount
                  _buildField(
                    _discountCtrl,
                    _discountType == 'percent'
                        ? 'Discount % (e.g. 70)'
                        : 'Discount \$ Amount (e.g. 5)',
                    Icons.discount,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 10),

                  // Max Uses
                  _buildField(
                    _maxUsesCtrl,
                    'Max number of uses (e.g. 100)',
                    Icons.people,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Customer Visibility
                  const Text('Visible To',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _newCustomersOnly,
                              activeColor:
                                  const Color(0xFF2E7D52),
                              onChanged: (v) => setState(
                                  () => _newCustomersOnly =
                                      v!),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('New Customers Only',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600)),
                                  Text(
                                    'Only for users who never purchased',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _allCustomers,
                              activeColor:
                                  const Color(0xFF2E7D52),
                              onChanged: (v) => setState(
                                  () => _allCustomers = v!),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('All Customers',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600)),
                                  Text(
                                    'Visible to everyone',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2E7D52),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: const Text('🎟️ Create Coupon',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Coupons List
            if (_coupons.isNotEmpty) ...[
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Coupons (${_coupons.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._coupons.asMap().entries.map((e) =>
                  _couponCard(e.value, e.key)),
            ] else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Text('🎟️',
                          style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('No coupons yet',
                          style: TextStyle(
                              color: Colors.grey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn({
    required String label,
    required String value,
  }) {
    final isSelected = _discountType == value;
    return GestureDetector(
      onTap: () => setState(() => _discountType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D52)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: label.contains('Code')
          ? TextCapitalization.characters
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: const Color(0xFF2E7D52)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF2E7D52), width: 2),
        ),
      ),
    );
  }

  Widget _couponCard(Map<String, dynamic> coupon, int i) {
    final isPercent = coupon['discountType'] == 'percent';
    final discount = (coupon['discount'] as num).toDouble();
    final isActive = coupon['active'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF2E7D52).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon['dealName'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (_) => _toggleCoupon(i),
                activeColor: const Color(0xFF2E7D52),
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    color: Colors.red, size: 20),
                onPressed: () => _deleteCoupon(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Coupon Code
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: coupon['code'] as String));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content: Text('Code copied!'),
                    backgroundColor: Color(0xFF2E7D52),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D52),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        coupon['code'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy,
                          color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPercent
                      ? '${discount.toInt()}% OFF'
                      : '\$${discount.toStringAsFixed(0)} OFF',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Used: ${coupon['usedCount']}/${coupon['maxUses']} uses  •  ${coupon['newCustomersOnly'] == true ? '🆕 New customers' : ''} ${coupon['allCustomers'] == true ? '👥 All customers' : ''}',
            style: const TextStyle(
                color: Colors.grey, fontSize: 11),
          ),
          if (!isActive)
            const Text('⛔ Inactive',
                style: TextStyle(
                    color: Colors.red, fontSize: 11)),
        ],
      ),
    );
  }
}