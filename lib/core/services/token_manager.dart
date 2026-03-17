import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class TokenManager {
  static const String _legacyTokenKey = 'auth_token';
  static const String _clientTokenKey = 'client_auth_token';
  static const String _professionalTokenKey = 'professional_auth_token';
  static const String _adminTokenKey = 'admin_auth_token';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _addressKey = 'current_address';
  static const String _subAddressKey = 'current_sub_address';
  
  static String? _clientToken;
  static String? _professionalToken;
  static String? _adminToken;
  static bool _onboardingComplete = false;
  static String? _currentAddress;
  static String? _currentSubAddress;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _clientToken = prefs.getString(_clientTokenKey);
    _professionalToken = prefs.getString(_professionalTokenKey);
    _adminToken = prefs.getString(_adminTokenKey);
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _currentAddress = prefs.getString(_addressKey);
    _currentSubAddress = prefs.getString(_subAddressKey);

    if (prefs.containsKey(_legacyTokenKey)) {
      await prefs.remove(_legacyTokenKey);
      debugPrint('TokenManager: removed legacy token key $_legacyTokenKey');
    }

    debugPrint(
      'TokenManager: init client=${_clientToken != null}, '
      'professional=${_professionalToken != null}, admin=${_adminToken != null}',
    );
  }

  // Token Management
  static String get _activeTokenKey {
    if (AppConfig.isProfessional) {
      return _professionalTokenKey;
    }
    return _clientTokenKey;
  }

  static String? get token {
    final activeToken = _activeToken;
    debugPrint(
      'TokenManager: read active token key=$_activeTokenKey present=${activeToken != null}',
    );
    return activeToken;
  }

  static bool get hasToken => _activeToken != null;

  static String? get _activeToken {
    if (AppConfig.isProfessional) {
      return _professionalToken;
    }
    return _clientToken;
  }

  static Future<void> saveClientToken(String token) async {
    _clientToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientTokenKey, token);
    debugPrint('TokenManager: wrote token key=$_clientTokenKey');
  }

  static String? getClientToken() {
    debugPrint(
      'TokenManager: read token key=$_clientTokenKey present=${_clientToken != null}',
    );
    return _clientToken;
  }

  static Future<void> clearClientToken() async {
    _clientToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clientTokenKey);
    debugPrint('TokenManager: cleared token key=$_clientTokenKey');
  }

  static Future<void> saveProfessionalToken(String token) async {
    _professionalToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_professionalTokenKey, token);
    debugPrint('TokenManager: wrote token key=$_professionalTokenKey');
  }

  static String? getProfessionalToken() {
    debugPrint(
      'TokenManager: read token key=$_professionalTokenKey present=${_professionalToken != null}',
    );
    return _professionalToken;
  }

  static Future<void> clearProfessionalToken() async {
    _professionalToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_professionalTokenKey);
    debugPrint('TokenManager: cleared token key=$_professionalTokenKey');
  }

  static Future<void> saveAdminToken(String token) async {
    _adminToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, token);
    debugPrint('TokenManager: wrote token key=$_adminTokenKey');
  }

  static String? getAdminToken() {
    debugPrint(
      'TokenManager: read token key=$_adminTokenKey present=${_adminToken != null}',
    );
    return _adminToken;
  }

  static Future<void> clearAdminToken() async {
    _adminToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    debugPrint('TokenManager: cleared token key=$_adminTokenKey');
  }

  static Future<void> setToken(String token) async {
    if (AppConfig.isProfessional) {
      await saveProfessionalToken(token);
      return;
    }
    await saveClientToken(token);
  }

  static Future<void> clearToken() async {
    if (AppConfig.isProfessional) {
      await clearProfessionalToken();
      return;
    }
    await clearClientToken();
  }

  // Onboarding Management
  static bool get isOnboardingComplete => _onboardingComplete;

  static Future<void> setOnboardingComplete(bool complete) async {
    _onboardingComplete = complete;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, complete);
  }

  // Location Management
  static String? get currentAddress => _currentAddress;
  static String? get currentSubAddress => _currentSubAddress;
  static bool get hasLocation => _currentAddress != null && _currentAddress!.isNotEmpty;

  static Future<void> setLocation(String address, String subAddress) async {
    _currentAddress = address;
    _currentSubAddress = subAddress;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
    await prefs.setString(_subAddressKey, subAddress);
  }
}
