import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crop_planner_screen.dart';
import 'dr_crop_screen.dart';
import 'weather_screen.dart';
import 'mandi_screen.dart';
import 'marketplace_screen.dart';
import 'carbon_screen.dart';
import 'esg_screen.dart';
import 'roi_screen.dart';
import 'subscription_screen.dart';
import 'profile_screen.dart';
import 'farm_registration_screen.dart';
import 'loan_screen.dart';
import '../services/language_service.dart';
import '../services/tr.dart';

class HomeScreen extends StatefulWidget {
  final LanguageService languageService;
  const HomeScreen({super.key, required this.languageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _creditsLeft  = 5;

  @override
  void initState() {
    super.initState();
    _loadCredits();
    widget.languageService.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    widget.languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final used  = prefs.getInt('credits_used')  ?? 0;
    final total = prefs.getInt('credits_total') ?? 5;
    if (mounted) setState(() => _creditsLeft = total - used);
  }

  Widget _getScreen(int index) {
    final langKey = ValueKey(widget.languageService.currentLangName);
    switch (index) {
      case 0:  return CropPlannerScreen(key: langKey);
      case 1:  return DrCropScreen(key: langKey);
      case 2:  return WeatherScreen(key: langKey);
      case 3:  return MandiScreen(key: langKey);
      case 4:  return MarketplaceScreen(key: langKey);
      case 5:  return CarbonScreen(key: langKey);
      case 6:  return ESGScreen(key: langKey);
      case 7:  return ROIScreen(key: langKey);
      case 8:  return const LoanScreen();
      default: return CropPlannerScreen(key: langKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _getScreen(_currentIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2E7D52),
          boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              // Logo
              Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: Color(0xFF2E7D52), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(Tr.get('appName'), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const Text('AgriGPT for Farmers', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              // Farm
              _appBarBtn(
                icon: Icons.agriculture,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmRegistrationScreen())),
              ),
              const SizedBox(width: 5),

              // Profile
              _appBarBtn(
                icon: Icons.person_outline,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(languageService: widget.languageService))).then((_) => _loadCredits()),
              ),
              const SizedBox(width: 5),

              // Credits badge
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())).then((_) => _loadCredits()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _creditsLeft <= 2 ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFC9A84C).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _creditsLeft <= 2 ? Colors.red.shade300 : const Color(0xFFC9A84C).withValues(alpha: 0.6)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.workspace_premium, color: _creditsLeft <= 2 ? Colors.red.shade200 : const Color(0xFFC9A84C), size: 12),
                    const SizedBox(width: 3),
                    Text('$_creditsLeft', style: TextStyle(color: _creditsLeft <= 2 ? Colors.red.shade200 : const Color(0xFFC9A84C), fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(width: 5),

              // Language picker
              GestureDetector(
                onTap: _showLanguagePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.language, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      widget.languageService.currentLangName.substring(0, widget.languageService.currentLangName.length > 6 ? 6 : widget.languageService.currentLangName.length),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 13),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _appBarBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Text(Tr.get('selectLanguage'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...LanguageService.supportedLanguages.map((lang) {
            final isSelected = widget.languageService.currentLangName == lang['name'];
            return ListTile(
              leading: Text(lang['flag'] as String, style: const TextStyle(fontSize: 22)),
              title: Text(lang['name'] as String),
              subtitle: Text(lang['nativeName'] as String),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2E7D52)) : null,
              onTap: () {
                widget.languageService.changeLanguage(lang['locale'] as Locale, lang['name'] as String);
                Navigator.pop(context);
              },
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildBottomNav() {
    final tabs = [
      {'icon': Icons.eco_outlined,                'active': Icons.eco,                'label': Tr.get('cropPlanner'), 'color': const Color(0xFF2E7D52)},
      {'icon': Icons.medical_services_outlined,   'active': Icons.medical_services,   'label': Tr.get('drCropShort'), 'color': const Color(0xFF1565C0)},
      {'icon': Icons.cloud_outlined,              'active': Icons.cloud,              'label': Tr.get('weatherShort'),'color': const Color(0xFF0097A7)},
      {'icon': Icons.storefront_outlined,         'active': Icons.storefront,         'label': Tr.get('mandi'),       'color': const Color(0xFFE65100)},
      {'icon': Icons.shopping_cart_outlined,      'active': Icons.shopping_cart,      'label': Tr.get('market'),      'color': const Color(0xFF6A1B9A)},
      {'icon': Icons.energy_savings_leaf_outlined,'active': Icons.energy_savings_leaf,'label': Tr.get('carbon'),      'color': const Color(0xFF2E7D52)},
      {'icon': Icons.workspace_premium_outlined,  'active': Icons.workspace_premium,  'label': Tr.get('esgShort'),    'color': const Color(0xFF283593)},
      {'icon': Icons.calculate_outlined,          'active': Icons.calculate,          'label': 'ROI',                 'color': const Color(0xFF00695C)},
      {'icon': Icons.account_balance_outlined,    'active': Icons.account_balance,    'label': 'Loan',                'color': const Color(0xFF1B5E20)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i      = entry.key;
              final tab    = entry.value;
              final bool isActive = _currentIndex == i;
              final Color color   = tab['color'] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isActive ? tab['active'] as IconData : tab['icon'] as IconData, color: isActive ? color : Colors.grey.shade400, size: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(tab['label'] as String,
                      style: TextStyle(fontSize: 9, color: isActive ? color : Colors.grey.shade400, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}   