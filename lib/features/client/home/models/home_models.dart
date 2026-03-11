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
      id:          json['id'] ?? 0,
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
      sortOrder:   json['sort_order'] ?? 0,
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
      id:          json['id'] ?? 0,
      title:       json['title'] ?? '',
      subtitle:    json['subtitle'],
      imageUrl:    json['url'] ?? json['image'] ?? '',
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
      id:       json['id'] ?? 0,
      name:     json['name'] ?? '',
      slug:     json['slug'] ?? '',
      imageUrl: json['image'] ?? '',
      badge:    json['badge'],
    );
  }
}

class HomeService {
  final int id;
  final String title;
  final String? subtitle;
  final double rating;
  final int reviewCount;
  final double price;
  final int? optionCount;
  final String? optionsLabel;
  final String imageUrl;
  final String? badge;

  HomeService({
    required this.id,
    required this.title,
    this.subtitle,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.optionCount,
    this.optionsLabel,
    required this.imageUrl,
    this.badge,
  });

  factory HomeService.fromJson(Map<String, dynamic> json) {
    return HomeService(
      id:          json['id'] ?? 0,
      title:       json['name'] ?? '',
      subtitle:    json['subtitle'],
      rating:      double.tryParse((json['average_rating'] ?? 0).toString()) ?? 0.0,
      reviewCount: int.tryParse((json['total_reviews'] ?? 0).toString()) ?? 0,
      price:       double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      imageUrl:    json['image'] ?? '',
      badge:       json['badge'],
    );
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
      id:         json['id'] ?? 0,
      title:      json['title'] ?? '',
      subtitle:   json['subtitle'],
      url:        json['url'] ?? '',
      thumbnail:  json['thumbnail'],
      targetPage: json['target_page'],
    );
  }
}
