class HomeBanner {
  final String title;
  final String subtitle;
  final String imageUrl;

  HomeBanner({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

class HomeCategory {
  final String name;
  final String imageUrl;
  final String badge;

  HomeCategory({
    required this.name,
    required this.imageUrl,
    this.badge = '',
  });
}

class HomeService {
  final String title;
  final double rating;
  final int reviewCount;
  final double price;
  final int? optionCount;
  final String? optionsLabel; // Keeping this for cases where '8 options' is preferred over raw int
  final String imageUrl;

  HomeService({
    required this.title,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.optionCount,
    this.optionsLabel,
    required this.imageUrl,
  });
}
