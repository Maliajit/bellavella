import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/utils/parser_util.dart';

String _resolvePackageImageUrl(String? rawImage) {
  if (rawImage == null || rawImage.isEmpty || rawImage.startsWith('http')) {
    return rawImage ?? '';
  }

  final hostUrl = AppConfig.baseUrl.replaceAll(RegExp(r'/api.*'), '');
  return '$hostUrl/storage/$rawImage';
}

class PackageContextRef {
  final String type;
  final int? id;
  final String? slug;
  final String? name;

  const PackageContextRef({
    required this.type,
    this.id,
    this.slug,
    this.name,
  });

  factory PackageContextRef.fromJson(Map<String, dynamic> json) {
    return PackageContextRef(
      type: json['type']?.toString() ?? 'unknown',
      id: _parseNullableInt(json['id']),
      slug: json['slug']?.toString(),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'slug': slug,
      'name': name,
    };
  }
}

class PackageOption {
  final int id;
  final String name;
  final String? subtitle;
  final double? price;
  final int? durationMinutes;
  final bool isDefault;

  const PackageOption({
    required this.id,
    required this.name,
    this.subtitle,
    this.price,
    this.durationMinutes,
    this.isDefault = false,
  });

  factory PackageOption.fromJson(Map<String, dynamic> json) {
    return PackageOption(
      id: _parseNullableInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? json['label']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? json['description']?.toString(),
      price: _parseNullableDouble(
        json['price'] ?? json['display_price'] ?? json['amount'],
      ),
      durationMinutes: _parseNullableInt(
        json['duration_minutes'] ?? json['duration'],
      ),
      isDefault: json['is_default'] == true || json['default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_default': isDefault,
    };
  }
}

class PackageItemDefinition {
  final int id;
  final String name;
  final String sourceType;
  final int? serviceId;
  final String? serviceSlug;
  final int? serviceTypeId;
  final bool isRequired;
  final bool isDefaultSelected;
  final String selectionMode;
  final bool requiresRuntimeVariantSelection;
  final int? selectedVariantId;
  final double? selectedPrice;
  final int? selectedDurationMinutes;
  final List<PackageOption> options;

  const PackageItemDefinition({
    required this.id,
    required this.name,
    this.sourceType = 'custom',
    this.serviceId,
    this.serviceSlug,
    this.serviceTypeId,
    this.isRequired = false,
    this.isDefaultSelected = false,
    this.selectionMode = 'manual_option',
    this.requiresRuntimeVariantSelection = false,
    this.selectedVariantId,
    this.selectedPrice,
    this.selectedDurationMinutes,
    this.options = const [],
  });

  factory PackageItemDefinition.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? const [];
    return PackageItemDefinition(
      id: _parseNullableInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? json['label']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? 'custom',
      serviceId: _parseNullableInt(json['service_id']),
      serviceSlug: json['service_slug']?.toString(),
      serviceTypeId: _parseNullableInt(json['service_type_id']),
      isRequired: json['is_required'] == true || json['required'] == true,
      isDefaultSelected:
          json['is_default_selected'] == true || json['default_selected'] == true,
      selectionMode: json['selection_mode']?.toString() ?? 'manual_option',
      requiresRuntimeVariantSelection:
          json['requires_runtime_variant_selection'] == true,
      selectedVariantId: _parseNullableInt(
        json['selected_variant_id'] ?? json['selected_option_id'],
      ),
      selectedPrice: _parseNullableDouble(
        json['selected_price'] ?? json['price'] ?? json['display_price'],
      ),
      selectedDurationMinutes: _parseNullableInt(
        json['selected_duration_minutes'] ?? json['duration_minutes'],
      ),
      options: rawOptions
          .whereType<Map>()
          .map((item) => PackageOption.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source_type': sourceType,
      'service_id': serviceId,
      'service_slug': serviceSlug,
      'service_type_id': serviceTypeId,
      'is_required': isRequired,
      'is_default_selected': isDefaultSelected,
      'selection_mode': selectionMode,
      'requires_runtime_variant_selection': requiresRuntimeVariantSelection,
      'selected_variant_id': selectedVariantId,
      'selected_price': selectedPrice,
      'selected_duration_minutes': selectedDurationMinutes,
      'options': options.map((item) => item.toJson()).toList(),
    };
  }
}

class PackageGroupDefinition {
  final int id;
  final String title;
  final String sourceType;
  final String? linkedType;
  final int? linkedId;
  final List<PackageItemDefinition> items;

  const PackageGroupDefinition({
    required this.id,
    required this.title,
    this.sourceType = 'custom',
    this.linkedType,
    this.linkedId,
    this.items = const [],
  });

