import 'package:flutter/material.dart';
import '../models/story_model.dart';
import 'video_story_card.dart';

class HomeStorySection extends StatelessWidget {
  final List<Story> stories;
  final String title;
  final String subtitle;

  const HomeStorySection({
    super.key,
    required this.stories,
    this.title = '',
    this.subtitle = 'Real lives, real impact',
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              return VideoStoryCard(
                story: stories[index],
                totalStories: stories,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}
