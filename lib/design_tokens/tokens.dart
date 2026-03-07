import 'package:flutter/material.dart';

// Central design tokens for colors, radii, elevations, and spacing
class DesignTokens {
  // Color tokens
  static const Color brandStart = Color(0xFF6366F1);
  static const Color brandEnd = Color(0xFF8B5CF6);
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color surface = Colors.white;
  static const Color danger = Color(0xFFEF4444);

  // Radius tokens (in px)
  static const double rSm = 12.0;
  static const double rMd = 14.0;
  static const double rLg = 16.0;

  // Elevation / shadows
  static const double shadowBlur = 8.0;
  static const double elevation = 6.0;

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [brandStart, brandEnd],
  );
}
