import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class AppThemes {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.hot,
      ),
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.syne(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        surface: AppColors.lightSurface,
        error: AppColors.hot,
      ),
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.syne(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
