import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../routes/app_routes.dart';
import '../config/app_config.dart';
import '../router/client_router.dart';
import '../router/professional_router.dart';
import 'token_manager.dart';

class ApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static Completer<bool>? _refreshCompleter;
  static bool _isRedirectingToLogin = false;
  static const String sessionExpiredMessage =
      'Your session expired. Please sign in again to continue.';

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

  static void _logRequest(
    String method,
    String url,
    Map<String, String> headers, [
    Map<String, dynamic>? body,
  ]) {
    final hasToken = TokenManager.hasToken;
    final hasAuthorization = headers.containsKey('Authorization');
    debugPrint('ApiService: $method request to $url');
    debugPrint(
      'ApiService: auth state -> hasToken=$hasToken, authorizationHeader=$hasAuthorization',
    );
    if (body != null) {
      debugPrint('ApiService: request body -> ${jsonEncode(body)}');
    }
  }

  static Map<String, dynamic> _decodeResponseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': 'Unexpected response format',
        'data': decoded,
      };
    } catch (_) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.body.isEmpty
            ? 'Empty response body'
            : 'Non-JSON response body',
        'raw_body': response.body,
      };
    }
  }

  static void _logResponse(
    String method,
    String url,
    http.Response response,
    Map<String, dynamic> decodedResponse,
  ) {
    debugPrint('ApiService: response status for $method $url -> ${response.statusCode}');
    if (response.statusCode == 401) {
      debugPrint('ApiService: 401 body for $url -> ${jsonEncode(decodedResponse)}');
    }
  }

  static String get _refreshEndpoint =>
      AppConfig.isProfessional
          ? '/professional/auth/refresh'
          : '/client/auth/refresh';

  static String get _loginRoute =>
      AppConfig.isProfessional ? AppRoutes.proLogin : AppRoutes.clientLogin;

  static bool _canAttemptRefresh(
    String endpoint,
    Map<String, String> headers,
    bool hasRetried,
  ) {
    if (hasRetried || !TokenManager.hasToken) {
      return false;
    }
    if (!headers.containsKey('Authorization')) {
      return false;
    }

    final normalized = endpoint.toLowerCase();
    return normalized != _refreshEndpoint.toLowerCase() &&
        !normalized.endsWith('/send-otp') &&
        !normalized.endsWith('/verify-otp') &&
        !normalized.endsWith('/login');
  }

  static Future<bool> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final existingToken = TokenManager.token;
      if (existingToken == null || existingToken.isEmpty) {
        completer.complete(false);
        return completer.future;
      }

      final url = '$_baseUrl$_refreshEndpoint';
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $existingToken',
      };

      _logRequest('POST', url, headers);
      final response = await http.post(Uri.parse(url), headers: headers);
      final decodedResponse = _decodeResponseBody(response);
      _logResponse('POST', url, response, decodedResponse);

      final nextToken =
          decodedResponse['data']?['access_token']?.toString() ??
          decodedResponse['access_token']?.toString();
      final refreshed =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decodedResponse['success'] == true &&
          nextToken != null &&
          nextToken.isNotEmpty;

      if (refreshed) {
        await TokenManager.setToken(nextToken);
        debugPrint('ApiService: token refresh succeeded');
      } else {
        debugPrint('ApiService: token refresh failed');
      }

      completer.complete(refreshed);
      return completer.future;
    } catch (e) {
      debugPrint('ApiService: token refresh error -> $e');
      completer.complete(false);
      return completer.future;
    } finally {
      _refreshCompleter = null;
    }
  }

  static Future<void> _handleAuthFailure() async {
    await TokenManager.clearToken();
    if (_isRedirectingToLogin) {
      return;
    }

    _isRedirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (AppConfig.isProfessional) {
          professionalRouter.go(_loginRoute);
        } else {
          clientRouter.go(_loginRoute);
        }
      } catch (e) {
        debugPrint('ApiService: login redirect failed -> $e');
      } finally {
        _isRedirectingToLogin = false;
      }
    });
  }

  static Future<http.Response> _sendJsonRequest(
    String method,
    String url,
    Map<String, String> headers, [
    Map<String, dynamic>? body,
  ]) {
    switch (method) {
      case 'POST':
        return http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
      case 'PUT':
        return http.put(Uri.parse(url), headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return http.patch(Uri.parse(url), headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return http.delete(Uri.parse(url), headers: headers);
      default:
        return http.get(Uri.parse(url), headers: headers);
    }
  }

  static Future<Map<String, dynamic>> _unauthorizedResponse(
    Map<String, dynamic> decodedResponse,
    int statusCode,
  ) async {
    await _handleAuthFailure();
    return {
      ...decodedResponse,
      'message': sessionExpiredMessage,
      '_http_status': statusCode,
      '_auth_expired': true,
    };
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _request('POST', endpoint, body);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _request('PUT', endpoint, body);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    return _request('PATCH', endpoint, body);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _request('DELETE', endpoint);
  }

  static Future<Map<String, dynamic>> multipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, XFile> files, {
    bool hasRetriedAfterRefresh = false,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      final headers = _headers;
      _logRequest('MULTIPART POST', url, headers);

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);
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
      final decodedResponse = _decodeResponseBody(response);
      _logResponse('MULTIPART POST', url, response, decodedResponse);
      if (response.statusCode == 401 &&
          _canAttemptRefresh(endpoint, headers, hasRetriedAfterRefresh)) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return multipart(
            endpoint,
            fields,
            files,
            hasRetriedAfterRefresh: true,
          );
        }
        return _unauthorizedResponse(decodedResponse, response.statusCode);
      }

      decodedResponse['_http_status'] = response.statusCode;
      return decodedResponse;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, [
    Map<String, dynamic>? body,
    bool _hasRetriedAfterRefresh = false,
  ]) async {
    try {
      final url = '$_baseUrl$endpoint';
      final headers = _headers;
      _logRequest(method, url, headers, body);

      final response = await _sendJsonRequest(method, url, headers, body);
      final decodedResponse = _decodeResponseBody(response);
      _logResponse(method, url, response, decodedResponse);

      if (response.statusCode == 401 &&
          _canAttemptRefresh(endpoint, headers, _hasRetriedAfterRefresh)) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _request(method, endpoint, body, true);
        }
        return _unauthorizedResponse(decodedResponse, response.statusCode);
      }

      decodedResponse['_http_status'] = response.statusCode;
      return decodedResponse;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
