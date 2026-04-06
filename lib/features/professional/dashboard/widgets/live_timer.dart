import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LiveTimer extends StatefulWidget {
  final DateTime? startTime;
  final TextStyle? style;

  const LiveTimer({
    super.key,
    required this.startTime,
    this.style,
  });

  @override
  State<LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<LiveTimer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  late Duration _baseElapsed;
  late DateTime _initialNow;
  int _lastSecond = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTimer();

    _ticker = createTicker((_) {
      if (!mounted || widget.startTime == null) return;

      final now = DateTime.now();
      final seconds = now.difference(widget.startTime!).inSeconds;

      // ✅ CPU OPTIMIZATION: Only update UI once per second
      if (seconds != _lastSecond) {
        _lastSecond = seconds;
        setState(() {
          _elapsed = _baseElapsed + now.difference(_initialNow);
        });
      }
    });

    if (widget.startTime != null) {
      _ticker.start();
    }
  }

  void _initializeTimer() {
    _initialNow = DateTime.now();
    if (widget.startTime != null) {
      _baseElapsed = _initialNow.difference(widget.startTime!);
    } else {
      _baseElapsed = Duration.zero;
    }
    _lastSecond = -1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("⏱️ LiveTimer: Resumed from background. Re-syncing clock...");
      _initializeTimer();
    }
  }

  @override
  void didUpdateWidget(covariant LiveTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔥 Important: reset if startTime changes (e.g. toggle online/offline)
    if (oldWidget.startTime != widget.startTime) {
      _initializeTimer();
      if (widget.startTime != null && !_ticker.isActive) {
        _ticker.start();
      } else if (widget.startTime == null && _ticker.isActive) {
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  String _format() {
    if (widget.startTime == null) return "00:00:00";

    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Text(_format(), style: widget.style);
  }
}
