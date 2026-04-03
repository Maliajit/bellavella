import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/core/utils/media_url.dart';

// All data models used by the Home feature.

String _normalizeHomeSectionType(String? rawType) {
  final normalized = (rawType ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'hero_banners':
      return 'hero_banner';
    case 'promo_banners':
      return 'promo_banner';
    case 'image_banners':
      return 'image_banner';
    case 'video_story':
      return 'video_stories';
    default:
      return normalized;
  }
}

String _inferHomeMediaType(Map<String, dynamic> json) {
  final explicitType = (json['media_type'] ?? json['type'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (explicitType == 'video' || explicitType == 'image') {
    return explicitType;
  }

  final rawMedia = (json['media_url'] ??
          json['media_path'] ??
          json['url'] ??
          json['image'] ??
          '')
      .toString()
      .toLowerCase();
  if (rawMedia.endsWith('.mp4') ||
      rawMedia.endsWith('.mov') ||
      rawMedia.endsWith('.m4v') ||
      rawMedia.endsWith('.webm') ||
      rawMedia.endsWith('.m3u8')) {
    return 'video';
  }

  return 'image';
}

class HomeSection {
  final int id;
  final String type;
  final String? name;
  final String title;
  final String? subtitle;
  final String mediaType;      // 'banner' | 'video'
  final String contentType;   // 'static' | 'dynamic'
  final String? dataSource;
  final String? description;
  final String? btnText;
  final String? btnLink;
  final int sortOrder;
  final List<dynamic> items;

  HomeSection({
    required this.id,
    required this.type,
    this.name,
    required this.title,
    this.subtitle,
    required this.mediaType,
    required this.contentType,
    this.dataSource,
    this.description,
    this.btnText,
    this.btnLink,
    required this.sortOrder,
    required this.items,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id:          int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type:        _normalizeHomeSectionType(json['type']?.toString()),
      name:        json['name'],
      title:       json['title'] ?? '',
      subtitle:    json['subtitle'],
      mediaType:   json['media_type']?.toString() ?? 'banner',
      contentType: json['content_type'] ?? 'dynamic',
      dataSource:  json['data_source'],
      description: json['description'],
      btnText:     json['btn_text'],
      btnLink:     json['btn_link'],
      sortOrder:   int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      items:       json['items'] ?? json['banners'] ?? json['data'] ?? [],
    );
  }
}

class HomeBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? targetPage;   // e.g. 'services', 'packages', 'none'
  final String? description;

  HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.targetPage,
    this.description,
  });

  bool get isVideo => mediaType == 'video';
  String get imageUrl => isVideo ? (thumbnailUrl ?? '') : mediaUrl;
  bool get hasVisual => mediaUrl.isNotEmpty || (thumbnailUrl?.isNotEmpty ?? false);

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    final mediaType = _inferHomeMediaType(json);
    return HomeBanner(
      id:          int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title:       json['title'] ?? '',
      subtitle:    json['subtitle'],
      mediaType:   mediaType,
      mediaUrl:    resolveMediaUrl(
        json['media_url']?.toString() ??
            json['media_path']?.toString() ??
            json['url']?.toString() ??
            json['image']?.toString() ??
            json['file_url']?.toString(),
      ),
      thumbnailUrl: resolveNullableMediaUrl(
        json['thumbnail_url']?.toString() ??
            json['thumbnail']?.toString() ??
            json['preview_image']?.toString() ??
            json['poster']?.toString(),
      ),
      targetPage:  json['target_page']?.toString() ?? json['targetPage']?.toString(),
      description: json['description'],
    );
  }
}

class HomeCategory {
  final int id;
  final String name;
  final String slug;
  final String imageUrl;
  final String? badge;

  HomeCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.badge,
  });

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    return HomeCategory(
      id:       int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name:     json['name'] ?? '',
      slug:     json['slug'] ?? '',
      imageUrl: resolveMediaUrl(
        json['image']?.toString() ?? json['image_url']?.toString(),
      ),
      badge:    json['badge'],
    );
  }
}

class HomeService {
  final int id;
  final String slug;
  final String title;
  final String? subtitle;
  final double rating;
  final int reviewCount;
  final double price;
  final bool hasVariants;
  final bool isBookable;
  final int? optionCount;
  final String? optionsLabel;
  final String imageUrl;
  final String? badge;

  HomeService({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.hasVariants,
    required this.isBookable,
    this.optionCount,
    this.optionsLabel,
    required this.imageUrl,
    this.badge,
  });

  factory HomeService.fromJson(Map<String, dynamic> json) {
    return HomeService(
      id:          int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      slug:        json['slug'] ?? '',
      title:       json['name'] ?? '',
      subtitle:    json['subtitle'],
      rating:      double.tryParse((json['average_rating'] ?? 0).toString()) ?? 0.0,
      reviewCount: int.tryParse((json['total_reviews'] ?? 0).toString()) ?? 0,
      price:       double.tryParse(
            (json['lowest_variant_price'] ?? json['price'] ?? 0).toString(),
          ) ??
          0.0,
      hasVariants: json['has_variants'] == true,
      isBookable:  json['is_bookable'] == true,
      optionCount: int.tryParse(
        (json['variant_count'] ?? json['options_count'] ?? 0).toString(),
      ),
      optionsLabel: (() {
        final count = int.tryParse(
          (json['variant_count'] ?? json['options_count'] ?? 0).toString(),
        );
        if (json['has_variants'] == true && count != null) {
          return '$count options';
        }
        return null;
      })(),
      imageUrl:    resolveMediaUrl(
        json['image']?.toString() ?? json['image_url']?.toString(),
      ),
      badge:       json['badge'],
    );
  }

  DetailedService toDetailedService() {
    return DetailedService.fromJson({
      'id': id,
      'name': title,
      'slug': slug,
      'image': imageUrl,
      'short_description': subtitle,
      'display_price': price,
      'price': price,
      'average_rating': rating,
      'total_reviews': reviewCount,
      'has_variants': hasVariants,
      'is_bookable': isBookable,
      'bookable_type': isBookable ? 'service' : null,
      'has_children': hasVariants,
      'next_level': hasVariants ? 'variant' : null,
    });
  }
}

class HomeVideoStory {
  final int id;
  final String title;
  final String? subtitle;
  final String url;
  final String? thumbnail;
  final String? targetPage;

  HomeVideoStory({
    required this.id,
    required this.title,
    this.subtitle,
    required this.url,
    this.thumbnail,
    this.targetPage,
  });

  factory HomeVideoStory.fromJson(Map<String, dynamic> json) {
    return HomeVideoStory(
      id:         int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title:      json['title'] ?? '',
      subtitle:   json['subtitle'],
      url:        resolveMediaUrl(
        json['url']?.toString() ??
            json['video_url']?.toString() ??
            json['media_url']?.toString(),
      ),
      thumbnail:  resolveNullableMediaUrl(
        json['thumbnail']?.toString() ?? json['thumbnail_url']?.toString(),
      ),
      targetPage: json['target_page'],
    );
  }
}
