import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _request('POST', endpoint, body);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _request('PUT', endpoint, body);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  static Future<Map<String, dynamic>> multipart(String endpoint, Map<String, String> fields, Map<String, XFile> files) async {
    try {
      final url = '$_baseUrl$endpoint';
      debugPrint('ApiService: Multiparts POST request to $url');
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_headers);
      request.headers['Content-Type'] = 'multipart/form-data';
      
      request.fields.addAll(fields);
      
      for (var entry in files.entries) {
        if (kIsWeb) {
          final bytes = await entry.value.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            entry.key, 
            bytes, 
            filename: entry.value.name
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 401) {
        await TokenManager.clearToken();
      }
      return decodedResponse;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _request(String method, String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final url = '$_baseUrl$endpoint';
      debugPrint('ApiService: $method request to $url');
      
      late http.Response response;
      if (method == 'POST') {
        response = await http.post(Uri.parse(url), headers: _headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await http.put(Uri.parse(url), headers: _headers, body: jsonEncode(body));
      } else {
        response = await http.get(Uri.parse(url), headers: _headers);
      }

      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 401) {
        await TokenManager.clearToken();
      }
      return decodedResponse;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
