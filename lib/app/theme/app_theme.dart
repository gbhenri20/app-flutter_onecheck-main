import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual OneCheck: fundo azul-marinho, cartões escuros e ação em azul.
class AppTheme {
  static const brandGreen = Color(0xFF3DDC97);
  static const brandBlue = Color(0xFF3B82F6);
  static const brandBlueHover = Color(0xFF60A5FA);
  static const brandInk = Color(0xFF0B1220);
  static const brandCard = Color(0xFF141C2F);
  static const brandInput = Color(0xFF10192B);
  static const brandBorder = Color(0xFF2A3854);
  static const brandMuted = Color(0xFF93A4C3);
  static const brandDanger = Color(0xFFF07178);

  static const radius = 14.0;

  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? brandCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: brandBorder),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: brandGreen,
      onSecondary: Color(0xFF06281A),
      surface: brandInk,
      onSurface: Colors.white,
      onSurfaceVariant: brandMuted,
      error: brandDanger,
      onError: Colors.white,
      outline: brandBorder,
      outlineVariant: brandBorder,
      surfaceContainerHigh: brandCard,
      surfaceContainerHighest: Color(0xFF1B2740),
    );
    final textTheme = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);
    final display = GoogleFonts.soraTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: brandInk,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme.copyWith(
        displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: Colors.white),
        bodySmall: textTheme.bodySmall?.copyWith(color: brandMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brandInk,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: brandCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: brandBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: brandCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: brandBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: brandBorder, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brandInput,
        hintStyle: const TextStyle(color: brandMuted),
        labelStyle: const TextStyle(color: brandMuted),
        prefixIconColor: brandMuted,
        suffixIconColor: brandMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brandBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brandBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brandBlue, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brandDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brandDanger, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brandBlue.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandCard,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: brandBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brandCard,
        indicatorColor: brandBlue.withValues(alpha: 0.22),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF0E1728),
        indicatorColor: brandBlue.withValues(alpha: 0.22),
        selectedIconTheme: const IconThemeData(color: brandBlue),
        unselectedIconTheme: const IconThemeData(color: brandMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: brandMuted),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: brandCard,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brandCard,
        selectedColor: brandBlue.withValues(alpha: 0.22),
        side: const BorderSide(color: brandBorder),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brandBlue),
      iconTheme: const IconThemeData(color: brandMuted),
    );
  }
}
