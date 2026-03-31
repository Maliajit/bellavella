import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/widgets/app_network_image.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'package:bellavella/features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/features/client/services/utils/service_price_formatter.dart';
import 'package:bellavella/features/client/services/widgets/service_flow_banner_carousel.dart';
import 'package:bellavella/features/client/services/widgets/service_popup_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ServiceVariantOptionsSheet extends StatefulWidget {
  final DetailedService service;
  final String nodeKey;
  final ServiceHierarchyNode initialNode;
  final Future<void> Function(DetailedService, int) onQuantityChange;
  final int Function(DetailedService) quantityForItem;
  final bool Function(DetailedService) isItemSyncing;

  const ServiceVariantOptionsSheet({
    super.key,
    required this.service,
    required this.nodeKey,
    required this.initialNode,
    required this.onQuantityChange,
    required this.quantityForItem,
    required this.isItemSyncing,
  });

  @override
  State<ServiceVariantOptionsSheet> createState() =>
      _ServiceVariantOptionsSheetState();
}

class _ServiceVariantOptionsSheetState
    extends State<ServiceVariantOptionsSheet> {
  final Set<int> _pendingIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<ServiceProvider>();
      final sid = int.tryParse(widget.service.id.toString());
      if (sid != null) {
        sp.fetchServiceReviews(sid);
      }
    });
  }

  List<DetailedService> get _sheetItems {
    final variants = _resolvedNode.children
        .where((child) => child.level == 'variant')
        .map(_serviceFromNode)
        .toList();

    if (variants.isNotEmpty) {
      return variants;
    }

    return [widget.service];
  }

  bool get _hasVariantItems =>
      _resolvedNode.children.any((child) => child.level == 'variant');

  ServiceHierarchyNode get _resolvedNode {
    final provider = context.read<ServiceProvider>();
    return provider.hierarchyNode(widget.nodeKey) ?? widget.initialNode;
  }

  DetailedService _serviceFromNode(ServiceHierarchyNode node) {
    final normalizedNodeData = {
      ...node.toRouteData(),
      'id':
          node.serviceVariantId ??
          (node.level == 'variant' ? int.tryParse(node.id) : null) ??
          int.tryParse(node.id) ??
          widget.service.id,
      'service_id': node.serviceId ?? widget.service.id,
      'service_variant_id':
          node.serviceVariantId ??
          (node.level == 'variant' ? int.tryParse(node.id) : null),
      'bookable_type':
          node.bookableType ??
          ((node.serviceVariantId != null || node.level == 'variant')
              ? 'variant'
              : 'service'),
      'level': node.level,
      'image': node.image,
      'description': node.description,
      'price': node.price,
      'display_price': node.price,
    };

    return DetailedService.fromJson(normalizedNodeData);
  }

  Future<void> _handleQuantityChange(
    DetailedService item,
    int nextQuantity,
  ) async {
    setState(() => _pendingIds.add(item.id));
    try {
      await widget.onQuantityChange(item, nextQuantity);
    } finally {
      if (mounted) {
        setState(() => _pendingIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServiceProvider, CartProvider>(
      builder: (context, provider, _, __) {
        final resolvedNode =
            provider.hierarchyNode(widget.nodeKey) ?? widget.initialNode;
        final isInitialLoading =
            provider.isHierarchyLoading(widget.nodeKey) &&
            provider.hierarchyNode(widget.nodeKey) == null;

        if (isInitialLoading) {
          return ServicePopupSkeleton(
            showBanner: widget.initialNode.banners.hasPopupBanner,
            showVariantCarousel: true,
          );
        }

        final items = _sheetItems;
        final safeBottom = MediaQuery.of(context).padding.bottom;

        var totalQuantity = 0;
        var totalPrice = 0.0;

        for (final item in items) {
          final quantity = widget.quantityForItem(item);
          totalQuantity += quantity;
          totalPrice += quantity * item.price;
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  totalQuantity > 0 ? 128 + safeBottom : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.service.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if ((widget.service.description ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      widget.service.description!.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (resolvedNode.banners.hasPopupBanner) ...[
                      ServiceFlowBannerCarousel(
                        banners: resolvedNode.banners.popupBanner,
                        height: 188,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        borderRadius: BorderRadius.circular(22),
                        compact: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _hasVariantItems ? 'Choose a variant' : 'Service details',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_hasVariantItems)
                      _buildVariantCarousel(items)
                    else
                      ...items.map(_buildSelectionCard),
                    const SizedBox(height: 20),
                    _buildReviewsSection(widget.service.id),
                  ],
                ),
              ),
              if (totalQuantity > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + safeBottom),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$totalQuantity item${totalQuantity == 1 ? '' : 's'} selected',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatRupees(totalPrice),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 52,
                          width: 132,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Done',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionCard(DetailedService item) {
    final quantity = widget.quantityForItem(item);
    final isSyncing =
        _pendingIds.contains(item.id) || widget.isItemSyncing(item);
    final reviewText = item.reviewCount > 0
        ? '${item.ratingAvg.toStringAsFixed(1)} (${item.reviewCount} reviews)'
        : null;
    final durationText =
        item.durationMinutes == null ? null : '${item.durationMinutes} mins';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (reviewText != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        reviewText,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      formatRupees(item.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (durationText != null)
                      Text(
                        durationText,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildVariantQuantityControl(
            item: item,
            quantity: quantity,
            isSyncing: isSyncing,
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCarousel(List<DetailedService> items) {
    return SizedBox(
      height: 430,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildVariantImageCard(items[index]),
      ),
    );
  }

  Widget _buildVariantImageCard(DetailedService item) {
    final quantity = widget.quantityForItem(item);
    final isSyncing =
        _pendingIds.contains(item.id) || widget.isItemSyncing(item);
    final reviewText = item.reviewCount > 0
        ? '${item.ratingAvg.toStringAsFixed(2)} (${item.reviewCount} reviews)'
        : null;

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 224,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item.image != null && item.image!.isNotEmpty
                  ? AppNetworkImage(
                      url: item.image,
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(height: 14),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (reviewText != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.black87),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reviewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              formatRupees(item.price),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _buildVariantQuantityControl(
              item: item,
              quantity: quantity,
              isSyncing: isSyncing,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 210,
      width: double.infinity,
      color: const Color(0xFFF6F1FF),
      alignment: Alignment.center,
      child: Icon(Icons.spa_outlined, color: AppTheme.primaryColor, size: 40),
    );
  }

  Widget _buildReviewsSection(int serviceId) {
    return Consumer<ServiceProvider>(
      builder: (context, sp, _) {
        final reviews = sp.serviceReviews(serviceId);
        final isLoading = sp.isReviewsLoading(serviceId);
        final hasMore = sp.hasMoreReviews(serviceId);

        if (isLoading && reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Text(
                'Customer Reviews',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: reviews.isEmpty ? 1 : reviews.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              itemBuilder: (context, index) {
                if (reviews.isEmpty) {
                  return Text(
                    'No reviews yet.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  );
                }
                return _buildReviewCard(reviews[index]);
              },
            ),
            if ((hasMore && reviews.isNotEmpty) ||
                (isLoading && reviews.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => sp.fetchServiceReviews(
                              serviceId,
                              loadMore: true,
                            ),
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more'),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(ReviewData review) {
    final name = review.user?.name ?? 'Anonymous';
    final dateStr =
        '${review.createdAt.day} ${_getMonthName(review.createdAt.month)}, ${review.createdAt.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: review.user?.avatar != null
                  ? NetworkImage(review.user!.avatar!)
                  : null,
              child: review.user?.avatar == null && name.isNotEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A4D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.star, color: Colors.white, size: 11),
                ],
              ),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            review.comment!,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade800,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  Widget _buildVariantQuantityControl({
    required DetailedService item,
    required int quantity,
    required bool isSyncing,
    bool fullWidth = false,
  }) {
    if (quantity <= 0) {
      return SizedBox(
        width: fullWidth ? double.infinity : 100,
        height: 40,
        child: OutlinedButton(
          onPressed: isSyncing ? null : () => _handleQuantityChange(item, 1),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isSyncing
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Add',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }

    return Container(
      height: 40,
      width: fullWidth ? double.infinity : 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.35),
        ),
        color: const Color(0xFFF8F3FF),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: isSyncing
                  ? null
                  : () => _handleQuantityChange(item, quantity - 1),
              child: Icon(Icons.remove, size: 18, color: AppTheme.primaryColor),
            ),
          ),
          Expanded(
            child: Center(
              child: isSyncing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '$quantity',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: isSyncing
                  ? null
                  : () => _handleQuantityChange(item, quantity + 1),
              child: Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
