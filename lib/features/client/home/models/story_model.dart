import 'package:bellavella/core/utils/media_url.dart';

class Story {
  final String videoUrl;
  final String? title;
  final String? serviceCategory;
  final String? thumbnail;

  Story({
    required this.videoUrl,
    this.title,
    this.serviceCategory,
    this.thumbnail,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      videoUrl: resolveMediaUrl(
        json['url']?.toString() ??
            json['video_url']?.toString() ??
            json['media_url']?.toString() ??
            json['media_path']?.toString(),
      ),
      title: json['title']?.toString(),
      serviceCategory: json['subtitle']?.toString(),
      thumbnail: resolveNullableMediaUrl(
        json['thumbnail']?.toString() ??
            json['thumbnail_url']?.toString() ??
            json['preview_image']?.toString() ??
            json['poster']?.toString(),
      ),
    );
  }
}
