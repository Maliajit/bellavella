import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/core/widgets/base_widgets.dart';

class UserReviewScreen extends StatefulWidget {
  final String bookingId;
  final String endpoint;
  final String title;
  final String subtitle;
  final String subjectName;
  final String successMessage;

  const UserReviewScreen({
    super.key,
    required this.bookingId,
    required this.endpoint,
    required this.title,
    required this.subtitle,
    required this.subjectName,
    required this.successMessage,
  });

  @override
  State<UserReviewScreen> createState() => _UserReviewScreenState();
}

class _UserReviewScreenState extends State<UserReviewScreen> {
  final _commentController = TextEditingController();
  final _picker = ImagePicker();

  int _rating = 0;
  XFile? _videoFile;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );

    if (video == null) return;

    setState(() => _videoFile = video);
    await _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    if (_videoFile == null) return;

    if (kIsWeb) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_videoFile!.path),
      );
    } else {
      _videoPlayerController = VideoPlayerController.file(File(_videoFile!.path));
    }

    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
    );

    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ToastUtil.showError(context, 'Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);

    final Map<String, dynamic> response;
    if (_videoFile != null) {
      response = await ApiService.multipart(
        widget.endpoint,
        {
          'booking_id': widget.bookingId,
          'rating': _rating.toString(),
          'comment': _commentController.text.trim(),
        },
        {
          'video': _videoFile!,
        },
      );
    } else {
      response = await ApiService.post(
        widget.endpoint,
        {
          'booking_id': widget.bookingId,
          'rating': _rating,
          'comment': _commentController.text.trim(),
        },
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response['success'] != true) {
      ToastUtil.showError(
        context,
        response['message']?.toString() ?? 'Unable to submit review.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              'Review Submitted!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.successMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Done',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.rate_review_outlined,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'How was your experience?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < _rating ? Colors.orange : Colors.grey.shade400,
                    size: 48,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'Write a review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Video Review (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Attach a short video if you want richer feedback.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_videoFile == null)
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Video Review',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: _chewieController != null &&
                            _chewieController!.videoPlayerController.value.isInitialized
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Chewie(controller: _chewieController!),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change Video'),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            _isSubmitting
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : PrimaryButton(
                    label: 'Submit Review',
                    onPressed: _submit,
                  ),
          ],
        ),
      ),
    );
  }
}
