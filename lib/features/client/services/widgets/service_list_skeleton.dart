import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

class ServiceListSkeleton extends StatelessWidget {
  final bool showTypeGrid;
  final int itemCount;
  final bool showOfferCard;

  const ServiceListSkeleton({
    super.key,
    this.showTypeGrid = true,
    this.itemCount = 4,
    this.showOfferCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonBox(
              height: 200,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          if (showTypeGrid) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(height: 16, width: 168),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) => const Column(
                      children: [
                        SkeletonBox(
                          width: 65,
                          height: 65,
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        SizedBox(height: 8),
                        SkeletonBox(height: 10, width: 52),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
          if (showOfferCard) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(
                height: 110,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            const SizedBox(height: 30),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(height: 52, borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          const SizedBox(height: 10),
          ...List.generate(itemCount, (_) => const _ServiceCardSkeleton()),
        ],
      ),
    );
  }
}

class _ServiceCardSkeleton extends StatelessWidget {
  const _ServiceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SkeletonBox(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        padding: EdgeInsets.fromLTRB(14, 14, 14, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 18, width: 160),
                    SizedBox(height: 10),
                    SkeletonBox(height: 14, width: 110),
                    SizedBox(height: 10),
                    SkeletonBox(height: 14, width: 130),
                    SizedBox(height: 12),
                    SkeletonBox(height: 12, width: double.infinity),
                    SizedBox(height: 6),
                    SkeletonBox(height: 12, width: 170),
                    SizedBox(height: 14),
                    SkeletonBox(height: 14, width: 96),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                SkeletonBox(
                  width: 128,
                  height: 128,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                SizedBox(height: 12),
                SkeletonBox(
                  width: 100,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
