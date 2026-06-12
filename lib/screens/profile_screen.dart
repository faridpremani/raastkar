  import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final LanguageService languageService;
  const ProfileScreen({super.key, required this.languageService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _changingPassword = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _farmLocationCtrl = TextEditingController();

  // Password controllers
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _farmLocationCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final result = await AuthService.getProfile();
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true && result['user'] != null) {
      final user = result['user'] as Map<String, dynamic>;
      _nameCtrl.text = user['name']?.toString() ?? '';
      _emailCtrl.text = user['email']?.toString() ?? '';
      _phoneCtrl.text = user['phone']?.toString() ?? '';
      _countryCtrl.text = user['country']?.toString() ?? '';
      _farmLocationCtrl.text = user['farmLocation']?.toString() ?? '';
    } else {
      // Load from local storage if API fails
      final user = AuthService.currentUser;
      if (user != null) {
        _nameCtrl.text = user['name']?.toString() ?? '';
        _emailCtrl.text = user['email']?.toString() ?? '';
        _phoneCtrl.text = user['phone']?.toString() ?? '';
        _countryCtrl.text = user['country']?.toString() ?? '';
        _farmLocationCtrl.text = user['farmLocation']?.toString() ?? '';
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
      _success = '';
    });

    try {
      final response = await AuthService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        farmLocation: _farmLocationCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      if (response['success'] == true) {
        setState(() => _success = 'Profile updated successfully!');
      } else {
        setState(
            () => _error = response['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  Future<void> _changePassword() async {
    if (_currentPassCtrl.text.isEmpty ||
        _newPassCtrl.text.isEmpty ||
        _confirmPassCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all password fields');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _changingPassword = true;
      _error = '';
      _success = '';
    });

    try {
      final response = await AuthService.changePassword(
        currentPassword: _currentPassCtrl.text,
        newPassword: _newPassCtrl.text,
      );
      if (!mounted) return;
      setState(() => _changingPassword = false);
      if (response['success'] == true) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        setState(() => _success = 'Password changed successfully!');
      } else {
        setState(() =>
            _error = response['error'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _changingPassword = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to logout from RaastKar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                      languageService: widget.languageService),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout',
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
        title: const Text('My Account',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2E7D52)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_error.isNotEmpty) _buildErrorBox(),
                        if (_success.isNotEmpty) _buildSuccessBox(),
                        if (_error.isNotEmpty || _success.isNotEmpty)
                          const SizedBox(height: 12),
                        _buildProfileCard(),
                        const SizedBox(height: 16),
                        _buildPasswordCard(),
                        const SizedBox(height: 16),
                        _buildAccountInfoCard(),
                        const SizedBox(height: 16),
                        _buildLogoutButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final name = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : AuthService.currentUser?['name']?.toString() ?? 'Farmer';
    final email = _emailCtrl.text.isNotEmpty
        ? _emailCtrl.text
        : AuthService.currentUser?['email']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person,
                size: 50, color: Color(0xFF2E7D52)),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  AuthService.currentUser?['plan']
                          ?.toString() ??
                      'Free Trial',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline,
                  color: Color(0xFF2E7D52), size: 20),
              SizedBox(width: 8),
              Text(
                'Personal Information',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D52)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline,
            hint: 'Enter your full name',
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'Enter your email',
            enabled: false,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: 'e.g. 03001234567',
            type: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _countryCtrl,
            label: 'Country',
            icon: Icons.flag_outlined,
            hint: 'e.g. Pakistan',
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _farmLocationCtrl,
            label: 'Farm Location',
            icon: Icons.location_on_outlined,
            hint: 'e.g. Lahore, Punjab',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline,
                  color: Color(0xFF1565C0), size: 20),
              SizedBox(width: 8),
              Text(
                'Change Password',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _currentPassCtrl,
            label: 'Current Password',
            obscure: _obscureCurrent,
            onToggle: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _newPassCtrl,
            label: 'New Password',
            obscure: _obscureNew,
            onToggle: () =>
                setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _confirmPassCtrl,
            label: 'Confirm New Password',
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _changingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _changingPassword
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Change Password',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    final user = AuthService.currentUser ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Account Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.workspace_premium,
            'Plan',
            user['plan']?.toString() ?? 'Free Trial',
            Colors.amber,
          ),
          const Divider(height: 20),
          _infoRow(
            Icons.credit_score,
            'Credits',
            '${user['credits'] ?? 0} credits',
            const Color(0xFF2E7D52),
          ),
          const Divider(height: 20),
          _infoRow(
            Icons.calendar_today,
            'Member Since',
            user['createdAt']?.toString().split('T')[0] ??
                'N/A',
            Colors.blue,
          ),
          const Divider(height: 20),
          _infoRow(
            Icons.verified_user,
            'Account Status',
            'Active ✓',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout from RaastKar',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType type = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:
                Icon(icon, color: const Color(0xFF2E7D52), size: 20),
            filled: true,
            fillColor:
                enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF2E7D52), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.lock_outline,
                color: Color(0xFF1565C0), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1565C0), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error,
                style: TextStyle(
                    color: Colors.red.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: Colors.green.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_success,
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}