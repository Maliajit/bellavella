import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _addressKey = 'current_address';
  static const String _subAddressKey = 'current_sub_address';
  
  static String? _token;
  static bool _onboardingComplete = false;
  static String? _currentAddress;
  static String? _currentSubAddress;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _currentAddress = prefs.getString(_addressKey);
    _currentSubAddress = prefs.getString(_subAddressKey);
  }

  // Token Management
  static String? get token => _token;
  static bool get hasToken => _token != null;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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
