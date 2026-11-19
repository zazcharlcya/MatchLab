import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Золотая монетка «MB» с кантом.
class MbCoin extends StatelessWidget {
  const MbCoin({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoldCoinPainter(),
        child: Center(
          child: Text(
            'MB',
            style: TextStyle(
              color: const Color(0xFF5C3A00),
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.3,
              shadows: const [
                Shadow(
                  color: Color(0x66FFF6C8),
                  offset: Offset(0, 0.4),
                  blurRadius: 0.4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center.translate(0, 0.7),
      radius,
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.38, -0.42),
          radius: 1.05,
          colors: [
            Color(0xFFFFF6C4),
            Color(0xFFF0C63D),
            Color(0xFFC48A10),
            Color(0xFF8D5A08),
          ],
          stops: [0.0, 0.42, 0.82, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final side = size.width;

    canvas.drawCircle(
      center,
      radius - 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.08
        ..color = const Color(0xFF7A4E06),
    );

    canvas.drawCircle(
      center,
      radius - side * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.045
        ..color = const Color(0xCC9A640C),
    );

    canvas.drawCircle(
      center,
      radius - side * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.02
        ..color = const Color(0x88FFF3B0),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - side * 0.08),
      -2.5,
      1.15,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.07
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x88FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Овальный чип: баллы слева, золотая монетка справа.
class MbCoinChip extends StatelessWidget {
  const MbCoinChip({super.key});

  @override
  Widget build(BuildContext context) {
    var points = 0;
    try {
      points = context.watch<ProfileViewModel>().stats.points;
    } catch (_) {
      points = 0;
    }
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
        decoration: BoxDecoration(
          color: colors.accentDim,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$points',
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const MbCoin(size: 26),
          ],
        ),
      ),
    );
  }
}
