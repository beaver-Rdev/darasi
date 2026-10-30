import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const cream = Color(0xFFFDF8F0); // الخلفية: أبيض كريمي
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE8E0D5);
  static const text = Color(0xFF2C2C2C);
  static const muted = Color(0xFF6B6B6B);
  static const accent = Color(0xFF2E7D32);
  static const grass = Color(0xFF1B5E20); // أخضر عشبي داكن (أعلى مستوى في الخريطة)
  static const grassLight = Color(0xFFC8E6C9);
  static const warn = Color(0xFFB26A00);
  static const danger = Color(0xFFB3261E);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.accent)
      .copyWith(surface: AppColors.cream);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: GoogleFonts.cairoTextTheme()
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.grassLight,
      side: const BorderSide(color: AppColors.line),
      showCheckmark: false,
      labelStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

InputDecoration inputDeco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
