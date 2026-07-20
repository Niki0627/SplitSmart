import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class ShootingStarsGrid extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final bool rounded;

  const ShootingStarsGrid({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    this.minHeight = 520,
    this.rounded = false,
  });

  @override
  State<ShootingStarsGrid> createState() => _ShootingStarsGridState();
}

class _ShootingStarsGridState extends State<ShootingStarsGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.rounded ? 32 : 0),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            ),
            child: CustomPaint(
              painter: _ShootingStarsPainter(
                progress: _controller.value,
              ),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShootingStarsPainter extends CustomPainter {
  final double progress;

  const _ShootingStarsPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = true; // We can't access Theme here easily, but let's assume dark mode styling for the grid
    _paintGrid(canvas, size, isDark);
    _paintShootingStars(canvas, size, isDark);
  }

  void _paintGrid(Canvas canvas, Size size, bool isDark) {
    const gridSize = 44.0;
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintShootingStars(Canvas canvas, Size size, bool isDark) {
    final lanes = [3, 5, 7, 9, 11, 13, 16, 19];

    for (var i = 0; i < 6; i++) {
      final lane = lanes[i % lanes.length] * 44.0;
      final isHorizontal = i % 3 != 1;
      final direction = i.isEven ? 1.0 : -1.0;
      final delay = i * 0.13;
      final local = ((progress + delay) % 1.0);
      final eased = Curves.easeOut.transform(local);
      final opacity = math.sin(local * math.pi).clamp(0.0, 1.0);
      final length = 86 + _seeded(i, 15) * 132;

      final start = direction > 0 ? -length : (isHorizontal ? size.width + length : size.height + length);
      final end = direction > 0 ? (isHorizontal ? size.width + length : size.height + length) : -length;
      final position = start + (end - start) * eased;

      final startPoint = isHorizontal ? Offset(position, lane) : Offset(lane, position);
      final endPoint = isHorizontal
          ? Offset(position - direction * length, lane)
          : Offset(lane, position - direction * length);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.slate400.withValues(alpha: 0.6 * opacity),
            const Color(0xFFFFFFFF).withValues(alpha: 0.9 * opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromPoints(startPoint, endPoint))
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  double _seeded(int index, int salt) {
    final value = math.sin(index * 91.73 + salt * 37.11) * 10000;
    return value - value.floor();
  }

  @override
  bool shouldRepaint(covariant _ShootingStarsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
