import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/core/widgets/base_widgets.dart';
import 'package:bellavella/features/client/booking/widgets/slot_picker_bottom_sheet.dart';
import 'package:bellavella/features/client/booking/widgets/booking_cancel_reason_sheet.dart';
import 'package:intl/intl.dart';
import 'package:bellavella/features/shared/reviews/user_review_screen.dart';

class BookingStatusScreen extends StatefulWidget {
  final String bookingId;
  const BookingStatusScreen({super.key, required this.bookingId});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  bool _isLoading = true;
  bool _isRescheduling = false;
  bool _isCancelling = false;
  String? _errorMessage;
  Booking? _booking;

  void _goToMyBookings() {
    final refreshToken = DateTime.now().millisecondsSinceEpoch;
    context.go('/client/my-bookings?refresh=$refreshToken');
  }

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    if (widget.bookingId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid booking ID';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.get('/client/bookings/${widget.bookingId}');

      if (response['success'] == true) {
        if (!mounted) return;
        setState(() {
          _booking = Booking.fromJson(response['data'] ?? {});
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _errorMessage = response['message']?.toString() ?? 'Failed to load booking';
        if (response['message'] == 'Unauthenticated.' ||
            response['_auth_expired'] == true) {
          _errorMessage = ApiService.sessionExpiredMessage;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    if (_booking == null || _isCancelling) return;

    final selection = await BookingCancelReasonSheet.show(context);
    if (selection == null || !mounted) return;

    if (selection.code == 'reschedule') {
      await _openRescheduleSheet();
      return;
    }

    setState(() => _isCancelling = true);
    final response = await ApiService.post(
      '/client/bookings/${widget.bookingId}/cancel',
      <String, dynamic>{
        'reason_code': selection.code,
        if (selection.note != null) 'reason_note': selection.note,
      },
    );

    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (response['success'] == true) {
      ToastUtil.showSuccess(
        context,
        response['message']?.toString() ?? 'Booking cancelled.',
      );
      _goToMyBookings();
      return;
    }

    ToastUtil.showError(
      context,
      response['message']?.toString() ?? 'Unable to cancel booking.',
    );
  }

  Future<void> _openRescheduleSheet() async {
    final booking = _booking;
    if (booking == null || !booking.canReschedule || _isRescheduling) {
      return;
    }

    final availableDates = List<DateTime>.generate(
      8,
      (index) => DateTime.now().add(Duration(days: index)),
    );
    final selection = await SlotPickerBottomSheet.show(
      context: context,
      title: 'Reschedule Booking',
      subtitle: booking.rescheduleCutoffAt == null
          ? 'Select a new date and time. You can reschedule only once.'
          : 'Available until ${_formatDateTime(booking.rescheduleCutoffAt!)}. You can reschedule only once.',
      dates: availableDates,
      confirmLabel: 'Continue',
    );

    if (selection == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reschedule'),
        content: Text(
          'Change booking to ${_formatDate(selection.date)} at ${selection.timeLabel}?\n\nYou can reschedule this booking only once.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRescheduling = true);
    final response = await ApiService.post(
      '/client/bookings/${widget.bookingId}/reschedule',
      <String, dynamic>{
          'new_date': _formatApiDate(selection.date),
        'new_time_slot': selection.timeLabel,
      },
    );

    if (!mounted) return;
    setState(() => _isRescheduling = false);

    if (response['success'] == true) {
      ToastUtil.showSuccess(
        context,
        response['message']?.toString() ?? 'Booking rescheduled successfully.',
      );
      await _fetchStatus();
      return;
    }

    ToastUtil.showError(
      context,
      response['message']?.toString() ?? 'Unable to reschedule booking.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Status'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _goToMyBookings,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                )
              : _booking == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusHeader(_booking!),
                          if (_booking!.status == BookingStatus.cancelled &&
                              ((_booking!.cancelReasonCode ?? '').isNotEmpty ||
                                  (_booking!.cancelReasonNote ?? '').isNotEmpty)) ...[
                            const SizedBox(height: 24),
                            _buildCancellationReasonCard(_booking!),
                          ],
                          const SizedBox(height: 32),
                          _buildScheduleCard(_booking!),
                          const SizedBox(height: 32),
                          _buildTimeline(_booking!),
                          const SizedBox(height: 32),
                          if (_booking!.status != BookingStatus.cancelled) ...[
                            _buildProfessionalInfo(_booking!),
                            const SizedBox(height: 24),
                          ],
                          if (_booking!.canTrackProfessional)
                            PrimaryButton(
                              label: 'Track Professional',
                              onPressed: () => context.push(
                                '/client/live-tracking/${widget.bookingId}',
                              ),
                            ),
                          if (_booking!.canTrackProfessional)
                            const SizedBox(height: 12),
                          if (_booking!.canReschedule)
                            SecondaryButton(
                              label: 'Reschedule',
                              onPressed: _isRescheduling ? null : _openRescheduleSheet,
                              isLoading: _isRescheduling,
                            ),
                          if (_booking!.canReschedule)
                            const SizedBox(height: 12),
                          if (_booking!.canCancel)
                            OutlinedButton(
                              onPressed: _isCancelling ? null : _cancelBooking,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                foregroundColor: AppTheme.errorColor,
                                side: const BorderSide(color: AppTheme.errorColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCancelling
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Cancel Booking'),
                            ),
                          if (_booking!.canCancel)
                            const SizedBox(height: 12),
                          if (_booking!.status == BookingStatus.completed &&
                              _booking!.professional != null &&
                              _booking!.professional!.id.isNotEmpty)
                            PrimaryButton(
                              label: 'Review Professional',
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserReviewScreen(
                                      bookingId: _booking!.id,
                                      endpoint: '/client/review/professional',
                                      title: 'Review Professional',
                                      subtitle: 'Share feedback about the professional who served you.',
                                      subjectName: _booking!.professional!.name,
                                      successMessage: 'Your review for the professional was submitted for approval.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_booking!.status == BookingStatus.completed &&
                              _booking!.professional != null &&
                              _booking!.professional!.id.isNotEmpty)
                            const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _goToMyBookings,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Back to My Bookings'),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusHeader(Booking booking) {
    final isCancelled = booking.status == BookingStatus.cancelled;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
            color: isCancelled ? Colors.red : Colors.green,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _statusHeadline(booking),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          booking.bookingTime.isEmpty
              ? _formatDate(booking.dateTime)
              : '${_formatDate(booking.dateTime)} at ${booking.bookingTime}',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        if (booking.status == BookingStatus.paymentPending) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4891).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              booking.paymentMethod == 'COD' || booking.paymentMethod == 'CASH'
                  ? 'Please pay ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(booking.totalPrice)} in cash'
                  : 'Online Payment is being verified...',
              style: const TextStyle(
                color: Color(0xFFFF4891),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ] else if (booking.paymentStatus == 'SUCCESS') ...[
           const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'PAID · ${_formatStatus(booking.paymentMethod)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatStatus(String status) {
    if (status == 'COD') return 'Cash';
    if (status == 'ONLINE') return 'Online';
    if (status == 'WALLET') return 'Wallet';
    return status;
  }

  Widget _buildScheduleCard(Booking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(_formatDate(booking.dateTime)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(booking.bookingTime.isEmpty ? 'Slot pending' : booking.bookingTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationReasonCard(Booking booking) {
    final title = _cancelReasonLabel(booking.cancelReasonCode);
    final note = (booking.cancelReasonNote ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.red.shade400),
              const SizedBox(width: 10),
              const Text(
                'Cancellation Reason',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(Booking booking) {
    if (booking.status == BookingStatus.cancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lifecycle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _TimelineItem(
            title: 'Requested',
            time: _formatOptionalDateTime(booking.requestedAt),
            state: _TimelineState.completed,
            isFirst: true,
          ),
          _TimelineItem(
            title: 'Cancelled',
            time: _formatOptionalDateTime(booking.cancelledAt),
            state: _TimelineState.current,
            isLast: true,
          ),
        ],
      );
    }

    final steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Requested',
        timestamp: booking.requestedAt,
        isReached: booking.requestedAt != null,
      ),
      _TimelineStep(
        title: 'Accepted',
        timestamp: booking.acceptedAt ?? booking.assignedAt,
        isReached: booking.acceptedAt != null || booking.assignedAt != null,
      ),
      _TimelineStep(
        title: 'On the Way',
        timestamp: booking.onTheWayAt,
        isReached: booking.onTheWayAt != null,
      ),
      _TimelineStep(
        title: 'Started',
        timestamp: booking.startedAt,
        isReached: booking.startedAt != null,
      ),
      _TimelineStep(
        title: 'Completed',
        timestamp: booking.completedAt,
        isReached: booking.completedAt != null,
      ),
    ];

    final firstPendingIndex = steps.indexWhere((step) => !step.isReached);
    final activeIndex = firstPendingIndex == -1 ? steps.length - 1 : firstPendingIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lifecycle',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < steps.length; index++)
          _TimelineItem(
            title: steps[index].title,
            time: _formatOptionalDateTime(steps[index].timestamp),
            state: steps[index].isReached
                ? (index == activeIndex && booking.completedAt == null
                    ? _TimelineState.current
                    : _TimelineState.completed)
                : (index == activeIndex
                    ? _TimelineState.current
                    : _TimelineState.upcoming),
            isFirst: index == 0,
            isLast: index == steps.length - 1,
          ),
      ],
    );
  }

  Widget _buildProfessionalInfo(Booking booking) {
    final professional = booking.professional;

    if (professional == null || professional.id.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.secondaryColor),
        ),
        child: const Text(
          'Waiting for professional assignment.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    final subtitleParts = <String>[
      if ((professional.city ?? '').isNotEmpty) professional.city!,
      if (professional.rating > 0) professional.rating.toStringAsFixed(1),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: professional.photoUrl.isNotEmpty
                ? NetworkImage(professional.photoUrl)
                : null,
            child: professional.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  professional.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitleParts.isEmpty
                      ? 'Professional assigned'
                      : subtitleParts.join(' - '),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: professional.phone.isNotEmpty ? () {} : null,
            icon: Icon(Icons.call_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  String _statusHeadline(Booking booking) {
    switch (booking.status) {
      case BookingStatus.completed:
        return 'Booking Completed';
      case BookingStatus.cancelled:
        return 'Booking Cancelled';
      case BookingStatus.inProgress:
        return 'Service In Progress';
      case BookingStatus.onTheWay:
        return 'Professional On The Way';
      case BookingStatus.accepted:
      case BookingStatus.assigned:
        return 'Booking Accepted';
      default:
        return 'Booking Requested';
    }
  }

  String? _cancelReasonLabel(String? code) {
    switch (code) {
      case 'changed_plan':
        return 'My plan changed';
      case 'mistake':
        return 'I booked by mistake';
      case 'other_service':
        return 'I found another service';
      case 'trust_issue':
        return 'I am not comfortable with the booking';
      case 'price':
        return 'Price is too high';
      case 'reschedule':
        return 'I want to reschedule instead';
      case 'other':
        return 'Other';
      default:
        return null;
    }
  }

  static String _formatDate(DateTime value) {
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  static String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(value)} $hour:$minute $meridiem';
  }

  static String _formatApiDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  static String? _formatOptionalDateTime(DateTime? value) {
    if (value == null) {
      return null;
    }

    return _formatDateTime(value);
  }
}

class _TimelineStep {
  final String title;
  final DateTime? timestamp;
  final bool isReached;

  const _TimelineStep({
    required this.title,
    required this.timestamp,
    required this.isReached,
  });
}

enum _TimelineState { completed, current, upcoming }

class _TimelineItem extends StatelessWidget {
  final String title;
  final String? time;
  final _TimelineState state;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.time,
    required this.state,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _TimelineState.completed;
    final isCurrent = state == _TimelineState.current;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : (isCurrent ? AppTheme.primaryColor : Colors.grey.shade300),
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        width: 4,
                      )
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted ? Colors.green : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isCurrent
                        ? AppTheme.accentColor
                        : Colors.grey,
                  ),
                ),
                if (time != null)
                  Text(
                    time!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
