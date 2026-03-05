import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalNotificationsScreen extends StatefulWidget {
  const ProfessionalNotificationsScreen({super.key});

  @override
  State<ProfessionalNotificationsScreen> createState() => _ProfessionalNotificationsScreenState();
}

class _ProfessionalNotificationsScreenState extends State<ProfessionalNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notifications = await ProfessionalApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      final res = await ProfessionalApiService.markAllNotificationsRead();
      if (res['success'] == true) {
        _fetchNotifications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              "Mark all read",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchNotifications, child: const Text('Retry')),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return _buildNotificationItem(
                            icon: _getIconForType(n['type']),
                            iconColor: _getColorForType(n['type']),
                            title: n['title'] ?? 'Notification',
                            description: n['message'] ?? '',
                            time: n['created_at'] ?? '',
                            isUnread: n['read_at'] == null,
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'payment': return Icons.payments_outlined;
      case 'booking': return Icons.calendar_month_outlined;
      case 'system': return Icons.verified_user_outlined;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'payment': return Colors.green.shade600;
      case 'booking': return Colors.blue.shade600;
      case 'system': return Colors.orange.shade600;
      default: return AppTheme.primaryColor;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
