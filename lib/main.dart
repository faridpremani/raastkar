import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/language_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe only on mobile — wrapped in try/catch so crash won't kill app
  if (!kIsWeb) {
    try {
      await _initStripe();
    } catch (e) {
      debugPrint('Stripe init skipped: $e');
    }
  }

  runApp(const RaastKarApp());
}

Future<void> _initStripe() async {
  try {
    // Dynamic import to avoid web crash
    final stripe = await _getStripe();
    if (stripe != null) {
      stripe['publishableKey'] = 'pk_live_51TgJMfF0Dhlez29FgEpqqLZHN1gBT5cgCAA5oiPsP1ekikYpiHw4inWDmH5Z7JR3UwYY4Nm7TqZucnZuWCUOSCsy00urkU5UMp';
    }
  } catch (e) {
    debugPrint('Stripe not available: $e');
  }
}

Future<Map?> _getStripe() async => null; // placeholder

class RaastKarApp extends StatelessWidget {
  const RaastKarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RaastKar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D52)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try { await RemoteConfig.fetch(); } catch (_) {}
    if (!mounted) return;
    if (RemoteConfig.maintenanceMode) { _showMaintenance(); return; }
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (!mounted) return;
    if (token.isEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => LoginScreen(languageService: _languageService)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => HomeScreen(languageService: _languageService)));
    }
  }

  void _showMaintenance() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔧', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Under Maintenance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(RemoteConfig.maintenanceMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D52),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.eco, color: Color(0xFF2E7D52), size: 60),
          ),
          const SizedBox(height: 28),
          const Text('RaastKar',
              style: TextStyle(color: Colors.white, fontSize: 34,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('AgriGPT for Farmers',
              style: TextStyle(color: Color(0xFFC9A84C), fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Smart Farming Pakistan',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 50),
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text('Loading...',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ),
    );
  }
}