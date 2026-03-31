import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/core/widgets/app_network_image.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'package:bellavella/features/client/cart/models/cart_model.dart';
import 'package:bellavella/features/client/packages/controllers/package_provider.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:bellavella/features/client/packages/widgets/package_config_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ContextPackageSection extends StatefulWidget {
  final String contextType;
  final int contextId;
  final String title;
  final String? subtitle;

  const ContextPackageSection({
    super.key,
    required this.contextType,
    required this.contextId,
    required this.title,
    this.subtitle,
  });

  @override
  State<ContextPackageSection> createState() => _ContextPackageSectionState();
}

class _ContextPackageSectionState extends State<ContextPackageSection> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) {
      return;
    }
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchPackagesForContext(
            contextType: widget.contextType,
            contextId: widget.contextId.toString(),
          );
      context.read<CartProvider>().fetchCart();
    });
  }

  Future<void> _openPackage(
    PackageSummary summary, {
    CartItem? existingCartItem,
  }) async {
    final packageProvider = context.read<PackageProvider>();
    await packageProvider.fetchPackageConfiguration(
      packageId: summary.id,
      contextType: widget.contextType,
      contextId: widget.contextId.toString(),
    );

    if (!mounted) {
      return;
    }

    final config = packageProvider.packageConfig(summary.id);
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
        contextType: widget.contextType,
        contextId: widget.contextId,
        existingCartItem: existingCartItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PackageProvider, CartProvider>(
      builder: (context, packageProvider, cartProvider, _) {
        final cacheKey = '${widget.contextType}:${widget.contextId}';
        final packages = packageProvider.packagesForContext(cacheKey);
        final isLoading = packageProvider.isContextLoading(cacheKey);

        if (isLoading && packages.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (packages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if ((widget.subtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...packages.map((package) {
                final cartItem = cartProvider.findPackageItem(
                  package.id,
                  contextType: widget.contextType,
                  contextId: widget.contextId,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _ContextPackageCard(
                    package: package,
                    trailing: _buildActionForPackage(package, cartItem),
                    onTap: () => _openPackage(
                      package,
                      existingCartItem: cartItem,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionForPackage(PackageSummary package, CartItem? cartItem) {
    if (cartItem == null) {
      return _PackageActionButton(
        label: 'Add',
        onPressed: () => _openPackage(package),
      );
    }

    if (package.quantityAllowed) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD9C8FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => context.read<CartProvider>().decrementQuantity(
                    cartItem.quantityKey,
                  ),
              icon: const Icon(Icons.remove, size: 16),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '${cartItem.quantity}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => context.read<CartProvider>().incrementQuantity(
                    cartItem.quantityKey,
                  ),
              icon: const Icon(Icons.add, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    return _PackageActionButton(
      label: 'Edit',
      onPressed: () => _openPackage(
        package,
        existingCartItem: cartItem,
      ),
    );
  }
}

class _ContextPackageCard extends StatelessWidget {
  final PackageSummary package;
  final VoidCallback onTap;
  final Widget trailing;

  const _ContextPackageCard({
    required this.package,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((package.tagLabel ?? '').isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E7F6B),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              package.tagLabel!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0E7F6B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        package.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (package.rating != null ||
                          package.durationMinutes != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (package.rating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Color(0xFF2E2E2E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    package.reviewCount != null &&
                                            package.reviewCount! > 0
                                        ? '${package.rating!.toStringAsFixed(2)} (${package.reviewCount} reviews)'
                                        : package.rating!.toStringAsFixed(2),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      color: const Color(0xFF5A5A5A),
                                    ),
                                  ),
                                ],
                              ),
                            if (package.durationMinutes != null &&
                                package.durationMinutes! > 0)
                              Text(
                                '- ${_formatDuration(package.durationMinutes!)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  color: const Color(0xFF5A5A5A),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (package.displayPrice != null)
                            Text(
                              _formatPrice(package.displayPrice!),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          if (package.hasSavings)
                            Text(
                              _formatPrice(package.originalPrice!),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF8A8A8A),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      if (package.previewItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFFE8E8E8), height: 1),
                        const SizedBox(height: 10),
                        Text(
                          package.previewItems
                              .where((item) => item.trim().isNotEmpty)
                              .map((item) => '- $item')
                              .join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.35,
                            color: const Color(0xFF4B4B4B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDADADA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            'Edit your package',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 110,
                  child: AspectRatio(
                    aspectRatio: 0.88,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: const Color(0xFFF1F1F3),
                            child: package.imageUrl.isNotEmpty
                                ? AppNetworkImage(
                                    url: package.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Center(
                                    child: Text(
                                      package.discountPercentage != null &&
                                              package.discountPercentage! > 0
                                          ? '${package.discountPercentage}%\nOFF'
                                          : 'PACKAGE',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize:
                                            package.discountPercentage != null
                                            ? 22
                                            : 14,
                                        height: 1.0,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0B8A5B),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: -16,
                          child: Center(child: trailing),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double amount) {
    final isWhole = amount.truncateToDouble() == amount;
    return 'Rs ${amount.toStringAsFixed(isWhole ? 0 : 2)}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours <= 0) {
      return '$minutes mins';
    }
    if (remainingMinutes == 0) {
      return '$hours hrs';
    }
    return '$hours hrs ${remainingMinutes} mins';
  }
}

class _PackageActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PackageActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.14),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
