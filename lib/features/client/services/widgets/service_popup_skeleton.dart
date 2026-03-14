import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

class ServicePopupSkeleton extends StatelessWidget {
  final bool showBanner;
  final bool showVariantCarousel;

  const ServicePopupSkeleton({
    super.key,
    this.showBanner = true,
    this.showVariantCarousel = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, 0, 0, 28 + safeBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 22, width: 180),
                        SizedBox(height: 8),
                        SkeletonBox(height: 14, width: 240),
                        SizedBox(height: 6),
                        SkeletonBox(height: 14, width: 200),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  SkeletonBox(width: 36, height: 36, shape: BoxShape.circle),
                ],
              ),
            ),
            if (showBanner) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SkeletonBox(
                  height: 188,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SkeletonBox(height: 18, width: 132),
            ),
            const SizedBox(height: 14),
            if (showVariantCarousel)
              SizedBox(
                height: 356,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => const _VariantCardSkeleton(),
                ),
              )
            else
              Column(
                children: List.generate(
                  2,
                  (_) => const _SelectionCardSkeleton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VariantCardSkeleton extends StatelessWidget {
  const _VariantCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 224,
      child: SkeletonBox(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              height: 210,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(height: 14),
            SkeletonBox(height: 18, width: 124),
            SizedBox(height: 10),
            SkeletonBox(height: 13, width: 92),
            SizedBox(height: 10),
            SkeletonBox(height: 18, width: 64),
            SizedBox(height: 14),
            SkeletonBox(
              height: 40,
              width: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCardSkeleton extends StatelessWidget {
  const _SelectionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SkeletonBox(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 17, width: 140),
                  SizedBox(height: 8),
                  SkeletonBox(height: 13, width: 112),
                  SizedBox(height: 12),
                  SkeletonBox(height: 18, width: 72),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(
              width: 100,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}
