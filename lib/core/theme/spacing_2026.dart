import 'package:flutter/material.dart';

/// PlaceFlex 2026 - Spacing & Layout System
/// Sistema di spaziatura basato su scale di 4px
class AppSpacing2026 {
  // ============= BASE SPACING (4px base unit) =============
  static const double unit = 4.0;

  static const double xxxs = unit * 1; // 4px
  static const double xxs = unit * 2; // 8px
  static const double xs = unit * 3; // 12px
  static const double sm = unit * 4; // 16px
  static const double md = unit * 5; // 20px
  static const double lg = unit * 6; // 24px
  static const double xl = unit * 8; // 32px
  static const double xxl = unit * 10; // 40px
  static const double xxxl = unit * 12; // 48px
  static const double huge = unit * 16; // 64px

  // ============= SEMANTIC SPACING =============
  /// Padding interno componenti
  static const double paddingTiny = xxs;
  static const double paddingSmall = xs;
  static const double paddingMedium = sm;
  static const double paddingLarge = lg;
  static const double paddingXLarge = xl;

  /// Margini tra elementi
  static const double marginTiny = xxs;
  static const double marginSmall = xs;
  static const double marginMedium = sm;
  static const double marginLarge = lg;
  static const double marginXLarge = xl;

  /// Gap per Flex layouts
  static const double gapTiny = xxs;
  static const double gapSmall = xs;
  static const double gapMedium = sm;
  static const double gapLarge = lg;

  /// Layout page padding
  static const double pageHorizontal = lg;
  static const double pageVertical = lg;

  /// Card content padding
  static const double cardPadding = lg;
  static const double cardPaddingCompact = sm;

  /// List item spacing
  static const double listItemGap = xs;
  static const double listItemPadding = sm;

  // ============= EDGE INSETS PRESETS =============
  static const EdgeInsets zero = EdgeInsets.zero;

  static const EdgeInsets allXXS = EdgeInsets.all(xxs);
  static const EdgeInsets allXS = EdgeInsets.all(xs);
  static const EdgeInsets allSM = EdgeInsets.all(sm);
  static const EdgeInsets allMD = EdgeInsets.all(md);
  static const EdgeInsets allLG = EdgeInsets.all(lg);
  static const EdgeInsets allXL = EdgeInsets.all(xl);
  static const EdgeInsets allXXL = EdgeInsets.all(xxl);

  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);

  /// Page padding standard
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );

  static const EdgeInsets pageHorizontalOnly = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );

  static const EdgeInsets pageVerticalOnly = EdgeInsets.symmetric(
    vertical: pageVertical,
  );
}

/// Border radius constants
class AppRadius2026 {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double full = 999;

  // ============= BORDER RADIUS PRESETS =============
  static BorderRadius get roundedXS => BorderRadius.circular(xs);
  static BorderRadius get roundedSM => BorderRadius.circular(sm);
  static BorderRadius get roundedMD => BorderRadius.circular(md);
  static BorderRadius get roundedLG => BorderRadius.circular(lg);
  static BorderRadius get roundedXL => BorderRadius.circular(xl);
  static BorderRadius get roundedXXL => BorderRadius.circular(xxl);
  static BorderRadius get roundedXXXL => BorderRadius.circular(xxxl);
  static BorderRadius get roundedFull => BorderRadius.circular(full);

  /// Shaped border radius (top only, bottom only)
  static BorderRadius get topRoundedLG => const BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );

  static BorderRadius get topRoundedXL => const BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );

  static BorderRadius get bottomRoundedLG => const BorderRadius.only(
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );

  static BorderRadius get bottomRoundedXL => const BorderRadius.only(
    bottomLeft: Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );
}

/// Elevation & Shadow system
class AppElevation2026 {
  /// Shadow presets based on Material Design 3
  static List<BoxShadow> get level0 => [];

  static List<BoxShadow> get level1 => [
    BoxShadow(
      color: const Color(0x0D000000),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get level2 => [
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0x0A000000),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get level3 => [
    BoxShadow(
      color: const Color(0x1A000000),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0x0D000000),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get level4 => [
    BoxShadow(
      color: const Color(0x1F000000),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get level5 => [
    BoxShadow(
      color: const Color(0x29000000),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: const Color(0x1A000000),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  /// Colored shadows for special effects
  static List<BoxShadow> colored(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: color.withOpacity(opacity * 0.5),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Glow effect
  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withOpacity(intensity),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: color.withOpacity(intensity * 0.6),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];
}

/// Icon size constants
class AppIconSize2026 {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 40;
  static const double xxl = 48;
  static const double huge = 64;
}
