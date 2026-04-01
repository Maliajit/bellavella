// ignore_for_file: deprecated_member_use
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/theme/app_colors.dart';
import 'package:bellavella/features/client/profile/services/client_profile_api_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scratcher/scratcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  ScratchCardScreen — Entry point (The Cards List)
// ══════════════════════════════════════════════════════════════════════════════
class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  List<ScratchCard> _cards = [];
  int _walletBalance = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 🕵️ Debug: Check both wallet and dedicated scratch cards API
      final walletData = await ClientProfileApiService.getWallet();
      final wallet = Wallet.fromJson(walletData);
      
      final cardsList = await ClientProfileApiService.getScratchCards();
      
      // 🏆 Show everything for debugging transparency
      if (mounted) {
        setState(() {
          _cards = cardsList; // Direct unfiltered assignment
          _walletBalance = wallet.balance;
          _isLoading = false;
        });
        debugPrint("💎 UI: Displaying ${_cards.length} cards in Grid");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cards = []; // 🛡️ Safe fallback
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openScratchPlay(ScratchCard card) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScratchPlayScreen(card: card),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );

    if (result != null && mounted) {
      // 🏆 UPDATED: Instant UI Update (GPay-style)
      if (result is Map<String, dynamic>) {
        final newBalance = result['new_balance'] ?? result['wallet_balance'];
        if (newBalance != null) {
          setState(() {
            _walletBalance = (newBalance as num).toInt();
          });
        }
      }

      // Reward was collected, remove card from list
      setState(() {
        _cards.removeWhere((c) => c.id == card.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Scratch Cards',
            style: GoogleFonts.outfit(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D6D))) 
        : _error != null
            ? _buildError()
            : _cards.isEmpty 
                ? _buildEmpty() 
                : _buildGPayList(),
    );
  }

  Widget _buildGPayList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// 💰 TOP BANNER
        _buildTopBanner(),

        const SizedBox(height: 24),

        /// 🎴 SCRATCH CARDS
        Text(
          "Available Rewards",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _cards.length,
          itemBuilder: (context, index) {
            final card = _cards[index];
            return _StaggeredEntry(
              delayMs: 100 + (index * 80),
              child: _buildGridCard(card),
            );
          },
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0.9, end: 1.1),
              curve: Curves.easeInOutSine,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: const Text('🎁', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text('All Caught Up!',
                style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              "You've scratched all your cards.\nCheck back after your next booking!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.black45, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            
            // 🚀 The Engagement Loop: Actionable CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.clientHome),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D6D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Book a Service', 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 24),
            // 🎁 The Future Reward Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D6D).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🎁 Complete a booking to unlock new rewards',
                style: GoogleFonts.outfit(
                    color: const Color(0xFFFF4D6D),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.black12, size: 52),
          const SizedBox(height: 16),
          Text('Could not load rewards',
              style: GoogleFonts.outfit(color: Colors.black38, fontSize: 15)),
          const SizedBox(height: 20),
          TextButton(onPressed: _loadCards, child: const Text('Retry')),
        ],
      ),
    );
  }
  Widget _buildTopBanner() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5E548E), Color(0xFF4A4075)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E548E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Cashback won",
                style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "₹$_walletBalance",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 36),
          ),
        ],
      ),
    );
  }

  /// 🎴 Scratch Card Item: Grid Style
  Widget _buildGridCard(ScratchCard card) {
    return GestureDetector(
      onTap: () => _openScratchPlay(card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4D6D), Color(0xFFFF758F)], // App Theme Pink
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Icon(Icons.card_giftcard_rounded, 
                color: Colors.white.withOpacity(0.1), size: 100),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SCRATCH",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "& WIN",
                    style: GoogleFonts.outfit(
                      color: Color(0xFFFFD1D8),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ScratchPlayScreen — Dedicated Scratch Surface
// ══════════════════════════════════════════════════════════════════════════════
// 🛡️ Global Animation Helper: Ensures crash-free animations even with elastic overshoots
double _safeOpacity(double value) => value.clamp(0.0, 1.0);

class ScratchPlayScreen extends StatefulWidget {
  final ScratchCard card;
  const ScratchPlayScreen({super.key, required this.card});

  @override
  State<ScratchPlayScreen> createState() => _ScratchPlayScreenState();
}

class _ScratchPlayScreenState extends State<ScratchPlayScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confetti;
  late AudioPlayer _audio;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceScale;

  late AnimationController _panelCtrl;
  late Animation<Offset> _panelSlide;

  late AnimationController _pulseCtrl;    // general prompt pulse
  late AnimationController _tapPulseCtrl; // activation layer pulse
  late AnimationController _coinCtrl;     // coin particle shower

  bool _revealed = false;
  bool _isProcessing = false;
  bool _isActivated = false;
  double _progress = 0;
  bool _userHasStarted = false;
  Map<String, dynamic>? _scratchedData;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _audio = AudioPlayer();

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _bounceScale = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);

    _panelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _tapPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _coinCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _audio.dispose();
    _bounceCtrl.dispose();
    _panelCtrl.dispose();
    _pulseCtrl.dispose();
    _tapPulseCtrl.dispose();
    _coinCtrl.dispose();
    super.dispose();
  }

  Future<void> _onThreshold() async {
    if (_revealed || _isProcessing) return;
    setState(() => _isProcessing = true);

    // 🏆 STEP 1: The Big Bang (Elite Multi-stage Haptics)
    _audio.stop(); // Stop any looping scratch sounds
    _audio.play(AssetSource('audio/win.mp3')).ignore();
    
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    
    _confetti.play();
    
    // 🎧 Trigger Coin Shower Sound with a slight offset
    Future.delayed(const Duration(milliseconds: 350), () {
      _audio.play(AssetSource('audio/coin.mp3'), volume: 0.6).ignore();
    });

    try {
      final response = await ClientProfileApiService.scratchCard(widget.card.id);

      if (mounted) {
        setState(() {
          _revealed = true;
          _isProcessing = false;
          _scratchedData = response;
        });
        HapticFeedback.lightImpact(); // 🔥 Crisp reveal confirmation
      }

      // 🏆 STEP 2: The Visual Transformation
      
      // Delay reward bounce for impact
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) _bounceCtrl.forward();

      // 🏆 STEP 3: The Reward Panel Slide-up (with GPay-style Reveal Delay)
      await Future.delayed(const Duration(milliseconds: 700)); // Increased from 550 for polish
      if (mounted) {
        _panelCtrl.forward();
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _collect() => Navigator.pop(context, _scratchedData);
  void _cancel() => Navigator.pop(context, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── The Starry Backdrop (Refined for light theme) ─────────────────
          const _StarField(),

          // ── The Main Interaction Area ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildScratchArea()),
              ],
            ),
          ),

          // ── Sensory Layers (Confetti & Coins) ───────────────────────────
          if (_revealed)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _coinCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _CoinShowerPainter(_coinCtrl.value),
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              maxBlastForce: 25,
              minBlastForce: 10,
              colors: const [AppColors.primary, AppColors.primaryDark, Colors.amber, Colors.orange],
            ),
          ),

          if (_revealed)
            SlideTransition(position: _panelSlide, child: _buildRewardPanel()),

          if (_isProcessing)
            Positioned.fill(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
            onPressed: _revealed ? _collect : _cancel,
          ),
          Text('Scratch Card',
              style: GoogleFonts.outfit(
                  color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildScratchArea() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Prompt
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Opacity(
                opacity: _revealed ? 0 : (0.5 + 0.5 * _pulseCtrl.value),
                child: Text(
                  _isProcessing
                      ? 'Confirming reward...'
                      : _userHasStarted
                          ? '${_progress.toInt()}% revealed — keep going!'
                          : 'Use your finger to scratch ✨',
                  style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // The Card
            _buildInteractiveCard(),

            const SizedBox(height: 32),
            if (!_revealed) _buildProgressBar(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCard() {
    final glowPct = (_progress / 40.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4 + (glowPct * 0.3)),
            blurRadius: 40 + (glowPct * 20),
            spreadRadius: 2 + (glowPct * 4),
            offset: Offset(0, 10 - (glowPct * 4)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // ── The Scratcher Layer ───────────────────────────────────────
            Scratcher(
              brushSize: 60,
              threshold: 40,
              color: const Color(0xFFE5E7EB), // Branded Silver/Grey Surface
              onScratchStart: () {
                if (!_userHasStarted) {
                  _audio.play(AssetSource('audio/scratch.mp3'), volume: 0.4).ignore();
                }
              },
              onChange: (v) {
                if (mounted) {
                  setState(() {
                    _progress = v;
                    if (v > 3) _userHasStarted = true;
                  });
                  // Multi-level Haptic feedback: Every 10%
                  if (v.toInt() % 10 == 0) {
                    HapticFeedback.selectionClick();
                  }
                  // Intensity spike as reward is almost revealed
                  if (v > 85 && v.toInt() % 2 == 0) {
                    HapticFeedback.lightImpact();
                  }
                }
              },
              onThreshold: _onThreshold,
              child: _buildHiddenReward(),
            ),

            // ── The Shimmering Polish (Diagonal Reflection) ──────────────────
            // Creates that "reflective metallic" beam of light effect
            if (!_userHasStarted && !_revealed)
              IgnorePointer(
                child: Stack(
                  children: [
                    // ✨ SUBTLE LIGHT REFLECTION (User Suggested Shine)
                    Positioned(
                      top: -30,
                      left: -20,
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.white.withOpacity(0.0),
                      highlightColor: Colors.white.withOpacity(0.35),
                      period: const Duration(seconds: 2),
                      child: Container(
                        width: double.infinity,
                        height: 340,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white,
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.35, 0.5, 0.65],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Activation layer
            if (!_isActivated && !_revealed)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isActivated = true);
                  },
                  child: Container(
                    color: Colors.white.withOpacity(0.12), // Subtle light mask
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _tapPulseCtrl,
                        builder: (_, __) => Opacity(
                          opacity: 0.8 + (0.2 * _tapPulseCtrl.value),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)),
                                child: const Icon(Icons.touch_app_rounded,
                                    color: AppColors.primary, size: 36),
                              ),
                              const SizedBox(height: 20),
                              Text('TAP TO ACTIVATE',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenReward() {
    return Container(
      width: double.infinity,
      height: 340,
      color: const Color(0xFFF9FAFB), // Soft modern light surface
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0xFFFFEEAA), Color(0xFFFFBB00)])),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 28),
          Text('YOU WON',
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w900, color: Colors.amber.shade900)),
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _bounceScale,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.05),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutSine,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Text('₹${widget.card.amount}',
                  style: GoogleFonts.outfit(
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: AppColors.textDark)),
            ),
          ),
          Text('BellaVella Coins',
              style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textGrey)),
          
          // 💰 Immediate Coin Feedback
          if (_revealed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+₹${widget.card.amount} added',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final pct = (_progress / 40.0).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 8,
        backgroundColor: Colors.black.withOpacity(0.05),
        valueColor: AlwaysStoppedAnimation(pct < 0.7 ? AppColors.primary : Colors.green),
      ),
    );
  }

  Widget _buildRewardPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('You Won ₹${widget.card.amount}',
                style: GoogleFonts.outfit(
                    fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Added to your BellaVella wallet',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _collect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text('Collect Rewards 🙌',
                    style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Helper Widgets & Painters
// ══════════════════════════════════════════════════════════════════════════════

class _StaggeredEntry extends StatelessWidget {
  final int delayMs;
  final Widget child;
  const _StaggeredEntry({required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delayMs),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: _safeOpacity(value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _GlowingCardPreview extends StatefulWidget {
  final ScratchCard card;
  final VoidCallback onTap;
  const _GlowingCardPreview({required this.card, required this.onTap});

  @override
  State<_GlowingCardPreview> createState() => _GlowingCardPreviewState();
}

class _GlowingCardPreviewState extends State<_GlowingCardPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B00), Color(0xFFCC0066), Color(0xFF8B00CC)],
              stops: [0, 0.5, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1.55,
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                      const Spacer(),
                      Text('Scratch & Win',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      Text('Win up to ₹100 instantly',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                            Text('Tap to Scratch',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Reuse existing StarField and CoinShower from previous turn implementation --
class _StarField extends StatefulWidget {
  const _StarField();
  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(painter: _StarPainter(_ctrl.value)),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);
  static final _rng = Random(42);
  static final _stars = List.generate(45, (i) => (x: _rng.nextDouble(), y: _rng.nextDouble(), r: _rng.nextDouble() * 1.5 + 0.3, phase: _rng.nextDouble()));
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in _stars) {
      paint.color = Colors.white.withOpacity(0.06 + 0.15 * (0.5 + 0.5 * sin((t + s.phase) * pi * 2)));
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }
  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _CoinShowerPainter extends CustomPainter {
  final double progress;
  _CoinShowerPainter(this.progress);
  static final _rng = Random(7);
  static final _coins = List.generate(24, (i) => _CoinParticle(x: _rng.nextDouble(), startY: -0.1, speed: 0.15 + _rng.nextDouble() * 0.2, size: 10 + _rng.nextDouble() * 10, opacity: 0.4, wobble: 30, phase: _rng.nextDouble()));
  @override
  void paint(Canvas canvas, Size size) {
    for (final c in _coins) {
      final t = (progress + c.phase) % 1.0;
      final px = c.x * size.width + sin(t * pi * 5) * c.wobble;
      final py = (c.startY + t * 1.2) * size.height;
      if (py < 0 || py > size.height) continue;
      canvas.drawCircle(Offset(px, py), c.size / 2, Paint()..color = Colors.amber.withOpacity(0.5 * (1 - t)));
    }
  }
  @override
  bool shouldRepaint(_CoinShowerPainter old) => old.progress != progress;
}

class _CoinParticle {
  final double x, startY, speed, size, opacity, wobble, phase;
  const _CoinParticle({required this.x, required this.startY, required this.speed, required this.size, required this.opacity, required this.wobble, required this.phase});
}
