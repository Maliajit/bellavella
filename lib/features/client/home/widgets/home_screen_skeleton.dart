import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

class HomeScreenSkeleton extends StatelessWidget {
  static const double _pagePadding = 20;
  static const double _sectionGap = 28;
  static const double _heroHeight = 200;

  final int serviceCount;
  final int mostBookedCount;

  const HomeScreenSkeleton({
    super.key,
    this.serviceCount = 4,
    this.mostBookedCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedServiceCount = serviceCount < 1 ? 4 : serviceCount;
    final normalizedMostBookedCount = mostBookedCount < 1 ? 2 : mostBookedCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderSkeleton(),
          const SizedBox(height: 22),
          const _HeroSkeleton(),
          const SizedBox(height: 16),
          const _PageIndicatorsSkeleton(),
          const SizedBox(height: 24),
          const _SectionHeadingSkeleton(),
          const SizedBox(height: 18),
          _ServiceChipRow(count: normalizedServiceCount),
          const SizedBox(height: _sectionGap),
          const _SectionHeadingSkeleton(showSubtitle: true),
          const SizedBox(height: 18),
          _MostBookedRow(count: normalizedMostBookedCount),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeScreenSkeleton._pagePadding,
        14,
        HomeScreenSkeleton._pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            height: 16,
            width: 110,
            baseColor: Color(0xFFFFD6E3),
            highlightColor: Color(0xFFFFEEF4),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 20, color: Colors.black87),
                        SizedBox(width: 8),
                        SkeletonBox(height: 20, width: 152),
                      ],
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: EdgeInsets.only(left: 28),
                      child: Row(
                        children: [
                          SkeletonBox(height: 13, width: 92),
                          SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    SkeletonBox(
                      width: 48,
                      height: 12,
                      baseColor: Color(0x33FFFFFF),
                      highlightColor: Color(0x66FFFFFF),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black45,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD8D8D8)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search, color: Colors.black45, size: 24),
                    const SizedBox(width: 12),
                    SkeletonBox(
                      height: 14,
                      width: constraints.maxWidth * 0.48,
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
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeScreenSkeleton._pagePadding,
      ),
      child: SizedBox(
        width: double.infinity,
        height: HomeScreenSkeleton._heroHeight,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: HomeScreenSkeleton._heroHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFC8CDD5),
                    Color(0xFFB8BEC8),
                    Color(0xFFA4ACB8),
                  ],
                ),
              ),
              child: const SkeletonBox(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                baseColor: Color(0x00FFFFFF),
                highlightColor: Color(0x22FFFFFF),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        height: 30,
                        width: constraints.maxWidth * 0.58,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 12),
                      SkeletonBox(
                        height: 14,
                        width: constraints.maxWidth * 0.72,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        height: 14,
                        width: constraints.maxWidth * 0.42,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicatorsSkeleton extends StatelessWidget {
  const _PageIndicatorsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            2,
            (_) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeadingSkeleton extends StatelessWidget {
  final bool showSubtitle;

  const _SectionHeadingSkeleton({
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeScreenSkeleton._pagePadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 22, width: 180),
                if (showSubtitle) ...[
                  const SizedBox(height: 4),
                  const SkeletonBox(height: 14, width: 230),
                  const SizedBox(height: 6),
                  const SkeletonBox(height: 14, width: 160),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(top: showSubtitle ? 2 : 4),
            child: const SkeletonBox(height: 16, width: 52),
          ),
        ],
      ),
    );
  }
}

class _ServiceChipRow extends StatelessWidget {
  final int count;

  const _ServiceChipRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeScreenSkeleton._pagePadding,
        ),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => const _ServiceChipSkeleton(),
      ),
    );
  }
}

class _ServiceChipSkeleton extends StatelessWidget {
  const _ServiceChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF1F3F6),
                    Color(0xFFE1E5EB),
                    Color(0xFFA9AFB8),
                  ],
                ),
              ),
              child: const SkeletonBox(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                baseColor: Color(0x00FFFFFF),
                highlightColor: Color(0x1FFFFFFF),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const SkeletonBox(height: 12, width: 54),
        ],
      ),
    );
  }
}

class _MostBookedRow extends StatelessWidget {
  final int count;

  const _MostBookedRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 206,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeScreenSkeleton._pagePadding,
        ),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) => const _MostBookedCardSkeleton(),
      ),
    );
  }
}

class _MostBookedCardSkeleton extends StatelessWidget {
  const _MostBookedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 206,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(
                  height: 98,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  baseColor: Color(0xFFE4E6EA),
                  highlightColor: Color(0xFFF4F6F8),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SkeletonBox(height: 13, width: 74),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SkeletonBox(height: 13, width: 118),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SkeletonBox(height: 11, width: 94),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 14, width: 56),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 78),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 12,
              top: 12,
              child: SkeletonBox(
                height: 22,
                width: 48,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
