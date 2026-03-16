import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.shape = BoxShape.rectangle,
    this.margin,
    this.padding,
    this.child,
    this.baseColor = const Color(0xFFF1F3F5),
    this.highlightColor = const Color(0xFFF9FAFB),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget current = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius:
                widget.shape == BoxShape.circle ? null : widget.borderRadius,
            gradient: LinearGradient(
              begin: const Alignment(-1.6, -0.3),
              end: const Alignment(1.6, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                ((_controller.value - 0.28).clamp(0.0, 1.0) as num).toDouble(),
                (_controller.value.clamp(0.0, 1.0) as num).toDouble(),
                ((_controller.value + 0.28).clamp(0.0, 1.0) as num).toDouble(),
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child == null
          ? null
          : Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
    );

    if (widget.width != null || widget.height != null) {
      current = SizedBox(
        width: widget.width,
        height: widget.height,
        child: current,
      );
    }

    if (widget.margin != null) {
      current = Padding(
        padding: widget.margin!,
        child: current,
      );
    }

    return current;
  }
}
