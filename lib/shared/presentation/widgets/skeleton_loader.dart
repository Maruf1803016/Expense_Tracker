import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

/// Soft shimmer skeleton loader matching luxury dark & light themes.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  const SkeletonLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 14,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  const SkeletonLoader.line({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = context.isDark ? const Color(0xFF1E2F24) : const Color(0xFFE5ECE7);
    final highlightColor = context.isDark ? const Color(0xFF283F31) : const Color(0xFFF2F6F3);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                baseColor.withValues(alpha: _animation.value),
                highlightColor.withValues(alpha: _animation.value),
                baseColor.withValues(alpha: _animation.value),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}
