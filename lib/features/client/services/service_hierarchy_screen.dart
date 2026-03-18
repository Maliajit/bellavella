import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/widgets/app_network_image.dart';
import 'package:bellavella/features/client/packages/widgets/context_package_section.dart';
import 'package:bellavella/features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/features/client/services/utils/service_price_formatter.dart';
import 'package:bellavella/features/client/services/widgets/service_flow_banner_carousel.dart';
import 'package:bellavella/features/client/services/widgets/service_group_screen_skeleton.dart';
import 'package:bellavella/features/client/services/widgets/service_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ServiceHierarchyScreen extends StatefulWidget {
  final String nodeKey;
  final ServiceHierarchyNode? seedNode;
  final List<ServiceHierarchyNode> breadcrumbs;

  const ServiceHierarchyScreen({
    super.key,
    required this.nodeKey,
    this.seedNode,
    this.breadcrumbs = const [],
  });

  @override
  State<ServiceHierarchyScreen> createState() => _ServiceHierarchyScreenState();
}

class _ServiceHierarchyScreenState extends State<ServiceHierarchyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchHierarchyNode(
        nodeKey: widget.nodeKey,
        level: widget.seedNode?.level,
        seedNode: widget.seedNode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        final node = provider.hierarchyNode(widget.nodeKey) ?? widget.seedNode;
        final isLoading = provider.isHierarchyLoading(widget.nodeKey);
        final error = provider.hierarchyError(widget.nodeKey);
        final currentLevel = (node?.level ?? widget.seedNode?.level ?? '')
            .trim()
            .toLowerCase();
        final showServiceGroupSkeleton = currentLevel == 'category';

        // If we have an error and no real children yet, show error explicitly
        final hasRealData =
            provider.hierarchyNode(widget.nodeKey) != null &&
            (provider.hierarchyNode(widget.nodeKey)?.children.isNotEmpty ??
                false);
        final showFullSkeleton =
            (showServiceGroupSkeleton && isLoading && !hasRealData) ||
            (node == null && isLoading);

        if (error != null && !hasRealData && !isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.seedNode?.name ?? 'Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchHierarchyNode(
                        nodeKey: widget.nodeKey,
                        level: widget.seedNode?.level,
                        seedNode: widget.seedNode,
                        forceRefresh: true,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (showFullSkeleton) {
          return Scaffold(
            backgroundColor: Color(0xFFFAFAFA),
            body: SafeArea(
              child: showServiceGroupSkeleton
                  ? const ServiceGroupScreenSkeleton(itemCount: 2)
                  : const ServiceListSkeleton(itemCount: 3),
            ),
          );
        }

        if (node == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(error ?? 'Unable to load services')),
          );
        }

        final breadcrumbs = node.breadcrumbs.isNotEmpty
            ? node.breadcrumbs
            : [...widget.breadcrumbs, node];

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
              node.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchHierarchyNode(
              nodeKey: widget.nodeKey,
              level: node.level,
              seedNode: widget.seedNode,
              forceRefresh: true,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildHero(node),
                if (node.banners.hasPromoBanner) ...[
                  const SizedBox(height: 20),
                  ServiceFlowBannerCarousel(
                    banners: node.banners.promoBanner,
                    height: 156,
                    borderRadius: BorderRadius.circular(22),
                    compact: true,
                  ),
                ],
                if (breadcrumbs.length > 1) ...[
                  const SizedBox(height: 16),
                  _buildBreadcrumbs(breadcrumbs),
                ],
                if (node.level == 'category' && int.tryParse(node.id) != null) ...[
                  const SizedBox(height: 20),
                  ContextPackageSection(
                    contextType: 'category',
                    contextId: int.parse(node.id),
                    title: 'Packages',
                    subtitle: 'Available packages for this category',
                  ),
                ],
                const SizedBox(height: 24),
                if (isLoading && node.children.isEmpty)
                  showServiceGroupSkeleton
                      ? const ServiceGroupScreenSkeleton(itemCount: 2)
                      : const ServiceListSkeleton(
                          showOfferCard: false,
                          itemCount: 3,
                        )
                else if (node.hasChildren || node.children.isNotEmpty)
                  ..._buildChildren(context, node, breadcrumbs)
                else
                  _buildLeafDetail(context, node),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(ServiceHierarchyNode node) {
    if (node.banners.hasPageHeader) {
      return ServiceFlowBannerCarousel(
        banners: node.banners.pageHeader,
        height: 180,
        borderRadius: BorderRadius.circular(24),
      );
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: node.image == null
            ? const LinearGradient(
                colors: [Color(0xFFFFD6DE), Color(0xFFFFEEF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (node.image != null && node.image!.isNotEmpty)
            AppNetworkImage(
              url: node.image,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(24),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(
                    alpha: node.image != null ? 0.65 : 0.05,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayLevel(node.level),
                  style: TextStyle(
                    color: node.image != null
                        ? Colors.white70
                        : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  node.name,
                  style: TextStyle(
                    color: node.image != null ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (node.description != null && node.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    node.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: node.image != null ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(List<ServiceHierarchyNode> breadcrumbs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: breadcrumbs
          .map(
            (crumb) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                crumb.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildChildren(
    BuildContext context,
    ServiceHierarchyNode node,
    List<ServiceHierarchyNode> breadcrumbs,
  ) {
    final children = node.children;

    return [
      Text(
        node.nextLevel != null
            ? 'Select ${_displayLevel(node.nextLevel!)}'
            : 'Explore options',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      ...children.map((child) => _buildChildCard(context, child, breadcrumbs)),
    ];
  }

  Widget _buildChildCard(
    BuildContext context,
    ServiceHierarchyNode child,
    List<ServiceHierarchyNode> breadcrumbs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (child.level == 'service_group') {
              context.pushNamed(
                AppRoutes.clientCategoryDetailName,
                pathParameters: {'name': child.routeKey},
                extra: {
                  'hierarchyNodeKey': child.routeKey,
                  'seedNode': child.toRouteData(),
                  'breadcrumbs': breadcrumbs
                      .map((item) => item.toRouteData())
                      .toList(),
                },
              );
              return;
            }

            context.pushNamed(
              AppRoutes.clientServiceHierarchyName,
              pathParameters: {'nodeKey': child.routeKey},
              extra: {
                'seedNode': child.toRouteData(),
                'breadcrumbs': breadcrumbs
                    .map((item) => item.toRouteData())
                    .toList(),
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildThumbnail(child),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (child.tagLabel != null &&
                              child.tagLabel!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                child.tagLabel!,
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _displayLevel(child.level),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        child.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (child.description != null &&
                          child.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          child.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (child.price != null)
                            Text(
                              formatRupees(
                                child.price!,
                                from: child.hasVariants && !child.isBookable,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          if (child.ratingAvg > 0) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              child.ratingAvg.toStringAsFixed(1),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  child.isLeaf && child.isBookable
                      ? Icons.shopping_bag_outlined
                      : child.isLeaf
                      ? Icons.info_outline
                      : Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ServiceHierarchyNode node) {
    final placeholder = Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFEEF2),
      ),
      child: Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
    );

    if (node.image == null || node.image!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AppNetworkImage(
        url: node.image,
        height: 72,
        width: 72,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildLeafDetail(BuildContext context, ServiceHierarchyNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          node.isBookable ? 'Bookable Item' : 'Service Details',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (node.price != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatRupees(node.price!),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (node.salePrice != null &&
                        node.originalPrice != null &&
                        node.originalPrice! > node.price!)
                      Text(
                        formatRupees(node.originalPrice!),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              if (node.durationMinutes != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${node.durationMinutes} min',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              if (node.description != null && node.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  node.description!,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ],
              if (node.ratingAvg > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '${node.ratingAvg.toStringAsFixed(1)} (${node.reviewCount} reviews)',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (node.isBookable)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => context.push(
                AppRoutes.clientBooking,
                extra: node.toRouteData(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                node.bookableType == 'variant'
                    ? 'Book Variant'
                    : 'Book Service',
              ),
            ),
          ),
      ],
    );
  }

  String _displayLevel(String rawLevel) {
    return rawLevel.replaceAll('_', ' ').trim();
  }
}
