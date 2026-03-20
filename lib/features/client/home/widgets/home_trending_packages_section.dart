import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/core/widgets/app_network_image.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'package:bellavella/features/client/packages/controllers/package_provider.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:bellavella/features/client/packages/widgets/package_config_sheet.dart';
import 'package:bellavella/features/client/services/utils/service_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeTrendingPackagesSection extends StatefulWidget {
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
  State<HomeTrendingPackagesSection> createState() =>
      _HomeTrendingPackagesSectionState();
}

class _HomeTrendingPackagesSectionState extends State<HomeTrendingPackagesSection> {
  static const int _featuredCount = 2;
  bool _showAll = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) {
      return;
    }

    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchFeaturedPackages(limit: 8);
    });
  }

  Future<void> _openPackage(PackageSummary package) async {
    final contextRef = package.context;
    final contextType = contextRef?.type;
    final contextId = contextRef?.id;

    if (contextType == null || contextId == null) {
      ToastUtil.showError(context, 'This package is missing its booking context.');
      return;
    }

    final existingCartItem = context.read<CartProvider>().findPackageItem(
      package.id,
      contextType: contextType,
      contextId: contextId,
    );
    final packageProvider = context.read<PackageProvider>();

    await packageProvider.fetchPackageConfiguration(
      packageId: package.id,
      contextType: contextType,
      contextId: contextId.toString(),
    );

    if (!mounted) {
      return;
    }

    final config = packageProvider.packageConfig(package.id);
    if (config == null) {
      ToastUtil.showError(
        context,
        packageProvider.error ?? 'Unable to load package.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PackageConfigSheet(
        packageConfig: config,
        contextType: contextType,
        contextId: contextId,
        existingCartItem: existingCartItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PackageProvider>(
      builder: (context, packageProvider, _) {
        final packages = packageProvider.featuredPackages;
        final isLoading = packageProvider.isFeaturedLoading && packages.isEmpty;

        if (isLoading) {
          return _PackageSectionSkeleton(
            title: widget.title,
            subtitle: widget.subtitle,
          );
        }

        if (packages.isEmpty) {
          return const SizedBox.shrink();
        }

        final visiblePackages = _showAll
            ? packages
            : packages.take(_featuredCount).toList();
        final canSeeAll = packages.length > _featuredCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if ((widget.subtitle ?? '').trim().isNotEmpty)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (canSeeAll)
                    TextButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      child: Text(
                        _showAll ? 'Show less' : 'See all',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 360,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: visiblePackages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _FeaturedPackageCard(
                  package: visiblePackages[index],
                  onTap: () => _openPackage(visiblePackages[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedPackageCard extends StatelessWidget {
  final PackageSummary package;
  final VoidCallback onTap;

  const _FeaturedPackageCard({
    required this.package,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewItems = package.previewItems
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(2)
        .toList();
    final previewSummary = previewItems.join(' • ');
    final variablePricing = _hasVariablePricing(package);
    final displayPrice = variablePricing
        ? package.basePriceThreshold
        : package.displayPrice;
    final hasDiscount = !variablePricing && package.hasSavings;

    return SizedBox(
      width: 248,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEDE7EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 122,
                      width: double.infinity,
                      child: package.imageUrl.isNotEmpty
                          ? AppNetworkImage(
                              url: package.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFFFFF0F5),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.primaryColor,
                                size: 34,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PackageBadge(label: _badgeText(package)),
                  const SizedBox(height: 10),
                  Text(
                    package.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (previewItems.isNotEmpty)
                    Text(
                      previewSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    )
                  else
                    Text(
                      package.context?.name ?? 'Curated package',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const Spacer(),
                  if (displayPrice != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variablePricing ? 'Starts at' : 'Package price',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupees(displayPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: hasDiscount
                                ? AppTheme.primaryColor
                                : Colors.black,
                          ),
                        ),
                        if (hasDiscount || package.originalPrice != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (hasDiscount && package.originalPrice != null)
                                Text(
                                  formatRupees(package.originalPrice!),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (hasDiscount)
                                _SavingsPill(label: _savingsText(package)),
                            ],
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _hasVariablePricing(PackageSummary package) {
    if (!package.isConfigurable || package.basePriceThreshold == null) {
      return false;
    }

    final displayPrice = package.displayPrice;
    if (displayPrice == null) {
      return true;
    }

    return (displayPrice - package.basePriceThreshold!).abs() > 0.009;
  }

  static String _badgeText(PackageSummary package) {
    final tag = package.tagLabel?.trim();
    if (tag != null && tag.isNotEmpty) {
      return tag;
    }

    final contextName = package.context?.name?.trim();
    if (contextName != null && contextName.isNotEmpty) {
      return contextName;
    }

    return 'Featured';
  }

  static String _savingsText(PackageSummary package) {
    if (package.discountPercentage != null && package.discountPercentage! > 0) {
      return 'Save ${package.discountPercentage}%';
    }

    final originalPrice = package.originalPrice;
    final displayPrice = package.displayPrice;
    if (originalPrice != null &&
        displayPrice != null &&
        originalPrice > displayPrice) {
      return 'Save ${formatRupees(originalPrice - displayPrice)}';
    }

    return 'Offer';
  }
}

class _PackageBadge extends StatelessWidget {
  final String label;

  const _PackageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SavingsPill extends StatelessWidget {
  final String label;

  const _SavingsPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFFF6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F8A57),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PackageSectionSkeleton extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PackageSectionSkeleton({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => Container(
              width: 248,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
