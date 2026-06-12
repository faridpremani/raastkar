import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/tr.dart';

class DrCropScreen extends StatefulWidget {
  const DrCropScreen({super.key});

  @override
  State<DrCropScreen> createState() => _DrCropScreenState();
}

class _DrCropScreenState extends State<DrCropScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCrop = 'Wheat';
  final List<String> _selectedSymptoms = [];
  final _customSymptomsController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageBase64;
  String _photoCrop = 'Wheat';
  String _selectedUnit = 'kg';
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  Map<String, dynamic>? _diagnosis;
  String _error = '';

  final List<Map<String, dynamic>> _crops = [
    {'name': 'Wheat', 'icon': Icons.grass, 'color': Colors.amber},
    {'name': 'Rice', 'icon': Icons.spa, 'color': Colors.green},
    {'name': 'Cotton', 'icon': Icons.filter_vintage, 'color': Colors.purple},
    {'name': 'Maize', 'icon': Icons.eco, 'color': Colors.orange},
    {'name': 'Tomato', 'icon': Icons.circle, 'color': Colors.red},
    {'name': 'Potato', 'icon': Icons.lens, 'color': Colors.brown},
    {'name': 'Sugarcane', 'icon': Icons.nature, 'color': Colors.teal},
    {'name': 'Onion', 'icon': Icons.radio_button_checked, 'color': Colors.pink},
    {'name': 'Chili', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'name': 'Mango', 'icon': Icons.park, 'color': Colors.yellow},
    {'name': 'Fish', 'icon': Icons.set_meal, 'color': Colors.blue},
    {'name': 'Shrimp', 'icon': Icons.set_meal, 'color': Colors.cyan},
  ];

  final List<String> _symptomOptions = [
    'Yellow leaves', 'Brown spots on leaves', 'White powder on leaves',
    'Wilting / drooping', 'Black spots', 'Holes in leaves',
    'Rust colored patches', 'Stunted growth', 'Root rot', 'Curling leaves',
    'Dead patches in field', 'Sticky residue on leaves', 'Pale green color',
    'Purple discoloration', 'Water soaked lesions', 'Stem blackening',
    'Fruit rotting', 'Leaf drop',
  ];

  final List<String> _units = ['kg', 'pounds', 'tons'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() { _diagnosis = null; _error = ''; });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customSymptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageBase64 = base64Encode(bytes);
          _diagnosis = null;
          _error = '';
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not access camera/gallery. Check permissions.');
    }
  }

  Future<void> _diagnoseWithPhoto() async {
    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.get('takePhotoOrUpload')),
              backgroundColor: Colors.orange));
      return;
    }

    // ── 3 credits for Photo Analysis ──
    final ok = await AuthService.useCredit(
      context,
      amount: 3,
      featureName: 'Photo Analysis',
    );
    if (!ok) return;

    setState(() { _loading = true; _error = ''; _diagnosis = null; });
    try {
      final result = await ApiService.getDiagnosisFromPhoto(
          crop: _photoCrop, base64Image: _imageBase64!);
      setState(() {
        if (result['success'] == true) _diagnosis = result['diagnosis'];
        else _error = result['error'] ?? Tr.get('couldNotGet');
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Error: ${e.toString()}'; _loading = false; });
    }
  }

  Future<void> _diagnoseWithSymptoms() async {
    if (_selectedSymptoms.isEmpty && _customSymptomsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.get('pleaseSelectSymptom')),
              backgroundColor: Colors.orange));
      return;
    }

    // ── 2 credits for Dr Crop Diagnosis ──
    final ok = await AuthService.useCredit(
      context,
      amount: 2,
      featureName: 'Dr Crop Diagnosis',
    );
    if (!ok) return;

    final allSymptoms = [..._selectedSymptoms,
      if (_customSymptomsController.text.isNotEmpty)
        _customSymptomsController.text].join(', ');
    setState(() { _loading = true; _error = ''; _diagnosis = null; });
    try {
      final result = await ApiService.getDiagnosis(
          crop: _selectedCrop, symptoms: allSymptoms);
      setState(() {
        if (result['success'] == true) _diagnosis = result['diagnosis'];
        else _error = result['error'] ?? Tr.get('couldNotGet');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = Tr.get('connectionError');
        _loading = false;
      });
    }
  }

  Color _getSeverityColor(String s) {
    switch (s.toLowerCase()) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.deepOrange;
      case 'critical': return Colors.red;
      default: return Colors.grey;
    }
  }

  double _getSeverityValue(String s) {
    switch (s.toLowerCase()) {
      case 'low': return 0.25;
      case 'medium': return 0.50;
      case 'high': return 0.75;
      case 'critical': return 1.0;
      default: return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          // Credit info bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _creditBadge(Icons.checklist, '2 credits', 'Symptom Check', Colors.orange),
                const SizedBox(width: 8),
                _creditBadge(Icons.camera_alt, '3 credits', 'Photo Analysis', Colors.purple),
              ],
            ),
          ),
          // Unit Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Unit: ',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ..._units.map((u) {
                  final isSelected = _selectedUnit == u;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedUnit = u),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2E7D52) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(u,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 12)),
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D52),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D52),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.checklist, size: 16),
                      const SizedBox(width: 4),
                      Text(Tr.get('symptomCheck')),
                      const SizedBox(width: 4),
                      _tabBadge('2cr', Colors.orange),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 16),
                      const SizedBox(width: 4),
                      Text(Tr.get('photoAnalysis')),
                      const SizedBox(width: 4),
                      _tabBadge('3cr', Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSymptomTab(),
                _buildPhotoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditBadge(IconData icon, String credits, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(credits, style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Farming/plant photo background
        SizedBox(
          width: double.infinity,
          height: 170,
          child: Image.network(
            'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(color: const Color(0xFF1B5E20)),
          ),
        ),
        // Overlay
        Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.78),
                const Color(0xFF1B5E20).withValues(alpha: 0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Content
        SizedBox(
          width: double.infinity,
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.medical_services, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Tr.get('drCrop'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(Tr.get('drCropDesc'),
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _heroBadge('🌾', '50+ Crops'),
                      const SizedBox(width: 8),
                      _heroBadge('🤖', 'AI Diagnosis'),
                      const SizedBox(width: 8),
                      _heroBadge('📸', 'Photo Analysis'),
                      const SizedBox(width: 8),
                      _heroBadge('🌿', 'Organic Tips'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Stats bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.black.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroStat('50+', 'Crops'),
                Container(width: 1, height: 24, color: Colors.white24),
                _heroStat('2cr', 'Symptom'),
                Container(width: 1, height: 24, color: Colors.white24),
                _heroStat('3cr', 'Photo AI'),
                Container(width: 1, height: 24, color: Colors.white24),
                _heroStat('99%', 'Accuracy'),
              ],
            ),
          ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _heroBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildSymptomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('Uses 2 credits per diagnosis',
                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCropSelector(),
          const SizedBox(height: 16),
          _buildSymptomSelector(),
          const SizedBox(height: 12),
          TextField(
            controller: _customSymptomsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: Tr.get('describeSymptoms'),
              hintText: 'e.g., leaves turning yellow from edges...',
              prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF2E7D52)),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E7D52), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _diagnoseWithSymptoms,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search, color: Colors.white),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _loading ? Tr.get('diagnosing') : '${Tr.get('diagnose')} $_selectedCrop',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (!_loading) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('2 credits', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 24),
            _buildLoadingCard(isPhoto: false),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],
          if (_diagnosis != null) ...[
            const SizedBox(height: 16),
            _buildDiagnosisResult(cropName: _selectedCrop, isPhoto: false),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.purple, size: 16),
                SizedBox(width: 8),
                Text('Uses 3 credits per photo analysis',
                    style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E7D52).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF2E7D52), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Take a clear photo of the affected plant part for instant AI diagnosis',
                    style: TextStyle(color: Color(0xFF2E7D52), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(Tr.get('selectCropType'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _crops.map((c) {
                final selected = _photoCrop == c['name'];
                final Color color = c['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _photoCrop = c['name'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c['icon'] as IconData, size: 14,
                            color: selected ? Colors.white : color),
                        const SizedBox(width: 4),
                        Text(c['name'] as String,
                            style: TextStyle(
                                color: selected ? Colors.white : color,
                                fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(Tr.get('photoAnalysis'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_imageBytes == null)
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E7D52).withValues(alpha: 0.4), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo, color: Color(0xFF2E7D52), size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(Tr.get('noPhotoSelected'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2E7D52))),
                  Text(Tr.get('takePhotoOrUpload'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_imageBytes!, width: double.infinity, height: 260, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _imageBytes = null;
                      _imageBase64 = null;
                      _diagnosis = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(Tr.get('takePhoto')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D52),
                    side: const BorderSide(color: Color(0xFF2E7D52)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: Text(Tr.get('fromGallery')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D52),
                    side: const BorderSide(color: Color(0xFF2E7D52)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _diagnoseWithPhoto,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.biotech, color: Colors.white),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _loading ? Tr.get('gettingDiagnosis') : Tr.get('getDiagnosis'),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (!_loading) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('3 credits', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _imageBytes == null ? Colors.grey : const Color(0xFF2E7D52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            _buildLoadingCard(isPhoto: true),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildErrorCard(),
          ],
          if (_diagnosis != null) ...[
            const SizedBox(height: 16),
            _buildDiagnosisResult(cropName: _photoCrop, isPhoto: true),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
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
          Text(Tr.get('selectCrop'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _crops.map((c) {
              final selected = _selectedCrop == c['name'];
              final Color color = c['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedCrop = c['name'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c['icon'] as IconData, size: 16,
                          color: selected ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(c['name'] as String,
                          style: TextStyle(
                              color: selected ? Colors.white : color,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomSelector() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Tr.get('selectSymptoms'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (_selectedSymptoms.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D52),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_selectedSymptoms.length} selected',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _symptomOptions.map((s) {
              final selected = _selectedSymptoms.contains(s);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) _selectedSymptoms.remove(s);
                  else _selectedSymptoms.add(s);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2E7D52) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF2E7D52) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w500 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({required bool isPhoto}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF2E7D52)),
          const SizedBox(height: 16),
          Text(isPhoto ? Tr.get('analyzingPhoto') : Tr.get('analyzing'),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          const SizedBox(height: 6),
          Text(isPhoto ? Tr.get('detectingDisease') : Tr.get('checkingDatabase'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_error, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildDiagnosisResult({required String cropName, required bool isPhoto}) {
    final d = _diagnosis!;
    final severity = d['severity'] ?? 'medium';
    final severityColor = _getSeverityColor(severity);
    final severityValue = _getSeverityValue(severity);
    final confidence = (d['confidence_percent'] as num?)?.toInt() ?? 0;
    final organicTreatment = (d['organic_treatment'] as List?)?.cast<String>() ?? [];
    final preventionSteps = (d['prevention_steps'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPhoto && _imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_imageBytes!, width: double.infinity, height: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: severityColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.coronavirus, color: severityColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['disease_name'] ?? 'Unknown Disease',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$cropName · $confidence% confidence',
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(severity.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(Tr.get('severityLevel'),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: severityValue,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (organicTreatment.isNotEmpty)
          _TreatmentCard(
            title: Tr.get('organicTreatment'),
            icon: Icons.eco,
            color: const Color(0xFF2E7D52),
            steps: organicTreatment,
          ),
        const SizedBox(height: 10),
        if (d['chemical_treatment'] != null)
          _ChemicalCard(treatment: d['chemical_treatment']),
        const SizedBox(height: 10),
        if (preventionSteps.isNotEmpty)
          _TreatmentCard(
            title: Tr.get('preventionSteps'),
            icon: Icons.shield,
            color: const Color(0xFF1565C0),
            steps: preventionSteps,
          ),
        const SizedBox(height: 10),
        if (d['fertilizer_schedule'] != null || d['water_recommendation'] != null)
          _CareCard(fertilizer: d['fertilizer_schedule'], water: d['water_recommendation']),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> steps;
  const _TreatmentCard({required this.title, required this.icon, required this.color, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ]),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ChemicalCard extends StatelessWidget {
  final dynamic treatment;
  const _ChemicalCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.science, color: Color(0xFF1565C0), size: 18),
            const SizedBox(width: 8),
            Text(Tr.get('chemicalTreatment'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1565C0))),
          ]),
          const SizedBox(height: 10),
          if (treatment['product'] != null) _InfoRow(label: 'Product', value: treatment['product']),
          if (treatment['dose'] != null) _InfoRow(label: 'Dose', value: treatment['dose']),
          if (treatment['frequency'] != null) _InfoRow(label: 'Frequency', value: treatment['frequency']),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final String? fertilizer, water;
  const _CareCard({this.fertilizer, this.water});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E7D52).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Tr.get('careRecommendations'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D52))),
          const SizedBox(height: 10),
          if (fertilizer != null)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.science, color: Color(0xFF2E7D52), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(fertilizer!, style: const TextStyle(fontSize: 13))),
            ]),
          if (water != null) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(water!, style: const TextStyle(fontSize: 13))),
            ]),
          ],
        ],
      ),
    );
  }
}