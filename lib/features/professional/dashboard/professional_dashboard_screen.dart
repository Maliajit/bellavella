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
import './widgets/job_card.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/services/realtime_job_service.dart';
import 'package:bellavella/features/professional/screens/kit_store/kit_store_screen.dart';

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
  bool _isOnline = false;
  int _remainingSeconds = 0;
  double _shiftProgress = 0;
  int _totalShiftSeconds = 28800;
  String? _lastNotificationId;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  Timer? _syncTimer;
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
    if (profileController.profile == null) {
      debugPrint("🆕 Dashboard Init: Fetching missing profile...");
      profileController.fetchProfile();
    }
    
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
        // stats is non-nullable
        setState(() {
          _isOnline = stats.isOnline;
          _kitCount = stats.kitCount;
          _remainingSeconds = stats.remainingSeconds;
          _shiftProgress = stats.shiftProgress;
          _totalShiftSeconds = stats.shiftDuration * 60;
          if (_totalShiftSeconds <= 0) _totalShiftSeconds = 28800;
          _isLoading = false;
        });
        
        // Ensure timer is running if online
        if (_isOnline && _remainingSeconds > 0) {
          _startCountdown();
        } else { // If not online OR remaining seconds <= 0
          _stopTimers();
        }

        // Seed the DashboardController on app start / re-open so the
        // Job Card appears immediately without waiting for stats API.
        final activeInStats = stats.recentBookings.firstWhere(
          (b) => b.isActive,
          orElse: () => pro_models.ProfessionalBooking.empty(),
        );

        if (activeInStats.id.isNotEmpty && activeInStats.isActive && activeInStats.status != BookingStatus.completed) {
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

            // Step 6: Safety fix for dashboard and Firestore listener to clear job on 'idle' status.
            // This logic is typically handled by a real-time listener (e.g., FirebaseMessagingService)
            // or a dedicated job status update mechanism.
            // For the polling fallback, we only push 'pending' requests.
            // The 'idle' status check would be relevant if this method also processed job status updates.
            // As per the provided snippet, if 'data' had a status of 'idle', it would clear the job.
            // However, in this specific polling context, 'status' is hardcoded to 'pending'.
            // If this method were to receive dynamic status updates, the following logic would apply:
            // if (data?['status'] == 'pending') {
            //   _showJobPopup(navKey, data!); // Assuming _showJobPopup and navKey are defined elsewhere
            // } else if (data?['status'] == 'idle') {
            //   // Redundant safety clear for real-time dashboard sync
            //   DashboardController.instance.clearJob();
            // }

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
    // Going online requires at least 5 kits
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
    _countdownTimer?.cancel();
    _syncTimer?.cancel();
    _radarController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _startHeartbeat();
      _loadActiveJob(); // re-check active job when app returns to foreground
    }
  }

  // bool get _isOnline => mounted ? context.watch<ProfessionalProfileController>().isOnline : false; // Replaced by local _isOnline state

  void _startHeartbeat() {
    _fetchDashboardData(isSilent: true);
    _startSyncTimer();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_remainingSeconds <= 0) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            // Recalculate progress locally for smoothness
            if (_shiftProgress < 1.0 && _totalShiftSeconds > 0) {
              _shiftProgress += (1.0 / _totalShiftSeconds); 
            }
          });
        }
      } else {
        _stopTimers();
        _fetchDashboardData(); // Hard sync when timer hits zero
      }
    });
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _syncTimer?.cancel();
  }


  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchDashboardData(isSilent: true);
    });
  }

  String _formatRemainingTime(int seconds) {
    if (seconds <= 0) return "Ending";
    final d = Duration(seconds: seconds);
    int h = d.inHours;
    int m = d.inMinutes.remainder(60);

    if (h > 0) return "${h}h ${m}m";
    if (m > 0) return "${m}m";
    return "${seconds}s";
  }

  String _formatRemainingTimeDigital(int totalSeconds) {
    if (totalSeconds <= 0) return "00:00:00";
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Color _getBadgeColor(int seconds) {
    if (seconds > 3600) return Colors.green;
    if (seconds > 900) return Colors.orange;
    return Colors.red;
  }

  Widget _buildShiftBadge() {
    if (!_isOnline || _remainingSeconds <= 0) return const SizedBox.shrink();

    String timeStr = _formatRemainingTime(_remainingSeconds);
    Color badgeColor = _getBadgeColor(_remainingSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          if (_shiftProgress > 0) ...[
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 3,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: LinearProgressIndicator(
                value: _shiftProgress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),
          ],
        ],
      ),
    );
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
                      if (_stats?.recentBookings.isNotEmpty ?? false) ...[
                        const SizedBox(height: 32),
                        _buildScheduleTimeline(),
                      ],
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
                    Row(
                      children: [
                        Text(
                          profileController.isOnline ? 'Available for bookings' : 'Currently Offline',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: profileController.isOnline ? Colors.green.shade600 : Colors.grey.shade500,
                          ),
                        ),
                        if (profileController.isOnline) ...[
                          const SizedBox(width: 8),
                          _buildShiftBadge(),
                        ],
                      ],
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.1), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        "You’re now visible to customers.",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 6),
                        Text(
                          _formatRemainingTimeDigital(_remainingSeconds),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "remaining",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
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
        final bool showActiveCard = activeJob != null && activeJob.isActive;

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
      case BookingStatus.assigned:
      case BookingStatus.accepted:
        buttonText = "Start Journey";
        onPressed = () => context.pushNamed(AppRoutes.proNavigationName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.onTheWay:
        buttonText = "I Have Arrived";
        onPressed = () => context.pushNamed(AppRoutes.proArriveName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.scanKit:
        buttonText = "Start Job";
        onPressed = () => context.pushNamed(AppRoutes.proScanKitName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.inProgress:
        buttonText = "View Progress";
        onPressed = () => context.pushNamed(AppRoutes.proActiveJobName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      case BookingStatus.paymentPending:
        buttonText = "Collect Payment";
        onPressed = () => context.pushNamed(AppRoutes.proCollectPaymentName, pathParameters: {'id': activeJob.id}, extra: activeJob);
        break;
      default:
        buttonText = "View Details";
        onPressed = () => context.pushNamed(AppRoutes.proActiveJobName, pathParameters: {'id': activeJob.id}, extra: activeJob);
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
          itemCount: (_stats?.recentBookings ?? []).where((b) => !b.status.name.contains('cancelled')).length,
          itemBuilder: (context, index) {
            final activeRecent = (_stats?.recentBookings ?? []).where((b) => !b.status.name.contains('cancelled')).toList();
            final booking = activeRecent[index];
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
  void _showRequirementsError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 15),
                Text(
                  'Current Status: $_kitCount / 5 Kits',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const KitStoreScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Buy Kit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Maybe Later', style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
