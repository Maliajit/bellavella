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
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import './widgets/booking_request_dialog.dart';
import './widgets/job_card.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/services/realtime_job_service.dart';

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
  bool _hasActiveJob = false;
  int _kitCount = 0;
  double _walletCash = 0;
  String? _lastNotificationId;
  Timer? _pollingTimer;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Load active job immediately (fast, dedicated endpoint)
    // This runs in parallel with _fetchDashboardData so the job card
    // appears even before the full dashboard stats load completes.
    _loadActiveJob();
    _fetchDashboardData();
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiController.play();
    PermissionHandlerUtil.requestAllPermissions(context);
    });

    // Start Polling Fallback
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkIncomingRequests();
    });

    final profileController = context.read<ProfessionalProfileController>();
    debugPrint("🆔 Dashboard Init: Professional ID = ${profileController.profile?.id}, isOnline = ${profileController.isOnline}");

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  /// Immediately hydrates DashboardController from the server.
  Future<void> _loadActiveJob() async {
    try {
      final job = await ProfessionalApiService.getActiveJob();
      if (mounted) {
        if (job != null) {
          context.read<DashboardController>().setActiveJob(job);
        } else {
          context.read<DashboardController>().clearJob();
          // Reset real-time listener cache so new requests can be detected
          RealtimeJobService.shownBookings.clear();
          debugPrint('✅ Dashboard: No active job found. Cleared controller and shownBookings cache.');
        }
      }
    } catch (e) {
      if (mounted) {
        context.read<DashboardController>().clearJob();
      }
    }
  }

  Future<void> _fetchDashboardData({bool isSilent = true}) async {
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
          // A job is "active" if it's accepted or in progress (not assigned/completed/cancelled)
          _hasActiveJob = stats.recentBookings.any((b) =>
            b.status == BookingStatus.accepted ||
            b.status == BookingStatus.onTheWay ||
            b.status == BookingStatus.arrived ||
            b.status == BookingStatus.scanKit ||
            b.status == BookingStatus.inProgress ||
            b.status == BookingStatus.paymentPending
          );
          
          _kitCount = stats.kitCount;
          _walletCash = stats.walletBalance; 
        });

        // Seed the DashboardController on app start / re-open so the
        // Job Card appears immediately without waiting for stats API.
        final activeInStats = stats.recentBookings.firstWhere(
          (b) => b.status == BookingStatus.accepted || 
                 b.status == BookingStatus.onTheWay || 
                 b.status == BookingStatus.arrived ||
                 b.status == BookingStatus.scanKit ||
                 b.status == BookingStatus.inProgress ||
                 b.status == BookingStatus.paymentPending,
          orElse: () => pro_models.ProfessionalBooking.empty(),
        );

        if (activeInStats.id.isNotEmpty) {
          context.read<DashboardController>().setActiveJob(activeInStats);
        } else {
          context.read<DashboardController>().clearJob();
        }
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

  Future<void> _checkIncomingRequests() async {
    // Only check if professional is online
    final isOnline = context.read<ProfessionalProfileController>().isOnline;
    if (!isOnline) {
       // debugPrint('⏸ Polling skipped: Professional is OFFLINE');
       return;
    }

    try {
      // debugPrint('🔍 Polling: Checking for incoming requests...');
      final bookings = await ProfessionalApiService.getBookingRequests();
      
      if (bookings.isNotEmpty) {
        debugPrint('🔍 Polling: Found ${bookings.length} requests in API');
      }

      for (var booking in bookings) {
        debugPrint('🔍 Polling: Checking booking ${booking.id} with status ${booking.status}');
        // "assigned" means admin dispatched it but professional hasn't accepted yet
        if (booking.status == BookingStatus.assigned) {
          if (!RealtimeJobService.shownBookings.contains(booking.id)) {
            debugPrint('🔔 Polling: New assignment found! ${booking.id}');
            
            // Map model to the generic JSON map IncomingRequestScreen expects
            final data = {
              'booking_id': booking.id,
              'client_name': booking.clientName,
              'service': booking.serviceName,
              'location': booking.address,
              'price': booking.totalPrice,
              'status': 'pending',
            };

            if (mounted) {
              RealtimeJobService.shownBookings.add(booking.id.toString());
              context.pushNamed(
                AppRoutes.proIncomingRequestName,
                extra: data,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🔔 Polling error: $e');
    }
  }

  // Notification checking logic removed in favor of FirebaseMessagingService

  Future<void> _toggleAvailability(bool value) async {
    // Going online requires ₹1500 wallet balance
    if (value && _walletCash < 1500) {
      _showRequirementsError("Minimum ₹1500 wallet balance required to go online.");
      return;
    }
    // Going online requires at least 5 kits
    if (value && _kitCount < 5) {
      _showRequirementsError("Minimum 5 kits required to go online.");
      return;
    }
    await context.read<ProfessionalProfileController>().toggleAvailability(value);
    if (value && mounted) {
      _fetchDashboardData(isSilent: true);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _radarController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _startHeartbeat();
      _loadActiveJob(); // re-check active job when app returns to foreground
    }
  }

  bool get _isOnline => mounted ? context.watch<ProfessionalProfileController>().isOnline : false;

  void _startHeartbeat() {
    // Heartbeat logic now moved to ProfessionalProfileController
    _fetchDashboardData(isSilent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
                      profileController.isOnline ? 'Available for bookings' : 'Currently Offline',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: profileController.isOnline ? Colors.green.shade600 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side: Toggle & Notification
              Row(
                children: [
                  AvailabilityToggle(
                    isOnline: profileController.isOnline,
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

  Widget _buildStatusFeedback() {
    if (!_isOnline) return const SizedBox.shrink();

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
                color: Colors.green.withOpacity(0.05),
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
                color: Colors.grey.withOpacity(0.05),
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

  // 2⃣ Primary Focus Panel — reactive to DashboardController
  Widget _buildPrimaryFocusPanel() {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final activeJob = controller.activeJob;
        // Strictly only show card for statuses that are truly in-progress (not assigned/completed/cancelled)
        final bool showActiveCard = activeJob != null && (
          activeJob.status == BookingStatus.accepted ||
          activeJob.status == BookingStatus.onTheWay ||
          activeJob.status == BookingStatus.arrived ||
          activeJob.status == BookingStatus.scanKit ||
          activeJob.status == BookingStatus.inProgress ||
          activeJob.status == BookingStatus.paymentPending
        );

        return AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuart,
          child: showActiveCard
              ? _buildJobActiveCard(activeJob)
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildNoJobContent(),
                ),
        );
      },
    );
  }

  Widget _buildNoJobContent() {
    return Column(
      children: [
        // Radar/Ripple Animation Area
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isOnline) ...[
                // Outer Ripple
                _rippleCircle(size: 100, delay: 0),
                _rippleCircle(size: 140, delay: 0.5),
                _rippleCircle(size: 180, delay: 1.0),
              ],
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isOnline ? AppTheme.primaryColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isOnline)
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  _isOnline ? Icons.radar_rounded : Icons.power_settings_new_rounded,
                  size: 32,
                  color: _isOnline ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isOnline ? "Waiting for Bookings" : "You're Offline",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _isOnline 
              ? "Your radar is active. We'll notify you as soon as a new request matches your profile."
              : "Turn on your availability to start receiving job requests and earning.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        if (_isOnline) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "SEARCHING LIVE",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _rippleCircle({required double size, required double delay}) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        // Offset the value by delay
        double progress = (_radarController.value + delay) % 1.0;
        double opacity = (1.0 - progress).clamp(0.0, 1.0);
        double scale = 0.8 + (0.4 * progress);

        return Opacity(
          opacity: opacity,
          child: Container(
            width: size * scale,
            height: size * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobActiveCard(pro_models.ProfessionalBooking activeJob) {
    String buttonText = "Start Job";
    VoidCallback onPressed = () => context.pushNamed(
      AppRoutes.proArriveName, 
      pathParameters: {'id': activeJob.id},
      extra: activeJob
    );

    switch (activeJob.status) {
      case BookingStatus.accepted:
        buttonText = "Start Journey";
        onPressed = () => context.pushNamed(AppRoutes.proNavigationName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.onTheWay:
        buttonText = "I Have Arrived";
        onPressed = () => context.pushNamed(AppRoutes.proArriveName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.arrived:
        buttonText = "Start Service";
        onPressed = () => context.pushNamed(AppRoutes.proActiveJobName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.inProgress:
        buttonText = "Complete Job";
        onPressed = () => context.pushNamed(AppRoutes.proActiveJobName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      default:
        buttonText = "View Details";
        onPressed = () => context.pushNamed(AppRoutes.proBookingDetailName, pathParameters: {'id': activeJob.id});
    }

    return JobCard(
      job: activeJob,
      buttonText: buttonText,
      onPressed: onPressed,
      onCall: () {
          // Logic for call
      },
      onNavigate: () => context.pushNamed(
        AppRoutes.proNavigationName, 
        pathParameters: {'id': activeJob.id},
        extra: activeJob
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
              onPressed: () => context.pushNamed(AppRoutes.proScheduleName),
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


  void _showRequirementsError(String message) {
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
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 5),
              Text(
                'Current: ₹${_walletCash.toStringAsFixed(0)} | $_kitCount Kits',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
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
          gradient: LinearGradient(
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
