import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'package:bellavella/features/client/cart/models/cart_model.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:bellavella/features/client/packages/services/package_api_service.dart';
import 'package:bellavella/features/client/packages/widgets/package_option_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PackageConfigSheet extends StatefulWidget {
  final ConfigurablePackage packageConfig;
  final String contextType;
  final int contextId;
  final CartItem? existingCartItem;

  const PackageConfigSheet({
    super.key,
    required this.packageConfig,
    required this.contextType,
    required this.contextId,
    this.existingCartItem,
  });

  @override
  State<PackageConfigSheet> createState() => _PackageConfigSheetState();
}

class _PackageConfigSheetState extends State<PackageConfigSheet> {
  final Map<int, bool> _selectedItems = {};
  final Map<int, int?> _selectedOptionIds = {};
  final Map<int, List<PackageOption>> _runtimeOptions = {};
  final Set<int> _loadingRuntimeOptions = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _seedSelections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final group in widget.packageConfig.groups) {
        for (final item in group.items) {
          if (item.requiresRuntimeVariantSelection &&
              _selectedItems[item.id] == true) {
            _ensureRuntimeOptions(item);
          }
        }
      }
    });
  }

  void _seedSelections() {
    final existingGroups =
        widget.existingCartItem?.packageConfiguration?['groups'] as List? ??
            const [];
    final existingItemMap = <int, Map<String, dynamic>>{};
    for (final group in existingGroups.whereType<Map>()) {
      final items = group['items'] as List? ?? const [];
      for (final item in items.whereType<Map>()) {
        final itemId = int.tryParse(item['id']?.toString() ?? '') ??
            int.tryParse(item['item_id']?.toString() ?? '');
        if (itemId == null) {
          continue;
        }
        existingItemMap[itemId] = Map<String, dynamic>.from(item);
      }
    }

    for (final group in widget.packageConfig.groups) {
      for (final item in group.items) {
        final existing = existingItemMap[item.id];
        final selected =
            existing == null
                ? (item.isRequired ||
                    item.isDefaultSelected ||
                    item.selectedVariantId != null ||
                    (item.selectedOptionLabel?.trim().isNotEmpty ?? false) ||
                    ((item.selectedPrice ?? 0) > 0))
                : (existing['selected'] == true);
        final defaultOption = item.options.cast<PackageOption?>().firstWhere(
              (option) => option?.isDefault == true,
              orElse: () => item.options.isNotEmpty ? item.options.first : null,
            );
        final optionId =
            existing == null
                ? (item.selectedVariantId ?? defaultOption?.id)
                : int.tryParse(
                  (existing['selected_variant_id'] ??
                              existing['selected_option_id'] ??
                              existing['option_id'])
                          ?.toString() ??
                      '',
                );

        _selectedItems[item.id] = selected;
        _selectedOptionIds[item.id] = optionId;
      }
    }
  }

  List<PackageOption> _optionsFor(PackageItemDefinition item) {
    if (item.options.isNotEmpty) {
      return item.options;
    }
    return _runtimeOptions[item.id] ?? const [];
  }

  PackageOption? _selectedOptionFor(PackageItemDefinition item) {
    final options = _optionsFor(item);
    if (options.isEmpty) {
      return null;
    }

    return options
        .where((candidate) => candidate.id == _selectedOptionIds[item.id])
        .cast<PackageOption?>()
        .firstWhere(
          (candidate) => candidate != null,
          orElse: () => options.isNotEmpty ? options.first : null,
        );
  }

  Future<List<PackageOption>> _ensureRuntimeOptions(
    PackageItemDefinition item,
  ) async {
    if (item.serviceId == null || !item.requiresRuntimeVariantSelection) {
      return const [];
    }
    if (_runtimeOptions.containsKey(item.id)) {
      return _runtimeOptions[item.id]!;
    }
    if (_loadingRuntimeOptions.contains(item.id)) {
      return const [];
    }

    setState(() => _loadingRuntimeOptions.add(item.id));
    try {
      final options = await PackageApiService.getVariantsForService(
        item.serviceId!,
      );
      if (!mounted) {
        return options;
      }

      setState(() {
        _runtimeOptions[item.id] = options;
        _loadingRuntimeOptions.remove(item.id);
        _selectedOptionIds[item.id] ??= options
            .cast<PackageOption?>()
            .firstWhere(
              (option) => option?.isDefault == true,
              orElse: () => options.isNotEmpty ? options.first : null,
            )
            ?.id;
      });
      return options;
    } catch (_) {
      if (mounted) {
        setState(() => _loadingRuntimeOptions.remove(item.id));
      }
      rethrow;
    }
  }

  double get _originalTotal {
    var total = 0.0;
    for (final group in widget.packageConfig.groups) {
      for (final item in group.items) {
        if (_selectedItems[item.id] != true) {
          continue;
        }
        final option = _selectedOptionFor(item);
        total += option?.price ?? item.selectedPrice ?? 0;
      }
    }
    if (total <= 0 && widget.packageConfig.summary.originalPrice != null) {
      return widget.packageConfig.summary.originalPrice!;
    }
    if (total <= 0 && widget.packageConfig.summary.price != null) {
      return widget.packageConfig.summary.price!;
    }
    return total;
  }

  int get _durationMinutes {
    var total = 0;
    for (final group in widget.packageConfig.groups) {
      for (final item in group.items) {
        if (_selectedItems[item.id] != true) {
          continue;
        }
        final option = _selectedOptionFor(item);
        total += option?.durationMinutes ?? item.selectedDurationMinutes ?? 0;
      }
    }
    if (total <= 0 && widget.packageConfig.summary.durationMinutes != null) {
      return widget.packageConfig.summary.durationMinutes!;
    }
    return total;
  }

  double get _discountAmount {
    final threshold = widget.packageConfig.basePriceThreshold ?? 0;
    if (_originalTotal < threshold) {
      return 0;
    }

    final discountType = widget.packageConfig.discountType;
    final discountValue = widget.packageConfig.discountValue ?? 0;
    if (discountValue <= 0 || discountType == null || discountType.isEmpty) {
      return 0;
    }

    if (discountType == 'fixed') {
      return discountValue > _originalTotal ? _originalTotal : discountValue;
    }

    return (_originalTotal * discountValue) / 100;
  }

  double get _finalTotal {
    return (_originalTotal - _discountAmount).clamp(0, double.infinity);
  }

  Map<String, dynamic> get _configurationPayload {
    return {
      'groups': widget.packageConfig.groups
          .map(
            (group) => {
              'group_id': group.id,
              'items': group.items
                  .map(
                    (item) => {
                      'item_id': item.id,
                      'selected': _selectedItems[item.id] == true,
                      'option_id': _selectedOptionIds[item.id],
                      'variant_id': _selectedOptionIds[item.id],
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'totals': {
        'original_total': _originalTotal,
        'discounted_total': _finalTotal,
        'final_total': _finalTotal,
        'duration_minutes': _durationMinutes,
      },
    };
  }

  Future<void> _openOptionSelector(PackageItemDefinition item) async {
    try {
      await _ensureRuntimeOptions(item);
    } catch (error) {
      if (mounted) {
        ToastUtil.showError(context, error.toString());
      }
      return;
    }

    final options = _optionsFor(item);
    if (options.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<PackageOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PackageOptionSelectorSheet(
        title: item.name,
        options: options,
        selectedOptionId: _selectedOptionIds[item.id],
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedItems[item.id] = true;
      _selectedOptionIds[item.id] = selected.id;
    });
  }

  Future<void> _savePackage() async {
    setState(() => _isSaving = true);

    final error = await context.read<CartProvider>().saveConfiguredPackage(
          package: widget.packageConfig.summary,
          contextType: widget.contextType,
          contextId: widget.contextId,
          configuration: _configurationPayload,
          cartId: widget.existingCartItem?.cartId == 0
              ? null
              : widget.existingCartItem?.cartId,
          quantity: widget.packageConfig.quantityAllowed
              ? (widget.existingCartItem?.quantity ?? 1)
              : 1,
        );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (error != null) {
      ToastUtil.showError(context, error);
      return;
    }

    if (widget.existingCartItem == null) {
      ToastUtil.showPackageAddedToast(context);
    } else {
      ToastUtil.showSuccess(context, 'Package updated');
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D8D8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SheetHeader(
                      title: widget.packageConfig.summary.title,
                      durationMinutes: _durationMinutes,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        widget.packageConfig.groups
                            .map((group) => _buildGroup(group))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(
              finalTotal: _finalTotal,
              originalTotal: _originalTotal,
              isSaving: _isSaving,
              bottomInset: bottomInset,
              label: widget.existingCartItem == null
                  ? 'Add to cart'
                  : 'Update package',
              onPressed: _savePackage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(PackageGroupDefinition group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          ...group.items.map(_buildItemRow),
          const SizedBox(height: 6),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0F0F0),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(PackageItemDefinition item) {
    final isSelected = _selectedItems[item.id] == true;
    final option = _selectedOptionFor(item);
    final itemPrice = option?.price ?? item.selectedPrice ?? 0;
    final buttonLabel =
        _loadingRuntimeOptions.contains(item.id)
            ? 'Loading...'
            : option?.name ??
                item.selectedOptionLabel ??
                (item.requiresRuntimeVariantSelection
                    ? 'Choose'
                    : item.selectionMode == 'fixed_service'
                    ? 'Included'
                    : 'Choose');
    final canOpenSelector =
        item.options.isNotEmpty ||
        item.requiresRuntimeVariantSelection;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-6, -2),
            child: Checkbox(
              value: isSelected,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: const Color(0xFF2D2D2D),
              onChanged: item.isRequired
                  ? null
                  : (value) => setState(
                        () => _selectedItems[item.id] = value ?? false,
                      ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF232323),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${itemPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 122,
            child: OutlinedButton(
              onPressed: canOpenSelector ? () => _openOptionSelector(item) : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                side: const BorderSide(color: Color(0xFFDADADA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: const Color(0xFF252525),
                backgroundColor: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      buttonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    canOpenSelector
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final int durationMinutes;

  const _SheetHeader({
    required this.title,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1E6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF252525)),
              ),
            ],
          ),
          if (durationMinutes > 0)
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled_rounded,
                  size: 14,
                  color: Color(0xFF666666),
                ),
                const SizedBox(width: 6),
                Text(
                  'Service time: ${_formatDuration(durationMinutes)}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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

class _BottomBar extends StatelessWidget {
  final double finalTotal;
  final double originalTotal;
  final bool isSaving;
  final double bottomInset;
  final String label;
  final VoidCallback onPressed;

  const _BottomBar({
    required this.finalTotal,
    required this.originalTotal,
    required this.isSaving,
    required this.bottomInset,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalTotal > finalTotal;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                Row(
                  children: [
                    Text(
                      '₹${finalTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF141414),
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        '₹${originalTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: const Color(0xFF8A8A8A),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            height: 56,
            width: 160,
            child: ElevatedButton(
              onPressed: isSaving ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
