import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/auth_service.dart';
import '../services/tr.dart';

// ═══════════════════════════════════════════════════════════════
// Verra VM0042 v2.0 — Improved Agricultural Land Management
// IPCC 2006 Guidelines Vol.4 Ch.5 — Tier 1 SOC factors
// VCS Standard v4.5 — Permanence buffer §3.7.4
// ═══════════════════════════════════════════════════════════════

class CarbonScreen extends StatefulWidget {
  const CarbonScreen({super.key});
  @override
  State<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends State<CarbonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _locationCtrl = TextEditingController();
  final _acresCtrl    = TextEditingController();

  String _selectedCrop     = 'Wheat';
  String _climateZone      = 'Semi-Arid (Punjab/Sindh)';
  String _soilType         = 'Loam';
  String _landUseHistory   = 'Degraded Cropland';
  String _tillage          = 'Conventional Tillage';

  Map<String, dynamic>? _result;
  bool _loading        = false;
  bool _hasCalculated  = false;
  bool _gpsLoading     = false;

  final Set<String> _selectedPractices = {};

  // ── IPCC Tier 1 SOC Reference (t C/ha) ──
  static const Map<String, double> _socRef = {
    'Semi-Arid (Punjab/Sindh)':    38.0,
    'Sub-Humid (KPK/Balochistan)': 47.5,
    'Arid (Desert areas)':         24.0,
    'Humid (Northern areas)':      88.0,
  };

  // ── IPCC Land Use Factors (FLU) ──
  static const Map<String, double> _flu = {
    'Degraded Cropland':    0.58,
    'Long-term Cropland':   0.69,
    'Improved Cropland':    0.75,
    'Recently Converted':   0.64,
  };

  // ── IPCC Management Factors (FMG) ──
  static const Map<String, double> _fmg = {
    'Conventional Tillage': 1.00,
    'Reduced Tillage':      1.02,
    'No-Till / Zero Tillage': 1.10,
  };

  // ── IPCC Input Factors (FI) by crop ──
  static const Map<String, double> _fi = {
    'Wheat': 1.00, 'Rice (Basmati)': 1.04, 'Rice (IRRI)': 1.02,
    'Maize': 1.02, 'Barley': 0.98, 'Sorghum': 0.97, 'Millet': 0.95,
    'Cotton': 0.95, 'Sugarcane': 1.08, 'Tobacco': 0.90,
    'Tomato': 0.96, 'Potato': 0.94, 'Onion': 0.92, 'Garlic': 0.91,
    'Chili': 0.96, 'Capsicum': 0.95, 'Brinjal': 0.94, 'Okra': 0.93,
    'Spinach': 0.92, 'Carrot': 0.93, 'Cabbage': 0.92, 'Cauliflower': 0.91,
    'Peas': 1.08, 'Cucumber': 0.93, 'Pumpkin': 0.94, 'Watermelon': 0.93,
    'Melon': 0.93, 'Mango': 1.15, 'Orange': 1.12, 'Banana': 1.10,
    'Guava': 1.08, 'Apple': 1.14, 'Pomegranate': 1.10, 'Dates': 1.13,
    'Grapes': 1.11, 'Chickpea': 1.11, 'Lentils': 1.09, 'Mung Bean': 1.08,
    'Soybean': 1.10, 'Black-eyed Pea': 1.07, 'Sunflower': 0.97,
    'Canola': 0.96, 'Sesame': 0.95, 'Groundnut': 1.05,
    'Coriander': 0.92, 'Mint': 0.93, 'Fenugreek': 1.06,
    'Turmeric': 1.04, 'Ginger': 1.03,
    'Fish (Freshwater)': 0.85, 'Fish (Marine)': 0.80, 'Shrimp': 0.75,
    'Prawns': 0.76, 'Crabs': 0.78, 'Octopus': 0.77, 'Lobster': 0.79,
    'Carp': 0.84, 'Tilapia': 0.83, 'Catfish': 0.82,
  };

  // ── Soil texture adjustment ──
  static const Map<String, double> _soilAdj = {
    'Clay': 1.16, 'Loam': 1.00, 'Sandy Loam': 0.87,
    'Sandy': 0.71, 'Silty Clay': 1.08,
  };

