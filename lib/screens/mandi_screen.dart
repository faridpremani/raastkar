import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/tr.dart';

class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});
  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  static const String _base = 'https://raastkar-backend.vercel.app';

  List<Map<String, dynamic>> _allPrices  = [];
  List<Map<String, dynamic>> _filtered   = [];
  List<String> _cities = ['All Cities'];
  List<String> _crops  = ['All Crops'];

  String _selectedCity = 'All Cities';
  String _selectedCrop = 'All Crops';
  String _searchQuery  = '';
  String _lastUpdated  = '';
  String _source       = '';
  String _date         = '';

  bool _loading  = true;
  bool _hasError = false;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      String url = '$_base/api/mandi';
      final params = <String>[];
      if (_selectedCity != 'All Cities') params.add('city=${Uri.encodeComponent(_selectedCity)}');
      if (_selectedCrop != 'All Crops')  params.add('crop=${Uri.encodeComponent(_selectedCrop)}');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      final data     = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final prices = (data['prices'] as List).cast<Map<String, dynamic>>();
        final cities = ['All Cities', ...(data['cities'] as List? ?? []).cast<String>()];
        final crops  = ['All Crops',  ...(data['crops']  as List? ?? []).cast<String>()];

        setState(() {
          _allPrices   = prices;
          _filtered    = prices;
          _cities      = cities;
          _crops       = crops;
          _lastUpdated = data['lastUpdated'] as String? ?? '';
          _source      = data['source']      as String? ?? 'estimated';
          _date        = data['date']        as String? ?? '';
          _loading     = false;
        });
        _applyFilters();
      } else {
        setState(() { _loading = false; _hasError = true; });
      }
    } catch (e) {
      setState(() { _loading = false; _hasError = true; });
    }
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allPrices);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
        (p['crop']  as String? ?? '').toLowerCase().contains(q) ||
        (p['city']  as String? ?? '').toLowerCase().contains(q) ||
        (p['urdu']  as String? ?? '').contains(q)
      ).toList();
    }
    setState(() => _filtered = list);
  }

  String _timeAgo(String iso) {
    if (iso.isEmpty) return 'Unknown';
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24)  return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return 'Recently'; }
  }

  Color _sourceColor() {
    if (_source == 'amis.pk')       return Colors.green;
    if (_source == 'kisan.com.pk')  return Colors.blue;
    return Colors.orange;
  }

  String _sourceLabel() {
    if (_source == 'amis.pk')       return '🟢 Live — amis.pk';
    if (_source == 'kisan.com.pk')  return '🔵 Live — kisan.com.pk';
    return '🟡 Estimated Prices';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D3B1F), Color(0xFF1B5E20)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.storefront, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mandi Prices', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Pakistan Agricultural Markets', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
            ])),
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_sourceLabel(), style: TextStyle(color: _source == 'estimated' ? Colors.orange.shade200 : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),

          // Last updated + refresh
          Row(children: [
            const Icon(Icons.access_time, color: Colors.white54, size: 12),
            const SizedBox(width: 4),
            Text('Updated: ${_timeAgo(_lastUpdated)}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const Spacer(),
            GestureDetector(
              onTap: _loading ? null : _loadPrices,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_loading ? Icons.hourglass_empty : Icons.refresh, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  const Text('Refresh', style: TextStyle(color: Colors.white, fontSize: 11)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Search
          Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search crop or city...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.white54, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) { _searchQuery = v; _applyFilters(); },
            ),
          ),
        ]),
      ),

      // Filters
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Expanded(child: _filterDropdown('City', _selectedCity, _cities, (v) {
            setState(() => _selectedCity = v!);
            _loadPrices();
          })),
          const SizedBox(width: 8),
          Expanded(child: _filterDropdown('Crop', _selectedCrop, _crops, (v) {
            setState(() => _selectedCrop = v!);
            _loadPrices();
          })),
        ]),
      ),

      // Stats bar
      if (!_loading && !_hasError)
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Text('${_filtered.length} results', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            Text(_date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),

      // Content
      Expanded(child: _loading
          ? _buildLoading()
          : _hasError
              ? _buildError()
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : _buildPriceList()),
    ]);
  }

  Widget _filterDropdown(String hint, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(color: Colors.black87, fontSize: 12),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: Color(0xFF2E7D52)),
      const SizedBox(height: 16),
      const Text('Loading mandi prices...', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 8),
      const Text('Fetching from amis.pk & kisan.com.pk', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]));
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
      const SizedBox(height: 16),
      const Text('Could not load prices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Check internet connection', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _loadPrices,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Try Again', style: TextStyle(color: Colors.white)),
      ),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🌾', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      const Text('No prices found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Try a different city or crop', style: TextStyle(color: Colors.grey.shade500)),
    ]));
  }

  Widget _buildPriceList() {
    // Group by crop
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final p in _filtered) {
      final crop = p['crop'] as String? ?? 'Other';
      grouped.putIfAbsent(crop, () => []).add(p);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: grouped.length,
      itemBuilder: (context, idx) {
        final crop   = grouped.keys.elementAt(idx);
        final prices = grouped[crop]!;
        return _buildCropCard(crop, prices);
      },
    );
  }

  Widget _buildCropCard(String crop, List<Map<String, dynamic>> prices) {
    final first   = prices.first;
    final emoji   = first['emoji']  as String? ?? '🌾';
    final urdu    = first['urdu']   as String? ?? '';
    final unit    = first['unit']   as String? ?? '40kg';

    // Average price across cities
    final avgPrice = prices.isNotEmpty
        ? (prices.map((p) => p['avg_price'] as int? ?? 0).reduce((a, b) => a + b) / prices.length).round()
        : 0;
    final minPrice = prices.isNotEmpty ? prices.map((p) => p['min_price'] as int? ?? 0).reduce((a, b) => a < b ? a : b) : 0;
    final maxPrice = prices.isNotEmpty ? prices.map((p) => p['max_price'] as int? ?? 0).reduce((a, b) => a > b ? a : b) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Crop header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D3B1F), Color(0xFF1B5E20)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(crop, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              if (urdu.isNotEmpty)
                Text(urdu, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Per $unit (maund)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₨ ${avgPrice.toLocaleString()}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('avg', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
            ]),
          ]),
        ),

        // Price summary row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade50),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _priceTag('Min', '₨ $minPrice', Colors.green),
            Container(width: 1, height: 24, color: Colors.grey.shade300),
            _priceTag('Avg', '₨ $avgPrice', const Color(0xFF1B5E20)),
            Container(width: 1, height: 24, color: Colors.grey.shade300),
            _priceTag('Max', '₨ $maxPrice', Colors.red),
            Container(width: 1, height: 24, color: Colors.grey.shade300),
            _priceTag('Cities', '${prices.length}', Colors.blue),
          ]),
        ),

        // City breakdown (show first 5)
        if (prices.length > 1) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              ...prices.take(5).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Expanded(child: Text(p['city'] as String? ?? '', style: const TextStyle(fontSize: 13))),
                  Text('₨ ${p['min_price']} – ${p['max_price']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '₨ ${p['avg_price']}'));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${p['crop']} price copied!'),
                        backgroundColor: const Color(0xFF2E7D52),
                        duration: const Duration(seconds: 1),
                      ));
                    },
                    child: Text('₨ ${p['avg_price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                  ),
                ]),
              )),
              if (prices.length > 5)
                Text('+ ${prices.length - 5} more cities', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _priceTag(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
  ]);
}

extension IntExt on int {
  String toLocaleString() {
    return toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}