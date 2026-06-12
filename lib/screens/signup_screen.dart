import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final LanguageService languageService;
  const SignupScreen({super.key, required this.languageService});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _idNumberController = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _error = '';
  String _selectedCountry = 'PK';
  String _selectedIdType = 'CNIC';
  Uint8List? _idImageBytes;
  String? _idImageBase64;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _countries = [
    {'code': 'PK', 'name': '🇵🇰 Pakistan'},
    {'code': 'US', 'name': '🇺🇸 USA'},
    {'code': 'GB', 'name': '🇬🇧 UK'},
    {'code': 'AE', 'name': '🇦🇪 UAE'},
    {'code': 'SA', 'name': '🇸🇦 Saudi Arabia'},
    {'code': 'AU', 'name': '🇦🇺 Australia'},
    {'code': 'CA', 'name': '🇨🇦 Canada'},
    {'code': 'IN', 'name': '🇮🇳 India'},
    {'code': 'BD', 'name': '🇧🇩 Bangladesh'},
    {'code': 'EU', 'name': '🇪🇺 Europe'},
  ];

  final List<Map<String, dynamic>> _idTypes = [
    {'value': 'CNIC', 'label': '🪪 CNIC (Pakistan)', 'hint': 'e.g., 42101-1234567-1', 'format': 'XXXXX-XXXXXXX-X'},
    {'value': 'Government ID', 'label': '🏛️ Government ID', 'hint': 'Enter ID number', 'format': 'Government ID Number'},
    {'value': 'Driving License', 'label': '🚗 Driving License', 'hint': 'Enter license number', 'format': 'License Number'},
    {'value': 'Passport', 'label': '🛂 Passport', 'hint': 'e.g., AB1234567', 'format': 'Passport Number'},
    {'value': 'National ID', 'label': '🌍 National ID', 'hint': 'Enter national ID', 'format': 'National ID Number'},
  ];

  String get _currentIdHint {
    return _idTypes.firstWhere((t) => t['value'] == _selectedIdType,
        orElse: () => _idTypes[0])['hint'] as String;
  }

  Future<void> _pickIdImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _idImageBytes = bytes;
          _idImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access camera/gallery. Check permissions.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload ID Document',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Take a clear photo of your ID document',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickIdImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2E7D52).withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xFF2E7D52), size: 36),
                          SizedBox(height: 8),
                          Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D52))),
                          Text('Take photo', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickIdImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library, color: Colors.blue, size: 36),
                          SizedBox(height: 8),
                          Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Text('Choose file', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passController.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (_passController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_passController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    final result = await AuthService.register(
      email: _emailController.text.trim(),
      password: _passController.text,
      name: _nameController.text.trim(),
      country: _selectedCountry,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      _showWelcomeDialog();
    } else {
      setState(() => _error = result['error'] ?? 'Signup failed');
    }
  }

  Future<void> _googleSignup() async {
    setState(() { _googleLoading = true; _error = ''; });
    final result = await AuthService.loginWithGoogle();
    setState(() => _googleLoading = false);
    if (result['success'] == true) {
      _showWelcomeDialog();
    } else {
      setState(() => _error = result['error'] ?? 'Google signup failed');
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Account Created!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text('🎁 Welcome Gift!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('10 FREE Credits Added!',
                      style: TextStyle(
                          color: Color(0xFF2E7D52), fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Start using AI farming features right now!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(languageService: widget.languageService),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D52),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start Farming! 🌾',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D52), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text('Create Account',
                        style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free credits banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF2E7D52).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Text('🎁', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sign up now and get 10 FREE credits!',
                                style: TextStyle(
                                    color: Color(0xFF2E7D52),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _googleLoading ? null : _googleSignup,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _googleLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.google.com/favicon.ico',
                                      width: 20, height: 20,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.g_mobiledata, size: 24, color: Colors.blue),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Sign up with Google',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Name
                      _buildField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10),

                      // Email
                      _buildField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      // Country
                      DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF2E7D52)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2),
                          ),
                        ),
                        items: _countries
                            .map((c) => DropdownMenuItem(value: c['code'], child: Text(c['name']!)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCountry = v!),
                      ),
                      const SizedBox(height: 10),

                      // Password
                      _buildField(
                        controller: _passController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        onToggle: () => setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 10),

                      // Confirm Password
                      _buildField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_outlined,
                        obscure: _obscureConfirm,
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 20),

                      // ── GOVERNMENT ID SECTION ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.badge_outlined, color: Color(0xFF2E7D52), size: 20),
                                SizedBox(width: 8),
                                Text('Government ID',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF2E7D52))),
                                SizedBox(width: 8),
                                Text('(Optional)',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Upload your CNIC, driving license, or government ID for verified seller badge',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 14),

                            // ID Type Selector
                            const Text('ID Type',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87)),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _idTypes.map((type) {
                                  final isSelected = _selectedIdType == type['value'];
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedIdType = type['value'] as String),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2E7D52)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2E7D52)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        type['label'] as String,
                                        style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ID Number field
                            TextField(
                              controller: _idNumberController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: '$_selectedIdType Number',
                                hintText: _currentIdHint,
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                prefixIcon: const Icon(Icons.numbers, color: Color(0xFF2E7D52), size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ID Image Upload
                            const Text('Upload ID Document Photo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87)),
                            const SizedBox(height: 8),

                            if (_idImageBytes == null)
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  width: double.infinity,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF2E7D52).withValues(alpha: 0.4),
                                        width: 1.5,
                                        style: BorderStyle.solid),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8F5E9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.upload_file,
                                            color: Color(0xFF2E7D52), size: 24),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Tap to upload ID photo',
                                          style: TextStyle(
                                              color: Color(0xFF2E7D52),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      const Text('Camera or Gallery · JPG, PNG',
                                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _idImageBytes!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _idImageBytes = null;
                                        _idImageBase64 = null;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                            color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8, left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.greenAccent, size: 14),
                                          SizedBox(width: 4),
                                          Text('ID Uploaded',
                                              style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: _showImageSourceDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D52),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('Change',
                                            style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.security, color: Colors.blue, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your ID is securely stored and used only for identity verification. We never share it with third parties.',
                                      style: TextStyle(color: Colors.blue, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_error,
                                      style: const TextStyle(color: Colors.red, fontSize: 12))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Create Account 🌾',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoginScreen(languageService: widget.languageService),
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have account? ',
                              style: TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                      color: Color(0xFF2E7D52), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D52)),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2),
        ),
      ),
    );
  }
}