import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Cinema Modern" design system, adapted from the Stitch project
/// "NextWatch: Discover & Track".
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF200E0C);
  static const Color surfaceContainerLowest = Color(0xFF1A0908);
  static const Color surfaceContainerLow = Color(0xFF2A1614);
  static const Color surfaceContainer = Color(0xFF2E1A18);
  static const Color surfaceContainerHigh = Color(0xFF3A2522);
  static const Color surfaceVariant = Color(0xFF462F2C);

  static const Color primary = Color(0xFFFFB4AA);
  static const Color primaryContainer = Color(0xFFE50914);
  static const Color onPrimaryContainer = Color(0xFFFFF7F6);

  static const Color secondary = Color(0xFFC8C6C5);
  static const Color onSurface = Color(0xFFFFDAD5);
  static const Color onSurfaceVariant = Color(0xFFE9BCB6);
  static const Color tertiary = Color(0xFFA7C8FF);

  static const Color outline = Colors.white10;
  static const Color glowPrimary = Color(0x66E50914);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLg => GoogleFonts.montserrat(
        fontSize: 40,
        height: 48 / 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.montserrat(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.montserrat(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.montserrat(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.onSurface,
      );
}

class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 24;
  static const double full = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double base = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.background,
        primary: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSurface: AppColors.onSurface,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTextStyles.headlineLgMobile,
        titleMedium: AppTextStyles.headlineMd,
        bodyMedium: AppTextStyles.bodyMd,
        labelSmall: AppTextStyles.labelSm,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.primary),
      ),
      cardColor: AppColors.surfaceContainer,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          textStyle: AppTextStyles.headlineMd.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outline, width: 2),
          textStyle: AppTextStyles.headlineMd.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceContainer,
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppTextStyles.labelSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
    );
  }
}