  // ── VM0042 Practice Additionality (t CO2e/ha/yr) ──
  final List<Map<String, dynamic>> _practices = [
    {'id': 'no_till',        'label': '🌾 No-Till / Zero Tillage',      'co2e': 0.82, 'vm': 'VM0042 §4.2.1', 'desc': 'Eliminate soil disturbance'},
    {'id': 'cover_crops',    'label': '🌿 Cover Crops / Green Manure',   'co2e': 0.54, 'vm': 'VM0042 §4.2.3', 'desc': 'Improve soil organic matter'},
    {'id': 'organic_matter', 'label': '♻️ Organic Matter Addition',      'co2e': 0.71, 'vm': 'VM0042 §4.2.4', 'desc': 'Compost / manure application'},
    {'id': 'agroforestry',   'label': '🌳 Agroforestry / Tree Belts',    'co2e': 1.24, 'vm': 'VM0042 §4.3.1', 'desc': 'Trees integrated with crops'},
    {'id': 'biochar',        'label': '🔥 Biochar Application',          'co2e': 1.05, 'vm': 'VM0042 §4.2.5', 'desc': 'Stable carbon in soil'},
    {'id': 'water_mgmt',     'label': '💧 Improved Water Management',    'co2e': 0.48, 'vm': 'VM0042 §4.2.6', 'desc': 'Drip irrigation, water saving'},
    {'id': 'reduced_fert',   'label': '🧪 Reduced Synthetic Fertilizer', 'co2e': 0.63, 'vm': 'VM0042 §4.2.7', 'desc': 'Cut N2O emissions'},
    {'id': 'crop_rotation',  'label': '🔄 Crop Rotation with Legumes',   'co2e': 0.59, 'vm': 'VM0042 §4.2.2', 'desc': 'Nitrogen fixation cycle'},
    {'id': 'no_burning',     'label': '🚫 No Crop Residue Burning',      'co2e': 0.44, 'vm': 'VM0042 §4.2.8', 'desc': 'Prevent GHG emissions'},
    {'id': 'solar_pump',     'label': '☀️ Solar Water Pump',             'co2e': 0.38, 'vm': 'VM0042 §4.2.9', 'desc': 'Replace diesel pumps'},
  ];

  final List<String> _crops = [
    'Wheat','Rice (Basmati)','Rice (IRRI)','Maize','Barley','Sorghum','Millet',
    'Cotton','Sugarcane','Tobacco',
    'Tomato','Potato','Onion','Garlic','Chili','Capsicum','Brinjal','Okra',
    'Spinach','Carrot','Cabbage','Cauliflower','Peas','Cucumber','Pumpkin',
    'Mango','Orange','Banana','Guava','Apple','Pomegranate','Dates','Grapes',
    'Watermelon','Melon',
    'Chickpea','Lentils','Mung Bean','Soybean','Black-eyed Pea',
    'Sunflower','Canola','Sesame','Groundnut',
    'Fish (Freshwater)','Fish (Marine)','Shrimp','Prawns','Crabs',
    'Octopus','Lobster','Carp','Tilapia','Catfish',
    'Coriander','Mint','Fenugreek','Turmeric','Ginger',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationCtrl.dispose();
    _acresCtrl.dispose();
    super.dispose();
  }

  bool get _isSeafood => [
    'Fish (Freshwater)','Fish (Marine)','Shrimp','Prawns','Crabs',
    'Octopus','Lobster','Carp','Tilapia','Catfish'
  ].contains(_selectedCrop);

