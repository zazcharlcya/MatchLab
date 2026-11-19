import 'package:flutter/material.dart';

import '../services/badge_url.dart';
import '../theme/app_theme.dart';

class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.name,
    this.url,
    this.size = 36,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = BadgeUrl.displayUrl(url);
    return SizedBox(
      width: size,
      height: size,
      child: imageUrl == null
          ? _CrestFallback(size: size)
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              headers: BadgeUrl.headers,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame == null) {
                  return _CrestFallback(size: size);
                }
                return ClipOval(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.12),
                      child: child,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _CrestFallback(size: size),
            ),
    );
  }
}

/// Тихий круг вместо букв: без белого квадрата и без «FK».
class _CrestFallback extends StatelessWidget {
  const _CrestFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.badgeFill,
        border: Border.all(color: colors.badgeBorder, width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          size: size * 0.46,
          color: colors.muted,
        ),
      ),
    );
  }
}
