import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:bellavella/core/utils/razorpay/razorpay_helper.dart' as rzp_helper;
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/models/data_models.dart';

enum WalletTab { earnings, deposit, coins, kits }

class ProfessionalWalletScreen extends StatefulWidget {
  const ProfessionalWalletScreen({super.key});
  @override
  State<ProfessionalWalletScreen> createState() => _ProfessionalWalletScreenState();
}

class _ProfessionalWalletScreenState extends State<ProfessionalWalletScreen>
    with SingleTickerProviderStateMixin {
  pro_models.ProfessionalWallet? _wallet;
  pro_models.ProfessionalDashboardStats? _stats;
  Professional? _profile;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  WalletTab _activeTab = WalletTab.earnings;
  rzp_helper.RazorpayService? _razorpayService;
  bool _isProcessing = false;
  double _pendingDepositAmount = 0.0;
  static const String _razorpayKey = 'rzp_test_S7dlJIqMvrpcaj'; 

  // Design tokens
  static const double _minDeposit = 1500.0;
  static const Color _primary = Color(0xFFFF4D7D); // Primary Pink
  static const Color _green   = Color(0xFF22C55E); // Success Color
  static const Color _blue    = Color(0xFF3D8BFF);
  static const Color _amber   = Color(0xFFFFB020);
  static const Color _violet  = Color(0xFF7C5CFC);
  static const Color _bg      = Color(0xFFF6F7F9); // Background Color
  static const Color _textPrimary = Color(0xFF1F2937); // Primary Text
  static const Color _textSecondary = Color(0xFF6B7280); // Secondary Text

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() => _activeTab = WalletTab.values[_tabController.index]);
    });
    _initRazorpay();
    _fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfessionalProfileController>().fetchProfile();
    });
  }

  void _initRazorpay() {
    _razorpayService = rzp_helper.getService();
    _razorpayService?.init(_onPaymentSuccess, _onPaymentError, _onExternalWallet);
  }

  @override
  void dispose() { 
    _tabController.dispose(); 
    _razorpayService?.clear();
    super.dispose(); 
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final wallet = await ProfessionalApiService.getWallet(tab: 'earnings');
      final stats  = await ProfessionalApiService.getDashboardStats();
      final profile = await ProfessionalApiService.getProfile();
      if (mounted) setState(() { _wallet = wallet; _stats = stats; _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // Getters
  double get _earn  => _wallet?.earningsBalance ?? 0.0;
  double get _dep   => _wallet?.depositBalance  ?? 0.0;
  double get _total => _earn + _dep;
  bool   get _depOk => _dep >= _minDeposit;
  double get _need  => (_minDeposit - _dep).clamp(0.0, _minDeposit);
  String _fmt(double v) {
    if (v >= 100000) return '₹${(v/100000).toStringAsFixed(1)}L';
    return v >= 1000 ? '₹${(v/1000).toStringAsFixed(1)}K' : '₹${v.toStringAsFixed(0)}';
  }

  // --- Razorpay Methods ---

  void _openRazorpayForDeposit(double amount) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _pendingDepositAmount = amount;
    });

    try {
      final orderData = await ProfessionalApiService.createWalletDepositOrder(amount);
      final options = {
        'key': _razorpayKey,
        'amount': orderData['amount'],
        'name': 'BellaVella',
        'description': 'Wallet Deposit',
        'order_id': orderData['order_id'],
        'prefill': {
          'contact': '', // Can be filled if available in stats
          'email': '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpayService?.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    try {
      await ProfessionalApiService.verifyWalletDeposit(
        amount: _pendingDepositAmount,
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit successful!'), backgroundColor: _green),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
      if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${response.walletName}'), backgroundColor: _blue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Stack(
                children: [
                  _error != null
                      ? _errView()
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: _primary,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              _buildAppBar(),
                              SliverToBoxAdapter(child: _buildHeroCard()),
                              if (!_depOk) SliverToBoxAdapter(child: _buildWarning()),
                              SliverToBoxAdapter(child: _buildTabs()),
                              SliverToBoxAdapter(child: _buildTabBody()),
                              const SliverToBoxAdapter(child: SizedBox(height: 100)),
                            ],
                          ),
                        ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      pinned: false,
      floating: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (context.canPop())
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('My Wallet', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
            ),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _depOk ? _green.withOpacity(0.1) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: _depOk ? _green : Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    _depOk ? 'Active' : 'Low Deposit',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _depOk ? _green : Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1C1B3A), Color(0xFF2D1F5E), Color(0xFF1A1A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(top: -30, right: -30, child: _decoCircle(130, Colors.white.withOpacity(0.04))),
              Positioned(bottom: -20, left: -20, child: _decoCircle(100, Colors.white.withOpacity(0.03))),
              Positioned(top: 10, right: 80, child: _decoCircle(60, Colors.white.withOpacity(0.03))),
              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text('Total Balance', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${_total.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _heroPill(Icons.trending_up_rounded, 'Earnings', _earn, _green)),
                        const SizedBox(width: 12),
                        Expanded(child: _heroPill(Icons.savings_outlined, 'Deposit', _dep, _blue)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decoCircle(double size, Color c) => Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _heroPill(IconData icon, String label, double val, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
            Text('₹${val.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ])),
        ],
      ),
    );
  }

  // ─── Warning Banner ─────────────────────────────────────────────────────────
  Widget _buildWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: _amber.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: _amber, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Low Deposit', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.orange.shade900)),
            Text('Add ₹${_need.toStringAsFixed(0)} to receive new bookings', style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange.shade700)),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAddMoneySheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(12)),
              child: Text('Add', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Row(
        children: [
          _tab(Icons.trending_up_rounded, 'Earnings', WalletTab.earnings, _primary),
          _tab(Icons.savings_outlined, 'Deposit', WalletTab.deposit, _blue),
          _tab(Icons.toll_rounded, 'Coins', WalletTab.coins, _amber),
          _tab(Icons.inventory_2_outlined, 'Kits', WalletTab.kits, _violet),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, WalletTab tab, Color activeColor) {
    final sel = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _activeTab = tab); _tabController.animateTo(tab.index); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sel ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: sel ? Colors.white : Colors.grey.shade400),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.grey.shade500)),
          ]),
        ),
      ),
    );
  }

  // ─── Tab Body ────────────────────────────────────────────────────────────────
  Widget _buildTabBody() {
    switch (_activeTab) {
      case WalletTab.earnings: return _earningsTab();
      case WalletTab.deposit:  return _depositTab();
      case WalletTab.coins:    return _coinsTab();
      case WalletTab.kits:     return _kitsTab();
    }
  }

  // ══════════════════════════════════════════════════════
  //  EARNINGS TAB
  // ══════════════════════════════════════════════════════
  Widget _earningsTab() {
    final today   = (_wallet?.todayEarnings   ?? _stats?.todayEarnings ?? 0.0).toDouble();
    final weekly  = (_wallet?.weeklyEarnings  ?? 0.0).toDouble();
    final monthly = (_wallet?.monthlyEarnings ?? 0.0).toDouble();
    final jobs    = _wallet?.totalJobs ?? _stats?.totalBookings ?? 0;
    final active  = _stats?.activeJobsCount ?? 0;

    final profile = context.watch<ProfessionalProfileController>().profile;
    final isKycVerified = profile?.verification == 'Verified';
    final isBankAdded = profile?.payout.accountNumber.isNotEmpty ?? false;
    final isBankVerified = (profile?.payout.verificationStatus ?? 'Pending') == 'Verified';
    final needsVerification = !isKycVerified || !isBankAdded || !isBankVerified;

    return _padded(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),

      if (needsVerification) ...[
        _buildVerificationBanner(isKycVerified, isBankAdded, isBankVerified),
        const SizedBox(height: 16),
      ],

      // Action buttons row
      Row(children: [
        Expanded(child: _actionCard(Icons.call_received_rounded, 'Withdraw', _primary, () => _handleWithdrawClick(isEarnings: true))),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(Icons.receipt_long_rounded, 'Transactions', Colors.black87, () => context.pushNamed(AppRoutes.proTransactionsName), outlined: true)),
      ]),
      const SizedBox(height: 24),

      // Summary
      _sLabel('Earnings Summary'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard(Icons.wb_sunny_outlined, 'Today', '₹${today.toStringAsFixed(0)}', Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.bar_chart_rounded, 'Weekly', _fmt(weekly), Colors.blue)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.calendar_month_outlined, 'Monthly', _fmt(monthly), _primary)),
      ]),
      const SizedBox(height: 24),

      // Jobs
      _sLabel('Active Jobs'),
      const SizedBox(height: 12),
      _card(Column(children: [
        _jobRow(Icons.work_outline_rounded, 'Jobs Assigned', '$jobs', Colors.indigo),
        _divider(),
        _jobRow(Icons.autorenew_rounded, 'In Progress', '$active', Colors.orange),
      ])),
      const SizedBox(height: 24),

      // Quick actions
      _sLabel('Quick Actions'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _bigActionCell(Icons.calendar_month_rounded, 'Schedule', _violet, () => context.push(AppRoutes.proSchedule))),
        const SizedBox(width: 12),
        Expanded(child: _bigActionCell(Icons.history_rounded, 'History', Colors.teal, () => context.pushNamed(AppRoutes.proTransactionsName))),
      ]),
      const SizedBox(height: 24),

      // Transactions
      _sLabel('Recent Transactions'),
      const SizedBox(height: 12),
      _txSection(),
    ]));
  }

  // ══════════════════════════════════════════════════════
  //  DEPOSIT TAB
  // ══════════════════════════════════════════════════════
  Widget _depositTab() {
    return _padded(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),

      // Deposit balance card
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Deposit Balance', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('₹${_dep.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)),
          ]),
          Container(width: 54, height: 54, decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.savings_outlined, color: _blue, size: 26)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Required: ₹${_minDeposit.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _depOk ? _green.withOpacity(0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_depOk ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                  color: _depOk ? _green : Colors.red, size: 13),
              const SizedBox(width: 4),
              Text(_depOk ? 'Met ✓' : 'Need ₹${_need.toStringAsFixed(0)} more',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: _depOk ? _green : Colors.red.shade700)),
            ]),
          ),
        ]),
        if (!_depOk) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
            value: (_dep / _minDeposit).clamp(0.0, 1.0), backgroundColor: Colors.grey.shade100,
            color: _amber, minHeight: 5,
          )),
        ],
      ])),
      const SizedBox(height: 14),

      // Buttons
      Row(children: [
        Expanded(child: _actionCard(Icons.add_circle_outline_rounded, 'Add Money', _blue, () => _showAddMoneySheet())),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(Icons.arrow_upward_rounded, 'Withdraw', Colors.black87, () => _handleWithdrawClick(isEarnings: false), outlined: true)),
      ]),
      const SizedBox(height: 24),

      // Info
      _sLabel('About Deposit'),
      const SizedBox(height: 12),
      _card(Column(children: [
        _infoRow(Icons.info_outline_rounded, 'Min ₹1,500 required to receive job assignments', _blue),
        _divider(),
        _infoRow(Icons.shield_outlined, 'Protects against cancellations & no-shows', Colors.indigo),
        _divider(),
        _infoRow(Icons.timer_outlined, 'Withdrawal takes 24 hours to process', Colors.orange),
      ])),
    ]));
  }

  // ══════════════════════════════════════════════════════
  //  COINS TAB
  // ══════════════════════════════════════════════════════
  Widget _coinsTab() {
    final coins = _wallet?.coins ?? 0;
    return _padded(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),

      // Gold coin card
      Container(
        width: double.infinity, padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFB020), Color(0xFFFF8A00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _amber.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20, child: _decoCircle(100, Colors.white.withOpacity(0.07))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('BellaVella Coins', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Center(child: Text('🪙', style: TextStyle(fontSize: 20)))),
            ]),
            const SizedBox(height: 10),
            Text('$coins', style: GoogleFonts.outfit(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2, height: 1)),
            Text('coins available', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text('Loyalty rewards for our gold partners', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 24),

      // How to earn
      _sLabel('How to Earn Coins'),
      const SizedBox(height: 12),
      _card(Column(children: [
        _earnRow('🎯', 'Invite a new professional', '500 coins'),
        _divider(),
        _earnRow('⭐', 'Complete 5 premium jobs in a week', '200 coins'),
        _divider(),
        _earnRow('✅', 'Verify your profile', '100 coins'),
        _divider(),
        _earnRow('📅', 'Complete a job on time', '50 coins'),
      ])),
      const SizedBox(height: 24),

      // Coin transactions
      _sLabel('Coin History'),
      const SizedBox(height: 12),
      _txSection(),
    ]));
  }

  // ══════════════════════════════════════════════════════
  //  KITS TAB
  // ══════════════════════════════════════════════════════
  Widget _kitsTab() {
    final kits = _wallet?.kits ?? 0;
    return _padded(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),

      // Kits card
      Container(
        width: double.infinity, padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _violet.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Service Kits', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const Icon(Icons.inventory_2_outlined, color: Colors.white54, size: 22),
          ]),
          const SizedBox(height: 10),
          Text('$kits', style: GoogleFonts.outfit(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2, height: 1)),
          Text('kits available', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          if (kits < 5) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Min 5 kits required. Add ${5 - kits} more.', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.goNamed(AppRoutes.proKitStoreName),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Get More Kits', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: _violet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),

      _sLabel('Inventory Log'),
      const SizedBox(height: 12),
      _emptyState(Icons.inventory_2_outlined, 'No kit log yet', 'Kit assignments will appear here.'),
    ]));
  }

  // ─── Shared small widgets ────────────────────────────────────────────────────
  Widget _padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

  Widget _card(Widget child) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 4))]),
      child: child,
    );
  }

  Widget _sLabel(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: _textSecondary, letterSpacing: 1.4));

  Widget _divider() => const Divider(color: Color(0xFFE5E7EB), height: 24, thickness: 1);

  Widget _statCard(IconData icon, String label, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: c, size: 18)),
        const SizedBox(height: 10),
        Text(val, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: _textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: _textSecondary)),
      ]),
    );
  }

  Widget _jobRow(IconData icon, String label, String count, Color c) {
    return Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: c, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary))),
      Text(count, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: _textPrimary)),
    ]);
  }

  Widget _actionCard(IconData icon, String label, Color c, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : c,
          borderRadius: BorderRadius.circular(16),
          border: outlined ? Border.all(color: Colors.grey.shade200, width: 1.5) : null,
          boxShadow: outlined ? null : [BoxShadow(color: c.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: outlined ? Colors.black87 : Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(color: outlined ? Colors.black87 : Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _bigActionCell(IconData icon, String label, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withOpacity(0.12))),
        child: Column(children: [
          Icon(icon, color: c, size: 26),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color c) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: c, size: 17)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600))),
    ]);
  }

  Widget _earnRow(String emoji, String label, String reward) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: _amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(reward, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange.shade800)),
      ),
    ]);
  }

  Widget _txSection() {
    final txns = _wallet?.transactions ?? [];
    if (txns.isEmpty) return _emptyState(Icons.receipt_long_outlined, 'No transactions yet', 'Complete jobs to start earning.');
    return Column(children: txns.map((tx) {
      final isCredit = tx.type == 'credit';
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: (isCredit ? _green : Colors.red).withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(isCredit ? Icons.call_received_rounded : Icons.call_made_rounded,
                  color: isCredit ? _green : Colors.red, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.description.isEmpty ? 'Transaction' : tx.description, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(tx.date, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400)),
          ])),
          Text('${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: isCredit ? _green : Colors.red)),
        ]),
      );
    }).toList());
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(icon, size: 48, color: Colors.grey.shade200),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Text(sub, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade300)),
      ]),
    );
  }

  Widget _errView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.wifi_off_rounded, color: Colors.grey.shade200, size: 64),
    const SizedBox(height: 14),
    Text('Could not load wallet', style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade500)),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: _fetchData, icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'), style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  ]));

  // ─── Bottom Sheets ────────────────────────────────────────────────────────────
  void _showAddMoneySheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _AddMoneySheet(onAdd: (amount, method) {
          Navigator.pop(context);
          if (method == 'Razorpay') {
            _openRazorpayForDeposit(amount);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Adding ₹${amount.toStringAsFixed(0)} via $method…'), backgroundColor: _green));
          }
        }));
  }

  void _handleWithdrawClick({bool isEarnings = true}) {
    final profile = context.read<ProfessionalProfileController>().profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile loading...')));
      return;
    }

    final isKycVerified = profile.verification == 'Verified';
    final isBankAdded = profile.payout.accountNumber.isNotEmpty;
    final isBankVerified = profile.payout.verificationStatus == 'Verified';

    if (!isKycVerified) {
      _showVerificationDialog(
        title: "KYC Verification Required",
        desc: "Please complete your ID and professional document verification to enable withdrawals.",
        btnLabel: "Complete KYC",
        onPressed: () => context.push(AppRoutes.proKycDocuments),
      );
      return;
    }

    if (!isBankAdded) {
      _showVerificationDialog(
        title: "Bank Account Required",
        desc: "Please add your bank account details to withdraw your earnings.",
        btnLabel: "Add Bank Account",
        onPressed: () => context.push(AppRoutes.proEditBankDetails),
      );
      return;
    }

    if (!isBankVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Your bank account is under verification. Withdrawals will be available once approved.')),
            ],
          ),
          backgroundColor: _amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showWithdrawSheet(isEarnings: isEarnings);
  }

  void _showVerificationDialog({required String title, required String desc, required String btnLabel, required VoidCallback onPressed}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text(desc, style: GoogleFonts.outfit(color: Colors.grey.shade600, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onPressed();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(btnLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(bool kyc, bool bankAdded, bool bankVerified) {
    String msg = "Complete KYC to enable withdrawals.";
    if (kyc && !bankAdded) msg = "Add bank account to withdraw money.";
    if (kyc && bankAdded && !bankVerified) msg = "Bank verification pending.";

    return GestureDetector(
      onTap: () {
        if (!kyc) context.push(AppRoutes.proKycDocuments);
        else if (!bankAdded) context.push(AppRoutes.proEditBankDetails);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_person_outlined, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verification Required', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.red.shade900)),
                  Text(msg, style: GoogleFonts.outfit(fontSize: 12, color: Colors.red.shade700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.red.shade300),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet({bool isEarnings = true}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _WithdrawSheet(
          maxAmount: isEarnings ? _earn : _dep,
          label: isEarnings ? 'Earnings' : 'Deposit',
          onWithdraw: (amount) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Withdrawal of ₹${amount.toStringAsFixed(0)} requested.'), backgroundColor: _primary));
          },
        ));
  }
}

// ─── Add Money Sheet ───────────────────────────────────────────────────────────
class _AddMoneySheet extends StatefulWidget {
  final void Function(double, String) onAdd;
  const _AddMoneySheet({required this.onAdd});
  @override State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  static const _presets = [500.0, 1000.0, 1500.0, 2000.0];
  static const _blue = Color(0xFF3D8BFF);
  double? _sel;
  bool    _custom = false;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Add to Deposit', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Minimum ₹1,500 to receive jobs', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          // presets
          GridView.count(crossAxisCount: 2, shrinkWrap: true, childAspectRatio: 3.6, mainAxisSpacing: 10, crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: _presets.map((a) {
                final sel = !_custom && _sel == a;
                return GestureDetector(
                  onTap: () => setState(() { _sel = a; _custom = false; _ctrl.text = ''; }),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(color: sel ? _blue : Colors.grey.shade50, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? _blue : Colors.grey.shade200, width: 1.5)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('₹${a.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: sel ? Colors.white : Colors.black87)),
                      if (a == 1500) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: sel ? Colors.white.withOpacity(0.2) : Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text('Rec.', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: sel ? Colors.white : Colors.green.shade700)))],
                    ]),
                  ),
                );
              }).toList()),
          const SizedBox(height: 12),
          // Custom
          TextField(controller: _ctrl,
            keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => setState(() { _custom = v.isNotEmpty; _sel = double.tryParse(v); }),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            decoration: InputDecoration(hintText: 'Custom amount', hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
              prefixText: '₹  ', prefixStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _blue, width: 1.5))),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: (_sel != null && _sel! > 0) ? () => widget.onAdd(_sel!, 'Razorpay') : null,
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
              child: Text(_sel != null && _sel! > 0 ? 'Add ₹${_sel!.toStringAsFixed(0)}' : 'Select an amount',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Withdraw Sheet ────────────────────────────────────────────────────────────
class _WithdrawSheet extends StatefulWidget {
  final double maxAmount;
  final String label;
  final void Function(double) onWithdraw;
  const _WithdrawSheet({required this.maxAmount, required this.label, required this.onWithdraw});
  @override State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final TextEditingController _ctrl = TextEditingController();
  double? _amount;
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isValid = _amount != null && _amount! > 0 && _amount! <= widget.maxAmount;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Withdraw ${widget.label}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Available: ₹${widget.maxAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          TextField(controller: _ctrl,
            keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => setState(() => _amount = double.tryParse(v)),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            decoration: InputDecoration(hintText: 'Enter amount', hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
              prefixText: '₹  ', prefixStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              filled: true, fillColor: Colors.grey.shade50,
              errorText: _amount != null && _amount! > widget.maxAmount ? 'Exceeds available balance' : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5))),
          ),
          const SizedBox(height: 12),
          // Presets
          Row(children: [500.0, 1000.0, widget.maxAmount].map((v) {
            final label = v == widget.maxAmount ? 'All' : '₹${v.toStringAsFixed(0)}';
            return Padding(padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { if (v <= widget.maxAmount) { _ctrl.text = v.toStringAsFixed(0); setState(() => _amount = v); } },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700)),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: isValid ? () => widget.onWithdraw(_amount!) : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
              child: Text(isValid ? 'Withdraw ₹${_amount!.toStringAsFixed(0)}' : 'Enter an amount',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