  factory PackageGroupDefinition.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return PackageGroupDefinition(
      id: _parseNullableInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? 'custom',
      linkedType: json['linked_type']?.toString(),
      linkedId: _parseNullableInt(json['linked_id']),
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => PackageItemDefinition.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source_type': sourceType,
      'linked_type': linkedType,
      'linked_id': linkedId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class ConfigurablePackage {
  final PackageSummary summary;
  final PackageContextRef? context;
  final List<PackageGroupDefinition> groups;
  final String packageMode;
  final String pricingRule;
  final String durationRule;
  final double? basePriceThreshold;
  final String? discountType;
  final double? discountValue;
  final bool quantityAllowed;

  const ConfigurablePackage({
    required this.summary,
    this.context,
    this.groups = const [],
    this.packageMode = 'hierarchy',
    this.pricingRule = 'unknown',
    this.durationRule = 'unknown',
    this.basePriceThreshold,
    this.discountType,
    this.discountValue,
    this.quantityAllowed = true,
  });

  factory ConfigurablePackage.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List? ?? const [];
    return ConfigurablePackage(
      summary: PackageSummary.fromJson(json),
      context: json['context'] is Map<String, dynamic>
          ? PackageContextRef.fromJson(
              Map<String, dynamic>.from(json['context'] as Map),
            )
          : null,
      groups: rawGroups
          .whereType<Map>()
          .map(
            (item) => PackageGroupDefinition.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      packageMode: json['package_mode']?.toString() ?? 'hierarchy',
      pricingRule: json['pricing_rule']?.toString() ?? 'unknown',
      durationRule: json['duration_rule']?.toString() ?? 'unknown',
      basePriceThreshold: _parseNullableDouble(json['base_price_threshold']),
      discountType: json['discount_type']?.toString(),
      discountValue: _parseNullableDouble(json['discount_value']),
      quantityAllowed:
          json['quantity_allowed'] == null || json['quantity_allowed'] == true,
    );
  }
}

class PackageSummary {
  final int id;
  final String title;
  final String slug;
  final String imageUrl;
  final String? shortDescription;
  final String? tagLabel;
  final double? price;
  final double? originalPrice;
  final double? discountedPrice;
  final int? discountPercentage;
  final int? durationMinutes;
  final double? rating;
  final int? reviewCount;
  final List<String> previewItems;
  final PackageContextRef? context;
  final String packageMode;
  final double? basePriceThreshold;
  final String? discountType;
  final double? discountValue;
  final bool isConfigurable;
  final bool quantityAllowed;

  const PackageSummary({
    required this.id,
    required this.title,
    this.slug = '',
    this.imageUrl = '',
    this.shortDescription,
    this.tagLabel,
    this.price,
    this.originalPrice,
    this.discountedPrice,
    this.discountPercentage,
    this.durationMinutes,
    this.rating,
    this.reviewCount,
    this.previewItems = const [],
    this.context,
    this.packageMode = 'hierarchy',
    this.basePriceThreshold,
    this.discountType,
    this.discountValue,
    this.isConfigurable = false,
    this.quantityAllowed = true,
  });

  bool get hasDisplayPrice => displayPrice != null;
  bool get hasSavings =>
      originalPrice != null &&
      displayPrice != null &&
      originalPrice! > displayPrice!;

  double? get displayPrice => discountedPrice ?? price;

  factory PackageSummary.fromJson(Map<String, dynamic> json) {
    final rawPreview = json['preview_items'] as List? ??
        json['included_items_preview'] as List? ??
        json['bullets'] as List? ??
        const [];

    final parsedPrice = _parseNullableDouble(
      json['price'] ?? json['display_price'],
    );
    final parsedOriginalPrice = _parseNullableDouble(
      json['original_price'] ?? json['mrp'],
    );
    final parsedDiscountedPrice = _parseNullableDouble(
      json['discounted_price'] ?? json['final_price'] ?? json['sale_price'],
    );

    final parsedContext = json['context'];

    return PackageSummary(
      id: _parseNullableInt(json['id']) ?? 0,
      title: json['title']?.toString() ??
          json['name']?.toString() ??
          'Package',
      slug: json['slug']?.toString() ?? '',
      imageUrl: _resolvePackageImageUrl(
        json['image']?.toString() ??
            json['image_url']?.toString() ??
            json['url']?.toString(),
      ),
      shortDescription: json['subtitle']?.toString() ??
          json['short_description']?.toString() ??
          json['description']?.toString(),
      tagLabel: json['tag']?.toString() ??
          json['tag_label']?.toString() ??
          json['badge']?.toString(),
      price: parsedPrice,
      originalPrice: parsedOriginalPrice,
      discountedPrice: parsedDiscountedPrice,
      discountPercentage: _parseNullableInt(
        json['discount_percentage'] ?? json['discount'],
      ),
      durationMinutes: _parseNullableInt(
        json['duration_minutes'] ?? json['duration'],
      ),
      rating: _parseNullableDouble(
        json['rating'] ?? json['rating_avg'] ?? json['average_rating'],
      ),
      reviewCount: _parseNullableInt(
        json['review_count'] ?? json['reviews_count'] ?? json['total_reviews'],
      ),
      previewItems: rawPreview
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      context: parsedContext is Map<String, dynamic>
          ? PackageContextRef.fromJson(parsedContext)
          : parsedContext is Map
              ? PackageContextRef.fromJson(Map<String, dynamic>.from(parsedContext))
              : null,
      packageMode: json['package_mode']?.toString() ?? 'hierarchy',
      basePriceThreshold: _parseNullableDouble(json['base_price_threshold']),
      discountType: json['discount_type']?.toString(),
      discountValue: _parseNullableDouble(json['discount_value']),
      isConfigurable:
          json['is_configurable'] == true || json['configurable'] == true,
      quantityAllowed:
          json['quantity_allowed'] == null || json['quantity_allowed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'image_url': imageUrl,
      'short_description': shortDescription,
      'tag_label': tagLabel,
      'price': price,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'discount_percentage': discountPercentage,
      'duration_minutes': durationMinutes,
      'rating': rating,
      'review_count': reviewCount,
      'preview_items': previewItems,
      'context': context?.toJson(),
      'package_mode': packageMode,
      'base_price_threshold': basePriceThreshold,
      'discount_type': discountType,
      'discount_value': discountValue,
      'is_configurable': isConfigurable,
      'quantity_allowed': quantityAllowed,
    };
  }
}

double? _parseNullableDouble(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }
  return ParserUtil.safeParseDouble(value);
}

int? _parseNullableInt(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }
  return int.tryParse(value.toString());
}
