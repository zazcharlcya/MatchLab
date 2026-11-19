import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Живая шапка: слово MatchLab и маленький игрок, который пинает мяч.
class MatchLabBrand extends StatelessWidget {
  const MatchLabBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        const _KickMark(width: 48, height: 38),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Match',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Lab',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Футбольная аналитика',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  color: colors.muted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KickMark extends StatefulWidget {
  const _KickMark({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_KickMark> createState() => _KickMarkState();
}

class _KickMarkState extends State<_KickMark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _KickPainter(
                t: _controller.value,
                accent: colors.accent,
                ink: colors.text,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KickPainter extends CustomPainter {
  _KickPainter({
    required this.t,
    required this.accent,
    required this.ink,
  });

  final double t;
  final Color accent;
  final Color ink;

  static double _lerp(double a, double b, double x) => a + (b - a) * x;

  static double _seg(double start, double end, double x) {
    if (x <= start) {
      return 0;
    }
    if (x >= end) {
      return 1;
    }
    return (x - start) / (end - start);
  }

  static Offset _quad(Offset a, Offset b, Offset c, double x) {
    final u = 1 - x;
    return a * (u * u) + b * (2 * u * x) + c * (x * x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60, size.height / 40);

    const meet = Offset(29.2, 32.1);
    const hipBase = Offset(13.2, 22.2);

    var hipX = hipBase.dx;
    var hipY = hipBase.dy;
    var leftA = 0.2;
    var rightA = -0.2;
    var lean = 0.0;
    var ball = const Offset(61.5, 32.1);
    var ballScale = 0.0;
    var spin = 0.0;

    final roll = Curves.easeInCubic.transform(_seg(0.08, 0.54, t));
    ballScale = Curves.easeOutCubic.transform(_seg(0.02, 0.10, t));
    final rolling = Offset(
      _lerp(61.5, meet.dx, roll),
      meet.dy - math.sin(roll * math.pi) * 0.55,
    );
    spin = (61.5 - rolling.dx) * 0.42;

    if (t < 0.46) {
      final phase = (t / 0.46) * 2.25 * math.pi * 2;
      final swing = math.sin(phase) * 0.62;
      leftA = swing;
      rightA = -swing;
      hipY = hipBase.dy - math.sin(phase).abs() * 1.55;
      hipX = hipBase.dx + math.sin(phase) * 0.45;
      lean = math.sin(phase) * 0.35;
      ball = rolling;
    } else if (t < 0.54) {
      final u = Curves.easeInOut.transform(_seg(0.46, 0.54, t));
      hipX = _lerp(hipBase.dx, 16.4, u);
      hipY = _lerp(hipBase.dy, 22.6, u);
      leftA = _lerp(0.62, 0.28, u);
      rightA = _lerp(-0.62, -1.22, u);
      lean = _lerp(0.35, -1.15, u);
      ball = rolling;
    } else if (t < 0.61) {
      final u = Curves.easeOutCubic.transform(_seg(0.54, 0.61, t));
      hipX = _lerp(16.4, 17.2, u);
      hipY = 22.6;
      leftA = 0.28;
      rightA = _lerp(-1.22, 1.08, u);
      lean = _lerp(-1.15, 1.35, u);
      ball = meet;
      ballScale = 1;
      spin = (61.5 - meet.dx) * 0.42;
    } else {
      final fly = Curves.easeOutCubic.transform(_seg(0.61, 0.88, t));
      hipX = 17.2;
      hipY = 22.6;
      leftA = 0.28;
      rightA = _lerp(1.08, 0.46, Curves.easeInOut.transform(_seg(0.61, 0.78, t)));
      lean = _lerp(1.35, 0.4, Curves.easeInOut.transform(_seg(0.61, 0.78, t)));
      ball = _quad(meet, const Offset(42, 3.8), const Offset(56.8, 15.8), fly);
      ballScale = t > 0.9 ? 1 - _seg(0.9, 1, t) : 1;
      spin = (61.5 - meet.dx) * 0.42 + fly * 4.5;
      if (t > 0.92) {
        final r = _seg(0.92, 1, t);
        hipX = _lerp(17.2, hipBase.dx, r);
        hipY = _lerp(22.6, hipBase.dy, r);
        leftA = _lerp(0.28, 0.2, r);
        rightA = _lerp(0.46, -0.2, r);
        lean = _lerp(0.4, 0, r);
      }
    }

    final hip = Offset(hipX, hipY);
    final head = Offset(hip.dx + 0.6 + lean * 0.35, 9.3);
    final left = _limb(hip, leftA, 8.3, 9.1, 0.22);
    final right = _limb(hip, rightA, 8.5, 9.3, 0.16);
    final shoulder = Offset(hip.dx, 14.4);
    final armBack = Offset(shoulder.dx - 7.2 - rightA * 1.4, 17.6);
    final armFront = Offset(shoulder.dx + 7.4 + leftA * 1.2, 17.2);

    final player = Paint()
      ..color = ink.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(head, 3.7, player);
    canvas.drawLine(Offset(head.dx, head.dy + 3.7), hip, player);
    canvas.drawLine(shoulder, armBack, player);
    canvas.drawLine(shoulder, armFront, player);
    canvas.drawLine(hip, left.$1, player);
    canvas.drawLine(left.$1, left.$2, player);
    canvas.drawLine(hip, right.$1, player);
    canvas.drawLine(right.$1, right.$2, player);

    canvas.drawLine(
      const Offset(4, 37.4),
      const Offset(56, 37.4),
      Paint()
        ..color = ink.withValues(alpha: 0.16)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    if (ballScale <= 0.02) {
      return;
    }

    canvas.save();
    canvas.translate(ball.dx, ball.dy);
    canvas.scale(ballScale);
    canvas.rotate(spin);

    canvas.drawCircle(
      Offset.zero,
      10.5,
      Paint()
        ..color = accent.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );
    canvas.drawCircle(Offset.zero, 5.15, Paint()..color = accent);

    final penta = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final p = Offset(math.cos(a) * 2.05, math.sin(a) * 2.05);
      if (i == 0) {
        penta.moveTo(p.dx, p.dy);
      } else {
        penta.lineTo(p.dx, p.dy);
      }
    }
    penta.close();
    canvas.drawPath(
      penta,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF123028).withValues(alpha: 0.28),
    );

    canvas.restore();
  }

  static (Offset, Offset) _limb(Offset hip, double angle, double thigh, double shin, double bend) {
    final knee = hip + Offset(math.sin(angle) * thigh, math.cos(angle) * thigh);
    final foot = Offset(
      knee.dx + math.sin(angle + bend) * shin,
      math.min(36.6, knee.dy + math.cos(angle + bend) * shin),
    );
    return (knee, foot);
  }

  @override
  bool shouldRepaint(covariant _KickPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.accent != accent || oldDelegate.ink != ink;
  }
}
