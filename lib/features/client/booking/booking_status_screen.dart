import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class BookingStatusScreen extends StatelessWidget {
  const BookingStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Status'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildStatusHeader(context),
            const SizedBox(height: 48),
            _buildTimeline(),
            const SizedBox(height: 48),
            _buildProfessionalInfo(context),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Track Professional',
              onPressed: () => context.push('/client/live-tracking/BOOKING123'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/client/home'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
        ),
        const SizedBox(height: 16),
        const Text(
          'Booking Confirmed!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your beautician will arrive at 10:30 AM',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _TimelineItem(title: 'Requested', time: '10:00 AM', isCompleted: true, isFirst: true),
        _TimelineItem(title: 'Accepted', time: '10:05 AM', isCompleted: true),
        _TimelineItem(title: 'On the way', time: '--:--', isActive: true),
        _TimelineItem(title: 'Started', time: '--:--'),
        _TimelineItem(title: 'Completed', time: '--:--', isLast: true),
      ],
    );
  }

  Widget _buildProfessionalInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200'),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elena Smith', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Pro Beautician • 4.9 ★', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_rounded, color: AppTheme.primaryColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isCompleted;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.time,
    this.isCompleted = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : (isActive ? AppTheme.primaryColor : Colors.grey.shade300),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 4) : null,
              ),
              child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive || isCompleted ? AppTheme.accentColor : Colors.grey,
                ),
              ),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}
