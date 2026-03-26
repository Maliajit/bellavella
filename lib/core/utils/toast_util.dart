import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ToastUtil {
  static OverlayEntry? _activeCartToastEntry;

  static void showAddToCartToast(BuildContext context, String itemName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showCartCelebrationOverlay(context, message: '$itemName added to cart');
  }

  static void showPackageAddedToast(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showCartCelebrationOverlay(context, message: 'Package added to cart');
  }

  static void _showCartCelebrationOverlay(
    BuildContext context, {
    required String message,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _activeCartToastEntry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CartCelebrationOverlay(
        message: message,
        onViewCart: () {
          if (entry.mounted) entry.remove();
          if (identical(_activeCartToastEntry, entry)) {
            _activeCartToastEntry = null;
          }
          if (context.mounted) context.push('/client/cart');
        },
        onComplete: () {
          if (entry.mounted) entry.remove();
          if (identical(_activeCartToastEntry, entry)) {
            _activeCartToastEntry = null;
          }
        },
      ),
    );

    _activeCartToastEntry = entry;
    overlay.insert(entry);
  }

  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(milliseconds: 1800),
      behavior: SnackBarBehavior.floating,
    ));
  }

  static void showError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(milliseconds: 1800),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ─────────────────────────────────────────────────────────────────
//  Overlay widget
// ─────────────────────────────────────────────────────────────────

class _CartCelebrationOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onViewCart;
  final VoidCallback onComplete;

  const _CartCelebrationOverlay({
    required this.message,
    required this.onViewCart,
    required this.onComplete,
  });

  @override
  State<_CartCelebrationOverlay> createState() =>
      _CartCelebrationOverlayState();
}

