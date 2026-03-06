import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_manager.dart';

class ApiService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = TokenManager.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = '$_baseUrl$endpoint';
      debugPrint('ApiService: POST request to $url');
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedResponse;
      } else {
        // Handle unauthenticated state
        if (response.statusCode == 401) {
          await TokenManager.clearToken();
        }
        return decodedResponse;
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 401) {
        await TokenManager.clearToken();
      }

      return decodedResponse;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = '$_baseUrl$endpoint';
      debugPrint('ApiService: DELETE request to $url');
      final response = await http.delete(Uri.parse(url), headers: _headers);

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedResponse;
      } else {
        // Handle unauthenticated state
        if (response.statusCode == 401) {
          await TokenManager.clearToken();
        }
        return decodedResponse;
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = '$_baseUrl$endpoint';
      debugPrint('ApiService: PATCH request to $url');
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedResponse;
      } else {
        if (response.statusCode == 401) {
          await TokenManager.clearToken();
        }
        return decodedResponse;
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
