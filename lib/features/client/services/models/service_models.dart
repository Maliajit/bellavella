import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/utils/parser_util.dart';

String _resolveImageUrl(String? rawImage) {
  if (rawImage == null || rawImage.isEmpty || rawImage.startsWith('http')) {
    return rawImage ?? '';
  }

  final hostUrl = AppConfig.baseUrl.replaceAll(RegExp(r'/api.*'), '');
  return '$hostUrl/storage/$rawImage';
}

String _normalizeLevel(String? level, {String fallback = 'service'}) {
  if (level == null || level.isEmpty) return fallback;
  return level.trim().toLowerCase().replaceAll(' ', '_');
}

class ServiceHierarchyNode {
  final String id;
  final String name;
  final String slug;
  final String level;
  final String? nextLevel;
  final bool hasChildren;
  final List<ServiceHierarchyNode> children;
  final List<DetailedService> services;
  final String? image;
  final String? description;
  final String? tagLabel;
  final double? price;
  final double? salePrice;
  final double? originalPrice;
  final int bookings;
  final double ratingAvg;
  final int reviewCount;
  final bool hasVariants;
  final bool isBookable;
  final bool isDiscounted;
  final String? bookableType;
  final int? durationMinutes;
  final int? serviceId;
  final int? serviceVariantId;
  final List<ServiceHierarchyNode> breadcrumbs;

  const ServiceHierarchyNode({
    required this.id,
    required this.name,
    required this.slug,
    required this.level,
    required this.nextLevel,
    required this.hasChildren,
    required this.children,
    this.services = const [],
    this.image,
    this.description,
    this.tagLabel,
    this.price,
    this.salePrice,
    this.originalPrice,
    this.bookings = 0,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.hasVariants = false,
    this.isBookable = false,
    this.isDiscounted = false,
    this.bookableType,
    this.durationMinutes,
    this.serviceId,
    this.serviceVariantId,
    this.breadcrumbs = const [],
  });

  bool get isLeaf => !hasChildren && children.isEmpty;

  String get routeKey => slug.isNotEmpty ? slug : id;