class _CartCelebrationOverlayState extends State<_CartCelebrationOverlay>
    with TickerProviderStateMixin {
  // ── Timeline ─────────────────────────────────────────────────────
  //
  //  0 ms ──── sprinkles burst & fade per-particle ──── 1300 ms
  //  0 ms ──────────────── fully visible ──────────── 2000 ms
  //                                    fade-out ────────────── 2450 ms
  //                                               overlay removed ── 2450 ms
  //
  static const int _particleDurationMs = 380;
  static const int _holdDurationMs     = 4550; // toast fully visible before fade
  static const int _fadeDurationMs     = 450;  // overlay fade-out duration

  late final AnimationController _particleCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _opacity;

  late final List<_SprinkleParticle> _particles;
  final GlobalKey _cardKey = GlobalKey();

  Rect? _cardRect;
  bool _started = false;
  bool _timersScheduled = false;
  bool _showParticles = true;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _particleDurationMs),
    );
    _particleCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showParticles = false;
        });
      }
    });

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _fadeDurationMs),
    );

    // 1.0 → 0.0 as _fadeCtrl goes forward
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut),
    );

    _particles = _buildParticles();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureCardBounds());
  }

  List<_SprinkleParticle> _buildParticles() {
    final rng = math.Random();

    const palette = [
      Color(0xFFE8192C), // Domino's red
      Color(0xFF006491), // Domino's blue
      Color(0xFFFFFFFF), // white
      Color(0xFFFFD700), // gold
      Color(0xFFFF6F00), // orange-red
      Color(0xFF00B4D8), // sky blue
    ];

    return List.generate(16, (i) {
      final isCircle = false;
      final isStar   = false;

      final angleDegrees = -90 + (rng.nextDouble() * 46 - 23);
      final angle    = angleDegrees * math.pi / 180;
      final distance = 90 + rng.nextDouble() * 390;
      final sideBias = rng.nextDouble() * 2 - 1;

      final end = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
      final control = Offset(
        end.dx * (0.22 + rng.nextDouble() * 0.1) + sideBias * 8,
        end.dy * (0.28 + rng.nextDouble() * 0.1) - 8 - rng.nextDouble() * 12,
      );

      final baseSize = 4.0 + rng.nextDouble() * 14;

      return _SprinkleParticle(
        width:         isCircle ? baseSize : baseSize * (0.5 + rng.nextDouble()),
        height:        isCircle ? baseSize : baseSize * (1.4 + rng.nextDouble()),
        radius:        isCircle ? baseSize / 2 : (1 + rng.nextDouble() * 2),
        color:         palette[rng.nextInt(palette.length)],
        endOffset:     end,
        controlOffset: control,
        rotationStart: rng.nextDouble() * math.pi * 2,
        rotationTurns: (rng.nextDouble() * 2.5 - 1.25) * math.pi,
        delayMs:    (i * 8 + rng.nextInt(10)).toInt(),
        durationMs: 250 + rng.nextInt(140),
        isStar:        isStar,
        starSize:      5 + rng.nextDouble() * 8,
      );
    });
  }

  void _captureCardBounds() {
    if (!mounted) return;
    final ro = _cardKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureCardBounds());
      return;
    }

    final rect = ro.localToGlobal(Offset.zero) & ro.size;
    if (_cardRect != rect) setState(() => _cardRect = rect);

    if (!_started) {
      _started = true;
      _particleCtrl.forward();
    }

    if (!_timersScheduled) {
      _timersScheduled = true;

      // Start fade-out after hold period
      Future.delayed(Duration(milliseconds: _holdDurationMs), () {
        if (mounted) _fadeCtrl.forward();
      });

      // Remove overlay exactly when fade finishes
      Future.delayed(
        Duration(milliseconds: _holdDurationMs + _fadeDurationMs),
        () { if (mounted) widget.onComplete(); },
      );
    }
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media      = MediaQuery.of(context);
    final screenSize = media.size;

    // ONE AnimatedBuilder wraps BOTH particles + card
    // → they fade out together, perfectly in sync
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Stack(
          children: [
            if (_cardRect != null && _showParticles)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: screenSize,
                      painter: _SprinklePainter(
                        progress:       _particleCtrl,
                        particles:      _particles,
                        origin: Offset(
                          _cardRect!.center.dx,
                          _cardRect!.top + (_cardRect!.height * 0.22),
                        ),
                        totalDurationMs: _particleDurationMs,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left:   16,
              right:  16,
              bottom: media.padding.bottom + 20,
              child: _CartToastCard(
                key:        _cardKey,
                message:    widget.message,
                onViewCart: widget.onViewCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Toast card
// ─────────────────────────────────────────────────────────────────

class _CartToastCard extends StatelessWidget {
  final String message;
  final VoidCallback onViewCart;

  const _CartToastCard({
    super.key,
    required this.message,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE8192C).withOpacity(0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:       const Color(0xFFE8192C).withOpacity(0.18),
              blurRadius:  24,
              spreadRadius: 2,
              offset:      const Offset(0, 8),
            ),
            const BoxShadow(
              color:      Color(0x33000000),
              blurRadius: 14,
              offset:     Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color:       Colors.white,
                  fontWeight:  FontWeight.w700,
                  fontSize:    14.5,
                  height:      1.3,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onViewCart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color:        const Color(0xFFE8192C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'View Cart',
                  style: TextStyle(
                    color:         Colors.white,
                    fontSize:      13.5,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Particle model
// ─────────────────────────────────────────────────────────────────

class _SprinkleParticle {
  final double width;
  final double height;
  final double radius;
  final Color  color;
  final Offset endOffset;
  final Offset controlOffset;
  final double rotationStart;
  final double rotationTurns;
  final int    delayMs;
  final int    durationMs;
  final bool   isStar;
  final double starSize;

  const _SprinkleParticle({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
    required this.endOffset,
    required this.controlOffset,
    required this.rotationStart,
    required this.rotationTurns,
    required this.delayMs,
    required this.durationMs,
    this.isStar   = false,
    this.starSize = 8,
  });
}

// ─────────────────────────────────────────────────────────────────
//  Painter
//  Each particle has its own smooth fade-out in the last 35% of
//  its individual lifetime — so they melt away one by one, not
//  all at once. The overlay-level Opacity then fades the whole
//  layer together at the end.
// ─────────────────────────────────────────────────────────────────

class _SprinklePainter extends CustomPainter {
  final Animation<double> progress;
  final List<_SprinkleParticle> particles;
  final Offset origin;
  final int totalDurationMs;

  _SprinklePainter({
    required this.progress,
    required this.particles,
    required this.origin,
    required this.totalDurationMs,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final elapsedMs = progress.value * totalDurationMs;

    for (final p in particles) {
      if (elapsedMs < p.delayMs) continue;

      final localT =
          ((elapsedMs - p.delayMs) / p.durationMs).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      if (localT >= 1.0) continue;

      final flightT  = Curves.easeOutCubic.transform(localT);
      final gravityT = Curves.easeInQuad.transform(localT);

      const fadeStart = 0.28;
      final particleOpacity = localT < fadeStart
          ? 1.0
          : Curves.easeOut.transform(
              1.0 - ((localT - fadeStart) / (1.0 - fadeStart)),
            );

      if (particleOpacity <= 0.005) continue;

      final position = _quadraticBezier(
        origin,
        origin + p.controlOffset,
        origin + p.endOffset + Offset(0, 10 * gravityT * gravityT),
        flightT,
      );

      final scale    = ui.lerpDouble(1.0, 0.78, localT) ?? 0.78;
      final rotation = p.rotationStart + (p.rotationTurns * flightT);
      final paint    = Paint()..color = p.color.withOpacity(particleOpacity);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);

      if (p.isStar) {
        _drawStar(canvas, paint, p.starSize * scale);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width:  p.width  * scale,
              height: p.height * scale,
            ),
            Radius.circular(p.radius),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    const spikes  = 5;
    const outerR  = 1.0;
    const innerR  = 0.42;
    final path    = Path();

    for (int i = 0; i < spikes * 2; i++) {
      final r     = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / spikes) - math.pi / 2;
      final x     = math.cos(angle) * r * size;
      final y     = math.sin(angle) * r * size;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1 - t;
    return Offset(
      (mt * mt * p0.dx) + (2 * mt * t * p1.dx) + (t * t * p2.dx),
      (mt * mt * p0.dy) + (2 * mt * t * p1.dy) + (t * t * p2.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _SprinklePainter old) =>
      old.progress != progress ||
      old.origin   != origin   ||
      old.particles != particles;
}
