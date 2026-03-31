import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:intl/intl.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() => _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _withdrawals = [];

  // Tokens
  static const Color _primary = Color(0xFFFF4D7D);
  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _textPrimary = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ProfessionalApiService.getWithdrawalHistory();
      if (mounted) {
        setState(() {
          // Typically paginated in the backend
          if (response['data'] != null && response['data']['data'] != null) {
            _withdrawals = response['data']['data'];
          } else {
             _withdrawals = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text('Withdrawal History', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
            ? _buildError()
            : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 64),
        const SizedBox(height: 16),
        Text('Failed to load history', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _fetchHistory, 
          icon: const Icon(Icons.refresh_rounded), 
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _buildList() {
    if (_withdrawals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchHistory,
        color: _primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No withdrawals yet', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: _primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _withdrawals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _withdrawals[index];
          final double amount = (item['amount'] as num) / 100;
          final status = (item['status'] ?? 'pending').toString().toLowerCase();
          final String method = (item['method'] ?? 'bank').toString().toUpperCase();
          final String dateStr = item['created_at'] ?? '';
          
          String formattedDate = '';
          try {
            formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateStr).toLocal());
          } catch(e) {
            formattedDate = dateStr;
          }

          Color statusColor;
          IconData statusIcon;
          
          switch (status) {
            case 'approved':
            case 'paid':
              statusColor = Colors.green;
              statusIcon = Icons.check_circle_rounded;
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusIcon = Icons.cancel_rounded;
              break;
            case 'pending':
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.pending_rounded;
              break;
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Withdrawal', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: _textPrimary)),
                    Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: _textPrimary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formattedDate, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(status.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                Row(
                  children: [
                    Icon(method == 'UPI' ? Icons.qr_code_2_rounded : Icons.account_balance_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('Transfer to $method', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    
                    if (item['transaction_reference'] != null) ...[
                      const Spacer(),
                      Text('Ref: ${item['transaction_reference']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
                    ]
                  ],
                ),
                if (status == 'rejected' && item['admin_note'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Reason: ${item['admin_note']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red.shade700)),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
