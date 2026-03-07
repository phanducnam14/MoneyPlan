import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppTheme {
  // Premium Color Palette
  static const Color primaryGradientStart = Color(0xFF6366F1); // Indigo
  static const Color primaryGradientEnd = Color(0xFF8B5CF6); // Purple
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color dangerColor = Color(0xFFEF4444); // Red

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primaryGradientStart,
      secondary: primaryGradientEnd,
      tertiary: accentColor,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFAFAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGradientStart,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGradientStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
        prefixIconColor: const Color(0xFF9CA3AF),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -1.5),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -1),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1F2937), letterSpacing: -0.5),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937), letterSpacing: 0.3),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.2),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280), height: 1.5),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF), height: 1.4),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: 0.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryGradientStart,
        inactiveTrackColor: Color(0xFFE5E7EB),
        thumbColor: primaryGradientStart,
        trackHeight: 6,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF818CF8),
      secondary: Color(0xFFA78BFA),
      tertiary: accentColor,
      surface: Color(0xFF1F2937),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1F2937),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          side: const BorderSide(color: Color(0xFF374151), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4B5563), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4B5563), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13, fontWeight: FontWeight.w500),
        prefixIconColor: const Color(0xFF9CA3AF),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB), letterSpacing: 0.2),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFD1D5DB), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF), height: 1.5),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF6B7280), height: 1.4),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        backgroundColor: const Color(0xFF1F2937),
        surfaceTintColor: const Color(0xFF1F2937),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF818CF8),
        inactiveTrackColor: Color(0xFF374151),
        thumbColor: Color(0xFF818CF8),
        trackHeight: 6,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
    );
  }
}

