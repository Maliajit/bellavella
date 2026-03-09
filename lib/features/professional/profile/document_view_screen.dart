import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class DocumentViewScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final File? localFile;

  const DocumentViewScreen({
    super.key, 
    required this.title, 
    required this.imageUrl, 
    this.localFile
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("DocumentViewScreen: Opening with URL: $imageUrl");
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (localFile != null && !kIsWeb) {
      return Image.file(localFile!, fit: BoxFit.contain);
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Failed to load image",
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}
