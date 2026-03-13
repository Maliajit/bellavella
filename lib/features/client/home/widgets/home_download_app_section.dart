import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class HomeDownloadAppSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<dynamic> items;
  final String? btnText;
  final String? btnLink;

  const HomeDownloadAppSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.btnText,
    this.btnLink,
  });

  @override
  Widget build(BuildContext context) {
    // If there's an image in items, use it as background
    String? backgroundImage;
    if (items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>;
      backgroundImage = firstItem['image'] ?? firstItem['url'] ?? '';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image if available
          if (backgroundImage != null && backgroundImage.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  backgroundImage,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.2),
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  )
                else
                  Text(
                    'Get the mobile app and enjoy seamless experience on the go',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 24),
                // Download buttons
                Row(
                  children: [
                    // iOS button
                    Expanded(
                      child: _buildStoreButton(
                        icon: Icons.language,
                        label: 'App Store',
                        onTap: () {
                          // TODO: Implement app store link
                          ToastUtil.showSuccess(
                            context,
                            'App Store link would open here',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Google Play button
                    Expanded(
                      child: _buildStoreButton(
                        icon: Icons.download_for_offline,
                        label: 'Play Store',
                        onTap: () {
                          // TODO: Implement play store link
                          ToastUtil.showSuccess(
                            context,
                            'Play Store link would open here',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