  factory ServiceHierarchyNode.fromJson(
    Map<String, dynamic> json, {
    String? fallbackLevel,
    String? fallbackNextLevel,
  }) {
    if (json['item'] is Map<String, dynamic>) {
      return ServiceHierarchyNode.fromHierarchyResponse(json);
    }

    final level = _normalizeLevel(
      json['level']?.toString() ??
          json['node_level']?.toString() ??
          json['item_level']?.toString(),
      fallback: fallbackLevel ?? 'service',
    );

    final image = _resolveImageUrl(
      json['image']?.toString() ??
          json['image_url']?.toString() ??
          json['icon']?.toString(),
    );

    final rawChildren =
        (json['children'] as List?) ??
        (json['items'] as List?) ??
        (json['nodes'] as List?) ??
        (json['service_groups'] as List?) ??
        (json['service_types'] as List?) ??
        (json['services'] as List?) ??
        (json['variants'] as List?) ??
        const [];
    final rawServices = (json['services'] as List?) ?? const [];

    final nextLevel = _normalizeNullableLevel(
      json['next_level']?.toString() ??
          json['nextLevel']?.toString() ??
          fallbackNextLevel,
    );

    final childFallbackLevel = nextLevel ?? _inferChildLevel(level);
    final parsedChildren = rawChildren
        .whereType<Map>()
        .map(
          (child) => ServiceHierarchyNode.fromJson(
            Map<String, dynamic>.from(child),
            fallbackLevel: childFallbackLevel,
          ),
        )
        .toList();

    final explicitHasChildren = json['has_children'];
    final inferredHasChildren = explicitHasChildren is bool
        ? explicitHasChildren
        : explicitHasChildren == 1 ||
              parsedChildren.isNotEmpty ||
              json['has_service_groups'] == true ||
              json['has_variants'] == true;

    return ServiceHierarchyNode(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      level: level,
      nextLevel: nextLevel,
      hasChildren: inferredHasChildren,
      children: parsedChildren,
      services: rawServices
          .whereType<Map>()
          .map(
            (service) =>
                DetailedService.fromJson(Map<String, dynamic>.from(service)),
          )
          .toList(),
      image: image.isEmpty ? null : image,
      description:
          json['description']?.toString() ?? json['subtitle']?.toString(),
      tagLabel: json['tag_label']?.toString() ?? json['badge']?.toString(),
      price: _parseNullableDouble(json['display_price'] ?? json['price']),
      salePrice: _parseNullableDouble(json['sale_price']),
      originalPrice: _parseNullableDouble(json['original_price']),
      bookings: json['bookings'] ?? 0,
      ratingAvg: ParserUtil.safeParseDouble(
        json['rating_avg'] ?? json['average_rating'] ?? 0,
      ),
      reviewCount: json['review_count'] ?? json['total_reviews'] ?? 0,
      hasVariants: json['has_variants'] == 1 || json['has_variants'] == true,
      isBookable: json['is_bookable'] == true || json['is_bookable'] == 1,
      isDiscounted: json['is_discounted'] == true || json['is_discounted'] == 1,
      bookableType: json['bookable_type']?.toString(),
      durationMinutes: _parseNullableInt(json['duration_minutes']),
      serviceId: _parseNullableInt(json['service_id']),
      serviceVariantId: _parseNullableInt(
        json['service_variant_id'] ??
            ((level == 'variant' ||
                    json['bookable_type']?.toString() == 'variant')
                ? json['id']
                : null),
      ),
      breadcrumbs: (json['breadcrumbs'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (crumb) =>
                ServiceHierarchyNode.fromJson(Map<String, dynamic>.from(crumb)),
          )
          .toList(),
    );
  }

  factory ServiceHierarchyNode.fromHierarchyResponse(
    Map<String, dynamic> json,
  ) {
    final item = Map<String, dynamic>.from(
      json['item'] as Map<String, dynamic>,
    );
    final children = (json['children'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (child) => ServiceHierarchyNode.fromJson(
            Map<String, dynamic>.from(child),
            fallbackLevel: _childTypeToLevel(json['children_type']?.toString()),
          ),
        )
        .toList();
    final breadcrumbs = (json['breadcrumbs'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (crumb) =>
              ServiceHierarchyNode.fromJson(Map<String, dynamic>.from(crumb)),
        )
        .toList();

    return ServiceHierarchyNode.fromJson({
      ...item,
      'level': json['level'] ?? item['level'],
      'next_level':
          item['next_level'] ??
          _childTypeToLevel(json['children_type']?.toString()),
      'children': children.map((child) => child.toRouteData()).toList(),
      'has_children': json['has_children'],
      'has_variants': json['has_variants'] ?? item['has_variants'],
      'is_bookable': json['is_bookable'] ?? item['is_bookable'],
      'bookable_type': json['bookable_type'] ?? item['bookable_type'],
      'service_id': item['service_id'],
      'service_variant_id': item['service_variant_id'],
      'services': item['services'],
      'breadcrumbs': breadcrumbs.map((crumb) => crumb.toRouteData()).toList(),
    });
  }

  Map<String, dynamic> toRouteData() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'level': level,
      'next_level': nextLevel,
      'has_children': hasChildren,
      'image': image,
      'description': description,
      'tag_label': tagLabel,
      'price': price,
      'sale_price': salePrice,
      'original_price': originalPrice,
      'bookings': bookings,
      'rating_avg': ratingAvg,
      'review_count': reviewCount,
      'has_variants': hasVariants,
      'is_bookable': isBookable,
      'is_discounted': isDiscounted,
      'bookable_type': bookableType,
      'display_name': name,
      'display_price': price,
      'duration_minutes': durationMinutes,
      'service_id':
          serviceId ??
          (bookableType == 'service' ? _parseNullableInt(id) : null),
      'service_variant_id':
          serviceVariantId ??
          (bookableType == 'variant' ? _parseNullableInt(id) : null),
      'services': services
          .map((service) => service.toHierarchyNode().toRouteData())
          .toList(),
      'children': children.map((child) => child.toRouteData()).toList(),
      'breadcrumbs': breadcrumbs.map((crumb) => crumb.toRouteData()).toList(),
    };
  }

  static String? _normalizeNullableLevel(String? value) {
    if (value == null || value.isEmpty) return null;
    return _normalizeLevel(value);
  }

  static String _inferChildLevel(String parentLevel) {
    switch (parentLevel) {
      case 'category':
        return 'service_group';
      case 'service_group':
        return 'service_type';
      case 'service_type':
        return 'service';
      case 'service':
        return 'variant';
      default:
        return 'service';
    }
  }

  static String? _childTypeToLevel(String? childType) {
    if (childType == null || childType.isEmpty) return null;
    final normalized = childType.trim().toLowerCase();
    return normalized.endsWith('s')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return ParserUtil.safeParseDouble(value);
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return int.tryParse(value.toString());
  }
}

class CategoryBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String bannerType;

  CategoryBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkUrl,
    required this.bannerType,
  });

  factory CategoryBanner.fromJson(Map<String, dynamic> json) {
    return CategoryBanner(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'],
      bannerType: json['banner_type'] ?? 'slider',
    );
  }
}

class DetailedService {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final String? description;
  final double price;
  final double? salePrice;
  final double? originalPrice;
  final int bookings;
  final double ratingAvg;
  final int reviewCount;
  final bool hasVariants;
  final bool isBookable;
  final String? bookableType;
  final int? durationMinutes;
  final int? serviceTypeId;
  final String level;
  final String? nextLevel;
  final bool hasChildren;

  DetailedService({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.description,
    required this.price,
    this.salePrice,
    this.originalPrice,
    required this.bookings,
    required this.ratingAvg,
    required this.reviewCount,
    required this.hasVariants,
    this.isBookable = false,
    this.bookableType,
    this.durationMinutes,
    this.serviceTypeId,
    this.level = 'service',
    this.nextLevel,
    this.hasChildren = false,
  });

  factory DetailedService.fromJson(Map<String, dynamic> json) {
    return DetailedService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: _resolveImageUrl(json['image']?.toString()),
      description:
          json['short_description']?.toString() ??
          json['description']?.toString(),
      price: ParserUtil.safeParseDouble(json['display_price'] ?? json['price']),
      salePrice: json['sale_price'] != null
          ? ParserUtil.safeParseDouble(json['sale_price'])
          : null,
      originalPrice: json['original_price'] != null
          ? ParserUtil.safeParseDouble(json['original_price'])
          : null,
      bookings: json['bookings'] ?? 0,
      ratingAvg: ParserUtil.safeParseDouble(
        json['rating_avg'] ?? json['average_rating'] ?? 0,
      ),
      reviewCount: json['review_count'] ?? json['total_reviews'] ?? 0,
      hasVariants: json['has_variants'] == 1 || json['has_variants'] == true,
      isBookable: json['is_bookable'] == true || json['is_bookable'] == 1,
      bookableType: json['bookable_type']?.toString(),
      durationMinutes: ServiceHierarchyNode._parseNullableInt(
        json['duration_minutes'],
      ),
      serviceTypeId: ServiceHierarchyNode._parseNullableInt(
        json['service_type_id'],
      ),
      level: _normalizeLevel(json['level']?.toString(), fallback: 'service'),
      nextLevel: ServiceHierarchyNode._normalizeNullableLevel(
        json['next_level']?.toString() ??
            ((json['has_variants'] == 1 || json['has_variants'] == true)
                ? 'variant'
                : null),
      ),
      hasChildren:
          json['has_children'] == true ||
          json['has_children'] == 1 ||
          json['has_variants'] == 1 ||
          json['has_variants'] == true,
    );
  }

  ServiceHierarchyNode toHierarchyNode() {
    return ServiceHierarchyNode(
      id: id.toString(),
      name: name,
      slug: slug,
      level: level,
      nextLevel: nextLevel,
      hasChildren: hasChildren,
      children: const [],
      services: const [],
      image: image,
      description: description,
      price: price,
      salePrice: salePrice,
      originalPrice: originalPrice,
      bookings: bookings,
      ratingAvg: ratingAvg,
      reviewCount: reviewCount,
      hasVariants: hasVariants,
      isBookable: isBookable,
      bookableType: bookableType,
      durationMinutes: durationMinutes,
      serviceId: id,
    );
  }
}

class CategoryMinimal {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final bool hasServiceGroups;
  final String level;
  final String? nextLevel;
  final bool hasChildren;

  CategoryMinimal({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.hasServiceGroups = false,
    this.level = 'category',
    this.nextLevel,
    this.hasChildren = false,
  });

  factory CategoryMinimal.fromJson(Map<String, dynamic> json) {
    final hasChildren =
        json['has_children'] == true ||
        json['has_children'] == 1 ||
        json['has_service_groups'] == true;

    return CategoryMinimal(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: _resolveImageUrl(json['image']?.toString()),
      hasServiceGroups: json['has_service_groups'] == true,
      level: _normalizeLevel(json['level']?.toString(), fallback: 'category'),
      nextLevel: ServiceHierarchyNode._normalizeNullableLevel(
        json['next_level']?.toString() ??
            (json['has_service_groups'] == true ? 'service_group' : null),
      ),
      hasChildren: hasChildren,
    );
  }

