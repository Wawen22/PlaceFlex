import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6759FF);
  static const Color secondary = Color(0xFF5EFCE8);
  static const Color accent = Color(0xFFFF6584);
  static const Color surface = Color(0xFFF5F5FB);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceMedium = Color(0xFF1B1F3B);
  static const Color card = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFCBD2E8);
}

class AppGradients {
  static const LinearGradient mainBackground = LinearGradient(
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF312E81),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGlow = LinearGradient(
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient action = LinearGradient(
    colors: [
      Color(0xFF6759FF),
      Color(0xFF927DFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x330F172A),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
