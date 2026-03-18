import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';

class PackageApiService {
  static const String _prefix = '/client';

  // TODO(package-engine): confirm final Phase 2 backend contract.
  // Expected list response:
  // {
  //   "context": {...},
  //   "packages": [...]
  // }
  static Future<List<PackageSummary>> getPackagesForContext({
    required String contextType,
    required String contextId,
  }) async {
    final response = await ApiService.get(
      '$_prefix/packages?context_type=$contextType&context_id=$contextId',
    );

    if (response['success'] == true && response['data'] is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response['data']);
      final rawPackages = data['packages'] as List? ?? const [];
      return rawPackages
          .whereType<Map>()
          .map((item) => PackageSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw Exception(
      response['message'] ?? 'Failed to load packages for context.',
    );
  }

  // TODO(package-engine): confirm final Phase 2 backend contract.
  // Expected detail response:
  // {
  //   "package": { ...groups/items/options... }
  // }
  static Future<ConfigurablePackage> getPackageConfiguration({
    required int packageId,
    String? contextType,
    String? contextId,
  }) async {
    final query = <String>[
      if (contextType != null && contextType.isNotEmpty) 'context_type=$contextType',
      if (contextId != null && contextId.isNotEmpty) 'context_id=$contextId',
    ];

    final endpoint = query.isEmpty
        ? '$_prefix/packages/$packageId/config'
        : '$_prefix/packages/$packageId/config?${query.join('&')}';

    final response = await ApiService.get(endpoint);

    if (response['success'] == true && response['data'] is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response['data']);
      final payload = data['package'] is Map<String, dynamic>
          ? data['package'] as Map<String, dynamic>
          : data;
      return ConfigurablePackage.fromJson(payload);
    }

    throw Exception(
      response['message'] ?? 'Failed to load package configuration.',
    );
  }

  static Future<List<PackageOption>> getVariantsForService(int serviceId) async {
    final response = await ApiService.get('$_prefix/services/$serviceId/variants');

    if (response['success'] == true && response['data'] is List) {
      final raw = response['data'] as List;
      return raw
          .whereType<Map>()
          .map((item) => PackageOption.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw Exception(
      response['message'] ?? 'Failed to load service variants.',
    );
  }
}