  ServiceHierarchyNode toHierarchyNode() {
    return ServiceHierarchyNode(
      id: id.toString(),
      name: name,
      slug: slug,
      level: level,
      nextLevel: nextLevel ?? (hasServiceGroups ? 'service_group' : null),
      hasChildren: hasChildren || hasServiceGroups,
      children: const [],
      image: image,
    );
  }
}

class CategorySection {
  final String type;
  final String key;
  final String title;
  final String? subtitle;
  final List<dynamic> items;

  CategorySection({
    required this.type,
    required this.key,
    required this.title,
    this.subtitle,
    required this.items,
  });

  factory CategorySection.fromJson(Map<String, dynamic> json) {
    String type = json['type'] ?? 'unknown';
    List<dynamic> rawItems = json['items'] ?? [];
    List<dynamic> items = [];

    if (json['key'] == 'service_types' || type == 'grid') {
      items = rawItems.map((e) => CategoryMinimal.fromJson(e)).toList();
    } else if (json['type'] == 'banner') {
      items = rawItems.map((e) => CategoryBanner.fromJson(e)).toList();
    } else if (json['type'] == 'instagram') {
      items = [];
    } else {
      items = rawItems.map((e) => DetailedService.fromJson(e)).toList();
    }

    return CategorySection(
      type: type,
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      items: items,
    );
  }
}

class CategoryPageData {
  final CategoryMinimal category;
  final List<CategoryBanner> sliderBanners;
  final List<CategoryBanner> inlineBanners;
  final List<CategorySection> sections;

  CategoryPageData({
    required this.category,
    required this.sliderBanners,
    required this.inlineBanners,
    required this.sections,
  });

  factory CategoryPageData.fromJson(Map<String, dynamic> json) {
    return CategoryPageData(
      category: CategoryMinimal.fromJson(json['category'] ?? {}),
      sliderBanners: (json['slider_banners'] as List? ?? [])
          .map((e) => CategoryBanner.fromJson(e))
          .toList(),
      inlineBanners: (json['inline_banners'] as List? ?? [])
          .map((e) => CategoryBanner.fromJson(e))
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((e) => CategorySection.fromJson(e))
          .toList(),
    );
  }
}

class ServiceGroup {
  final int id;
  final String name;
  final String slug;
  final String? tagLabel;
  final String? description;
  final String? image;
  final List<DetailedService> services;
  final String level;
  final String? nextLevel;
  final bool hasChildren;

  ServiceGroup({
    required this.id,
    required this.name,
    required this.slug,
    this.tagLabel,
    this.description,
    this.image,
    this.services = const [],
    this.level = 'service_group',
    this.nextLevel,
    this.hasChildren = false,
  });

  factory ServiceGroup.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List? ?? [])
        .map((e) => DetailedService.fromJson(e))
        .toList();

    return ServiceGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      tagLabel: json['tag_label'] ?? json['badge'],
      description: json['description'],
      image: _resolveImageUrl(json['image']?.toString()),
      services: services,
      level: _normalizeLevel(
        json['level']?.toString(),
        fallback: 'service_group',
      ),
      nextLevel: ServiceHierarchyNode._normalizeNullableLevel(
        json['next_level']?.toString() ??
            (services.isNotEmpty ? 'service' : null),
      ),
      hasChildren:
          json['has_children'] == true ||
          json['has_children'] == 1 ||
          services.isNotEmpty,
    );
  }

  ServiceHierarchyNode toHierarchyNode() {
    return ServiceHierarchyNode(
      id: id.toString(),
      name: name,
      slug: slug,
      level: level,
      nextLevel: nextLevel ?? (services.isNotEmpty ? 'service' : null),
      hasChildren: hasChildren || services.isNotEmpty,
      children: services.map((service) => service.toHierarchyNode()).toList(),
      image: image,
      description: description,
      tagLabel: tagLabel,
    );
  }
}

class CategoryDetail {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final String? description;
  final List<ServiceGroup> serviceGroups;

  CategoryDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.description,
    required this.serviceGroups,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    return CategoryDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'],
      description: json['description'],
      serviceGroups: (json['service_groups'] as List? ?? [])
          .map((e) => ServiceGroup.fromJson(e))
          .toList(),
    );
  }

  ServiceHierarchyNode toHierarchyNode() {
    return ServiceHierarchyNode(
      id: id.toString(),
      name: name,
      slug: slug,
      level: 'category',
      nextLevel: serviceGroups.isNotEmpty ? 'service_group' : null,
      hasChildren: serviceGroups.isNotEmpty,
      children: serviceGroups.map((group) => group.toHierarchyNode()).toList(),
      image: _resolveImageUrl(image),
      description: description,
    );
  }
}
