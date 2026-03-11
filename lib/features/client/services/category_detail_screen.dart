import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
        await sp.fetchHierarchyNode(
          nodeKey: _hierarchyLookupKey,
          level: 'service_group',
          seedNode: widget.hierarchySeedNode,
        );
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
    final response = await ApiService.get('/client/cart');
    if (!mounted ||
        response['success'] != true ||
        response['data'] is! Map<String, dynamic>) {
      return;
    }

    final items = (response['data']['items'] as List? ?? const []);
    final nextQuantities = <int, int>{};
    final nextCartIds = <int, int>{};

    for (final rawItem in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(rawItem);
      if (item['item_type']?.toString() != 'service') {
        continue;
      }

      final serviceId = int.tryParse(item['service_id']?.toString() ?? '');
      final cartId = int.tryParse(item['id']?.toString() ?? '');
      final quantity = int.tryParse(item['quantity']?.toString() ?? '');

      if (serviceId == null || cartId == null || quantity == null) {
        continue;
      }

      nextQuantities[serviceId] = quantity;
      nextCartIds[serviceId] = cartId;
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
        response = await ApiService.post('/client/cart', {
          'item_type': 'service',
          'item_id': service.id,
          'service_id': service.id,
          'quantity': 1,
        });

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
        } else {
          _showSnack(
            response['message']?.toString() ?? 'Failed to add service.',
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
    await provider.fetchHierarchyNode(
      nodeKey: service.slug,
      level: 'service',
      seedNode: service.toHierarchyNode(),
      forceRefresh: provider.hierarchyNode(service.slug) == null,
    );

    if (!mounted) {
      return;
    }

    final node = provider.hierarchyNode(service.slug);
    if (node == null) {
      _showSnack('Unable to load options.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VariantOptionsSheet(
        service: service,
        node: node,
        onSelectVariant: (variant) {
          Navigator.pop(context);
          context.push(AppRoutes.clientBooking, extra: variant.toRouteData());
        },
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    if (sp.isLoadingDetail) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
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
    final node =
        sp.hierarchyNode(_hierarchyLookupKey) ?? widget.hierarchySeedNode;
    final isLoading = sp.isHierarchyLoading(_hierarchyLookupKey);
    final error = sp.hierarchyError(_hierarchyLookupKey);

    if (node == null && isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (node == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(child: Text(error ?? 'Unable to load services.')),
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
                ),
                const SizedBox(height: 20),
                _buildServiceTypeGrid(serviceTypes),
                const SizedBox(height: 30),
                _buildOfferCard(node.name),
                const SizedBox(height: 40),
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
  }) {
    final bannerImage =
        imageUrl ??
        'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=600';

    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(bannerImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
    );
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
                      image: NetworkImage(
                        group.image ??
                            'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=100',
                      ),
                      fit: BoxFit.cover,
                    ),
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
      child: Image.network(
        imageUrl,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _buildOfferCard(String title) {
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
        child: Image.network(
          service.image ??
              'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=300',
          height: 128,
          width: 128,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 128,
            width: 128,
            color: const Color(0xFFFFF1F4),
            alignment: Alignment.center,
            child: Icon(
              _getIconForLabel(service.name),
              color: AppTheme.primaryColor,
              size: 34,
            ),
          ),
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
              child: const Text(
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
                  if (isVariantService)
                    InkWell(
                      onTap: () => _openVariantSelector(service),
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
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
                        ? 'Starts at Rs ${lowestVariantPrice.toStringAsFixed(0)}'
                        : 'Rs ${service.price.toStringAsFixed(0)}${service.durationMinutes == null ? '' : '  •  ${service.durationMinutes} mins'}',
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
                  GestureDetector(
                    onTap: isVariantService
                        ? () => _openVariantSelector(service)
                        : () => _showServiceDetails(context, service),
                    child: const Text(
                      'View details',
                      style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

    if (isVariantService) {
      return InkWell(
        onTap: () => _openVariantSelector(service),
        borderRadius: BorderRadius.circular(18),
        child: cardChild,
      );
    }

    return cardChild;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (service.image != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                service.image!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB6C1,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  'Rs ${service.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                service.durationMinutes == null
                                    ? 'Duration on request'
                                    : '${service.durationMinutes} mins',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Service Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (service.description ?? '').trim().isNotEmpty
                                ? service.description!.trim()
                                : 'Professional service using premium products and techniques. Our trained experts ensure you get the best experience with guaranteed results.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  _buildModalFooter(service),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalFooter(DetailedService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            if (service.hasVariants && !service.isBookable) {
              _openVariantSelector(service);
              return;
            }
            _changeServiceQuantity(
              service,
              (_serviceQuantities[service.id] ?? 0) + 1,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: Text(
            service.hasVariants && !service.isBookable
                ? 'View Variants'
                : 'Add to Cart',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
            : const Text(
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
          InkWell(
            onTap: isSyncing ? null : onDecrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.remove, size: 18, color: AppTheme.primaryColor),
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
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          InkWell(
            onTap: isSyncing ? null : onIncrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('wax')) return Icons.auto_fix_high;
    if (normalized.contains('facial')) return Icons.face_retouching_natural;
    if (normalized.contains('cleanup')) return Icons.clean_hands;
    if (normalized.contains('mani') || normalized.contains('pedi'))
      return Icons.spa;
    if (normalized.contains('thread')) return Icons.content_cut;
    if (normalized.contains('bleach')) return Icons.shutter_speed;
    if (normalized.contains('massage')) return Icons.spa_outlined;
    return Icons.star_outline;
  }
}

class _VariantOptionsSheet extends StatelessWidget {
  final DetailedService service;
  final ServiceHierarchyNode node;
  final ValueChanged<ServiceHierarchyNode> onSelectVariant;

  const _VariantOptionsSheet({
    required this.service,
    required this.node,
    required this.onSelectVariant,
  });

  @override
  Widget build(BuildContext context) {
    final variants = node.children
        .where((child) => child.level == 'variant')
        .toList();
    final lowestPrice = variants.isEmpty
        ? service.price
        : variants
              .map((variant) => variant.price ?? 0)
              .reduce((value, element) => value < element ? value : element);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Starts at Rs ${lowestPrice.toStringAsFixed(0)} • ${variants.length} options',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: variants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    return InkWell(
                      onTap: () => onSelectVariant(variant),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 76,
                                width: 76,
                                color: const Color(0xFFFFF1F4),
                                child:
                                    variant.image == null ||
                                        variant.image!.isEmpty
                                    ? const Icon(
                                        Icons.auto_awesome,
                                        color: AppTheme.primaryColor,
                                      )
                                    : Image.network(
                                        variant.image!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    variant.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if ((variant.description ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      variant.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rs ${(variant.price ?? 0).toStringAsFixed(0)}${variant.durationMinutes == null ? '' : ' • ${variant.durationMinutes} mins'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => onSelectVariant(variant),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Select',
                                style: TextStyle(color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
