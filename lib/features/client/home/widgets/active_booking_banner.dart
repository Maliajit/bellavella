import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ActiveBookingBanner extends StatelessWidget {
  final String status;
  final String professionalName;
  final String distance;
  final String eta;
  final String imageUrl;
  final double progress;

  const ActiveBookingBanner({
    super.key,
    this.status = 'Live Tracker 📍',
    this.professionalName = 'Elena',
    this.distance = '1.2km away',
    this.eta = '4 min',
    this.imageUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200',
    this.progress = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/client/booking-status'),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      backgroundColor: const Color(0xFFFCE4EC),
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey.shade200,
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
                      '$professionalName is $distance',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  eta,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
