import 'package:flutter/material.dart';

class ESGScreen extends StatefulWidget {
  const ESGScreen({super.key});

  @override
  State<ESGScreen> createState() => _ESGScreenState();
}

class _ESGScreenState extends State<ESGScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Environmental metrics
  double _waterConservation = 70;
  double _soilHealth = 65;
  double _carbonFootprint = 80;
  double _pesticideUse = 60;
  double _energyEfficiency = 55;
  double _biodiversity = 50;

  // Social metrics
  double _workerSafety = 75;
  double _fairWages = 70;
  double _communityImpact = 65;
  double _farmerTraining = 60;
  double _womenEmpowerment = 55;

  // Governance metrics
  double _recordKeeping = 80;
  double _certification = 75;
  double _compliance = 70;
  double _transparency = 65;
  double _supplyChain = 60;

  late TabController _metricTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _metricTabController =
        TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metricTabController.dispose();
    super.dispose();
  }

  double get _eScore =>
      ((_waterConservation +
                  _soilHealth +
                  _carbonFootprint +
                  _pesticideUse +
                  _energyEfficiency +
                  _biodiversity) /
              6) *
      0.40;

  double get _sScore =>
      ((_workerSafety +
                  _fairWages +
                  _communityImpact +
                  _farmerTraining +
                  _womenEmpowerment) /
              5) *
      0.35;

  double get _gScore =>
      ((_recordKeeping +
                  _certification +
                  _compliance +
                  _transparency +
                  _supplyChain) /
              5) *
      0.25;

  double get _totalScore =>
      _eScore + _sScore + _gScore;

  String get _rating {
    if (_totalScore >= 90) return 'Platinum';
    if (_totalScore >= 75) return 'Excellent';
    if (_totalScore >= 60) return 'Good';
    if (_totalScore >= 45) return 'Average';
    return 'Needs Improvement';
  }

  Color get _ratingColor {
    if (_totalScore >= 90)
      return const Color(0xFF6A1B9A);
    if (_totalScore >= 75)
      return const Color(0xFF2E7D52);
    if (_totalScore >= 60)
      return const Color(0xFF1565C0);
    if (_totalScore >= 45)
      return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  IconData get _ratingIcon {
    if (_totalScore >= 90) return Icons.diamond;
    if (_totalScore >= 75)
      return Icons.workspace_premium;
    if (_totalScore >= 60) return Icons.star;
    if (_totalScore >= 45)
      return Icons.star_half;
    return Icons.trending_up;
  }

  List<Map<String, dynamic>> get _improvements {
    final tips = <Map<String, dynamic>>[];
    if (_waterConservation < 70) {
      tips.add({
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'title': 'Water Conservation',
        'tip':
            'Install drip irrigation system to save up to 60% water',
        'impact': '+8 points',
      });
    }
    if (_soilHealth < 70) {
      tips.add({
        'icon': Icons.grass,
        'color': Colors.green,
        'title': 'Soil Health',
        'tip':
            'Add organic compost and reduce chemical fertilizers',
        'impact': '+7 points',
      });
    }
    if (_carbonFootprint < 70) {
      tips.add({
        'icon': Icons.eco,
        'color': const Color(0xFF2E7D52),
        'title': 'Carbon Footprint',
        'tip':
            'Plant trees on farm borders to offset carbon emissions',
        'impact': '+10 points',
      });
    }
    if (_pesticideUse < 70) {
      tips.add({
        'icon': Icons.bug_report,
        'color': Colors.red,
        'title': 'Pesticide Use',
        'tip':
            'Switch to Integrated Pest Management (IPM) techniques',
        'impact': '+6 points',
      });
    }
    if (_workerSafety < 70) {
      tips.add({
        'icon': Icons.health_and_safety,
        'color': Colors.orange,
        'title': 'Worker Safety',
        'tip':
            'Provide PPE equipment and safety training to all workers',
        'impact': '+8 points',
      });
    }
    if (_fairWages < 70) {
      tips.add({
        'icon': Icons.payments,
        'color': Colors.purple,
        'title': 'Fair Wages',
        'tip':
            'Review and align wages with regional minimum wage standards',
        'impact': '+7 points',
      });
    }
    if (_recordKeeping < 70) {
      tips.add({
        'icon': Icons.folder,
        'color': Colors.teal,
        'title': 'Record Keeping',
        'tip':
            'Use digital farm management apps to track all activities',
        'impact': '+6 points',
      });
    }
    if (_certification < 70) {
      tips.add({
        'icon': Icons.verified,
        'color': Colors.indigo,
        'title': 'Certification',
        'tip':
            'Apply for GlobalGAP or organic certification to increase value',
        'impact': '+12 points',
      });
    }
    return tips.take(4).toList();
  }

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
              indicatorColor: const Color(0xFF2E7D52),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Environment'),
                Tab(text: 'Social'),
                Tab(text: 'Governance'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEnvironmentTab(),
                _buildSocialTab(),
                _buildGovernanceTab(),
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
          const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: const Color(0xFF2E7D52),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ESG Score Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Environmental · Social · Governance',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _totalScore.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '/100',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildScoreCard(),
          const SizedBox(height: 14),
          _buildCategoryCards(),
          const SizedBox(height: 14),
          _buildRatingBadge(),
          const SizedBox(height: 14),
          _buildESGBenefits(),
          const SizedBox(height: 14),
          if (_improvements.isNotEmpty)
            _buildImprovements(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ratingColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(_ratingIcon,
              color: Colors.white, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Overall ESG Score',
            style: TextStyle(
                color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _totalScore.toInt().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '/100',
            style: TextStyle(
                color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_ratingIcon,
                    color: _ratingColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _rating,
                  style: TextStyle(
                    color: _ratingColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScoreBar(
                  label: 'E',
                  score: (_eScore / 0.40),
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScoreBar(
                  label: 'S',
                  score: (_sScore / 0.35),
                  color: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScoreBar(
                  label: 'G',
                  score: (_gScore / 0.25),
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar({
    required String label,
    required double score,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          score.toInt().toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor:
                Colors.white.withOpacity(0.3),
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCards() {
    return Row(
      children: [
        Expanded(
          child: _CategoryCard(
            title: 'Environmental',
            emoji: '🌍',
            score: _eScore / 0.40,
            weight: '40%',
            color: const Color(0xFF2E7D52),
            metrics: 6,
            onTap: () => _tabController.animateTo(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CategoryCard(
            title: 'Social',
            emoji: '👥',
            score: _sScore / 0.35,
            weight: '35%',
            color: const Color(0xFF1565C0),
            metrics: 5,
            onTap: () => _tabController.animateTo(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CategoryCard(
            title: 'Governance',
            emoji: '📋',
            score: _gScore / 0.25,
            weight: '25%',
            color: const Color(0xFF6A1B9A),
            metrics: 5,
            onTap: () => _tabController.animateTo(3),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBadge() {
    final ratings = [
      {
        'label': 'Needs Improvement',
        'range': '0-44',
        'color': Colors.red,
        'icon': Icons.trending_up
      },
      {
        'label': 'Average',
        'range': '45-59',
        'color': Colors.orange,
        'icon': Icons.star_half
      },
      {
        'label': 'Good',
        'range': '60-74',
        'color': Colors.blue,
        'icon': Icons.star
      },
      {
        'label': 'Excellent',
        'range': '75-89',
        'color': const Color(0xFF2E7D52),
        'icon': Icons.workspace_premium
      },
      {
        'label': 'Platinum',
        'range': '90-100',
        'color': const Color(0xFF6A1B9A),
        'icon': Icons.diamond
      },
    ];

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
          const Row(
            children: [
              Icon(Icons.stars,
                  color: Color(0xFF2E7D52), size: 20),
              SizedBox(width: 8),
              Text(
                'Rating Scale',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ratings.map((r) {
            final isCurrentRating =
                _rating == r['label'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentRating
                    ? (r['color'] as Color)
                        .withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrentRating
                      ? (r['color'] as Color)
                      : Colors.grey.shade200,
                  width: isCurrentRating ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    r['icon'] as IconData,
                    color: r['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['label'] as String,
                      style: TextStyle(
                        fontWeight: isCurrentRating
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentRating
                            ? r['color'] as Color
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (r['color'] as Color)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      r['range'] as String,
                      style: TextStyle(
                        color: r['color'] as Color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isCurrentRating) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: r['color'] as Color,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildESGBenefits() {
    final benefits = [
      {
        'icon': Icons.attach_money,
        'color': Colors.green,
        'title': 'Higher Market Price',
        'desc':
            'ESG certified farms get 15-25% premium price for their produce',
      },
      {
        'icon': Icons.verified,
        'color': Colors.blue,
        'title': 'Export Eligibility',
        'desc':
            'Good ESG score makes your farm eligible for international export',
      },
      {
        'icon': Icons.energy_savings_leaf,
        'color': const Color(0xFF2E7D52),
        'title': 'Carbon Credits',
        'desc':
            'Higher environmental score earns more VERRA carbon credits',
      },
      {
        'icon': Icons.account_balance,
        'color': Colors.purple,
        'title': 'Bank Loans',
        'desc':
            'ESG compliant farms get easier access to agricultural loans',
      },
      {
        'icon': Icons.people,
        'color': Colors.orange,
        'title': 'Community Trust',
        'desc':
            'Social score builds trust with buyers and local communities',
      },
    ];

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
          const Row(
            children: [
              Icon(Icons.lightbulb,
                  color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Why ESG Score Matters',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map((b) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (b['color'] as Color)
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Icon(
                        b['icon'] as IconData,
                        color: b['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['title'] as String,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            b['desc'] as String,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildImprovements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch,
                  color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quick Wins to Improve Score',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  '+${_improvements.fold(0, (sum, i) => sum + int.parse((i['impact'] as String).replaceAll(RegExp(r'[^0-9]'), '')))} pts possible',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._improvements.map((tip) => Container(
                margin:
                    const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (tip['color'] as Color)
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        tip['icon'] as IconData,
                        color: tip['color'] as Color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tip['title']
                                      as String,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .green.shade50,
                                  borderRadius:
                                      BorderRadius
                                          .circular(6),
                                ),
                                child: Text(
                                  tip['impact']
                                      as String,
                                  style:
                                      const TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip['tip'] as String,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEnvironmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryHeader(
            emoji: '🌍',
            title: 'Environmental Score',
            score: _eScore / 0.40,
            color: const Color(0xFF2E7D52),
            weight: '40% of total ESG',
            description:
                'Measures your farm\'s impact on the natural environment including water, soil, air and biodiversity',
          ),
          const SizedBox(height: 14),
          _buildMetricCard(
            title: 'Water Conservation',
            value: _waterConservation,
            color: Colors.blue,
            icon: Icons.water_drop,
            description:
                'Efficient use of water resources through modern irrigation',
            tips: [
              'Install drip irrigation system',
              'Collect rainwater for irrigation',
              'Monitor soil moisture before watering',
            ],
            onChanged: (v) =>
                setState(() => _waterConservation = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Soil Health',
            value: _soilHealth,
            color: Colors.brown,
            icon: Icons.grass,
            description:
                'Quality and fertility of farm soil for long-term productivity',
            tips: [
              'Apply organic compost regularly',
              'Practice crop rotation',
              'Minimize soil compaction',
            ],
            onChanged: (v) =>
                setState(() => _soilHealth = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Carbon Footprint',
            value: _carbonFootprint,
            color: const Color(0xFF2E7D52),
            icon: Icons.eco,
            description:
                'Net carbon emissions from farming activities',
            tips: [
              'Plant trees on farm boundaries',
              'Use solar-powered water pumps',
              'Avoid burning crop residue',
            ],
            onChanged: (v) =>
                setState(() => _carbonFootprint = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Low Pesticide Use',
            value: _pesticideUse,
            color: Colors.orange,
            icon: Icons.bug_report,
            description:
                'Reduction in harmful chemical pesticide application',
            tips: [
              'Use Integrated Pest Management (IPM)',
              'Apply neem-based organic pesticides',
              'Use pheromone traps for pest control',
            ],
            onChanged: (v) =>
                setState(() => _pesticideUse = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Energy Efficiency',
            value: _energyEfficiency,
            color: Colors.yellow.shade700,
            icon: Icons.bolt,
            description:
                'Use of renewable and efficient energy sources on farm',
            tips: [
              'Install solar panels for farm electricity',
              'Use energy-efficient irrigation pumps',
              'Generate biogas from farm waste',
            ],
            onChanged: (v) =>
                setState(() => _energyEfficiency = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Biodiversity',
            value: _biodiversity,
            color: Colors.teal,
            icon: Icons.park,
            description:
                'Protection of local plants, animals and ecosystems',
            tips: [
              'Grow multiple crop varieties',
              'Maintain hedgerows and wild areas',
              'Avoid clearing natural vegetation',
            ],
            onChanged: (v) =>
                setState(() => _biodiversity = v),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryHeader(
            emoji: '👥',
            title: 'Social Score',
            score: _sScore / 0.35,
            color: const Color(0xFF1565C0),
            weight: '35% of total ESG',
            description:
                'Measures your farm\'s impact on workers, families and the wider farming community',
          ),
          const SizedBox(height: 14),
          _buildMetricCard(
            title: 'Worker Safety',
            value: _workerSafety,
            color: Colors.red,
            icon: Icons.health_and_safety,
            description:
                'Protection of farm workers from accidents and health hazards',
            tips: [
              'Provide PPE (masks, gloves, boots)',
              'Train workers on safe pesticide handling',
              'Install first aid kits on farm',
            ],
            onChanged: (v) =>
                setState(() => _workerSafety = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Fair Wages',
            value: _fairWages,
            color: Colors.purple,
            icon: Icons.payments,
            description:
                'Ensuring workers receive fair and timely compensation',
            tips: [
              'Pay at least minimum wage',
              'Provide timely salary payments',
              'Offer performance bonuses',
            ],
            onChanged: (v) =>
                setState(() => _fairWages = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Community Impact',
            value: _communityImpact,
            color: Colors.orange,
            icon: Icons.people,
            description:
                'Positive contribution to local village and farming community',
            tips: [
              'Share farming knowledge with neighbors',
              'Participate in cooperative farming',
              'Support local agricultural events',
            ],
            onChanged: (v) =>
                setState(() => _communityImpact = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Farmer Training',
            value: _farmerTraining,
            color: Colors.teal,
            icon: Icons.school,
            description:
                'Investment in skills and education for farm workers',
            tips: [
              'Attend government agricultural workshops',
              'Join farmer cooperatives',
              'Use digital farming apps for learning',
            ],
            onChanged: (v) =>
                setState(() => _farmerTraining = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Women Empowerment',
            value: _womenEmpowerment,
            color: Colors.pink,
            icon: Icons.woman,
            description:
                'Equal opportunities and rights for women in farming',
            tips: [
              'Hire equal number of women workers',
              'Provide equal pay for equal work',
              'Support women in leadership roles',
            ],
            onChanged: (v) =>
                setState(() => _womenEmpowerment = v),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGovernanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryHeader(
            emoji: '📋',
            title: 'Governance Score',
            score: _gScore / 0.25,
            color: const Color(0xFF6A1B9A),
            weight: '25% of total ESG',
            description:
                'Measures transparency, compliance and ethical management of your farm operations',
          ),
          const SizedBox(height: 14),
          _buildMetricCard(
            title: 'Record Keeping',
            value: _recordKeeping,
            color: Colors.teal,
            icon: Icons.folder,
            description:
                'Maintaining accurate and up-to-date farm records',
            tips: [
              'Use digital farm management software',
              'Keep daily crop activity logs',
              'Record all input costs and revenues',
            ],
            onChanged: (v) =>
                setState(() => _recordKeeping = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Certification',
            value: _certification,
            color: Colors.indigo,
            icon: Icons.verified,
            description:
                'Holding recognized farming certifications and standards',
            tips: [
              'Apply for GlobalGAP certification',
              'Get organic farming certification',
              'Obtain food safety certifications',
            ],
            onChanged: (v) =>
                setState(() => _certification = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Regulatory Compliance',
            value: _compliance,
            color: Colors.blue,
            icon: Icons.gavel,
            description:
                'Following all local and national farming regulations',
            tips: [
              'Register your farm with local authorities',
              'Follow pesticide usage regulations',
              'Comply with water usage permits',
            ],
            onChanged: (v) =>
                setState(() => _compliance = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Transparency',
            value: _transparency,
            color: Colors.cyan,
            icon: Icons.visibility,
            description:
                'Open and honest reporting of farm activities and data',
            tips: [
              'Share farm reports with buyers',
              'Be honest about pesticide usage',
              'Report environmental incidents promptly',
            ],
            onChanged: (v) =>
                setState(() => _transparency = v),
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            title: 'Supply Chain Ethics',
            value: _supplyChain,
            color: Colors.deepOrange,
            icon: Icons.local_shipping,
            description:
                'Ethical practices throughout the farming supply chain',
            tips: [
              'Source seeds from certified suppliers',
              'Use licensed chemical distributors',
              'Sell through registered mandis',
            ],
            onChanged: (v) =>
                setState(() => _supplyChain = v),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader({
    required String emoji,
    required String title,
    required double score,
    required Color color,
    required String weight,
    required String description,
  }) {
    String scoreLabel;
    if (score >= 80) scoreLabel = 'Excellent';
    else if (score >= 60) scoreLabel = 'Good';
    else if (score >= 40) scoreLabel = 'Average';
    else scoreLabel = 'Needs Work';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weight,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    score.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      scoreLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
    required String description,
    required List<String> tips,
    required ValueChanged<double> onChanged,
  }) {
    String label;
    if (value >= 80) label = 'Excellent';
    else if (value >= 60) label = 'Good';
    else if (value >= 40) label = 'Average';
    else label = 'Poor';

    Color labelColor;
    if (value >= 80) labelColor = Colors.green;
    else if (value >= 60) labelColor = Colors.blue;
    else if (value >= 40) labelColor = Colors.orange;
    else labelColor = Colors.red;

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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          labelColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                          color: labelColor,
                          fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(
                      overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: color,
              inactiveColor: Colors.grey.shade200,
              onChanged: onChanged,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates,
                        color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'How to improve:',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: 3),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right,
                              color: color, size: 14),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title, emoji, weight;
  final double score;
  final Color color;
  final int metrics;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.emoji,
    required this.score,
    required this.weight,
    required this.color,
    required this.metrics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(emoji,
                style:
                    const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              score.toInt().toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weight,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 6),
            Text(
              '$metrics metrics',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor:
                    color.withOpacity(0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                        color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to edit →',
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}