import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Colores principales - paleta minimalista
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color nearlyWhite = Color(0xFFFEFEFE);
  static const Color white = Color(0xFFFFFFFF);

  // Textos
  static const Color darkText = Color(0xFF2D3436);
  static const Color darkerText = Color(0xFF1A1A2E);
  static const Color lightText = Color(0xFF636E72);
  static const Color deactivatedText = Color(0xFFB2BEC3);

  // Acentos
  static const Color primaryAccent = Color(0xFF6C5CE7);
  static const Color secondaryAccent = Color(0xFF00CEC9);
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFE17055);

  // Colores por tipo de dispositivo
  static const Color lightColor = Color(0xFFF9CA24);
  static const Color temperatureColor = Color(0xFFFF6B6B);
  static const Color fanColor = Color(0xFF74B9FF);
  static const Color lockColor = Color(0xFFA29BFE);
  static const Color energyColor = Color(0xFF55EFC4);
  static const Color curtainColor = Color(0xFFFDA7DF);

  // Sombras
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  // Tipografía
  static const String fontName = 'WorkSans';

  static const TextTheme textTheme = TextTheme(
    displayLarge: display1,
    displayMedium: display2,
    headlineLarge: headline1,
    headlineMedium: headline2,
    headlineSmall: headline3,
    titleLarge: title1,
    titleMedium: title2,
    titleSmall: subtitle1,
    bodyLarge: body1,
    bodyMedium: body2,
    bodySmall: caption,
    labelLarge: button,
  );

  static const TextStyle display1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    letterSpacing: -0.5,
    height: 1.1,
    color: darkerText,
  );

  static const TextStyle display2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: -0.3,
    height: 1.2,
    color: darkerText,
  );

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.2,
    height: 1.3,
    color: darkerText,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: -0.1,
    height: 1.3,
    color: darkText,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    letterSpacing: 0,
    height: 1.4,
    color: darkText,
  );

  static const TextStyle title1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.1,
    height: 1.4,
    color: darkText,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0.1,
    height: 1.4,
    color: darkText,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.1,
    height: 1.5,
    color: lightText,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.2,
    height: 1.6,
    color: darkText,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.2,
    height: 1.6,
    color: darkText,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.3,
    height: 1.5,
    color: lightText,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.5,
    height: 1.4,
    color: white,
  );

  // ThemeData
  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: surface,
        error: error,
      ),
      textTheme: textTheme,
      fontFamily: fontName,
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarThemeData(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: darkText,
        titleTextStyle: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: darkText,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8ECF0),
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryAccent,
        inactiveTrackColor: primaryAccent.withValues(alpha: 0.2),
        thumbColor: primaryAccent,
        overlayColor: primaryAccent.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryAccent;
          return Colors.grey.shade300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent.withValues(alpha: 0.4);
          }
          return Colors.grey.shade200;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
