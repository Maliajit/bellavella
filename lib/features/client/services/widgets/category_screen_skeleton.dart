import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

class CategoryScreenSkeleton extends StatelessWidget {
  static const double _pagePadding = 20;
  static const double _sectionGap = 28;

  final int categoryCount;
  final int carouselCount;

  const CategoryScreenSkeleton({
    super.key,
    this.categoryCount = 4,
    this.carouselCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedCategoryCount = categoryCount < 1 ? 4 : categoryCount;
    final normalizedCarouselCount = carouselCount < 1 ? 2 : carouselCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AppBarSkeleton(),
          const SizedBox(height: 22),
          const _TaglineSkeleton(),
          const SizedBox(height: 20),
          const _HeroBannerSkeleton(),
          const SizedBox(height: 14),
          const _DotsSkeleton(),
          const SizedBox(height: 26),
          const _SectionHeaderSkeleton(),
          const SizedBox(height: 16),
          _CategoryGridSkeleton(count: normalizedCategoryCount),
          const SizedBox(height: 30),
          const _InstagramBannerSkeleton(),
          const SizedBox(height: 30),
          _CarouselCardsSkeleton(count: normalizedCarouselCount),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AppBarSkeleton extends StatelessWidget {
  const _AppBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CategoryScreenSkeleton._pagePadding,
        14,
        CategoryScreenSkeleton._pagePadding,
        0,
      ),
      child: Row(
        children: const [
          SkeletonBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(width: 18),
          SkeletonBox(height: 20, width: 110),
        ],
      ),
    );
  }
}

class _TaglineSkeleton extends StatelessWidget {
  const _TaglineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CategoryScreenSkeleton._pagePadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                height: 24,
                width: constraints.maxWidth * 0.74,
                baseColor: const Color(0xFFFFD7E4),
                highlightColor: const Color(0xFFFFEFF5),
              ),
              const SizedBox(height: 12),
              SkeletonBox(
                height: 24,
                width: constraints.maxWidth * 0.58,
                baseColor: const Color(0xFFFFD7E4),
                highlightColor: const Color(0xFFFFEFF5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBannerSkeleton extends StatelessWidget {
  const _HeroBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CategoryScreenSkeleton._pagePadding,
      ),
      child: Stack(
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3E4E8),
                  Color(0xFFD4D6DC),
                  Color(0xFFB9BCC5),
                ],
              ),
            ),
            child: const SkeletonBox(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              baseColor: Color(0x0FFFFFFF),
              highlightColor: Color(0x22FFFFFF),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      SkeletonBox(
                        height: 20,
                        width: constraints.maxWidth * 0.52,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 10),
                      SkeletonBox(
                        height: 14,
                        width: constraints.maxWidth * 0.74,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        height: 14,
                        width: constraints.maxWidth * 0.56,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsSkeleton extends StatelessWidget {
  const _DotsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            6,
            (index) => Container(
              width: index == 1 ? 9 : 8,
              height: index == 1 ? 9 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == 1
                    ? const Color(0xFFF75A95)
                    : const Color(0xFFD7D7DC),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CategoryScreenSkeleton._pagePadding,
      ),
      child: const SkeletonBox(
        height: 22,
        width: 196,
        baseColor: Color(0xFFE9ECF1),
        highlightColor: Color(0xFFF7F9FC),
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  final int count;

  const _CategoryGridSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CategoryScreenSkeleton._pagePadding,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 18,
          childAspectRatio: 1.06,
        ),
        itemBuilder: (context, index) => const _CategoryTileSkeleton(),
      ),
    );
  }
}

class _CategoryTileSkeleton extends StatelessWidget {
  const _CategoryTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      baseColor: const Color(0xFFFFEEF2),
      highlightColor: const Color(0xFFFFF8FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SkeletonBox(
                width: 28,
                height: 28,
                shape: BoxShape.circle,
                baseColor: Color(0xFFFDE1EA),
                highlightColor: Color(0xFFFFF2F6),
              ),
              SizedBox(height: 14),
              SkeletonBox(
                height: 14,
                width: 98,
                baseColor: Color(0xFFF3F4F7),
                highlightColor: Color(0xFFFCFCFD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramBannerSkeleton extends StatelessWidget {
  const _InstagramBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CategoryScreenSkeleton._pagePadding,
      ),
      child: SkeletonBox(
        padding: const EdgeInsets.fromLTRB(24, 24, 18, 24),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        baseColor: const Color(0xFFEBDCF6),
        highlightColor: const Color(0xFFF8F1FC),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(
                    height: 22,
                    width: 182,
                    baseColor: Color(0xFFF7F1FB),
                    highlightColor: Color(0xFFFFFFFF),
                  ),
                  SizedBox(height: 12),
                  SkeletonBox(
                    height: 14,
                    width: 138,
                    baseColor: Color(0xFFF7F1FB),
                    highlightColor: Color(0xFFFFFFFF),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const SkeletonBox(
              width: 86,
              height: 38,
              borderRadius: BorderRadius.all(Radius.circular(24)),
              baseColor: Color(0xFFF8F2FC),
              highlightColor: Color(0xFFFFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselCardsSkeleton extends StatelessWidget {
  final int count;

  const _CarouselCardsSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 198,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: CategoryScreenSkeleton._pagePadding,
        ),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => const _CarouselCardSkeleton(),
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemCount: count,
      ),
    );
  }
}

class _CarouselCardSkeleton extends StatelessWidget {
  const _CarouselCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          SizedBox(height: 12),
          SkeletonBox(height: 16, width: 126),
          SizedBox(height: 8),
          SkeletonBox(height: 12, width: 88),
          SizedBox(height: 10),
          SkeletonBox(height: 16, width: 64),
        ],
      ),
    );
  }
}
