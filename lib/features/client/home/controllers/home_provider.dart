import 'package:flutter/material.dart';
import '../models/home_models.dart';
import '../services/home_location_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeLocationService _locationService = HomeLocationService();

  String _locationAddress = 'Fetching location...';
  String _locationSubAddress = '';

  String get locationAddress => _locationAddress;
  String get locationSubAddress => _locationSubAddress;

  // Banner data
  final List<HomeBanner> _banners = [
    HomeBanner(
      title: 'Perfect Combo',
      subtitle: 'Haircut & Makeup - ₹1500',
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=800',
    ),
    HomeBanner(
      title: 'New Season Sale',
      subtitle: 'Flat 30% Off on Facials',
      imageUrl: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=800',
    ),
    HomeBanner(
      title: 'Bridal Special',
      subtitle: 'Book now for Exclusive Glow',
      imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?q=80&w=800',
    ),
  ];

  List<HomeBanner> get banners => _banners;

  // Category data
  final List<HomeCategory> _categories = [
    HomeCategory(name: 'Waxing', imageUrl: 'https://thumbs.dreamstime.com/b/arm-waxing-beauty-salon-216809376.jpg'),
    HomeCategory(name: 'Signature...', imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200', badge: 'New'),
    HomeCategory(name: 'Facial', imageUrl: 'https://thumbs.dreamstime.com/b/beautiful-smiling-woman-healthy-smooth-facial-clean-skin-applying-cosmetic-cream-touch-own-face-model-beauty-face-169183142.jpg'),
    HomeCategory(name: 'Cleanup', imageUrl: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?q=80&w=200'),
    HomeCategory(name: 'Pedicure', imageUrl: 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=200'),
    HomeCategory(name: 'Threadi...', imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=200'),
    HomeCategory(name: 'Spa Ca...', imageUrl: 'https://www.shutterstock.com/image-photo/beautiful-young-happy-woman-getting-260nw-2692322845.jpg'),
    HomeCategory(name: 'Super S...', imageUrl: 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?q=80&w=200', badge: 'Off'),
    HomeCategory(name: 'Bridle', imageUrl: 'https://images.unsplash.com/photo-1594473728867-05ac7ad836d1?q=80&w=400', badge: 'Spec'),
  ];

  List<HomeCategory> get categories => _categories;

  // Service data
  final List<HomeService> _womenSalonServices = [
    HomeService(
      title: 'Threading',
      rating: 4.91,
      reviewCount: 346000,
      price: 99,
      optionCount: 8,
      optionsLabel: '8 options',
      imageUrl: 'https://images.unsplash.com/photo-1519415387722-a1c3bbef716c?q=80&w=1470&auto=format&fit=crop',
    ),
    HomeService(
      title: 'Full arms & underarms waxing',
      rating: 4.90,
      reviewCount: 133000,
      price: 599,
      optionCount: 6,
      optionsLabel: '6 options',
      imageUrl: 'https://cdn.prod.website-files.com/6680826684515a60a2de75f2/66a2853a54f27d4192e28f08_under-arm.webp',
    ),
    HomeService(
      title: 'Face & neck de-tan',
      rating: 4.85,
      reviewCount: 89000,
      price: 249,
      optionCount: 4,
      optionsLabel: '4 options',
      imageUrl: 'https://lotus-professional.com/cdn/shop/files/face-detan.webp?v=1664367570',
    ),
  ];

  List<HomeService> get womenSalonServices => _womenSalonServices;

  final List<HomeService> _massageServices = [
    HomeService(
      title: 'Stress Relief Body Massage',
      rating: 4.95,
      reviewCount: 52000,
      price: 1299,
      optionCount: 3,
      optionsLabel: '3 options',
      imageUrl: 'https://www.shutterstock.com/image-photo/woman-enjoying-professional-body-massage-260nw-2301687789.jpg',
    ),
    HomeService(
      title: 'Deep Tissue Therapy',
      rating: 4.92,
      reviewCount: 28000,
      price: 1599,
      optionCount: 2,
      optionsLabel: '2 options',
      imageUrl: 'https://spameraki.com/cdn/shop/products/WebsitePics_27.png?v=1623620680',
    ),
  ];

  List<HomeService> get massageServices => _massageServices;

  final List<HomeService> _skincareServices = [
    HomeService(
      title: 'Bridal Glow Facial',
      rating: 4.98,
      reviewCount: 12000,
      price: 2499,
      optionCount: 1,
      optionsLabel: '1 option',
      imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=400',
    ),
    HomeService(
      title: 'Vitamin C Brightening',
      rating: 4.89,
      reviewCount: 45000,
      price: 1899,
      optionCount: 2,
      optionsLabel: '2 options',
      imageUrl: 'https://images.unsplash.com/photo-1552693673-1bf958298935?q=80&w=400',
    ),
  ];

  List<HomeService> get skincareServices => _skincareServices;

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
}
