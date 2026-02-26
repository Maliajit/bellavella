import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class ServiceReviewScreen extends StatefulWidget {
  final String bookingId;
  const ServiceReviewScreen({super.key, required this.bookingId});

  @override
  State<ServiceReviewScreen> createState() => _ServiceReviewScreenState();
}

class _ServiceReviewScreenState extends State<ServiceReviewScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );

    if (video != null) {
      setState(() {
        _videoFile = video;
      });
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = VideoPlayerController.file(File(_videoFile!.path));
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
    );
    setState(() {});
  }

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);
      
      final bool earnedPoints = _videoFile != null;
      
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
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                earnedPoints 
                  ? 'Congratulations! 50 Bellavella points have been credited to your account for the video review.' 
                  : 'Thank you for your feedback! Your review helps us improve our services.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Back to Bookings',
                  onPressed: () {
                    context.go('/client/my-bookings');
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Rate & Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceInfo(),
            const SizedBox(height: 32),
            _buildRatingSection(),
            const SizedBox(height: 32),
            _buildTextReviewSection(),
            const SizedBox(height: 32),
            _buildVideoReviewSection(),
            const SizedBox(height: 48),
            _isSubmitting 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : PrimaryButton(label: 'Submit Review', onPressed: _submitReview),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Container(
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
            child: const Icon(Icons.spa_outlined, color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking #${widget.bookingId.substring(0, 8).toUpperCase()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('Korean Glass skin facial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Center(child: Text('How was your experience?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => setState(() => _rating = index + 1),
              icon: Icon(
                index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: index < _rating ? Colors.orange : Colors.grey.shade400,
                size: 48,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Write a review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your thoughts about the service...',
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
      ],
    );
  }

  Widget _buildVideoReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text('Video Review (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: Colors.orange.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: const Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(Icons.stars, color: Colors.orange, size: 14),
                   SizedBox(width: 4),
                   Text(' Earn 50 Points', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Add a short video review to earn redeemable points!', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_outlined, color: AppTheme.primaryColor.withValues(alpha: 0.5), size: 32),
                  const SizedBox(height: 8),
                  const Text('Upload Video Review', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
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
                child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
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
      ],
    );
  }
}
