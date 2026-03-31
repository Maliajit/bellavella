import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:bellavella/features/client/packages/widgets/package_card.dart';
import 'package:flutter/material.dart';

class PackageSummarySection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<PackageSummary> packages;
  final ValueChanged<PackageSummary>? onPackageTap;
  final Widget Function(PackageSummary package)? trailingBuilder;
  final String emptyMessage;

  const PackageSummarySection({
    super.key,
    required this.title,
    this.subtitle,
    required this.packages,
    this.onPackageTap,
    this.trailingBuilder,
    this.emptyMessage = 'No packages available right now.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if ((subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (packages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: packages
                  .map(
                    (package) => PackageCard(
                      package: package,
                      onTap: onPackageTap == null
                          ? null
                          : () => onPackageTap!(package),
                      trailing: trailingBuilder?.call(package),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
