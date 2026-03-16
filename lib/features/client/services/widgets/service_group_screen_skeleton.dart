import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

class ServiceGroupScreenSkeleton extends StatelessWidget {
  static const double _pagePadding = 16;

  final int itemCount;

  const ServiceGroupScreenSkeleton({
    super.key,
    this.itemCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedItemCount = itemCount < 1 ? 2 : itemCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AppBarSkeleton(),
          const SizedBox(height: 18),
          const _HeroBannerSkeleton(),
          const SizedBox(height: 14),
          const _DotsSkeleton(),
          const SizedBox(height: 28),
          const _SectionHeadingSkeleton(),
          const SizedBox(height: 22),
          ...List.generate(
            normalizedItemCount,
            (index) => const _ServiceGroupCardSkeleton(),
          ),
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
        ServiceGroupScreenSkeleton._pagePadding,
        14,
        ServiceGroupScreenSkeleton._pagePadding,
        0,
      ),
      child: Row(
        children: const [
          SkeletonBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(width: 16),
          SkeletonBox(height: 22, width: 172),
        ],
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
        horizontal: ServiceGroupScreenSkeleton._pagePadding,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 176,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 176,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD3D7DE),
                    Color(0xFFBFC5CE),
                    Color(0xFFA9B0BC),
                  ],
                ),
              ),
              child: const SkeletonBox(
                borderRadius: BorderRadius.all(Radius.circular(22)),
                baseColor: Color(0x00FFFFFF),
                highlightColor: Color(0x22FFFFFF),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.24),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        height: 24,
                        width: constraints.maxWidth * 0.5,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 10),
                      SkeletonBox(
                        height: 14,
                        width: constraints.maxWidth * 0.72,
                        baseColor: const Color(0x40FFFFFF),
                        highlightColor: const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        height: 14,
                        width: constraints.maxWidth * 0.44,
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

class _DotsSkeleton extends StatelessWidget {
  const _DotsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (index) => Container(
            width: index == 0 ? 18 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == 0
                  ? const Color(0xFFF75A95)
                  : const Color(0xFFD5D7DC),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeadingSkeleton extends StatelessWidget {
  const _SectionHeadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ServiceGroupScreenSkeleton._pagePadding,
      ),
      child: SkeletonBox(height: 22, width: 210),
    );
  }
}

class _ServiceGroupCardSkeleton extends StatelessWidget {
  const _ServiceGroupCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ServiceGroupScreenSkeleton._pagePadding,
        0,
        ServiceGroupScreenSkeleton._pagePadding,
        16,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F0F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(
              width: 72,
              height: 72,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              baseColor: Color(0xFFF8EAF0),
              highlightColor: Color(0xFFFFF8FA),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(
                    height: 22,
                    width: 126,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    baseColor: Color(0xFFFFE4EC),
                    highlightColor: Color(0xFFFFF2F6),
                  ),
                  SizedBox(height: 12),
                  SkeletonBox(height: 20, width: 86),
                  SizedBox(height: 10),
                  SkeletonBox(height: 14, width: 188),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14, width: 156),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(top: 26),
              child: SkeletonBox(
                width: 18,
                height: 18,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
