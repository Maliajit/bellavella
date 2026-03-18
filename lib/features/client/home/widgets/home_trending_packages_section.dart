import 'package:flutter/material.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:bellavella/features/client/packages/widgets/package_summary_section.dart';

class HomeTrendingPackagesSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<dynamic> items;

  const HomeTrendingPackagesSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final packages = items
        .whereType<Map>()
        .map((item) => PackageSummary.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    return PackageSummarySection(
      title: title,
      subtitle: subtitle,
      packages: packages,
      emptyMessage: 'No trending packages available yet',
    );
  }
}
