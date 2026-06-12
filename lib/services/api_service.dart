import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
static const String baseUrl = 'https://raastkar-backend.vercel.app';
  static Future<List<dynamic>> getMandiPrices() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/mandi/prices'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success']) return data['prices'];
      return [];
    } catch (e) {
      print('Mandi error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getWeather(
      String city) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$baseUrl/api/weather/current?city=$city'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      print('Weather error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getWeatherForecast(
      String city) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$baseUrl/api/weather/forecast?city=$city'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success']) return data['forecast'];
      return [];
    } catch (e) {
      print('Forecast error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>>
      getCropRecommendations({
    required String location,
    required String ph,
    required String tds,
    required String salinity,
    String language = 'English',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/crop/recommend'),
            headers: {
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'location': location,
              'soil_ph': ph,
              'tds': tds,
              'salinity': salinity,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      print('Crop error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getDiagnosis({
    required String crop,
    required String symptoms,
    String language = 'English',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/drcrop/diagnose'),
            headers: {
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'crop': crop,
              'symptoms': symptoms,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      print('DrCrop error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>>
      getDiagnosisFromPhoto({
    required String crop,
    required String base64Image,
    String language = 'English',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(
                '$baseUrl/api/drcrop/diagnose-photo'),
            headers: {
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'crop': crop,
              'image': base64Image,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 60));
      return jsonDecode(res.body);
    } catch (e) {
      print('Photo diagnosis error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> calculateCarbon({
    required double acres,
    required int plantsPerAcre,
    required String crop,
    required List<String> practices,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/carbon/calculate'),
            headers: {
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'acres': acres,
              'plants_per_acre': plantsPerAcre,
              'crop': crop,
              'practices': practices,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      print('Carbon error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<dynamic>>
      getCarbonPractices() async {
    try {
      final res = await http
          .get(
              Uri.parse('$baseUrl/api/carbon/practices'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success']) return data['practices'];
      return [];
    } catch (e) {
      print('Practices error: $e');
      return [];
    }
  }
}