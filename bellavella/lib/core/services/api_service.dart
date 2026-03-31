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

class _ApiAuthExpiredException implements Exception {
  const _ApiAuthExpiredException([this.decodedResponse]);

  final Map<String, dynamic>? decodedResponse;
}

class _ApiSuspendedException implements Exception {
  const _ApiSuspendedException([this.decodedResponse]);

  final Map<String, dynamic>? decodedResponse;
}

class ApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static Completer<bool>? _refreshCompleter;
  static bool _isRedirectingToLogin = false;
  static bool _isRedirectingToSuspended = false;
  static const String sessionExpiredMessage =
      'Your session expired. Please sign in again to continue.';

  static String get _activeTokenKeyName =>
      AppConfig.isProfessional ? 'professional_auth_token' : 'client_auth_token';

  static String? get _activeToken {
    if (AppConfig.isProfessional) {
      return TokenManager.getProfessionalToken();
    }
    return TokenManager.getClientToken();
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _activeToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static String _normalizeEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    
    final baseUri = Uri.parse(_baseUrl);
    final endpointUri = Uri.parse(endpoint);
    
    final normalizedEndpointPath = _normalizeEndpoint(endpointUri.path);
    final combinedPath =
        '${baseUri.path}$normalizedEndpointPath'.replaceAll(RegExp(r'/+'), '/');

    return baseUri.replace(
      path: combinedPath,
      query: endpointUri.hasQuery ? endpointUri.query : null,
      fragment: endpointUri.hasFragment ? endpointUri.fragment : null,
    );
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
      'ApiService: auth state -> key=$_activeTokenKeyName, hasToken=$hasToken, '
      'authorizationHeader=$hasAuthorization',
    );
    if (!hasToken) {
      debugPrint('ApiService: missing token before request for key=$_activeTokenKeyName');
    }
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
      final existingToken = _activeToken;
      if (existingToken == null || existingToken.isEmpty) {
        debugPrint('ApiService: refresh skipped, missing token for key=$_activeTokenKeyName');
        completer.complete(false);
        return completer.future;
      }

      final uri = _buildUri(_refreshEndpoint);
      final url = uri.toString();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $existingToken',
      };

      debugPrint(
        'ApiService: refreshing token via endpoint=$_refreshEndpoint key=$_activeTokenKeyName',
      );
      _logRequest('POST', url, headers);
      final response = await http.post(uri, headers: headers);
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
        debugPrint('ApiService: token refresh failed via endpoint=$_refreshEndpoint');
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
    debugPrint('ApiService: auth failure, clearing key=$_activeTokenKeyName');
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

  static Future<void> _handleSuspendedAccount() async {
    debugPrint('ApiService: accounts suspended, redirecting to SuspendedScreen');
    if (_isRedirectingToSuspended) {
      return;
    }

    _isRedirectingToSuspended = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (AppConfig.isProfessional) {
          professionalRouter.go(AppRoutes.proSuspended);
        }
      } catch (e) {
        debugPrint('ApiService: suspended redirect failed -> $e');
      } finally {
        _isRedirectingToSuspended = false;
      }
    });
  }

  static Future<http.Response> _sendJsonRequest(
    String method,
    Uri uri,
    Map<String, String> headers, [
    Map<String, dynamic>? body,
  ]) {
    switch (method) {
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return http.put(uri, headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return http.patch(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        return http.get(uri, headers: headers);
    }
  }

  static Future<Map<String, dynamic>> _unauthorizedResponse(
    Map<String, dynamic> decodedResponse,
  ) async {
    await _handleAuthFailure();
    throw _ApiAuthExpiredException(decodedResponse);
  }

  static Map<String, dynamic> _authExpiredResponse([
    Map<String, dynamic>? decodedResponse,
  ]) {
    final rawMessage = decodedResponse?['message']?.toString();
    return {
      'success': false,
      'message':
          rawMessage == null || rawMessage.isEmpty || rawMessage == 'Unauthenticated.'
              ? sessionExpiredMessage
              : rawMessage,
      '_auth_expired': true,
      '_http_status': 401,
    };
  }

  static Map<String, dynamic> _suspendedResponse([
    Map<String, dynamic>? decodedResponse,
  ]) {
    return {
      'success': false,
      'message':
          decodedResponse?['message']?.toString() ??
          'Your account has been suspended. Please contact support.',
      'status': 'suspended',
      '_account_suspended': true,
      '_http_status': 403,
    };
  }

  static Map<String, dynamic> _forbiddenResponse([
    Map<String, dynamic>? decodedResponse,
  ]) {
    return {
      'success': false,
      'message':
          decodedResponse?['message']?.toString() ??
          'You do not have permission to perform this action.',
      '_forbidden': true,
      '_http_status': 403,
    };
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _request('POST', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _request('PUT', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    return _request('PATCH', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParameters}) async {
    return _request('GET', endpoint, queryParameters: queryParameters);
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
      final uri = _buildUri(endpoint);
      final url = uri.toString();
      final headers = _headers;
      _logRequest('MULTIPART POST', url, headers);

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      
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
      if (response.statusCode == 401) {
        if (_canAttemptRefresh(endpoint, headers, hasRetriedAfterRefresh)) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            return multipart(
              endpoint,
              fields,
              files,
              hasRetriedAfterRefresh: true,
            );
          }
        }
        return _unauthorizedResponse(decodedResponse);
      }

      if (response.statusCode == 403 && decodedResponse['status'] == 'suspended') {
        await _handleSuspendedAccount();
        throw _ApiSuspendedException(decodedResponse);
      }

      if (response.statusCode == 403) {
        return _forbiddenResponse(decodedResponse);
      }

      decodedResponse['_http_status'] = response.statusCode;
      return decodedResponse;
    } on _ApiAuthExpiredException catch (e) {
      return _authExpiredResponse(e.decodedResponse);
    } on _ApiSuspendedException catch (e) {
      return _suspendedResponse(e.decodedResponse);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool hasRetriedAfterRefresh = false,
  }) async {
    try {
      var uri = _buildUri(endpoint);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...queryParameters,
        });
      }
      print("API GET REQUEST: ${uri.toString()}");
      
      final url = uri.toString();
      final headers = _headers;
      _logRequest(method, url, headers, body);

      final response = await _sendJsonRequest(method, uri, headers, body);
      final decodedResponse = _decodeResponseBody(response);
      _logResponse(method, url, response, decodedResponse);

      if (response.statusCode == 401) {
        if (_canAttemptRefresh(endpoint, headers, hasRetriedAfterRefresh)) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            return _request(
              method, 
              endpoint, 
              body: body, 
              queryParameters: queryParameters, 
              hasRetriedAfterRefresh: true
            );
          }
        }
        return _unauthorizedResponse(decodedResponse);
      }

      if (response.statusCode == 403 && decodedResponse['status'] == 'suspended') {
        await _handleSuspendedAccount();
        throw _ApiSuspendedException(decodedResponse);
      }

      if (response.statusCode == 403) {
        return _forbiddenResponse(decodedResponse);
      }

      decodedResponse['_http_status'] = response.statusCode;
      return decodedResponse;
    } on _ApiAuthExpiredException catch (e) {
      return _authExpiredResponse(e.decodedResponse);
    } on _ApiSuspendedException catch (e) {
      return _suspendedResponse(e.decodedResponse);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
