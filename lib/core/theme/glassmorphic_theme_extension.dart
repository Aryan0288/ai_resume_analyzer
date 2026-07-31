import 'dart:ui';
import 'package:flutter/material.dart';

/// Custom theme extension for defining pixel-perfect glassmorphism design tokens.
class GlassmorphicThemeExtension extends ThemeExtension<GlassmorphicThemeExtension> {
  final Color midnightBg;
  final double blurRadius;
  final Border borderSubtle;

  GlassmorphicThemeExtension({
    required this.midnightBg,
    required this.blurRadius,
    required this.borderSubtle,
  });

  @override
  GlassmorphicThemeExtension copyWith({
    Color? midnightBg,
    double? blurRadius,
    Border? borderSubtle,
  }) {
    return GlassmorphicThemeExtension(
      midnightBg: midnightBg ?? this.midnightBg,
      blurRadius: blurRadius ?? this.blurRadius,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  GlassmorphicThemeExtension lerp(
    ThemeExtension<GlassmorphicThemeExtension>? other,
    double t,
  ) {
    if (other is! GlassmorphicThemeExtension) return this;
    return GlassmorphicThemeExtension(
      midnightBg: Color.lerp(midnightBg, other.midnightBg, t)!,
      blurRadius: lerpDouble(blurRadius, other.blurRadius, t)!,
      borderSubtle: Border.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}
