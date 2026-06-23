import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Could not connect to backend: $e');
    }
  }

  Future<Map<String, dynamic>> fetchCalendarData({
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/calendar/').replace(
        queryParameters: {
          'month': month.toString(),
          'year': year.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Show the raw body in the error so you can debug easily
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to calendar API: $e');
    }
  }
}