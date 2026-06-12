import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class FarmRegistrationScreen extends StatefulWidget {
  const FarmRegistrationScreen({super.key});

  @override
  State<FarmRegistrationScreen> createState() =>
      _FarmRegistrationScreenState();
}

class _FarmRegistrationScreenState
    extends State<FarmRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _farmSizeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _cropsGrownCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  String _selectedCountryCode = '+92';
  String _selectedFinancialMethod = 'EasyPaisa';
  bool _loading = false;
  bool _checkingStatus = true;

  // Farm status
  String _farmStatus = 'not_registered';
  Map<String, dynamic>? _farmData;

  final List<String> _countryCodes = [
    '+92', '+1', '+44', '+971',
    '+966', '+61', '+91', '+880',
  ];

  final List<String> _financialMethods = [
    'Cash', 'Bank Transfer', 'EasyPaisa',
    'JazzCash', 'Cheque', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkFarmStatus();
  }

  Future<void> _checkFarmStatus() async {
    setState(() => _checkingStatus = true);
    try {
      final user = AuthService.currentUser;
      final email = user?['email'] ?? '';
      if (email.isEmpty) {
        setState(() => _checkingStatus = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/api/farm/status?email=$email',
        ),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          _farmStatus = data['status'] ?? 'not_registered';
          _farmData = data['farm'];
        });

        // Save approved status locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
          'farm_registered',
          data['status'] == 'approved',
        );
        await prefs.setString(
          'farm_status', data['status'] ?? 'not_registered',
        );
      }
    } catch (e) {
      // Use cached status if offline
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('farm_status') ?? 'not_registered';
      setState(() => _farmStatus = cached);
    }
    setState(() => _checkingStatus = false);

    // Prefill email
    final user = AuthService.currentUser;
    if (user != null) {
      _emailCtrl.text = user['email']?.toString() ?? '';
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = AuthService.currentUser;
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/farm/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'farmName': _farmNameCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'farmSize': _farmSizeCtrl.text.trim(),
          'email': _emailCtrl.text.trim().toLowerCase(),
          'phone': '$_selectedCountryCode${_phoneCtrl.text.trim()}',
          'whatsapp': '$_selectedCountryCode${_whatsappCtrl.text.trim()}',
          'cropsGrown': _cropsGrownCtrl.text.trim(),
          'quantity': _quantityCtrl.text.trim(),
          'financialMethod': _selectedFinancialMethod,
          'userId': user?['id'] ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      setState(() {
        _loading = false;
        _farmStatus = data['status'] ?? 'pending';
        _farmData = data['farm'];
      });

      // Save status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farm_status', _farmStatus);
      await prefs.setBool('farm_registered', _farmStatus == 'approved');

      if (mounted) {
        _showStatusDialog(data['status'] ?? 'pending');
      }
    } catch (e) {
      setState(() => _loading = false);
      // Save as pending if offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farm_status', 'pending');
      setState(() => _farmStatus = 'pending');
      if (mounted) _showStatusDialog('pending');
    }
  }

  void _showStatusDialog(String status) {
    String emoji, title, message;
    Color color;

    switch (status) {
      case 'approved':
        emoji = '✅';
        title = 'Farm Approved!';
        message = 'Congratulations! Your farm is approved. You can now sell crops on marketplace!';
        color = const Color(0xFF2E7D52);
        break;
      case 'rejected':
        emoji = '❌';
        title = 'Registration Rejected';
        message = _farmData?['rejectionReason'] ??
            'Your registration was rejected. Please contact support.';
        color = Colors.red;
        break;
      default:
        emoji = '⏳';
        title = 'Request Submitted!';
        message = 'Your farm registration has been submitted. Admin will review within 24 hours. You will be notified once approved.';
        color = Colors.orange;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (status != 'rejected') Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D52),
        title: const Text('Farm Registration',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _checkFarmStatus,
          ),
        ],
      ),
      body: _checkingStatus
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D52)),
                  SizedBox(height: 16),
                  Text('Checking farm status...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_farmStatus) {
      case 'approved':
        return _buildApprovedView();
      case 'pending':
        return _buildPendingView();
      case 'rejected':
        return _buildRejectedView();
      default:
        return _buildRegistrationForm();
    }
  }

  // ── Approved View ──
  Widget _buildApprovedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D52)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('✅',
                    style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Farm Approved!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _farmData?['farmName'] ?? 'Your Farm',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified,
                          color: Colors.greenAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'You can now sell on Marketplace!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_farmData != null) ...[
            _infoCard('Farm Details', [
              _infoRow('Farm Name', _farmData!['farmName'] ?? ''),
              _infoRow('Address', _farmData!['address'] ?? ''),
              _infoRow('Crops', _farmData!['cropsGrown'] ?? ''),
              _infoRow('Approved', _farmData!['approvedAt'] != null
                  ? _farmData!['approvedAt'].toString().substring(0, 10)
                  : 'N/A'),
            ]),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.shopping_cart,
                  color: Colors.white),
              label: const Text('Go to Marketplace',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending View ──
  Widget _buildPendingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade300, width: 2),
            ),
            child: Column(
              children: [
                const Text('⏳',
                    style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Under Review',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                const SizedBox(height: 8),
                const Text(
                  'Your farm registration is being reviewed by admin. This usually takes 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Progress steps
                _progressStep('✅', 'Registration Submitted', true),
                _progressStep('⏳', 'Admin Review', false, isActive: true),
                _progressStep('🔒', 'Farm Approved', false),
                _progressStep('🌾', 'Start Selling', false),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_farmData != null)
            _infoCard('Submitted Details', [
              _infoRow('Farm Name', _farmData!['farmName'] ?? ''),
              _infoRow('Address', _farmData!['address'] ?? ''),
              _infoRow('Crops', _farmData!['cropsGrown'] ?? ''),
              _infoRow('Submitted',
                  _farmData!['submittedAt'] != null
                      ? _farmData!['submittedAt']
                          .toString()
                          .substring(0, 10)
                      : 'N/A'),
            ]),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _checkFarmStatus,
            icon: const Icon(Icons.refresh,
                color: Color(0xFF2E7D52)),
            label: const Text('Check Status',
                style: TextStyle(color: Color(0xFF2E7D52))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2E7D52)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact: invest@ignitetheaspark.org for faster approval',
                    style: TextStyle(
                        color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rejected View ──
  Widget _buildRejectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade300, width: 2),
            ),
            child: Column(
              children: [
                const Text('❌',
                    style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Registration Rejected',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
                const SizedBox(height: 8),
                if (_farmData?['rejectionReason'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reason: ${_farmData!['rejectionReason']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'You can re-apply with updated information:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _farmStatus = 'not_registered'),
              icon: const Icon(Icons.refresh,
                  color: Colors.white),
              label: const Text('Re-Apply',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Registration Form ──
  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D52)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('🌾', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 8),
                  Text('Register Your Farm',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'Submit your farm details for admin approval to start selling',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Process steps
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text('How it works:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D52))),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _StepItem(
                          number: '1',
                          label: 'Submit\nRequest'),
                      Icon(Icons.arrow_forward,
                          color: Color(0xFF2E7D52),
                          size: 16),
                      _StepItem(
                          number: '2',
                          label: 'Admin\nReview'),
                      Icon(Icons.arrow_forward,
                          color: Color(0xFF2E7D52),
                          size: 16),
                      _StepItem(
                          number: '3',
                          label: 'Get\nApproved'),
                      Icon(Icons.arrow_forward,
                          color: Color(0xFF2E7D52),
                          size: 16),
                      _StepItem(
                          number: '4',
                          label: 'Start\nSelling'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Farm Details
            _section('🏡 Farm Details', [
              _field(_farmNameCtrl, 'Farm Name *',
                  Icons.home,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              _field(_descriptionCtrl,
                  'Description of crops grown',
                  Icons.description, maxLines: 3),
              const SizedBox(height: 10),
              _field(_addressCtrl, 'Farm Address *',
                  Icons.location_on,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              _field(_farmSizeCtrl,
                  'Farm Size (Acres) *',
                  Icons.crop_square,
                  type: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
            ]),
            const SizedBox(height: 16),

            // Contact
            _section('📞 Contact Details', [
              _field(_emailCtrl, 'Email Address *',
                  Icons.email,
                  type: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              _phoneRow(_phoneCtrl, 'Phone Number *'),
              const SizedBox(height: 10),
              _phoneRow(_whatsappCtrl, 'WhatsApp Number'),
            ]),
            const SizedBox(height: 16),

            // Crop Info
            _section('🌱 Crop Information', [
              _field(_cropsGrownCtrl,
                  'What crops do you grow? *',
                  Icons.grass,
                  hint: 'e.g., Wheat, Rice, Tomato',
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              _field(_quantityCtrl,
                  'How much do you grow? (tons/year)',
                  Icons.scale,
                  type: TextInputType.number),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedFinancialMethod,
                decoration: InputDecoration(
                  labelText: 'Financial Transaction Method',
                  prefixIcon: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF2E7D52)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF2E7D52),
                        width: 2),
                  ),
                ),
                items: _financialMethods
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(
                    () => _selectedFinancialMethod = v!),
              ),
            ]),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D52),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send,
                              color: Colors.white),
                          SizedBox(width: 8),
                          Text('Submit Registration Request',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _progressStep(String emoji, String label,
      bool done, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontWeight: isActive
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: done
                      ? Colors.green
                      : isActive
                          ? Colors.orange
                          : Colors.grey,
                  fontSize: 14)),
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('In Progress',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF2E7D52))),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF2E7D52))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D52)),
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

  Widget _phoneRow(TextEditingController ctrl, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: _selectedCountryCode,
            underline: const SizedBox(),
            items: _countryCodes
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedCountryCode = v!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: label,
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
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number, label;
  const _StepItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D52),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF2E7D52))),
      ],
    );
  }
}