import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

class ServiceGroupDetailSkeleton extends StatelessWidget {
  static const double _pagePadding = 16;

  final int serviceTypeCount;

  const ServiceGroupDetailSkeleton({
    super.key,
    this.serviceTypeCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedCount = serviceTypeCount < 1 ? 5 : serviceTypeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 18, width: 92),
            SizedBox(height: 6),
            SkeletonBox(height: 12, width: 110),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroSkeleton(),
                const SizedBox(height: 16),
                const _DotsSkeleton(),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: _pagePadding),
                  child: SkeletonBox(height: 20, width: 188),
                ),
                const SizedBox(height: 18),
                _ServiceTypeGridSkeleton(count: normalizedCount),
                const SizedBox(height: 28),
                const _PromoBannerSkeleton(),
                const SizedBox(height: 26),
              ],
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _ViewCartSkeleton(),
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
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFCACED7),
                    Color(0xFFB8BEC8),
                    Color(0xFFA2AAB6),
                  ],
                ),
              ),
              child: const SkeletonBox(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                baseColor: Color(0x00FFFFFF),
                highlightColor: Color(0x1FFFFFFF),
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
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
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
            width: index == 1 ? 18 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == 1
                  ? const Color(0xFFF75A95)
                  : const Color(0xFFD8DADF),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceTypeGridSkeleton extends StatelessWidget {
  final int count;

  const _ServiceTypeGridSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) => const _ServiceTypeTileSkeleton(),
      ),
    );
  }
}

class _ServiceTypeTileSkeleton extends StatelessWidget {
  const _ServiceTypeTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonBox(
          width: 65,
          height: 65,
          borderRadius: BorderRadius.all(Radius.circular(15)),
          baseColor: Color(0xFFFFF1F4),
          highlightColor: Color(0xFFFFF8FA),
        ),
        SizedBox(height: 10),
        SkeletonBox(height: 10, width: 54),
        SizedBox(height: 6),
        SkeletonBox(height: 10, width: 42),
      ],
    );
  }
}

class _PromoBannerSkeleton extends StatelessWidget {
  const _PromoBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const SkeletonBox(
        width: double.infinity,
        height: 148,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        baseColor: Color(0xFFF0F2F6),
        highlightColor: Color(0xFFF8FAFC),
      ),
    );
  }
}

class _ViewCartSkeleton extends StatelessWidget {
  const _ViewCartSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      height: 55,
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      baseColor: Color(0xFFFF5A8E),
      highlightColor: Color(0xFFFF78A3),
    );
  }
}
