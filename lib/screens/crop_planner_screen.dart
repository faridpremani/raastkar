import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';
import '../services/tr.dart';
import '../services/credit_service.dart';

class CropPlannerScreen extends StatefulWidget {
  const CropPlannerScreen({super.key});
  @override
  State<CropPlannerScreen> createState() => _CropPlannerScreenState();
}

class _CropPlannerScreenState extends State<CropPlannerScreen>
    with TickerProviderStateMixin {
  final _locationController = TextEditingController();
  final _phController       = TextEditingController();
  final _tdsController      = TextEditingController();
  final _salinityController = TextEditingController();

  bool _loading    = false;
  bool _gpsLoading = false;
  List<dynamic> _crops = [];
  String _error   = '';
  double _soilScore  = 0;
  String _soilRating = '';
  Color  _soilColor  = Colors.grey;

  late AnimationController _scoreAnimController;
  late Animation<double>   _scoreAnim;

  static const _green  = Color(0xFF2E7D52);
  static const _green2 = Color(0xFF1B6B3A);
  static const _dark   = Color(0xFF071F10);
  static const _gold   = Color(0xFFC9A84C);
  static const _greenL = Color(0xFFE8F5E9);

  final List<String> _pakistanCities = [
    'Karachi','Lahore','Faisalabad','Rawalpindi','Gujranwala','Peshawar',
    'Multan','Hyderabad','Islamabad','Quetta','Bahawalpur','Sargodha',
    'Sialkot','Sukkur','Larkana','Sheikhupura','Rahim Yar Khan','Jhang',
    'Dera Ghazi Khan','Gujrat','Sahiwal','Mardan','Kasur','Okara','Mingora',
    'Nawabshah','Chiniot','Hafizabad','Mirpur Khas','Abbottabad','Mansehra',
    'Swat','Kohat','Bannu','Dera Ismail Khan','Chakwal','Jhelum',
    'Mandi Bahauddin','Khanewal','Pakpattan','Lodhran','Vehari','Mianwali',
    'Bhakkar','Layyah','Muzaffargarh','Rajanpur','Jacobabad','Shikarpur',
    'Dadu','Jamshoro','Thatta','Badin','Umerkot','Sanghar','Khairpur',
    'Ghotki','Turbat','Khuzdar','Chaman','Hub','Zhob','Gwadar','Charsadda',
    'Nowshera','Haripur','Attock','Taxila','Wazirabad','Daska','Narowal',
    'Toba Tek Singh','Kamalia','Chichawatni','Arifwala','Burewala',
    'Hasilpur','Sadiqabad','Gilgit','Skardu','Hunza','Muzaffarabad',
    'Mirpur','Rawalakot','Kalam','Chitral','Dir','Murree',
  ];

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOut));
    _phController.addListener(_calculateSoilScore);
    _tdsController.addListener(_calculateSoilScore);
    _salinityController.addListener(_calculateSoilScore);
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    _locationController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _salinityController.dispose();
    super.dispose();
  }

  Future<void> _getGPSLocation() async {
    setState(() => _gpsLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _gpsLoading = false);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permission denied.'),
              backgroundColor: Colors.orange));
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final parts = <String>[];
        if (p.subLocality?.isNotEmpty == true)       parts.add(p.subLocality!);
        if (p.locality?.isNotEmpty == true)           parts.add(p.locality!);
        if (p.administrativeArea?.isNotEmpty == true) parts.add(p.administrativeArea!);
        setState(() {
          _locationController.text = parts.isNotEmpty ? parts.join(', ') : 'Pakistan';
          _gpsLoading = false;
        });
      }
    } catch (_) {
      setState(() => _gpsLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not get location. Please enter manually.'),
            backgroundColor: Colors.orange));
    }
  }

  void _calculateSoilScore() {
    final ph       = double.tryParse(_phController.text)       ?? 0;
    final tds      = double.tryParse(_tdsController.text)      ?? 0;
    final salinity = double.tryParse(_salinityController.text) ?? 0;
    if (ph == 0 && tds == 0 && salinity == 0) { setState(() => _soilScore = 0); return; }

    double phScore = ph >= 6.0 && ph <= 7.0 ? 100
        : ((ph >= 5.5 && ph < 6.0) || (ph > 7.0 && ph <= 7.5)) ? 70
        : ph > 0 ? 40 : 0;
    double tdsScore = tds > 0 && tds < 500 ? 100
        : tds < 1000 ? 75 : tds < 2000 ? 50 : tds >= 2000 ? 25 : 0;
    double salScore = salinity > 0 && salinity < 2 ? 100
        : salinity < 4 ? 70 : salinity < 8 ? 40 : salinity >= 8 ? 10 : 0;

    final score = phScore * 0.4 + tdsScore * 0.3 + salScore * 0.3;
    String rating; Color color;
    if (score >= 80)      { rating = Tr.get('excellent'); color = _green; }
    else if (score >= 60) { rating = Tr.get('good');      color = const Color(0xFF4CAF50); }
    else if (score >= 40) { rating = Tr.get('moderate');  color = Colors.orange; }
    else                  { rating = Tr.get('poor');       color = Colors.red; }

    _scoreAnim = Tween<double>(begin: _soilScore / 100, end: score / 100)
        .animate(CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOut));
    _scoreAnimController.forward(from: 0);
    setState(() { _soilScore = score; _soilRating = rating; _soilColor = color; });
  }

  Future<void> _analyze() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.get('pleaseEnterLocation')), backgroundColor: Colors.orange));
      return;
    }
    if (_phController.text.isEmpty || _tdsController.text.isEmpty || _salinityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.get('pleaseFillAllValues')), backgroundColor: Colors.orange));
      return;
    }
    final ok = await CreditService.useCredit(context, amount: 1, featureName: 'Crop Planner AI');
    if (!ok) return;
    setState(() { _loading = true; _error = ''; _crops = []; });
    try {
      final result = await ApiService.getCropRecommendations(
        location: _locationController.text,
        ph:       _phController.text,
        tds:      _tdsController.text,
        salinity: _salinityController.text,
      );
      setState(() {
        if (result['success'] == true) _crops = result['crops'];
        else _error = result['error'] ?? Tr.get('couldNotGet');
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = Tr.get('connectionError'); _loading = false; });
    }
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputCard(),
                if (_soilScore > 0) ...[
                  const SizedBox(height: 16),
                  _buildSoilScoreCard(),
                ],
                const SizedBox(height: 16),
                _buildAnalyzeButton(),
                if (_loading) ...[
                  const SizedBox(height: 24),
                  _buildLoadingCard(),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(),
                ],
                if (_crops.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildResultsHeader(),
                  const SizedBox(height: 12),
                  ..._crops.asMap().entries
                      .map((e) => _CropResultCard(crop: e.value, rank: e.key + 1)),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO ──────────────────────────────────────
  Widget _buildHero() {
    return Stack(
      children: [
        // Photo background
        SizedBox(
          width: double.infinity,
          height: 190,
          child: Image.network(
            'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: _green2),
          ),
        ),
        // Gradient overlay
        Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.78),
                _green2.withValues(alpha: 0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Content
        Column(
          children: [
            // Title row + badges
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.eco,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Tr.get('cropPlanner'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold)),
                            Text(Tr.get('cropPlannerDesc'),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _badge('⚗️', 'Soil pH'),
                        const SizedBox(width: 8),
                        _badge('🤖', 'AI Powered'),
                        const SizedBox(width: 8),
                        _badge('📍', 'GPS'),
                        const SizedBox(width: 8),
                        FutureBuilder<int>(
                          future: CreditService.getRemaining(),
                          builder: (ctx, snap) {
                            final cr = snap.data ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: cr > 0
                                    ? _gold.withValues(alpha: 0.25)
                                    : Colors.red.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: cr > 0
                                        ? _gold.withValues(alpha: 0.6)
                                        : Colors.red.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium,
                                      color: cr > 0 ? _gold : Colors.white,
                                      size: 13),
                                  const SizedBox(width: 4),
                                  Text('$cr credits',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Stats bar
            Container(
              margin: const EdgeInsets.only(top: 14),
              color: Colors.black.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('50+', 'Crops'),
                  _vDivider(),
                  _stat('99%', 'Accuracy'),
                  _vDivider(),
                  _stat('1 cr', 'Per Use'),
                  _vDivider(),
                  _stat('GPS', 'Auto Fill'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _stat(String v, String l) {
    return Column(children: [
      Text(v,
          style: const TextStyle(
              color: _gold, fontSize: 15, fontWeight: FontWeight.bold)),
      Text(l,
          style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]);
  }

  Widget _vDivider() =>
      Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2));

  // ── INPUT CARD ────────────────────────────────
  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _greenL,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _green, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.agriculture,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Tr.get('yourFarmDetails'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text(Tr.get('enterSoilData'),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Tr.get('location'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (tv) {
                        if (tv.text.length < 2)
                          return const Iterable<String>.empty();
                        return _pakistanCities
                            .where((c) => c
                                .toLowerCase()
                                .contains(tv.text.toLowerCase()))
                            .take(6);
                      },
                      onSelected: (s) => _locationController.text = s,
                      fieldViewBuilder: (ctx, ctrl, fn, _) {
                        if (_locationController.text.isNotEmpty &&
                            ctrl.text.isEmpty)
                          ctrl.text = _locationController.text;
                        return TextField(
                          controller: ctrl,
                          focusNode: fn,
                          onChanged: (v) => _locationController.text = v,
                          decoration: _inputDeco(
                              Tr.get('locationHint'), Icons.location_on),
                        );
                      },
                      optionsViewBuilder: (ctx, onSel, opts) => Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxHeight: 220),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: opts.length,
                              itemBuilder: (_, i) {
                                final opt = opts.elementAt(i);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_on,
                                      color: _green, size: 18),
                                  title: Text(opt,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                  subtitle: const Text('Pakistan',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey)),
                                  onTap: () => onSel(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _gpsLoading ? null : _getGPSLocation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(10)),
                      child: _gpsLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.gps_fixed,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _field(_phController, Tr.get('soilPh'),
                          'e.g., 6.5', Icons.science, Colors.purple)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(_tdsController, Tr.get('tds'),
                          'e.g., 800', Icons.water_drop, Colors.blue)),
                ]),
                const SizedBox(height: 12),
                _field(_salinityController, Tr.get('salinity'), 'e.g., 1.5',
                    Icons.waves, Colors.teal),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _greenL,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: _green, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Ideal: pH 6-7 · TDS < 500 ppm · Salinity < 2 dS/m',
                      style: TextStyle(color: _green, fontSize: 12),
                    )),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon,
      {Color col = _green}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: col, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      IconData icon, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDeco(hint, icon, col: col),
        ),
      ],
    );
  }

  // ── SOIL SCORE ────────────────────────────────
  Widget _buildSoilScoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _soilColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _soilColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Tr.get('soilScore'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _soilColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _soilColor.withValues(alpha: 0.3)),
                ),
                child: Text(_soilRating,
                    style: TextStyle(
                        color: _soilColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_soilScore.toInt()}',
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: _soilColor)),
            const Text('/100',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ]),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _scoreAnim.value,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_soilColor),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _ScoreChip(
                label: Tr.get('soilPh'),
                value: _phController.text,
                color: Colors.purple),
            const SizedBox(width: 8),
            _ScoreChip(
                label: 'TDS',
                value: '${_tdsController.text} ppm',
                color: Colors.blue),
            const SizedBox(width: 8),
            _ScoreChip(
                label: Tr.get('salinity'),
                value: '${_salinityController.text} dS/m',
                color: Colors.teal),
          ]),
        ],
      ),
    );
  }

  // ── ANALYZE BUTTON ────────────────────────────
  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: _loading
            ? null
            : const LinearGradient(
                colors: [_dark, _green2, _green],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
        color: _loading ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _loading
            ? null
            : [
                BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _analyze,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _loading ? 'Analyzing...' : '✨ Get AI Recommendation',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Text('1 credit',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        const CircularProgressIndicator(color: _green, strokeWidth: 3),
        const SizedBox(height: 20),
        const Text('🌾', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        Text(Tr.get('aiAnalyzing'),
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(Tr.get('checkingCrop'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Tr.get('couldNotGet'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
            Text(_error,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_dark, _green2, _green],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(Tr.get('topRecommendations'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_crops.length} ${Tr.get('cropsFound')}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────
class _CropResultCard extends StatelessWidget {
  final dynamic crop;
  final int rank;
  const _CropResultCard({required this.crop, required this.rank});

  Color get _rankColor {
    switch (rank) {
      case 1:  return const Color(0xFF2E7D52);
      case 2:  return const Color(0xFF1565C0);
      case 3:  return const Color(0xFF6A1B9A);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = (crop['confidence_percent'] as num?)?.toInt() ?? 0;
    final price      = (crop['market_price_pkr']   as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFF2E7D52).withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: rank == 1 ? 2 : 1,
        ),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                    color: const Color(0xFF2E7D52).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: Column(children: [
        // Rank strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _rankColor.withValues(alpha: 0.07),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(15)),
            border: Border(
                bottom:
                    BorderSide(color: _rankColor.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: _rankColor,
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text('#$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop['name'] ?? 'Unknown',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(crop['season'] ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rankColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$confidence%',
                    style: TextStyle(
                        color: _rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 70,
                  child: LinearProgressIndicator(
                    value: confidence / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_rankColor),
                    minHeight: 5,
                  ),
                ),
              ),
            ]),
          ]),
        ),
        // Info tiles
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              _InfoTile(
                  icon: Icons.water_drop,
                  label: Tr.get('waterNeeds'),
                  value: '${crop['water_needs_mm'] ?? 0} mm',
                  color: Colors.blue),
              _InfoTile(
                  icon: Icons.agriculture,
                  label: Tr.get('yield'),
                  value: crop['yield_per_acre'] ?? '-',
                  color: const Color(0xFF2E7D52)),
              _InfoTile(
                  icon: Icons.storefront,
                  label: Tr.get('marketPrice'),
                  value: 'PKR $price',
                  color: Colors.orange),
            ]),
            if (crop['quick_tip'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates,
                          color: Color(0xFF2E7D52), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(crop['quick_tip'],
                              style: const TextStyle(
                                  color: Color(0xFF2E7D52),
                                  fontSize: 12,
                                  height: 1.4))),
                    ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ScoreChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}