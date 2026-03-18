import 'package:flutter/material.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:bellavella/features/client/packages/services/package_api_service.dart';

class PackageProvider extends ChangeNotifier {
  final Map<String, List<PackageSummary>> _packagesByContext = {};
  final Map<int, ConfigurablePackage> _packageConfigs = {};
  final Set<String> _loadingContexts = {};
  final Set<int> _loadingConfigs = {};
  String? _error;

  String? get error => _error;
  bool isContextLoading(String contextKey) => _loadingContexts.contains(contextKey);
  bool isPackageLoading(int packageId) => _loadingConfigs.contains(packageId);

  List<PackageSummary> packagesForContext(String contextCacheKey) {
    return _packagesByContext[contextCacheKey] ?? const [];
  }

  ConfigurablePackage? packageConfig(int packageId) {
    return _packageConfigs[packageId];
  }

  Future<void> fetchPackagesForContext({
    required String contextType,
    required String contextId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$contextType:$contextId';
    if (!forceRefresh && _packagesByContext.containsKey(cacheKey)) {
      return;
    }

    _loadingContexts.add(cacheKey);
    _error = null;
    notifyListeners();

    try {
      _packagesByContext[cacheKey] = await PackageApiService.getPackagesForContext(
        contextType: contextType,
        contextId: contextId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingContexts.remove(cacheKey);
      notifyListeners();
    }
  }

  Future<void> fetchPackageConfiguration({
    required int packageId,
    String? contextType,
    String? contextId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _packageConfigs.containsKey(packageId)) {
      return;
    }

    _loadingConfigs.add(packageId);
    _error = null;
    notifyListeners();

    try {
      _packageConfigs[packageId] =
          await PackageApiService.getPackageConfiguration(
        packageId: packageId,
        contextType: contextType,
        contextId: contextId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingConfigs.remove(packageId);
      notifyListeners();
    }
  }

  void clear() {
    _packagesByContext.clear();
    _packageConfigs.clear();
    _loadingContexts.clear();
    _loadingConfigs.clear();
    _error = null;
    notifyListeners();
  }
}