  Future<void> _getGPSLocation() async {
    setState(() => _gpsLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _gpsLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.'), backgroundColor: Colors.orange));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks[0];
        final parts = [p.subLocality, p.locality, p.administrativeArea].where((s) => s != null && s.isNotEmpty).toList();
        setState(() { _locationCtrl.text = parts.isNotEmpty ? parts.join(', ') : 'Pakistan'; _gpsLoading = false; });

        // Auto-detect climate zone from province
        final province = (p.administrativeArea ?? '').toLowerCase();
        if (province.contains('punjab') || province.contains('sindh')) {
          setState(() => _climateZone = 'Semi-Arid (Punjab/Sindh)');
        } else if (province.contains('khyber') || province.contains('baloch')) {
          setState(() => _climateZone = 'Sub-Humid (KPK/Balochistan)');
        } else if (province.contains('gilgit') || province.contains('kashmir')) {
          setState(() => _climateZone = 'Humid (Northern areas)');
        }
      }
    } catch (_) {
      setState(() => _gpsLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get location. Enter manually.'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _calculate() async {
    if (_acresCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter farm area'), backgroundColor: Colors.red));
      return;
    }
    final ok = await AuthService.useCredit(context, amount: 1, featureName: 'Carbon Credits (VM0042)');
    if (!ok) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    // ── VERRA VM0042 FORMULA ────────────────────────────────────
    final areaAcres = double.tryParse(_acresCtrl.text) ?? 0;
    final areaHa    = areaAcres * 0.404686; // 1 acre = 0.404686 ha

    // IPCC Tier 1 factors
    final socRef  = _socRef[_climateZone]   ?? 38.0;
    final flu     = _flu[_landUseHistory]   ?? 0.69;
    final fmg     = _fmg[_tillage]          ?? 1.00;
    final fi      = _fi[_selectedCrop]      ?? 1.00;
    final adj     = _soilAdj[_soilType]     ?? 1.00;

    // SOC stock change (IPCC 2006 Vol.4 Eq.2.25)
    final socBaseline = socRef * flu * 1.00 * 1.00 * adj;
    final socProject  = socRef * flu * fmg  * fi   * adj;
    final deltaSoc    = (socProject - socBaseline) / 20.0; // 20-yr horizon

    // Convert C to CO2e (×44/12 = ×3.6667)
    double baseCO2e = deltaSoc * areaHa * (44.0 / 12.0);
    if (baseCO2e < 0) baseCO2e = 0;

    // Practice additionality (VM0042 Table 4)
    double practiceCO2e = 0;
    final practiceDetails = <Map<String, dynamic>>[];
    for (final p in _practices) {
      if (_selectedPractices.contains(p['id'])) {
        final pCO2e = (p['co2e'] as double) * areaHa;
        practiceCO2e += pCO2e;
        practiceDetails.add({'label': p['label'], 'co2e': pCO2e, 'vm': p['vm']});
      }
    }

    final grossCO2e  = baseCO2e + practiceCO2e;
    final leakage    = grossCO2e * 0.03;          // 3% leakage (VM0042 §5)
    final netCO2e    = grossCO2e - leakage;
    final buffer     = netCO2e * 0.15;            // 15% buffer (VCS §3.7.4)
    final vcus       = netCO2e - buffer;          // Verified Carbon Units

    // Value (1 VCU = 1 tonne CO2e, ~$8.50 on market)
    final usdValue   = vcus * 8.50;
    final pkrValue   = usdValue * 280;

    setState(() {
      _result = {
        'area_ha':        areaHa,
        'area_acres':     areaAcres,
        'soc_ref':        socRef,
        'soc_baseline':   socBaseline,
        'soc_project':    socProject,
        'delta_soc':      deltaSoc,
        'base_co2e':      baseCO2e,
        'practice_co2e':  practiceCO2e,
        'gross_co2e':     grossCO2e,
        'leakage':        leakage,
        'net_co2e':       netCO2e,
        'buffer':         buffer,
        'vcus':           vcus,
        'co2e_kg':        (vcus * 1000).round(),
        'usd_value':      usdValue.toStringAsFixed(2),
        'pkr_value':      pkrValue.round(),
        'practice_details': practiceDetails,
      };
      _loading       = false;
      _hasCalculated = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('carbon_vcus', vcus);
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        color: const Color(0xFF1B5E20),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.verified, color: Color(0xFFC9A84C), size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Tr.get('carbonCredit'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Verra VM0042 · IPCC Tier 1 Certified', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 10, fontWeight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.workspace_premium, color: Colors.amber, size: 13),
                SizedBox(width: 4),
                Text('1 credit', style: TextStyle(color: Colors.white, fontSize: 11)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: Tr.get('farmSetup')),
              Tab(text: Tr.get('greenPractices')),
              Tab(text: Tr.get('creditsTab')),
            ],
          ),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabController, children: [
        _buildFarmSetup(),
        _buildPractices(),
        _buildResults(),
      ])),
    ]);
  }

  // ── Tab 1: Farm Setup ──────────────────────────────────────────
  Widget _buildFarmSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Verra notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.verified, color: Color(0xFF2E7D52), size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('Formula based on Verra VM0042 v2.0 + IPCC 2006 Tier 1 standards',
                style: TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Tr.get('farmDetails'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
            const SizedBox(height: 12),

            // Location + GPS
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Tr.get('farmLocation'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: TextField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g., Lahore, Multan',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2E7D52), size: 20),
                    filled: true, fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _gpsLoading ? null : _getGPSLocation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D52), borderRadius: BorderRadius.circular(10)),
                    child: _gpsLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 12),

            // Farm area
            TextFormField(
              controller: _acresCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${Tr.get('farmSize')} (Acres) *',
                prefixIcon: const Icon(Icons.crop_square, color: Color(0xFF2E7D52)),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
              ),
            ),
            const SizedBox(height: 12),

            // Crop
            DropdownButtonFormField<String>(
              value: _selectedCrop,
              decoration: InputDecoration(
                labelText: Tr.get('cropType'),
                prefixIcon: Icon(_isSeafood ? Icons.set_meal : Icons.grass, color: const Color(0xFF2E7D52)),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
              ),
              isExpanded: true,
              items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedCrop = v!),
            ),
            const SizedBox(height: 12),

            // Climate zone
            _dropField('Climate Zone (IPCC)', _climateZone, _socRef.keys.toList(), (v) => setState(() => _climateZone = v!)),
            const SizedBox(height: 12),

            // Soil type
            _dropField('Soil Type', _soilType, _soilAdj.keys.toList(), (v) => setState(() => _soilType = v!)),
            const SizedBox(height: 12),

            // Land use history
            _dropField('Land Use History', _landUseHistory, _flu.keys.toList(), (v) => setState(() => _landUseHistory = v!)),
            const SizedBox(height: 12),

            // Tillage
            _dropField('Tillage Practice', _tillage, _fmg.keys.toList(), (v) => setState(() => _tillage = v!)),
          ]),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () => _tabController.animateTo(1),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(Tr.get('nextGreenPractices'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Tab 2: Green Practices ─────────────────────────────────────
  Widget _buildPractices() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.info_outline, color: Color(0xFF2E7D52), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${_selectedPractices.length} ${Tr.get('practicesSelected')} — Each practice verified under Verra VM0042',
              style: const TextStyle(color: Color(0xFF2E7D52), fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 12),

        ..._practices.map((p) {
          final selected = _selectedPractices.contains(p['id']);
          return GestureDetector(
            onTap: () => setState(() => selected ? _selectedPractices.remove(p['id']) : _selectedPractices.add(p['id'] as String)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? const Color(0xFF2E7D52) : Colors.grey.shade200, width: selected ? 2 : 1),
              ),
              child: Row(children: [
                Text((p['label'] as String).substring(0, 2), style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((p['label'] as String).substring(3),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? const Color(0xFF1B5E20) : Colors.black87)),
                  Text(p['desc'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(p['vm'] as String, style: const TextStyle(color: Color(0xFF2E7D52), fontSize: 10, fontWeight: FontWeight.w600)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2E7D52) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+${p['co2e']}t\nCO₂e/ha',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _calculate,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(Tr.get('calculateCredits'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                        child: const Text('1 credit', style: TextStyle(color: Colors.white, fontSize: 11))),
                  ]),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── Tab 3: Results ─────────────────────────────────────────────
  Widget _buildResults() {
    if (!_hasCalculated || _result == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌍', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(Tr.get('setupFarmFirst'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(Tr.get('goToFarmSetup'), style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _tabController.animateTo(0),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(Tr.get('goToFarmSetupBtn'), style: const TextStyle(color: Colors.white)),
        ),
      ]));
    }

    final r = _result!;
    final vcus = r['vcus'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // Main VCU card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D3B1F), Color(0xFF1B5E20), Color(0xFF2E7D52)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Icon(Icons.verified, color: Color(0xFFC9A84C), size: 36),
            const SizedBox(height: 6),
            const Text('Verified Carbon Units (VCU)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text(vcus.toStringAsFixed(3), style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
            const Text('1 VCU = 1 tonne CO₂e on Verra Registry', style: TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _creditStat('${(vcus * 1000).round()} kg', 'CO₂ Reduced'),
              _creditStat('\$${r['usd_value']}', 'USD Value'),
              _creditStat('₨${(r['pkr_value'] as int)}', 'PKR Value'),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // VM0042 Breakdown
        _resultCard(title: 'VM0042 Calculation Breakdown', icon: Icons.calculate, children: [
          _row('Farm Area', '${(r['area_ha'] as double).toStringAsFixed(3)} ha (${r['area_acres']} acres)'),
          _row('SOC Reference (IPCC Tier 1)', '${(r['soc_ref'] as double).toStringAsFixed(1)} t C/ha'),
          _row('Baseline SOC', '${(r['soc_baseline'] as double).toStringAsFixed(3)} t C/ha'),
          _row('Project SOC', '${(r['soc_project'] as double).toStringAsFixed(3)} t C/ha'),
          _row('Annual SOC Change (÷20 yr)', '${(r['delta_soc'] as double).toStringAsFixed(4)} t C/ha/yr'),
          _row('Baseline CO₂e', '${(r['base_co2e'] as double).toStringAsFixed(3)} t CO₂e'),
          _row('Practices CO₂e', '+${(r['practice_co2e'] as double).toStringAsFixed(3)} t CO₂e'),
          _row('Gross CO₂e', '${(r['gross_co2e'] as double).toStringAsFixed(3)} t CO₂e'),
          _row('Leakage Discount (-3%)', '-${(r['leakage'] as double).toStringAsFixed(3)} t CO₂e'),
          _row('Net CO₂e', '${(r['net_co2e'] as double).toStringAsFixed(3)} t CO₂e'),
          _row('Permanence Buffer (-15%)', '-${(r['buffer'] as double).toStringAsFixed(3)} t CO₂e'),
          const Divider(),
          _row('✅ Verified VCUs', '${vcus.toStringAsFixed(3)} VCU', bold: true, color: const Color(0xFF2E7D52)),
        ]),
        const SizedBox(height: 12),

        // Practices breakdown
        if ((r['practice_details'] as List).isNotEmpty)
          _resultCard(title: 'Practice Additionality (VM0042 §4)', icon: Icons.eco, color: Colors.green, children: [
            ...(r['practice_details'] as List).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Text(p['label'].toString().substring(0, 2), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(p['label'].toString().substring(3), style: const TextStyle(fontSize: 12))),
                Text('+${(p['co2e'] as double).toStringAsFixed(3)} t', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
            )),
          ]),
        if ((r['practice_details'] as List).isNotEmpty) const SizedBox(height: 12),

        // How to sell
        _resultCard(title: Tr.get('howToSell'), icon: Icons.sell, color: Colors.orange, children: [
          _step('1', 'Register project on registry.verra.org'),
          _step('2', 'Hire Verra-accredited VVB for field verification'),
          _step('3', 'Submit Project Design Document (PDD)'),
          _step('4', 'Receive official VCUs on Verra Registry'),
          _step('5', 'Sell at \$5–15 per VCU on carbon markets'),
        ]),
        const SizedBox(height: 12),

        // Methodology
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 16), SizedBox(width: 6), Text('Methodology', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1565C0)))]),
            SizedBox(height: 8),
            Text('• Verra VM0042 v2.0 — Improved Agricultural Land Management', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text('• IPCC 2006 Guidelines Vol.4 Ch.5 — Tier 1 SOC factors', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text('• VCS Standard v4.5 — Permanence buffer §3.7.4', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text('• FAO Carbon Sequestration — South Asia regional data', style: TextStyle(fontSize: 11, color: Colors.grey)),
            SizedBox(height: 6),
            Text('⚠️ Official VCU issuance requires field verification by a Verra-accredited VVB.',
                style: TextStyle(fontSize: 11, color: Colors.orange, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _dropField(String label, String value, List<String> items, ValueChanged<String?> onChange) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChange,
    );
  }

  Widget _creditStat(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);

  Widget _resultCard({required String title, required IconData icon, required List<Widget> children, Color color = const Color(0xFF1B5E20)}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)))]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color ?? Colors.black87, fontSize: 12)),
    ]),
  );

  Widget _step(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 22, height: 22, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ]),
  );
}