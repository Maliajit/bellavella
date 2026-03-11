import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/permission_handler_util.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import './widgets/availability_toggle.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';
import './widgets/booking_request_dialog.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Real Data State
  pro_models.ProfessionalDashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = false; // Default: Offline until requirements met
  bool _hasActiveJob = false;
  int _kitCount = 0;
  double _walletCash = 0;
  Timer? _heartbeatTimer;
  String? _lastNotificationId;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchDashboardData();
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiController.play();
      PermissionHandlerUtil.requestAllPermissions(context);
    });
  }

  Future<void> _fetchDashboardData({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final stats = await ProfessionalApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
          // A job is "active" if it's assigned to me and not completed/cancelled
          _hasActiveJob = stats.recentBookings.any((b) => 
            b.status == BookingStatus.accepted || 
            b.status == BookingStatus.onTheWay || 
            b.status == BookingStatus.arrived || 
            b.status == BookingStatus.started
          );
          _kitCount = stats.kitCount;
          _walletCash = stats.walletBalance; 
          // _isOnline = stats.isOnline; // Removed as per your previous requirement for manual toggle
        });
        
        // Check for new notifications
        _checkNewNotifications();
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      if (mounted && !isSilent) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkNewNotifications() async {
    if (!_isOnline) return; // Only show alerts if professional is online

    try {
      final notifications = await ProfessionalApiService.getNotifications();
// ... (rest of the existing logic remains inside)
      if (notifications.isNotEmpty && mounted) {
        final latest = notifications.first;
        final String currentId = latest['id'].toString();
        final bool isUnread = latest['read_at'] == null;
        
        // Trigger if it's an assignment AND unread
        if (latest['type'] == 'booking_assigned' && isUnread) {
          // Mark as read immediately to prevent duplicate triggers
          await ProfessionalApiService.markNotificationAsRead(currentId);
          
          // Navigate to the full-screen interactive request screen
          if (mounted) {
            final result = await context.pushNamed(
              AppRoutes.proIncomingRequestName,
              extra: latest['data'] ?? latest, // Use 'data' if nested, else the whole map
            );
            
            // If the user accepted (returned true), refresh the dashboard
            if (result == true) {
              _fetchDashboardData(isSilent: true);
              _confettiController.play();
            }
          }
        }
        
        _lastNotificationId = currentId;
      }
    } catch (e) {
      debugPrint('[Notifications] Fetch error: $e');
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    // Going online requires ₹1500 wallet balance
    if (value && _walletCash < 1500) {
      _showRequirementsError();
      return;
    }

    final previousState = _isOnline;
    setState(() => _isOnline = value); // Optimistic Update

    try {
      final res = await ProfessionalApiService.toggleAvailability(value);
      if (res['success'] == true) {
        if (value) _checkNewNotifications(); // Immediate check when going online
      } else {
        // Rollback on server failure
        if (mounted) {
          setState(() => _isOnline = previousState);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to update status')),
          );
        }
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() => _isOnline = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startHeartbeat();
    } else {
      _heartbeatTimer?.cancel();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      // Periodic heartbeat + data refresh
      ProfessionalApiService.updateOnlineStatus();
      _fetchDashboardData(isSilent: true);
    });
    // Initial heartbeat
    ProfessionalApiService.updateOnlineStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSmartHeader(),
            _buildStatusFeedback(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDashboardData,
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildPrimaryFocusPanel(),
                      const SizedBox(height: 20),
                      _buildReferralBanner(),
                      const SizedBox(height: 32),
                      _buildTodayOverviewStrip(),
                      const SizedBox(height: 32),
                      _buildScheduleTimeline(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1️⃣ Smart Compact Header
  Widget _buildSmartHeader() {
    return Consumer<ProfessionalProfileController>(
      builder: (context, profileController, child) {
        final profile = profileController.profile;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Name stack
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${profile?.name ?? 'Professional'}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isOnline ? 'Available for bookings' : 'Currently Offline',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isOnline ? Colors.green.shade600 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side: Toggle & Notification
              Row(
                children: [
                  AvailabilityToggle(
                    isOnline: _isOnline,
                    onChanged: (value) => _toggleAvailability(value),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => context.pushNamed(AppRoutes.proNotificationsName),
                    icon: const Icon(Icons.notifications_none_rounded, size: 24, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Micro-UX Status Feedback
  Widget _buildStatusFeedback() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<bool>(_isOnline),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: _isOnline 
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    "You’re now visible to customers.",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "You will not receive new bookings while offline.",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // 2️⃣ Primary Focus Panel (Adaptive)
  Widget _buildPrimaryFocusPanel() {
    final bool showActiveCard = _hasActiveJob && _isOnline;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: showActiveCard ? AppTheme.primaryColor : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(28),
          boxShadow: showActiveCard
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: showActiveCard ? _buildJobActiveContent() : _buildNoJobContent(),
      ),
    );
  }

  Widget _buildNoJobContent() {
    return Column(
      children: [
        Icon(
          _isOnline ? Icons.radar_rounded : Icons.power_settings_new_rounded, 
          size: 48, 
          color: _isOnline ? AppTheme.primaryColor : Colors.grey
        ),
        const SizedBox(height: 16),
        Text(
          _isOnline ? "You're Online" : "You're Offline",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Waiting for new bookings",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildJobActiveContent() {
    // Find the most relevant active job
    if (_stats == null || _stats!.recentBookings.isEmpty) {
      return const SizedBox.shrink(); // No jobs to show in the active card
    }

    final activeJob = _stats?.recentBookings.firstWhere(
      (b) => b.status == BookingStatus.started || 
             b.status == BookingStatus.arrived || 
             b.status == BookingStatus.onTheWay || 
             b.status == BookingStatus.accepted,
      orElse: () => _stats!.recentBookings.first
    );

    String buttonText = "Start Job";
    VoidCallback onPressed = () => context.pushNamed(AppRoutes.proArriveName);

    switch (activeJob?.status) {
      case BookingStatus.accepted:
        buttonText = "Start Journey";
        onPressed = () => context.pushNamed(AppRoutes.proNavigationName, extra: activeJob);
        break;
      case BookingStatus.onTheWay:
        buttonText = "I Have Arrived";
        onPressed = () => context.pushNamed(AppRoutes.proArriveName, extra: activeJob);
        break;
      case BookingStatus.arrived:
        buttonText = "Start Job";
        onPressed = () => context.pushNamed(AppRoutes.proActiveJobName, extra: activeJob);
        break;
      case BookingStatus.started:
        buttonText = "Continue Job";
        onPressed = () => context.pushNamed(AppRoutes.proActiveJobName, extra: activeJob);
        break;
      default:
        buttonText = "View Details";
        onPressed = () => context.pushNamed(AppRoutes.proBookingDetailName, pathParameters: {'id': activeJob?.id ?? ''});
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activeJob?.time ?? 'Asap',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.more_horiz_rounded, color: Colors.white70),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          activeJob?.clientName ?? 'Customer',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activeJob?.serviceName ?? 'Service',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activeJob?.address ?? 'Location not set',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _panelAction(Icons.phone_rounded, "Call", Colors.green),
            const SizedBox(width: 12),
            _panelAction(Icons.near_me_rounded, "Navigate", Colors.blue, onTap: () => context.pushNamed(AppRoutes.proNavigationName)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              buttonText,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, 
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3️⃣ Today Overview Strip
  Widget _buildTodayOverviewStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _overviewItem("RATING", "⭐ ${_stats?.rating ?? 4.5}"),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 24, width: 1, color: Colors.grey.shade100);
  }

  // 4️⃣ Today Schedule (Timeline View)
  Widget _buildScheduleTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today Schedule',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.proOrders),
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _stats?.recentBookings.length ?? 0,
          itemBuilder: (context, index) {
            final booking = _stats!.recentBookings[index];
            bool isLast = index == (_stats?.recentBookings.length ?? 0) - 1;
            bool isDone = booking.status == BookingStatus.completed;

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                           color: isDone ? Colors.green : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.time,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDone ? Colors.grey : AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                booking.serviceName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDone ? Colors.grey : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDone ? Colors.grey : AppTheme.primaryColor).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.status.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isDone ? Colors.grey : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }


  void _showRequirementsError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D6F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF2D6F), size: 30),
              ),
              const SizedBox(height: 16),
              Text('Go Online Requirement',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  TextSpan(
                    text: 'You need at least ',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
                  ),
                  TextSpan(
                    text: '₹1500',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFFF2D6F)),
                  ),
                  TextSpan(
                    text: ' wallet balance to go online.\nCurrent balance: ',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
                  ),
                  TextSpan(
                    text: '₹${_walletCash.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800,
                      color: _walletCash > 0 ? const Color(0xFF111827) : const Color(0xFFEF4444)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Color(0xFFF97316), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Purchase a kit to get started and activate your professional account.',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF9A3412), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(AppRoutes.proKitStore);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D6F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Buy Kit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildReferralBanner() {
    return GestureDetector(
      onTap: () => context.pushNamed(AppRoutes.proReferEarnName),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF85A1), AppTheme.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite & Earn Rewards',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Earn credits for every successful referral',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
