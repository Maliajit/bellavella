import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/professional_profile_controller.dart';

class LiveTimer extends StatefulWidget {
  final TextStyle? style;

  const LiveTimer({
    super.key,
    this.style,
  });

  @override
  State<LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<LiveTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 🔥 UI TICKER: Force rebuild every second to update the displayed time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;

    return '${h.toString().padLeft(2, '0')}:'
           '${m.toString().padLeft(2, '0')}:'
           '${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalProfileController>(
      builder: (context, controller, child) {
        return Text(
          _format(controller.remainingSeconds),
          style: widget.style,
        );
      },
    );
  }
}
