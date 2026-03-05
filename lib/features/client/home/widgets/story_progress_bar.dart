import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentIndex;
  final double currentProgress;

  const StoryProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentIndex,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Row(
        children: List.generate(totalSegments, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: index == currentIndex
                      ? currentProgress
                      : (index < currentIndex ? 1.0 : 0.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                  minHeight: 3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
