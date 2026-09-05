import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// HyperDrop design tokens — charcoal surfaces, electric-blue primary,
/// cyan accent, violet highlight. A premium, offline-first product feel.
class HDColors {
  HDColors._();

  static const primary = Color(0xFF2E6BFF);
  static const primaryBright = Color(0xFF5B8CFF);
  static const accent = Color(0xFF22D3EE);
  static const violet = Color(0xFF8B5CF6);
  static const success = Color(0xFF16A34A);
  static const successBright = Color(0xFF34D399);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const darkBg = Color(0xFF090B10);
  static const darkSurface = Color(0xFF12151D);
  static const darkRaised = Color(0xFF181C27);
  static const darkRaised2 = Color(0xFF1E2330);
  static const darkBorder = Color(0xFF262B3A);
  static const darkBorderSoft = Color(0xFF1D2230);

  static const lightBg = Color(0xFFF4F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFF1F4F9);
  static const lightBorder = Color(0xFFE3E8F1);

  /// Signature brand gradient — used for hero panels, primary CTAs, logo mark.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E6BFF), Color(0xFF7C3AED), Color(0xFF22D3EE)],
    stops: [0.0, 0.55, 1.0],
  );

  static const brandGradientSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x332E6BFF), Color(0x1A22D3EE)],
  );
}

/// Reusable elevation shadows tuned for the dark-first UI.
class HDShadows {
  HDShadows._();

  static List<BoxShadow> card(bool dark) => [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(color: color.withOpacity(0.35), blurRadius: 28, spreadRadius: -6),
      ];
}

const _radiusLg = 20.0;
const _radiusMd = 14.0;
const _radiusSm = 10.0;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: HDColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: HDColors.primary,
    secondary: HDColors.accent,
    tertiary: HDColors.violet,
    surface: dark ? HDColors.darkSurface : HDColors.lightSurface,
    error: HDColors.danger,
    outline: dark ? HDColors.darkBorder : HDColors.lightBorder,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? HDColors.darkBg : HDColors.lightBg,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displaySmall: GoogleFonts.spaceGrotesk(
      textStyle: base.textTheme.displaySmall,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      textStyle: base.textTheme.headlineMedium,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      textStyle: base.textTheme.headlineSmall,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      textStyle: base.textTheme.titleLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      color: dark ? Colors.white.withOpacity(0.72) : Colors.black.withOpacity(0.62),
      height: 1.45,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      color: dark ? Colors.white.withOpacity(0.52) : Colors.black.withOpacity(0.5),
      height: 1.4,
    ),
  );

  final borderColor = dark ? HDColors.darkBorder : HDColors.lightBorder;

  return base.copyWith(
    textTheme: textTheme,
    canvasColor: dark ? HDColors.darkBg : HDColors.lightBg,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: dark ? Colors.white : Colors.black87),
    ),
    cardTheme: CardTheme(
      color: dark ? HDColors.darkSurface : HDColors.lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLg),
        side: BorderSide(color: borderColor),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
        side: BorderSide(color: borderColor, width: 1.4),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        foregroundColor: dark ? Colors.white : Colors.black87,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: borderColor,
      space: 1,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? HDColors.darkRaised2 : const Color(0xFF1F2430),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
      elevation: 6,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? HDColors.darkRaised : HDColors.lightRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
        borderSide: const BorderSide(color: HDColors.primary, width: 1.6),
      ),
      labelStyle: textTheme.bodyMedium,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.zero,
      iconColor: dark ? Colors.white70 : Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return HDColors.primary;
        return dark ? HDColors.darkBorder : HDColors.lightBorder;
      }),
      thumbColor: const MaterialStatePropertyAll(Colors.white),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
        selectedBackgroundColor: HDColors.primary,
        selectedForegroundColor: Colors.white,
        side: BorderSide(color: borderColor),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? HDColors.darkRaised2 : HDColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
        side: BorderSide(color: borderColor),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: dark ? HDColors.darkSurface : HDColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusLg)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: dark ? Colors.white.withOpacity(0.85) : Colors.black87,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: HDColors.primary,
      linearTrackColor: dark ? HDColors.darkRaised2 : HDColors.lightRaised,
      circularTrackColor: dark ? HDColors.darkRaised2 : HDColors.lightRaised,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? HDColors.darkSurface : HDColors.lightSurface,
      indicatorColor: HDColors.primary.withOpacity(0.16),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
      selectedIconTheme: const IconThemeData(color: HDColors.primary),
      unselectedIconTheme: IconThemeData(color: dark ? Colors.white54 : Colors.black45),
      selectedLabelTextStyle: const TextStyle(color: HDColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5),
      unselectedLabelTextStyle: TextStyle(color: dark ? Colors.white54 : Colors.black45, fontSize: 12.5),
      useIndicator: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? HDColors.darkSurface : HDColors.lightSurface,
      indicatorColor: HDColors.primary.withOpacity(0.16),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
      elevation: 0,
      height: 68,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? HDColors.primary : (dark ? Colors.white54 : Colors.black45),
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return IconThemeData(color: selected ? HDColors.primary : (dark ? Colors.white54 : Colors.black45));
      }),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? HDColors.darkRaised2 : const Color(0xFF1F2430),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

/// Panel surface used across screens — flat card with soft shadow.
class HDPanel extends StatelessWidget {
  const HDPanel({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? HDColors.darkSurface : HDColors.lightSurface,
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border.all(color: dark ? HDColors.darkBorder : HDColors.lightBorder),
        boxShadow: HDShadows.card(dark),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radiusLg),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(_radiusLg),
        child: content,
      ),
    );
  }
}

/// A hero panel with the brand gradient — used for the primary connection
/// code display and other flagship moments.
class HDHeroPanel extends StatelessWidget {
  const HDHeroPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radiusLg + 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF161B2E), const Color(0xFF11141F)]
              : [Colors.white, const Color(0xFFF4F7FF)],
        ),
        border: Border.all(color: HDColors.primary.withOpacity(dark ? 0.28 : 0.16)),
        boxShadow: HDShadows.card(dark),
      ),
      child: child,
    );
  }
}
