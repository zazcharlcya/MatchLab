import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({
    super.key,
    required this.home,
    required this.draw,
    required this.away,
  });

  final double home;
  final double draw;
  final double away;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(flex: _flex(home), child: Container(color: AppColors.accent)),
                Expanded(flex: _flex(draw), child: Container(color: AppColors.muted)),
                Expanded(
                  flex: _flex(away),
                  child: Container(color: const Color(0xFF4C8DFF)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('П1', home, AppColors.accent),
            _label('X', draw, AppColors.muted),
            _label('П2', away, const Color(0xFF4C8DFF)),
          ],
        ),
      ],
    );
  }

  int _flex(double value) => ((value * 1000).round()).clamp(1, 1000);

  Widget _label(String title, double value, Color color) {
    return Text(
      '$title ${percent(value)}',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}
