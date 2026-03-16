import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/widgets/app_network_image.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'package:bellavella/features/client/cart/models/cart_model.dart';
import 'package:bellavella/features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/features/client/services/utils/service_price_formatter.dart';
import 'package:bellavella/features/client/services/widgets/service_flow_banner_carousel.dart';
import 'package:bellavella/features/client/services/widgets/service_group_detail_skeleton.dart';
import 'package:bellavella/features/client/services/widgets/service_list_skeleton.dart';
import 'package:bellavella/features/client/services/widgets/service_popup_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final int? targetGroupId;
  final String? hierarchyNodeKey;
  final ServiceHierarchyNode? hierarchySeedNode;
  final List<ServiceHierarchyNode> hierarchyBreadcrumbs;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    this.targetGroupId,
    this.hierarchyNodeKey,
    this.hierarchySeedNode,
    this.hierarchyBreadcrumbs = const [],
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<int, int> _serviceQuantities = {};
  final Map<int, int> _serviceCartIds = {};
  final Set<int> _syncingServiceIds = {};
  String? _preloadedGroupKey;
  bool _hasAttemptedInitialHierarchyFetch = false;

  bool get _isHierarchyGroupMode =>
      widget.hierarchySeedNode?.level == 'service_group' ||
      widget.hierarchyNodeKey != null;

  String get _hierarchyLookupKey =>
      widget.hierarchyNodeKey ??
      widget.hierarchySeedNode?.routeKey ??
      widget.categoryName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = context.read<ServiceProvider>();
      await _loadCartState();

      if (_isHierarchyGroupMode) {
        try {
          await sp.fetchHierarchyNode(
            nodeKey: _hierarchyLookupKey,
            level: 'service_group',
            seedNode: widget.hierarchySeedNode,
          );
          final node = sp.hierarchyNode(_hierarchyLookupKey);
          if (node != null &&
              node.level == 'service' &&
              node.serviceId != null) {
            sp.fetchServiceReviews(node.serviceId!);
          }
        } finally {
          if (mounted) {
            setState(() {
              _hasAttemptedInitialHierarchyFetch = true;
            });
          }
        }
        return;
      }

      await sp.fetchCategoryDetails(widget.categoryName);

      if (widget.targetGroupId != null && mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToSection('group-${widget.targetGroupId}');
        });
      }
    });
  }

  void _scrollToSection(String key) {
    final sectionKey = _sectionKeys[key];
    if (sectionKey?.currentContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      sectionKey!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadCartState() async {
    final cartProvider = context.read<CartProvider>();
    await cartProvider.fetchCart();
    if (!mounted) {
      return;
    }

    final nextQuantities = <int, int>{};
    final nextCartIds = <int, int>{};

    for (final item in cartProvider.items) {
      nextQuantities[item.quantityKey] = item.quantity;
      if (item.cartId > 0) {
        nextCartIds[item.quantityKey] = item.cartId;
      }
    }

    setState(() {
      _serviceQuantities
        ..clear()
        ..addAll(nextQuantities);
      _serviceCartIds
        ..clear()
        ..addAll(nextCartIds);
    });
  }

  void _preloadVariantServices(List<DetailedService> services) {
    if (_preloadedGroupKey == _hierarchyLookupKey) {
      return;
    }

    _preloadedGroupKey = _hierarchyLookupKey;
    final provider = context.read<ServiceProvider>();
    for (final service in services.where((item) => item.hasVariants)) {
      provider.fetchHierarchyNode(
        nodeKey: service.slug,
        level: 'service',
        seedNode: service.toHierarchyNode(),
      );
    }
  }

  Future<void> _changeServiceQuantity(
    DetailedService service,
    int nextQuantity,
  ) async {
    if (_syncingServiceIds.contains(service.id)) {
      return;
    }

    setState(() => _syncingServiceIds.add(service.id));

    try {
      if (!TokenManager.hasToken) {
        final currentQuantity = _serviceQuantities[service.id] ?? 0;
        if (currentQuantity == nextQuantity) {
          return;
        }

        final cartItem = CartItem(
          cartId: 0,
          id: service.id,
          serviceId: service.parentServiceId ?? service.id,
          serviceVariantId: service.serviceVariantId,
          itemType: service.serviceVariantId != null ? 'variant' : 'service',
          title: service.name,
          subtitle: service.description,
          price: service.price,
          imageUrl: service.image ?? '',
          categoryName: widget.categoryName,
          quantity: nextQuantity <= 0 ? 1 : nextQuantity,
        );

        await context.read<CartProvider>().addOrUpdateLocalOrRemoteItem(
          cartItem,
          nextQuantityDelta: nextQuantity - currentQuantity,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          if (nextQuantity <= 0) {
            _serviceQuantities.remove(service.id);
          } else {
            _serviceQuantities[service.id] = nextQuantity;
          }
        });

        if (nextQuantity > currentQuantity) {
          ToastUtil.showAddToCartToast(context, service.name);
        }
        return;
      }

      Map<String, dynamic> response;

      if (nextQuantity <= 0) {
        final cartId = _serviceCartIds[service.id];
        if (cartId == null) {
          setState(() => _serviceQuantities.remove(service.id));
          return;
        }

        response = await ApiService.delete('/client/cart/$cartId');
        if (response['success'] == true) {
          setState(() {
            _serviceQuantities.remove(service.id);
            _serviceCartIds.remove(service.id);
          });
        }
        return;
      }

      final cartId = _serviceCartIds[service.id];
      if (cartId == null) {
        final payload = <String, dynamic>{
          'item_type': service.serviceVariantId != null ? 'variant' : 'service',
          'item_id': service.serviceVariantId ?? service.id,
          'service_id': service.parentServiceId ?? service.id,
          'quantity': 1,
        };
        if (service.serviceVariantId != null) {
          payload['service_variant_id'] = service.serviceVariantId;
          payload['bookable_type'] = 'variant';
        }

        debugPrint('Cart payload: $payload');

        response = await ApiService.post('/client/cart', payload);

        if (response['success'] == true &&
            response['data'] is Map<String, dynamic>) {
          final data = Map<String, dynamic>.from(response['data']);
          final createdCartId = int.tryParse(data['id']?.toString() ?? '');
          setState(() {
            _serviceQuantities[service.id] =
                int.tryParse(data['quantity']?.toString() ?? '1') ?? 1;
            if (createdCartId != null) {
              _serviceCartIds[service.id] = createdCartId;
            }
          });
          if (mounted) {
            ToastUtil.showAddToCartToast(context, service.name);
          }
        } else {
          final fieldErrors = response['errors'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(response['errors'])
              : null;
          final serviceErrors = fieldErrors?['service_id'];
          final variantErrors = fieldErrors?['service_variant_id'];
          final detailedMessage =
              (serviceErrors is List && serviceErrors.isNotEmpty)
                  ? serviceErrors.first.toString()
                  : (variantErrors is List && variantErrors.isNotEmpty)
                  ? variantErrors.first.toString()
                  : null;
          _showSnack(
            detailedMessage ??
                response['message']?.toString() ??
                'Failed to add service.',
          );
        }
        return;
      }

      response = await ApiService.put('/client/cart/$cartId', {
        'quantity': nextQuantity,
      });
      if (response['success'] == true &&
          response['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response['data']);
        setState(() {
          _serviceQuantities[service.id] =
              int.tryParse(data['quantity']?.toString() ?? '$nextQuantity') ??
              nextQuantity;
        });
      } else {
        _showSnack(
          response['message']?.toString() ?? 'Failed to update quantity.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncingServiceIds.remove(service.id));
      }
    }
  }


  Future<void> _openVariantSelector(DetailedService service) async {
    final provider = context.read<ServiceProvider>();
    provider.fetchHierarchyNode(
      nodeKey: service.slug,
      level: 'service',
      seedNode: service.toHierarchyNode(),
      forceRefresh: provider.hierarchyNode(service.slug) == null,
    );

    if (!mounted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VariantOptionsSheet(
        service: service,
        nodeKey: service.slug,
        initialNode: provider.hierarchyNode(service.slug) ?? service.toHierarchyNode(),
        onQuantityChange: _changeServiceQuantity,
        currentQuantities: _serviceQuantities,
        syncingStates: {
          for (var id in _syncingServiceIds) id: true,
        },
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ToastUtil.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, sp, _) {
        if (_isHierarchyGroupMode) {
          return _buildHierarchyGroupMode(context, sp);
        }
        return _buildLegacyCategoryMode(context, sp);
      },
    );
  }

  Widget _buildLegacyCategoryMode(BuildContext context, ServiceProvider sp) {
    if (sp.isLoadingDetail && sp.categoryDetail == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: SafeArea(
          child: ServiceListSkeleton(itemCount: 4),
        ),
      );
    }

    if (sp.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(child: Text('Error: ${sp.error}')),
      );
    }

    final detail = sp.categoryDetail;
    if (detail == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: Text('No details found.')),
      );
    }

    ServiceGroup? focusedGroup;
    if (widget.targetGroupId != null) {
      try {
        focusedGroup = detail.serviceGroups.firstWhere(
          (group) => group.id == widget.targetGroupId,
        );
      } catch (_) {
        focusedGroup = null;
      }
    }

    final displayTitle = focusedGroup?.name ?? detail.name;
    final displaySubtitle = focusedGroup != null ? detail.name : null;

    for (final group in detail.serviceGroups) {
      _sectionKeys['group-${group.id}'] = GlobalKey();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (displaySubtitle != null)
              Text(
                displaySubtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHeroBanner(
                  title: focusedGroup?.name ?? detail.name,
                  subtitle: focusedGroup?.description ?? detail.description,
                  imageUrl: focusedGroup?.image ?? detail.image,
                  eyebrow: focusedGroup != null
                      ? detail.name
                      : 'Explore Our Services',
                ),
                const SizedBox(height: 20),
                if (focusedGroup == null) ...[
                  _buildLegacyGroupGrid(detail.serviceGroups),
                  const SizedBox(height: 30),
                ],
                _buildOfferCard(focusedGroup?.name ?? detail.name),
                const SizedBox(height: 40),
                if (focusedGroup != null)
                  _buildLegacyServiceSection(focusedGroup)
                else
                  ...detail.serviceGroups.map(_buildLegacyServiceSection),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildViewCartButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyGroupMode(BuildContext context, ServiceProvider sp) {
    final resolvedNode = sp.hierarchyNode(_hierarchyLookupKey);
    final node = resolvedNode ?? widget.hierarchySeedNode;
    final isLoading = sp.isHierarchyLoading(_hierarchyLookupKey);
    final error = sp.hierarchyError(_hierarchyLookupKey);
    final serviceTypeCount = _normalizedServiceTypeCount(node);
    final hasOnlySeedNode = resolvedNode != null &&
        widget.hierarchySeedNode != null &&
        identical(resolvedNode, widget.hierarchySeedNode);
    final hasResolvedNode = resolvedNode != null && !hasOnlySeedNode;
    final showInitialSkeleton =
        !hasResolvedNode &&
        (!_hasAttemptedInitialHierarchyFetch || isLoading);

    if (showInitialSkeleton) {
      return ServiceGroupDetailSkeleton(
        serviceTypeCount: serviceTypeCount,
      );
    }

    if (node == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(child: Text(error ?? 'Unable to load services.')),
      );
    }

    if (!hasResolvedNode && error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(child: Text(error)),
      );
    }

    final serviceTypes = node.children
        .where((child) => child.level == 'service_type')
        .toList();
    final services = node.services;
    _preloadVariantServices(services);
    final breadcrumbTitle = widget.hierarchyBreadcrumbs.isNotEmpty
        ? widget.hierarchyBreadcrumbs.first.name
        : null;

    for (final type in serviceTypes) {
      _sectionKeys['type-${type.id}'] = GlobalKey();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (breadcrumbTitle != null)
              Text(
                breadcrumbTitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHeroBanner(
                  title: node.name,
                  subtitle: node.description,
                  imageUrl: node.image,
                  eyebrow: breadcrumbTitle ?? 'Explore Our Services',
                  banners: node.banners.pageHeader,
                ),
                const SizedBox(height: 20),
                _buildServiceTypeGrid(serviceTypes),
                const SizedBox(height: 30),
                _buildOfferCard(
                  node.name,
                  banners: node.banners.promoBanner,
                ),
                const SizedBox(height: 32),
                if (services.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      isLoading
                          ? 'Loading services...'
                          : 'No services found in this group.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  ...serviceTypes
                      .map(
                        (type) => _buildHierarchyServiceSection(type, services),
                      )
                      .whereType<Widget>(),
                if (node.level == 'service' && node.serviceId != null)
                  _buildReviewsSection(node.serviceId!),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildViewCartButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner({
    required String title,
    required String? subtitle,
    required String? imageUrl,
    required String eyebrow,
    List<ContextBanner> banners = const [],
  }) {
    if (banners.isNotEmpty) {
      return ServiceFlowBannerCarousel(
        banners: banners,
        height: 200,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
      );
    }

    final bannerImage =
        imageUrl ??
        'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=600';

    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: bannerImage,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(20),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _normalizedServiceTypeCount(ServiceHierarchyNode? node) {
    final rawCount = node?.children
            .where((child) => child.level == 'service_type')
            .length ??
        widget.hierarchySeedNode?.children
            .where((child) => child.level == 'service_type')
            .length ??
        5;
    if (rawCount < 1) {
      return 5;
    }
    return rawCount;
  }

  Widget _buildLegacyGroupGrid(List<ServiceGroup> groups) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return InkWell(
            onTap: () => _scrollToSection('group-${group.id}'),
            child: Column(
              children: [
                Container(
                  height: 65,
                  width: 65,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: const AssetImage('assets/images/placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: AppNetworkImage(
                    url: group.image ??
                        'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=100',
                    height: 65,
                    width: 65,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceTypeGrid(List<ServiceHierarchyNode> serviceTypes) {
    if (serviceTypes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'What are you looking for?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: serviceTypes.length,
            itemBuilder: (context, index) {
              final type = serviceTypes[index];
              return InkWell(
                onTap: () => _scrollToSection('type-${type.id}'),
                child: Column(
                  children: [
                    _buildSmallImageBadge(type.image, size: 65, radius: 15),
                    const SizedBox(height: 8),
                    Text(
                      type.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallImageBadge(
    String? imageUrl, {
    required double size,
    required double radius,
  }) {
    final placeholder = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AppNetworkImage(
        url: imageUrl,
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildOfferCard(String title, {List<ContextBanner> banners = const []}) {
    if (banners.isNotEmpty) {
      return ServiceFlowBannerCarousel(
        banners: banners,
        height: 148,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        borderRadius: BorderRadius.circular(20),
        compact: true,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7E98),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exclusive Offers on $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Best prices guaranteed',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'VIEW ALL',
              style: TextStyle(
                color: Color(0xFFFF7E98),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyServiceSection(ServiceGroup group) {
    return Column(
      key: _sectionKeys['group-${group.id}'],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(group.name),
        const SizedBox(height: 10),
        ...group.services.map((service) => _buildServiceItem(service)),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget? _buildHierarchyServiceSection(
    ServiceHierarchyNode type,
    List<DetailedService> allServices,
  ) {
    final services = allServices
        .where((service) => service.serviceTypeId?.toString() == type.id)
        .toList();

    if (services.isEmpty) {
      return null;
    }

    return Column(
      key: _sectionKeys['type-${type.id}'],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(type.name),
        const SizedBox(height: 10),
        ...services.map((service) => _buildServiceItem(service)),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppTheme.primaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(DetailedService service) {
    final provider = Provider.of<ServiceProvider>(context);
    final detailNode = provider.hierarchyNode(service.slug);
    final variants =
        detailNode?.children
            .where((child) => child.level == 'variant')
            .toList() ??
        const [];
    final lowestVariantPrice = variants.isEmpty
        ? service.price
        : variants
              .map((variant) => variant.price ?? 0)
              .reduce((value, element) => value < element ? value : element);
    final optionCount = variants.length;
    final quantity = _serviceQuantities[service.id] ?? 0;
    final isSyncing = _syncingServiceIds.contains(service.id);
    final isVariantService = service.hasVariants && !service.isBookable;
    final reviewText = service.reviewCount > 0
        ? '${service.ratingAvg.toStringAsFixed(2)} (${service.reviewCount} reviews)'
        : null;

    Widget imageBlock() {
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AppNetworkImage(
          url: service.image ??
              'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=300',
          height: 128,
          width: 128,
          fit: BoxFit.cover,
        ),
      );

      return Column(
        children: [
          isVariantService
              ? InkWell(
                  onTap: () => _openVariantSelector(service),
                  borderRadius: BorderRadius.circular(18),
                  child: image,
                )
              : image,
          const SizedBox(height: 12),
          if (isVariantService)
            OutlinedButton(
              onPressed: () => _openVariantSelector(service),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 48),
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            _buildQuantityControl(
              quantity: quantity,
              isSyncing: isSyncing,
              onAdd: () => _changeServiceQuantity(service, quantity + 1),
              onIncrement: () => _changeServiceQuantity(service, quantity + 1),
              onDecrement: () => _changeServiceQuantity(service, quantity - 1),
            ),
          if (isVariantService) ...[
            const SizedBox(height: 8),
            Text(
              optionCount > 0 ? '$optionCount options' : 'View options',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ],
      );
    }

    Widget cardChild = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (reviewText != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Color(0xFF5D3FD3),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reviewText,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    isVariantService
                        ? formatRupees(lowestVariantPrice, from: true)
                        : '${formatRupees(service.price)}${service.durationMinutes == null ? '' : '  •  ${service.durationMinutes} mins'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((service.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      service.description!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'View details',
                    style: TextStyle(
                      color: Color(0xFF6B4EFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          imageBlock(),
        ],
      ),
    );

    return InkWell(
      onTap: isVariantService
          ? () => _openVariantSelector(service)
          : () => _showServiceDetails(context, service),
      borderRadius: BorderRadius.circular(18),
      child: cardChild,
    );
  }

  Widget _buildViewCartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/client/cart'),
        icon: const Icon(Icons.shopping_cart_outlined),
        label: const Text(
          'View Cart',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  void _showServiceDetails(BuildContext context, DetailedService service) {
    final provider = context.read<ServiceProvider>();
    provider.fetchHierarchyNode(
      nodeKey: service.slug,
      level: 'service',
      seedNode: service.toHierarchyNode(),
      forceRefresh: provider.hierarchyNode(service.slug) == null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VariantOptionsSheet(
        service: service,
        nodeKey: service.slug,
        initialNode: provider.hierarchyNode(service.slug) ?? service.toHierarchyNode(),
        onQuantityChange: _changeServiceQuantity,
        currentQuantities: _serviceQuantities,
        syncingStates: {
          for (var id in _syncingServiceIds) id: true,
        },
      ),
    );
  }

  Widget _buildQuantityControl({
    required int quantity,
    required bool isSyncing,
    required VoidCallback onAdd,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    if (quantity <= 0) {
      return OutlinedButton(
        onPressed: isSyncing ? null : onAdd,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(100, 48),
          side: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.35),
        ),
        color: const Color(0xFFF8F3FF),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isSyncing ? null : onDecrement,
                child: Icon(
                  Icons.remove,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: isSyncing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
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
          SizedBox(
            width: 36,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isSyncing ? null : onIncrement,
                child: Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
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
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (reviews.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Customer Reviews',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
            ),
            if (hasMore || (isLoading && reviews.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
            const SizedBox(height: 40),
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
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: review.user?.avatar != null
                  ? NetworkImage(review.user!.avatar!)
                  : null,
              child: review.user?.avatar == null
                  ? Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A4D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    '${review.rating}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.star, color: Colors.white, size: 10),
                ],
              ),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            review.comment!,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade800,
              fontSize: 14,
              height: 1.5,
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

  IconData _getIconForLabel(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('wax')) return Icons.auto_fix_high;
    if (normalized.contains('facial')) return Icons.face_retouching_natural;
    if (normalized.contains('cleanup')) return Icons.clean_hands;
    if (normalized.contains('mani') || normalized.contains('pedi')) {
      return Icons.spa;
    }
    if (normalized.contains('thread')) return Icons.content_cut;
    if (normalized.contains('bleach')) return Icons.shutter_speed;
    if (normalized.contains('massage')) return Icons.spa_outlined;
    return Icons.star_outline;
  }
}
class _VariantOptionsSheet extends StatefulWidget {
  final DetailedService service;
  final String nodeKey;
  final ServiceHierarchyNode initialNode;
  final Future<void> Function(DetailedService, int) onQuantityChange;
  final Map<int, int> currentQuantities;
  final Map<int, bool> syncingStates;

  const _VariantOptionsSheet({
    required this.service,
    required this.nodeKey,
    required this.initialNode,
    required this.onQuantityChange,
    required this.currentQuantities,
    required this.syncingStates,
  });

  @override
  State<_VariantOptionsSheet> createState() => _VariantOptionsSheetState();
}

class _VariantOptionsSheetState extends State<_VariantOptionsSheet> {
  late final Set<int> _pendingIds;

  @override
  void initState() {
    super.initState();
    _pendingIds = widget.syncingStates.keys.toSet();
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

  Future<void> _handleQuantityChange(DetailedService item, int nextQuantity) async {
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
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
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
          final quantity = widget.currentQuantities[item.id] ?? 0;
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
                                if ((widget.service.description ?? '').trim().isNotEmpty)
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
    final quantity = widget.currentQuantities[item.id] ?? 0;
    final isSyncing = _pendingIds.contains(item.id);
    final reviewText = item.reviewCount > 0
        ? '${item.ratingAvg.toStringAsFixed(1)} (${item.reviewCount} reviews)'
        : null;
    final durationText = item.durationMinutes == null
        ? null
        : '${item.durationMinutes} mins';

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
    final quantity = widget.currentQuantities[item.id] ?? 0;
    final isSyncing = _pendingIds.contains(item.id);
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
            if ((hasMore && reviews.isNotEmpty) || (isLoading && reviews.isNotEmpty))
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
          SizedBox(
            width: 32,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isSyncing
                    ? null
                    : () => _handleQuantityChange(item, quantity - 1),
                child: Icon(
                  Icons.remove,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: isSyncing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
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
          SizedBox(
            width: 32,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isSyncing
                    ? null
                    : () => _handleQuantityChange(item, quantity + 1),
                child: Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
