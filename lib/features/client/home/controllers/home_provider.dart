import 'package:flutter/material.dart';
import '../models/home_models.dart';
import '../services/home_location_service.dart';
import 'package:bellavella/core/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeLocationService _locationService = HomeLocationService();

  String _locationAddress = 'Fetching location...';
  String _locationSubAddress = '';

  String get locationAddress => _locationAddress;
  String get locationSubAddress => _locationSubAddress;

  List<HomeSection> _sections = [];
  List<HomeSection> get sections => _sections;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> determinePosition() async {
    final result = await _locationService.determinePosition();
    if (result != null) {
      _locationAddress = result['address']!;
      _locationSubAddress = result['subAddress']!;
      notifyListeners();
    }
  }

  void setLocation(String main, String sub) {
    _locationAddress = main;
    _locationSubAddress = sub;
    notifyListeners();
  }

  Future<void> fetchHomepageData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/client/homepage');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        
        if (data['sections'] != null) {
          final sectionsList = data['sections'] as List;
          _sections = sectionsList
              .map((json) => HomeSection.fromJson(json))
              .toList();
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load homepage data.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while loading homepage data: \${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

