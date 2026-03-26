import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/core/utils/media_url.dart';

// All data models used by the Home feature.

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
      type:        json['type'] ?? '',
      name:        json['name'],
      title:       json['title'] ?? '',
      subtitle:    json['subtitle'],
      mediaType:   json['media_type'] ?? 'banner',
      contentType: json['content_type'] ?? 'dynamic',
      dataSource:  json['data_source'],
      description: json['description'],
      btnText:     json['btn_text'],
      btnLink:     json['btn_link'],
      sortOrder:   int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      items:       json['items'] ?? [],
    );
  }
}

class HomeBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? targetPage;   // e.g. 'services', 'packages', 'none'
  final String? description;

  HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.targetPage,
    this.description,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id:          int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title:       json['title'] ?? '',
      subtitle:    json['subtitle'],
      imageUrl:    resolveMediaUrl(
        json['url']?.toString() ?? json['image']?.toString(),
      ),
      targetPage:  json['target_page'],
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
      imageUrl: json['image'] ?? '',
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
      imageUrl:    json['image'] ?? '',
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
      url:        json['url'] ?? '',
      thumbnail:  json['thumbnail'],
      targetPage: json['target_page'],
    );
  }
}
