import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';
import '../services/tr.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? _weather;
  List<dynamic> _alerts = [];
  List<dynamic> _forecast = [];
  bool _loading = false;
  bool _gpsLoading = false;
  String _city = 'Lahore';
  final _cityController = TextEditingController(text: 'Lahore');


  Future<void> _getGPSLocation() async {
    setState(() => _gpsLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _gpsLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final parts = <String>[];
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        final location = parts.isNotEmpty ? parts.join(', ') : 'Lahore';
        setState(() {
          _city = location;
          _cityController.text = location;
          _gpsLoading = false;
        });
        _loadWeather();
      }
    } catch (e) {
      setState(() => _gpsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadWeather() async {
    setState(() => _loading = true);
    final result = await ApiService.getWeather(_city);
    final forecast = await ApiService.getWeatherForecast(_city);
    setState(() {
      if (result['success'] == true) {
        _weather = result['weather'];
        _alerts = result['alerts'] ?? [];
      }
      _forecast = forecast;
      _loading = false;
    });
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'rain': return Icons.umbrella;
      case 'clouds': return Icons.cloud;
      case 'thunderstorm': return Icons.flash_on;
      case 'snow': return Icons.ac_unit;
      default: return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'rain': return Colors.blue;
      case 'clouds': return Colors.grey;
      case 'thunderstorm': return Colors.deepPurple;
      case 'snow': return Colors.lightBlue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: Color(0xFF2E7D52)),
                  )
                else if (_weather != null) ...[
                  _buildMainWeatherCard(),
                  const SizedBox(height: 10),
                  _buildWeatherGrid(),
                  if (_alerts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildAlerts(),
                  ],
                  if (_forecast.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildForecast(),
                  ],
                  const SizedBox(height: 10),
                  _buildCropAdvice(),
                ] else
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter a city or use GPS to get weather data',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: const Color(0xFF2E7D52),
      child: Row(
        children: [
          const Icon(Icons.cloud, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Tr.get('weather'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(Tr.get('weatherDesc'),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityController,
            decoration: InputDecoration(
              hintText: Tr.get('enterCity'),
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.location_on,
                  color: Color(0xFF2E7D52), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF2E7D52), width: 2),
              ),
            ),
            onSubmitted: (v) {
              _city = v;
              _loadWeather();
            },
          ),
        ),
        const SizedBox(width: 8),
        // GPS Button
        GestureDetector(
          onTap: _gpsLoading ? null : _getGPSLocation,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _gpsLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        // Search Button
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              _city = _cityController.text;
              _loadWeather();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard() {
    final condition = _weather!['condition'] ?? 'Clear';
    final color = _getWeatherColor(condition);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_getWeatherIcon(condition), color: color, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_weather!['temp']}°C',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(
                  '${_weather!['city']} · ${_weather!['description']}',
                  style: TextStyle(color: color, fontSize: 13),
                ),
                Text(
                  '${Tr.get('feelsLike')} ${_weather!['feels_like']}°C',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherGrid() {
    return Row(
      children: [
        Expanded(
          child: _miniCard(
              icon: Icons.water_drop,
              value: '${_weather!['humidity']}%',
              label: Tr.get('humidity'),
              color: Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniCard(
              icon: Icons.air,
              value: '${_weather!['wind_speed']} km/h',
              label: Tr.get('wind'),
              color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniCard(
              icon: Icons.visibility,
              value: '${_weather!['visibility']}km',
              label: Tr.get('visibility'),
              color: Colors.teal),
        ),
      ],
    );
  }

  Widget _miniCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
            const SizedBox(width: 6),
            Text(Tr.get('activeAlerts'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        ..._alerts.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.red),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(alert['severity'] ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(alert['advice'] ?? '',
                      style: const TextStyle(
                          color: Color(0xFF2E7D52), fontSize: 12)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildForecast() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Tr.get('fiveDay'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _forecast.take(5).map((f) {
              final date =
                  DateTime.tryParse(f['date'] ?? '') ?? DateTime.now();
              final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              return Column(
                children: [
                  Text(days[date.weekday - 1],
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Icon(
                    _getWeatherIcon(f['condition'] ?? 'Clear'),
                    color: _getWeatherColor(f['condition'] ?? 'Clear'),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text('${f['temp_max']}°',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${f['temp_min']}°',
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCropAdvice() {
    final temp = _weather!['temp'] as int? ?? 25;
    final humidity = _weather!['humidity'] as int? ?? 50;
    final advices = <Map<String, dynamic>>[];

    if (temp >= 38) {
      advices.add({'icon': Icons.water_drop, 'color': Colors.blue,
          'text': 'Irrigate crops early morning (5-7 AM) to reduce heat stress'});
    }
    if (temp >= 35) {
      advices.add({'icon': Icons.wb_shade, 'color': Colors.orange,
          'text': 'Provide shade for sensitive crops like tomato and chili'});
    }
    if (humidity > 80) {
      advices.add({'icon': Icons.bug_report, 'color': Colors.red,
          'text': 'High humidity — check for fungal diseases. Apply fungicide preventively'});
    }
    if (humidity < 30) {
      advices.add({'icon': Icons.grass, 'color': Colors.green,
          'text': 'Low humidity — increase irrigation frequency to prevent wilting'});
    }
    if (temp < 10) {
      advices.add({'icon': Icons.ac_unit, 'color': Colors.lightBlue,
          'text': 'Risk of frost — cover sensitive crops at night'});
    }
    advices.add({'icon': Icons.tips_and_updates, 'color': const Color(0xFF2E7D52),
        'text': 'Best time to spray pesticides is early morning when wind is calm'});

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF2E7D52).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture,
                  color: Color(0xFF2E7D52), size: 18),
              const SizedBox(width: 6),
              Text(Tr.get('cropRecommendations'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2E7D52))),
            ],
          ),
          const SizedBox(height: 8),
          ...advices.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a['icon'] as IconData,
                        color: a['color'] as Color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a['text'] as String,
                          style: const TextStyle(
                              fontSize: 12, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}