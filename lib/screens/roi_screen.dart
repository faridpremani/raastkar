import 'package:flutter/material.dart';

class ROIScreen extends StatefulWidget {
  const ROIScreen({super.key});

  @override
  State<ROIScreen> createState() =>
      _ROIScreenState();
}

class _ROIScreenState extends State<ROIScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  double _areaValue = 1.0;
  String _areaUnit = 'Acre';
  String? _selectedCrop;
  String _selectedCropType = 'Grain';
  String _sowingMonth = 'October';
  String _harvestMonth = 'April';
  int _sowingYear = 2025;
  int _harvestYear = 2026;
  double _expectedYield = 0;
  double _raastkarYield = 0;
  double _marketRate = 0;
  double _seedCost = 0;
  double _landPrepCost = 0;
  double _laborCost = 0;
  double _employeeCost = 0;
  double _fuelCost = 0;
  double _fertilizerCost = 0;
  double _pesticideCost = 0;
  double _transportCost = 0;
  String _filterType = 'All';

  final List<String> _months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  final List<Map<String, dynamic>> _crops = [
    {'name': 'Wheat', 'type': 'Grain', 'yield': 45.0, 'price': 3500.0},
    {'name': 'Rice (Basmati)', 'type': 'Grain', 'yield': 35.0, 'price': 8500.0},
    {'name': 'Rice (IRRI)', 'type': 'Grain', 'yield': 55.0, 'price': 4500.0},
    {'name': 'Maize', 'type': 'Grain', 'yield': 60.0, 'price': 2800.0},
    {'name': 'Barley', 'type': 'Grain', 'yield': 35.0, 'price': 2200.0},
    {'name': 'Millet', 'type': 'Grain', 'yield': 20.0, 'price': 2000.0},
    {'name': 'Cotton', 'type': 'Cash Crop', 'yield': 20.0, 'price': 12000.0},
    {'name': 'Sugarcane', 'type': 'Cash Crop', 'yield': 400.0, 'price': 450.0},
    {'name': 'Tobacco', 'type': 'Cash Crop', 'yield': 15.0, 'price': 15000.0},
    {'name': 'Sunflower', 'type': 'Cash Crop', 'yield': 18.0, 'price': 6000.0},
    {'name': 'Tomato', 'type': 'Vegetable', 'yield': 120.0, 'price': 2500.0},
    {'name': 'Potato', 'type': 'Vegetable', 'yield': 150.0, 'price': 1200.0},
    {'name': 'Onion', 'type': 'Vegetable', 'yield': 100.0, 'price': 1800.0},
    {'name': 'Garlic', 'type': 'Vegetable', 'yield': 60.0, 'price': 8000.0},
    {'name': 'Chili', 'type': 'Vegetable', 'yield': 40.0, 'price': 5000.0},
    {'name': 'Spinach', 'type': 'Vegetable', 'yield': 80.0, 'price': 1500.0},
    {'name': 'Cabbage', 'type': 'Vegetable', 'yield': 120.0, 'price': 1200.0},
    {'name': 'Peas', 'type': 'Vegetable', 'yield': 50.0, 'price': 3000.0},
    {'name': 'Lentils', 'type': 'Vegetable', 'yield': 15.0, 'price': 6000.0},
    {'name': 'Chickpea', 'type': 'Vegetable', 'yield': 18.0, 'price': 9500.0},
    {'name': 'Mung Bean', 'type': 'Vegetable', 'yield': 12.0, 'price': 8000.0},
    {'name': 'Cucumber', 'type': 'Vegetable', 'yield': 100.0, 'price': 1500.0},
    {'name': 'Eggplant', 'type': 'Vegetable', 'yield': 100.0, 'price': 1800.0},
    {'name': 'Okra', 'type': 'Vegetable', 'yield': 60.0, 'price': 2500.0},
    {'name': 'Mango', 'type': 'Fruit', 'yield': 80.0, 'price': 4500.0},
    {'name': 'Citrus (Kinnow)', 'type': 'Fruit', 'yield': 120.0, 'price': 2000.0},
    {'name': 'Guava', 'type': 'Fruit', 'yield': 100.0, 'price': 2500.0},
    {'name': 'Banana', 'type': 'Fruit', 'yield': 200.0, 'price': 1500.0},
    {'name': 'Watermelon', 'type': 'Fruit', 'yield': 200.0, 'price': 800.0},
    {'name': 'Strawberry', 'type': 'Fruit', 'yield': 40.0, 'price': 15000.0},
    {'name': 'Apple', 'type': 'Fruit', 'yield': 80.0, 'price': 5000.0},
    {'name': 'Pomegranate', 'type': 'Fruit', 'yield': 60.0, 'price': 8000.0},
    {'name': 'Date Palm', 'type': 'Fruit', 'yield': 100.0, 'price': 5000.0},
    {'name': 'Dragon Fruit', 'type': 'Exotic Fruit', 'yield': 60.0, 'price': 12000.0},
    {'name': 'Avocado', 'type': 'Exotic Fruit', 'yield': 40.0, 'price': 15000.0},
    {'name': 'Kiwi', 'type': 'Exotic Fruit', 'yield': 50.0, 'price': 10000.0},
    {'name': 'Lychee', 'type': 'Exotic Fruit', 'yield': 80.0, 'price': 8000.0},
    {'name': 'Passion Fruit', 'type': 'Exotic Fruit', 'yield': 40.0, 'price': 9000.0},
    {'name': 'Fig', 'type': 'Exotic Fruit', 'yield': 60.0, 'price': 7000.0},
    {'name': 'Olive', 'type': 'Exotic Fruit', 'yield': 30.0, 'price': 12000.0},
    {'name': 'Soybean', 'type': 'Oilseed', 'yield': 20.0, 'price': 5000.0},
    {'name': 'Groundnut', 'type': 'Oilseed', 'yield': 25.0, 'price': 7000.0},
    {'name': 'Alfalfa', 'type': 'Fodder', 'yield': 200.0, 'price': 800.0},
    {'name': 'Berseem', 'type': 'Fodder', 'yield': 150.0, 'price': 600.0},
    {'name': 'Coriander', 'type': 'Spice', 'yield': 10.0, 'price': 8000.0},
    {'name': 'Cumin', 'type': 'Spice', 'yield': 8.0, 'price': 15000.0},
    {'name': 'Turmeric', 'type': 'Spice', 'yield': 30.0, 'price': 10000.0},
    {'name': 'Ginger', 'type': 'Spice', 'yield': 40.0, 'price': 8000.0},
    {'name': 'Tilapia', 'type': 'Fish', 'yield': 800.0, 'price': 450.0},
    {'name': 'Rohu Fish', 'type': 'Fish', 'yield': 700.0, 'price': 400.0},
    {'name': 'Catfish', 'type': 'Fish', 'yield': 600.0, 'price': 500.0},
    {'name': 'Pomfret', 'type': 'Fish', 'yield': 300.0, 'price': 1800.0},
    {'name': 'Shrimp', 'type': 'Seafood', 'yield': 400.0, 'price': 2500.0},
    {'name': 'Crab (Hard)', 'type': 'Seafood', 'yield': 200.0, 'price': 3000.0},
    {'name': 'Crab (Soft)', 'type': 'Seafood', 'yield': 150.0, 'price': 4000.0},
    {'name': 'Lobster', 'type': 'Seafood', 'yield': 100.0, 'price': 8000.0},
    {'name': 'Squid', 'type': 'Seafood', 'yield': 250.0, 'price': 1500.0},
    // Fish - Pakistan common fish
{'name': 'Rohu (Rohu Fish)', 'type': 'Fish', 'yield': 700.0, 'price': 400.0},
{'name': 'Tilapia', 'type': 'Fish', 'yield': 800.0, 'price': 450.0},
{'name': 'Catfish (Singhara)', 'type': 'Fish', 'yield': 600.0, 'price': 500.0},
{'name': 'Pomfret (Paplet)', 'type': 'Fish', 'yield': 300.0, 'price': 1800.0},
{'name': 'Sole Fish (Lahori)', 'type': 'Fish', 'yield': 250.0, 'price': 1200.0},
{'name': 'Tuna', 'type': 'Fish', 'yield': 400.0, 'price': 2000.0},
{'name': 'Salmon', 'type': 'Fish', 'yield': 300.0, 'price': 3000.0},
{'name': 'Hilsa (Palla)', 'type': 'Fish', 'yield': 200.0, 'price': 2500.0},
{'name': 'Mahseer (Mahasher)', 'type': 'Fish', 'yield': 150.0, 'price': 3500.0},
{'name': 'Grass Carp', 'type': 'Fish', 'yield': 900.0, 'price': 350.0},
{'name': 'Silver Carp', 'type': 'Fish', 'yield': 850.0, 'price': 320.0},
{'name': 'Common Carp (Gulfam)', 'type': 'Fish', 'yield': 750.0, 'price': 380.0},
{'name': 'Trout', 'type': 'Fish', 'yield': 400.0, 'price': 2800.0},
{'name': 'Mullet (Khagga)', 'type': 'Fish', 'yield': 350.0, 'price': 900.0},
{'name': 'Snapper (Heera)', 'type': 'Fish', 'yield': 280.0, 'price': 1500.0},
// Seafood
{'name': 'Shrimp (Jhinga)', 'type': 'Seafood', 'yield': 400.0, 'price': 2500.0},
{'name': 'Tiger Shrimp', 'type': 'Seafood', 'yield': 300.0, 'price': 4000.0},
{'name': 'Crab Hard Shell', 'type': 'Seafood', 'yield': 200.0, 'price': 3000.0},
{'name': 'Crab Soft Shell', 'type': 'Seafood', 'yield': 150.0, 'price': 4500.0},
{'name': 'Lobster', 'type': 'Seafood', 'yield': 100.0, 'price': 8000.0},
{'name': 'Squid (Seepia)', 'type': 'Seafood', 'yield': 250.0, 'price': 1500.0},
{'name': 'Octopus', 'type': 'Seafood', 'yield': 180.0, 'price': 2000.0},
{'name': 'Oyster', 'type': 'Seafood', 'yield': 500.0, 'price': 1200.0},
  ];

  List<String> get _cropTypes {
    final types = _crops
        .map((c) => c['type'] as String)
        .toSet()
        .toList();
    types.sort();
    return ['All', ...types];
  }

  List<Map<String, dynamic>> get _filteredCrops {
    List<Map<String, dynamic>> list =
        _filterType == 'All'
            ? _crops
            : _crops
                .where((c) =>
                    c['type'] == _filterType)
                .toList();
    final seen = <String>{};
    return list
        .where((c) =>
            seen.add(c['name'] as String))
        .toList();
  }

  double get _areaInAcres =>
      _areaUnit == 'Sq ft'
          ? _areaValue / 43560
          : _areaValue;

  double get _totalRevenue =>
      _expectedYield * _areaInAcres * _marketRate;
  double get _raastkarRevenue =>
      _raastkarYield * _areaInAcres * _marketRate;
  double get _totalExpense =>
      (_seedCost + _landPrepCost + _laborCost +
              _employeeCost + _fuelCost +
              _fertilizerCost + _pesticideCost +
              _transportCost) *
      _areaInAcres;
  double get _profit =>
      _totalRevenue - _totalExpense;
  double get _raastkarProfit =>
      _raastkarRevenue - _totalExpense;
  double get _roi => _totalExpense > 0
      ? (_profit / _totalExpense) * 100
      : 0;
  double get _raastkarRoi => _totalExpense > 0
      ? (_raastkarProfit / _totalExpense) * 100
      : 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this);
  }

  void _loadCropDefaults() {
    if (_selectedCrop == null) return;
    final crop = _crops.firstWhere(
      (c) => c['name'] == _selectedCrop,
      orElse: () => _crops[0],
    );
    setState(() {
      _raastkarYield = crop['yield'] as double;
      _marketRate = crop['price'] as double;
      _selectedCropType = crop['type'] as String;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _pkr(double amount) =>
      'PKR ${amount.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D52),
              unselectedLabelColor: Colors.grey,
              indicatorColor:
                  const Color(0xFF2E7D52),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              tabs: const [
                Tab(text: 'Farm Setup'),
                Tab(text: 'Expenses'),
                Tab(text: 'ROI Results'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFarmSetupTab(),
                _buildExpensesTab(),
                _buildResultsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: const Color(0xFF2E7D52),
      child: const Row(
        children: [
          Icon(Icons.calculate,
              color: Colors.white, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('ROI Crop Calculator',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold),
                    overflow:
                        TextOverflow.ellipsis),
                Text(
                    'Calculate profit & return on investment',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10),
                    overflow:
                        TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmSetupTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Farm Area',
          icon: Icons.crop_square,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                                  decimal: true),
                      decoration: _inputDec(
                          'Area value',
                          Icons.square_foot),
                      onChanged: (v) => setState(
                          () => _areaValue =
                              double.tryParse(v) ??
                                  1.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 95,
                    child:
                        DropdownButtonFormField
                            <String>(
                      value: _areaUnit,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(10),
                            borderSide: BorderSide(
                                color: Colors
                                    .grey.shade300)),
                        focusedBorder:
                            OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                borderSide:
                                    const BorderSide(
                                        color: Color(
                                            0xFF2E7D52),
                                        width: 2)),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10),
                      ),
                      items: ['Acre', 'Sq ft']
                          .map((u) =>
                              DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: const TextStyle(
                                          fontSize:
                                              13))))
                          .toList(),
                      onChanged: (v) => setState(
                          () => _areaUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Area in Acres:',
                        style: TextStyle(
                            color:
                                Color(0xFF2E7D52),
                            fontSize: 13)),
                    Text(
                        '${_areaInAcres.toStringAsFixed(4)} acres',
                        style: const TextStyle(
                            color:
                                Color(0xFF2E7D52),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title:
              'Crop Selection (${_crops.length}+ crops)',
          icon: Icons.grass,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text('Filter by type:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _cropTypes.map((t) {
                    final sel = _filterType == t;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _filterType = t;
                        _selectedCrop = null;
                      }),
                      child: Container(
                        margin:
                            const EdgeInsets.only(
                                right: 8),
                        padding: const EdgeInsets
                            .symmetric(
                            horizontal: 12,
                            vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(
                                  0xFF2E7D52)
                              : Colors
                                  .grey.shade100,
                          borderRadius:
                              BorderRadius.circular(
                                  20),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCrop,
                decoration: _inputDec(
                    'Select crop', Icons.eco),
                hint:
                    const Text('Select a crop'),
                isExpanded: true,
                items: _filteredCrops
                    .map((c) =>
                        DropdownMenuItem(
                          value:
                              c['name'] as String,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 5,
                                    vertical: 2),
                                decoration:
                                    BoxDecoration(
                                  color: _typeColor(
                                          c['type']
                                              as String)
                                      .withOpacity(
                                          0.15),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              4),
                                ),
                                child: Text(
                                  c['type']
                                      as String,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: _typeColor(
                                          c['type']
                                              as String)),
                                ),
                              ),
                              const SizedBox(
                                  width: 6),
                              Expanded(
                                child: Text(
                                  c['name']
                                      as String,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(
                      () => _selectedCrop = v);
                  _loadCropDefaults();
                },
              ),
              if (_selectedCrop != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 14),
                      const SizedBox(width: 6),
                      Text(
                          'Type: $_selectedCropType',
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Sowing & Harvest Schedule',
          icon: Icons.calendar_month,
          child: Column(
            children: [
              _buildScheduleRow(
                monthLabel: 'Sowing Month',
                monthValue: _sowingMonth,
                yearValue: _sowingYear,
                onMonthChanged: (v) => setState(
                    () => _sowingMonth = v),
                onYearChanged: (v) => setState(
                    () => _sowingYear = v),
              ),
              const SizedBox(height: 10),
              _buildScheduleRow(
                monthLabel: 'Harvest Month',
                monthValue: _harvestMonth,
                yearValue: _harvestYear,
                onMonthChanged: (v) => setState(
                    () => _harvestMonth = v),
                onYearChanged: (v) => setState(
                    () => _harvestYear = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Yield & Market Data',
          icon: Icons.trending_up,
          child: Column(
            children: [
              _numField(
                label:
                    'Expected Yield (last year) kg/acre',
                icon: Icons.history,
                color: Colors.orange,
                onChanged: (v) =>
                    setState(() =>
                        _expectedYield =
                            double.tryParse(v) ??
                                0),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          const Color(0xFF2E7D52)
                              .withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF2E7D52),
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                              'RaastKar Suggested Yield',
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color: Color(
                                      0xFF2E7D52),
                                  fontSize: 12)),
                          Text(
                            '${_raastkarYield.toStringAsFixed(0)} kg/acre',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: Color(
                                    0xFF2E7D52)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _numField(
                label:
                    'Market Rate (PKR/40kg bag)',
                icon: Icons.storefront,
                color: Colors.purple,
                initialValue: _marketRate > 0
                    ? _marketRate
                        .toStringAsFixed(0)
                    : null,
                onChanged: (v) =>
                    setState(() =>
                        _marketRate =
                            double.tryParse(v) ??
                                0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () =>
                _tabController.animateTo(1),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF2E7D52),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12)),
            ),
            child: const Text(
                'Next → Enter Expenses',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScheduleRow({
    required String monthLabel,
    required String monthValue,
    required int yearValue,
    required Function(String) onMonthChanged,
    required Function(int) onYearChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(monthLabel,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 5,
              child:
                  DropdownButtonFormField<String>(
                value: monthValue,
                isExpanded: true,
                decoration: _inputDec(
                    '', Icons.calendar_today),
                items: _months
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m,
                              style: const TextStyle(
                                  fontSize: 12)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    onMonthChanged(v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<int>(
                value: yearValue,
                isExpanded: true,
                decoration:
                    _inputDec('', Icons.event),
                items: [2024, 2025, 2026, 2027]
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(
                            '$y',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .bold),
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    onYearChanged(v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF2E7D52)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter costs per acre. Total × ${_areaInAcres.toStringAsFixed(2)} acres',
                  style: const TextStyle(
                      color: Color(0xFF2E7D52),
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Production Costs',
          icon: Icons.agriculture,
          child: Column(
            children: [
              _numField(
                  label: 'Seed Cost (PKR/acre)',
                  icon: Icons.grass,
                  color: Colors.green,
                  onChanged: (v) =>
                      setState(() =>
                          _seedCost =
                              double.tryParse(v) ??
                                  0)),
              const SizedBox(height: 10),
              _numField(
                  label:
                      'Land Preparation (PKR/acre)',
                  icon: Icons.terrain,
                  color: Colors.brown,
                  onChanged: (v) =>
                      setState(() =>
                          _landPrepCost =
                              double.tryParse(v) ??
                                  0)),
              const SizedBox(height: 10),
              _numField(
                  label:
                      'Fertilizer (PKR/acre)',
                  icon: Icons.science,
                  color: Colors.blue,
                  onChanged: (v) =>
                      setState(() =>
                          _fertilizerCost =
                              double.tryParse(v) ??
                                  0)),
              const SizedBox(height: 10),
              _numField(
                  label: 'Pesticide (PKR/acre)',
                  icon: Icons.bug_report,
                  color: Colors.red,
                  onChanged: (v) =>
                      setState(() =>
                          _pesticideCost =
                              double.tryParse(v) ??
                                  0)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Labor & Operations',
          icon: Icons.people,
          child: Column(
            children: [
              _numField(
                  label: 'Labor Cost (PKR/acre)',
                  icon: Icons.person,
                  color: Colors.orange,
                  onChanged: (v) =>
                      setState(() =>
                          _laborCost =
                              double.tryParse(v) ??
                                  0)),
              const SizedBox(height: 10),
              _numField(
                  label:
                      'Employee Fixed (PKR/acre)',
                  icon: Icons.badge,
                  color: Colors.purple,
                  onChanged: (v) =>
                      setState(() =>
                          _employeeCost =
                              double.tryParse(v) ??
                                  0)),
              const SizedBox(height: 10),
              _numField(
                  label: 'Fuel Cost (PKR/acre)',
                  icon: Icons.local_gas_station,
                  color: Colors.grey,
                  onChanged: (v) =>
                      setState(() =>
                          _fuelCost =
                              double.tryParse(v) ??
                                  0)),
              const SizedBox(height: 10),
              _numField(
                  label:
                      'Transportation (PKR/acre)',
                  icon: Icons.local_shipping,
                  color: Colors.teal,
                  onChanged: (v) =>
                      setState(() =>
                          _transportCost =
                              double.tryParse(v) ??
                                  0)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
                color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              const Text(
                  'Total Expense Summary',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 10),
              _expRow(
                'Per Acre',
                _pkr(_areaInAcres > 0
                    ? _totalExpense /
                        _areaInAcres
                    : 0),
              ),
              _expRow(
                'Total (${_areaInAcres.toStringAsFixed(2)} acres)',
                _pkr(_totalExpense),
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () =>
                _tabController.animateTo(2),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF2E7D52),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12)),
            ),
            child: const Text(
                'Next → View ROI Results',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultsTab() {
    final bool profitable = _profit >= 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: profitable
                ? const Color(0xFF2E7D52)
                : Colors.red.shade700,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                profitable
                    ? '✅ Profitable!'
                    : '⚠️ Loss!',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _pkr(_profit.abs()),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                profitable
                    ? 'Net Profit'
                    : 'Net Loss',
                style: const TextStyle(
                    color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _resultStat('ROI',
                      '${_roi.toStringAsFixed(1)}%'),
                  _resultStat('Revenue',
                      _pkr(_totalRevenue)),
                  _resultStat('Expense',
                      _pkr(_totalExpense)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Revenue Breakdown',
          icon: Icons.bar_chart,
          child: Column(
            children: [
              _expRow('Crop',
                  _selectedCrop ??
                      'Not selected'),
              _expRow('Area',
                  '${_areaInAcres.toStringAsFixed(2)} acres'),
              _expRow('Season',
                  '$_sowingMonth $_sowingYear → $_harvestMonth $_harvestYear'),
              _expRow('Your Yield/acre',
                  '${_expectedYield.toStringAsFixed(0)} kg'),
              _expRow('Market Rate',
                  '${_pkr(_marketRate)}/bag'),
              const Divider(),
              _expRow('Gross Revenue',
                  _pkr(_totalRevenue),
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Expense Breakdown',
          icon: Icons.receipt_long,
          child: Column(
            children: [
              if (_seedCost > 0)
                _expRow('Seed',
                    _pkr(_seedCost *
                        _areaInAcres)),
              if (_landPrepCost > 0)
                _expRow('Land Prep',
                    _pkr(_landPrepCost *
                        _areaInAcres)),
              if (_fertilizerCost > 0)
                _expRow('Fertilizer',
                    _pkr(_fertilizerCost *
                        _areaInAcres)),
              if (_pesticideCost > 0)
                _expRow('Pesticide',
                    _pkr(_pesticideCost *
                        _areaInAcres)),
              if (_laborCost > 0)
                _expRow('Labor',
                    _pkr(_laborCost *
                        _areaInAcres)),
              if (_employeeCost > 0)
                _expRow('Employee',
                    _pkr(_employeeCost *
                        _areaInAcres)),
              if (_fuelCost > 0)
                _expRow('Fuel',
                    _pkr(_fuelCost *
                        _areaInAcres)),
              if (_transportCost > 0)
                _expRow('Transport',
                    _pkr(_transportCost *
                        _areaInAcres)),
              const Divider(),
              _expRow('Total Expense',
                  _pkr(_totalExpense),
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0)
                .withOpacity(0.1),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1565C0)
                    .withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: Color(0xFF1565C0),
                      size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'RaastKar Optimized Yield',
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF1565C0),
                            fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _expRow('Optimized Revenue',
                  _pkr(_raastkarRevenue)),
              _expRow('Optimized Profit',
                  _pkr(_raastkarProfit),
                  isBold: true,
                  color: _raastkarProfit >= 0
                      ? Colors.green
                      : Colors.red),
              _expRow('Optimized ROI',
                  '${_raastkarRoi.toStringAsFixed(1)}%',
                  color:
                      const Color(0xFF1565C0)),
              if (_raastkarProfit > _profit) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 RaastKar can increase profit by ${_pkr(_raastkarProfit - _profit)}',
                    style: const TextStyle(
                        color:
                            Color(0xFF2E7D52),
                        fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
                color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates,
                      color: Colors.amber),
                  SizedBox(width: 8),
                  Text('How to improve ROI',
                      style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              ..._roiTips().map((tip) =>
                  Padding(
                    padding:
                        const EdgeInsets.only(
                            bottom: 6),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Icon(
                            Icons.arrow_right,
                            color: Colors.amber,
                            size: 16),
                        Expanded(
                            child: Text(tip,
                                style: const TextStyle(
                                    fontSize:
                                        12))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<String> _roiTips() {
    final tips = <String>[];
    if (_roi < 20)
      tips.add(
          'ROI is low. Reduce costs using organic alternatives.');
    if (_fertilizerCost > 8000)
      tips.add(
          'Fertilizer cost high. Use soil testing.');
    if (_pesticideCost > 3000)
      tips.add(
          'Try IPM to reduce pesticide cost.');
    if (_laborCost > 5000)
      tips.add(
          'Mechanization can reduce labor costs.');
    if (_expectedYield > 0 &&
        _expectedYield < _raastkarYield)
      tips.add(
          'Yield below recommendation. Better seeds can help.');
    tips.add(
        'Sell at mandi directly for 10-15% better price.');
    if (tips.isEmpty)
      tips.add(
          'Excellent ROI! Consider expanding farm area.');
    return tips.take(4).toList();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Grain': return Colors.amber.shade700;
      case 'Cash Crop': return Colors.purple;
      case 'Vegetable': return Colors.green;
      case 'Fruit': return Colors.orange;
      case 'Exotic Fruit': return Colors.deepPurple;
      case 'Oilseed': return Colors.brown;
      case 'Fodder': return Colors.teal;
      case 'Spice': return Colors.red;
      case 'Fish': return Colors.blue;
      case 'Seafood': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: const Color(0xFF2E7D52),
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E7D52))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _numField({
    required String label,
    required IconData icon,
    required Color color,
    required ValueChanged<String> onChanged,
    String? initialValue,
  }) {
    return TextField(
      keyboardType: const TextInputType
          .numberWithOptions(decimal: true),
      controller: initialValue != null
          ? TextEditingController(
              text: initialValue)
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 11),
        prefixIcon:
            Icon(icon, color: color, size: 18),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFF2E7D52),
                width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDec(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      labelStyle:
          const TextStyle(fontSize: 11),
      prefixIcon: Icon(icon,
          color: const Color(0xFF2E7D52),
          size: 18),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),
          borderSide: BorderSide(
              color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF2E7D52),
              width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
    );
  }

  Widget _expRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 3),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: isBold
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }

  Widget _resultStat(
      String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10)),
      ],
    );
  }
}