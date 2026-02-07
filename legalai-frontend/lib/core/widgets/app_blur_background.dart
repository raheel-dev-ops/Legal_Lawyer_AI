import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_palette.dart';
import '../preferences/preferences_providers.dart';

class AppBlurBackground extends ConsumerWidget {
  final Widget child;

  const AppBlurBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseTop = isDark ? AppPalette.backgroundDark : AppPalette.backgroundLight;
    final baseBottom = isDark ? AppPalette.surfaceVariantDark : AppPalette.surfaceVariantLight;
    final safeMode = ref.watch(safeModeProvider);
    final media = MediaQuery.of(context);
    final isSmallScreen = media.size.shortestSide < 600;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final reduceEffects = safeMode ||
        media.disableAnimations ||
        kIsWeb ||
        isSmallScreen ||
        (kDebugMode && isAndroid);
    final glowOpacityScale = reduceEffects ? 0.55 : 1.0;
    final glowScale = reduceEffects ? 0.8 : 1.0;
    final blurSigma = reduceEffects ? 0.0 : 12.0;

    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [baseTop, baseBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (!reduceEffects)
            _GlowSpot(
              alignment: Alignment.topRight,
              size: 420 * glowScale,
              opacity: 0.14 * glowOpacityScale,
            ),
          if (!reduceEffects)
            _GlowSpot(
              alignment: Alignment.bottomLeft,
              size: 360 * glowScale,
              opacity: 0.12 * glowOpacityScale,
            ),
          if (blurSigma > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: Container(
                      color: isDark ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GlowSpot extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final double opacity;

  const _GlowSpot({
    required this.alignment,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = alignment == Alignment.topRight ? AppPalette.primary : AppPalette.secondary;
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(isDark ? opacity : opacity * 0.9),
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
