import 'package:flutter/material.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/features/client/services/client_api_service.dart';

class ServiceProvider extends ChangeNotifier {
  CategoryPageData? _categoryPageData;
  List<ServiceGroup> _serviceGroups = [];
  CategoryDetail? _categoryDetail;
  final Map<String, ServiceHierarchyNode> _hierarchyNodes = {};
  final Map<String, bool> _hierarchyLoading = {};
  final Map<String, String?> _hierarchyErrors = {};
  final Map<int, List<ReviewData>> _serviceReviews = {};
  final Map<int, bool> _reviewsLoading = {};
  final Map<int, int> _reviewPages = {};
  final Map<int, bool> _hasMoreReviews = {};
  bool _isLoading = false;
  bool _isLoadingGroups = false;
  bool _isLoadingDetail = false;
  String? _error;

  CategoryPageData? get categoryPageData => _categoryPageData;
  List<ServiceGroup> get serviceGroups => _serviceGroups;
  CategoryDetail? get categoryDetail => _categoryDetail;
  ServiceHierarchyNode? hierarchyNode(String key) => _hierarchyNodes[key];
  bool isHierarchyLoading(String key) => _hierarchyLoading[key] ?? false;
  String? hierarchyError(String key) => _hierarchyErrors[key];
  List<ReviewData> serviceReviews(int serviceId) => _serviceReviews[serviceId] ?? [];
  bool isReviewsLoading(int serviceId) => _reviewsLoading[serviceId] ?? false;
  bool hasMoreReviews(int serviceId) => _hasMoreReviews[serviceId] ?? false;
  bool get isLoading => _isLoading;
  bool get isLoadingGroups => _isLoadingGroups;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;

  String? _normalizedLevel(String? level) {
    if (level == null || level.trim().isEmpty) {
      return null;
    }

    return level.trim().toLowerCase().replaceAll(' ', '_');
  }

  Future<void> fetchCategoryScreenData(String categorySlug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryPageData = await ClientApiService.getCategoryScreenData(categorySlug);
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> fetchServiceGroups(String categorySlug) async {
    _isLoadingGroups = true;
    _error = null;
    notifyListeners();

    try {
      _serviceGroups = await ClientApiService.getServiceGroups(categorySlug);
      _isLoadingGroups = false;
    } catch (e) {
      _error = e.toString();
      _isLoadingGroups = false;
    }
    notifyListeners();
  }

  Future<void> fetchCategoryDetails(String categorySlug) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      _categoryDetail = await ClientApiService.getCategoryDetails(categorySlug);
      _isLoadingDetail = false;
    } catch (e) {
      _error = e.toString();
      _isLoadingDetail = false;
    }
    notifyListeners();
  }

  Future<void> fetchHierarchyNode({
    required String nodeKey,
    String? level,
    ServiceHierarchyNode? seedNode,
    bool forceRefresh = false,
  }) async {
    final requestedLevel = _normalizedLevel(level ?? seedNode?.level);
    final cachedNode = _hierarchyNodes[nodeKey];
    final cachedLevel = _normalizedLevel(cachedNode?.level);

    if (!forceRefresh && cachedNode != null) {
      final canReuseCache =
          requestedLevel == null || requestedLevel == cachedLevel;
      if (canReuseCache) {
        return;
      }
    }

    _hierarchyLoading[nodeKey] = true;
    _hierarchyErrors[nodeKey] = null;
    if (seedNode != null) {
      _hierarchyNodes[nodeKey] = seedNode;
    }
    notifyListeners();

    try {
      final node = await ClientApiService.getHierarchyNode(
        nodeKey: nodeKey,
        level: level,
        seedNode: seedNode,
      );
      _hierarchyNodes[nodeKey] = node;
    } catch (e) {
      _hierarchyErrors[nodeKey] = e.toString();
    } finally {
      _hierarchyLoading[nodeKey] = false;
      notifyListeners();
    }
  }

  Future<void> fetchServiceReviews(
    int serviceId, {
    bool loadMore = false,
  }) async {
    if (!loadMore && _serviceReviews.containsKey(serviceId)) return;
    if (_reviewsLoading[serviceId] == true) return;

    final nextPage = loadMore ? (_reviewPages[serviceId] ?? 1) + 1 : 1;
    if (loadMore && !(_hasMoreReviews[serviceId] ?? false)) return;

    _reviewsLoading[serviceId] = true;
    notifyListeners();

    try {
      final page = await ClientApiService.getServiceReviews(
        serviceId,
        page: nextPage,
      );
      _serviceReviews[serviceId] = loadMore
          ? [...(_serviceReviews[serviceId] ?? const []), ...page.reviews]
          : page.reviews;
      _reviewPages[serviceId] = page.currentPage;
      _hasMoreReviews[serviceId] = page.hasMore;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    } finally {
      _reviewsLoading[serviceId] = false;
      notifyListeners();
    }
  }

  void clearData() {
    _categoryPageData = null;
    _serviceGroups = [];
    _categoryDetail = null;
    _hierarchyNodes.clear();
    _hierarchyLoading.clear();
    _hierarchyErrors.clear();
    _serviceReviews.clear();
    _reviewsLoading.clear();
    _reviewPages.clear();
    _hasMoreReviews.clear();
    _error = null;
    notifyListeners();
  }
}
