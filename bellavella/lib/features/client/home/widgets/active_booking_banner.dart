import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ActiveBookingBanner extends StatelessWidget {
  final String bookingId;
  final String status;
  final String professionalName;
  final String imageUrl;
  final double progress;

  const ActiveBookingBanner({
    super.key,
    required this.bookingId,
    this.status = 'View Status',
    this.professionalName = 'Assigned professional',
    this.imageUrl = '',
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/client/booking-status/$bookingId'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 55,
                    height: 55,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      backgroundColor: const Color(0xFFFCE4EC),
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    backgroundColor: Colors.grey.shade200,
                    child: imageUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      professionalName,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
