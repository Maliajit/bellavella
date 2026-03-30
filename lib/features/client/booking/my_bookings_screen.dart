import 'package:flutter/material.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/features/client/booking/widgets/booking_cancel_reason_sheet.dart';
import 'package:bellavella/features/shared/reviews/user_review_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = true;
  String? _errorMessage;
  List<dynamic> _upcoming = [];
  List<dynamic> _completed = [];
  List<dynamic> _cancelled = [];

  void _moveBookingToCancelled(String bookingId) {
    final upcomingIndex = _upcoming.indexWhere(
      (booking) => booking['id']?.toString() == bookingId,
    );
    if (upcomingIndex == -1) {
      return;
    }

    final updatedBooking = Map<String, dynamic>.from(
      _upcoming.removeAt(upcomingIndex) as Map,
    );
    updatedBooking['status'] = 'cancelled';
    updatedBooking['can_cancel'] = false;
    _cancelled.insert(0, updatedBooking);
  }

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (!TokenManager.hasToken) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isLoggedIn = true;
      _upcoming = [];
      _completed = [];
      _cancelled = [];
    });

    try {
      final response = await ApiService.get('/client/bookings');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        if (mounted) {
          setState(() {
            for (var booking in data) {
              final status = booking['status']?.toString().toLowerCase() ?? '';
              if (status == 'completed') {
                _completed.add(booking);
              } else if (status == 'cancelled') {
                _cancelled.add(booking);
              } else {
                _upcoming.add(booking);
              }
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load bookings';
            if (response['message'] == 'Unauthenticated.' ||
                response['_auth_expired'] == true) {
              _errorMessage = ApiService.sessionExpiredMessage;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.accentColor),
            onPressed: () => context.go('/client/home'),
          ),
          title: const Text(
            'My Bookings',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.greyText,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: !_isLoggedIn
            ? _buildLoginGate()
            : _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor)))
                    : TabBarView(
                    children: [
                      _buildList(_upcoming, 'upcoming'),
                      _buildList(_completed, 'completed'),
                      _buildList(_cancelled, 'cancelled'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(List<dynamic> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_outlined, size: 60, color: AppTheme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'No $type bookings',
              style: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final status = booking['status']?.toString().toLowerCase() ?? '';
        
        Color statusColor = AppTheme.primaryColor;
        Color statusBgColor = AppTheme.primaryColor.withOpacity(0.1);
        String displayStatus = 'Pending';
        bool showActions = true;

        if (status == 'accepted' || status == 'pending') {
          statusColor = AppTheme.successColor;
          statusBgColor = AppTheme.successColor.withOpacity(0.1);
          displayStatus = status == 'accepted' ? 'Accepted' : 'Pending';
        } else if (status == 'completed') {
          statusColor = const Color(0xFF3B82F6);
          statusBgColor = const Color(0xFFEFF6FF);
          displayStatus = 'Completed';
          showActions = false;
        } else if (status == 'cancelled') {
          statusColor = AppTheme.errorColor;
          statusBgColor = AppTheme.errorColor.withOpacity(0.1);
          displayStatus = 'Cancelled';
          showActions = false;
        }

        final List<Map<String, String>> services = [];
        if (booking['service'] != null) {
          final serviceName =
              booking['display_name']?.toString() ??
              booking['variant_name']?.toString() ??
              booking['service_name']?.toString() ??
              booking['service']['name']?.toString() ??
              'Unknown Service';
          final servicePrice =
              booking['display_price']?.toString() ??
              booking['service']['price']?.toString() ??
              '0';
          services.add({
            'name': serviceName,
            'price': servicePrice,
            'qty': '1',
          });
        } else if (booking['package_snapshot'] != null ||
            booking['package'] != null) {
          final package = PackageSummary.fromJson(
            Map<String, dynamic>.from(
              (booking['package_snapshot'] ?? booking['package']) as Map,
            ),
          );
          services.add({
            'name': booking['display_name']?.toString() ?? package.title,
            'price': (booking['display_price'] ?? package.displayPrice ?? 0)
                .toString(),
            'qty': '1',
          });
        }

        return _buildBookingCard(
          context,
          bookingData: booking,
          status: displayStatus,
          statusColor: statusColor,
          statusBgColor: statusBgColor,
          date: _formatBookingDate(booking['booking_date']?.toString()),
          time: booking['booking_time']?.toString() ?? 'N/A',
          services: services,
          total: booking['total_amount']?.toString() ?? '0',
          showActions: showActions,
        );
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context, {
    required Map<String, dynamic> bookingData,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required String date,
    required String time,
    required List<Map<String, String>> services,
    required String total,
    bool showActions = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHover: (hovering) {
            // Can be used for hover effects on web
          },
          onTap: () {
            context.push('/client/booking', extra: bookingData);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row (Date and Status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6F7F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Time Section
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4, bottom: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.greyText),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(
                          color: AppTheme.greyText,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 20),
                
                // Services Section
                Text(
                  'Services (${services.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                ...services.map((service) => _buildServiceItem(service)),
                
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 20),
                
                // Total Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    Text(
                      '₹$total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                
                if (showActions) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (bookingData['can_cancel'] == true)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelConfirmation(
                              context,
                              bookingData['id']?.toString() ?? '',
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancel Booking'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return AppTheme.primaryColor.withOpacity(0.04);
                                  }
                                  if (states.contains(WidgetState.focused) || states.contains(WidgetState.pressed)) {
                                    return AppTheme.primaryColor.withOpacity(0.12);
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      if (bookingData['can_cancel'] == true)
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await context.push('/client/booking-status/${bookingData['id']}');
                            if (!mounted) return;
                            _fetchBookings();
                          },
                          icon: const Icon(Icons.fact_check_outlined, size: 18),
                          label: const Text('View Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'Completed') ...[
                   const SizedBox(height: 24),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                        onPressed: () {
                          ToastUtil.showSuccess(context, 'Rebooking functionality is coming soon.');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        child: const Text('Book Again'),
                      ),
                   ),
                   const SizedBox(height: 12),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton.icon(
                        onPressed: () => context.push('/client/service-review/${bookingData['id']}'),
                        icon: const Icon(Icons.star_rounded, size: 20),
                        label: const Text('Rate Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor, // Dark navy
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                   ),
                   if ((bookingData['professional'] is Map &&
                           (bookingData['professional']['id']?.toString().isNotEmpty ?? false)) ||
                       (bookingData['professional_name']?.toString().isNotEmpty ?? false))
                     const SizedBox(height: 12),
                   if ((bookingData['professional'] is Map &&
                           (bookingData['professional']['id']?.toString().isNotEmpty ?? false)) ||
                       (bookingData['professional_name']?.toString().isNotEmpty ?? false))
                     SizedBox(
                       width: double.infinity,
                       child: OutlinedButton.icon(
                         onPressed: () async {
                           final professionalData = bookingData['professional'] is Map
                               ? Map<String, dynamic>.from(
                                   bookingData['professional'] as Map,
                                 )
                               : <String, dynamic>{};
                           final professionalName =
                               professionalData['name']?.toString() ??
                               bookingData['professional_name']?.toString() ??
                               'Professional';

                           await Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (_) => UserReviewScreen(
                                 bookingId: bookingData['id']?.toString() ?? '',
                                 endpoint: '/client/review/professional',
                                 title: 'Review Professional',
                                 subtitle:
                                     'Share feedback about the professional who served you.',
                                 subjectName: professionalName,
                                 successMessage:
                                     'Your review for the professional was submitted for approval.',
                               ),
                             ),
                           );
                         },
                         icon: const Icon(Icons.person_outline_rounded, size: 20),
                         label: const Text('Review Professional'),
                         style: OutlinedButton.styleFrom(
                           foregroundColor: AppTheme.primaryColor,
                           side: BorderSide(color: AppTheme.primaryColor),
                           padding: const EdgeInsets.symmetric(vertical: 14),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                           textStyle: const TextStyle(
                             fontWeight: FontWeight.bold,
                             fontSize: 14,
                           ),
                         ),
                       ),
                     ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, String> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.spa_outlined, color: AppTheme.primaryColor, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${service['price']!}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Qty: ${service['qty']!}',
              style: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBookingDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return 'N/A';
    }

    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) {
      return rawDate;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  void _showCancelConfirmation(BuildContext context, String bookingId) {
    BookingCancelReasonSheet.show(context).then((selection) async {
      if (selection == null || !mounted) return;

      if (selection.code == 'reschedule') {
        context.push('/client/booking-status/$bookingId');
        return;
      }

      final response = await ApiService.post(
        '/client/bookings/$bookingId/cancel',
        <String, dynamic>{
          'reason_code': selection.code,
          if (selection.note != null) 'reason_note': selection.note,
        },
      );

      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _moveBookingToCancelled(bookingId);
        });
        ToastUtil.showSuccess(
          context,
          response['message']?.toString() ?? 'Booking cancelled successfully',
        );
        return;
      }
      ToastUtil.showError(
        context,
        response['message']?.toString() ?? 'Unable to cancel booking',
      );
    });
  }
  Widget _buildLoginGate() {
    return Container(
      color: const Color(0xFFF6F7F9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.12),
                      AppTheme.primaryColor.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: 52,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Headline
              Text(
                'Sign in to your account',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Access and track your service\nbookings in one place.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.push('/client/login');
                    // Re-check auth after returning from login
                    _fetchBookings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
