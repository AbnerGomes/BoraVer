import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const displayFont = 'DMSerifDisplay';
  static const bodyFont = 'Poppins';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.terracottaDark,
      onPrimary: AppColors.cream,
      primaryContainer: Color(0xFFF3D9CC),
      onPrimaryContainer: Color(0xFF5A2A18),
      secondary: AppColors.sageDark,
      onSecondary: AppColors.cream,
      secondaryContainer: Color(0xFFDDE5D6),
      onSecondaryContainer: Color(0xFF2E3A2A),
      tertiary: AppColors.goldDark,
      onTertiary: AppColors.cream,
      tertiaryContainer: Color(0xFFF4E2B9),
      onTertiaryContainer: Color(0xFF4A3608),
      error: AppColors.error,
      onError: AppColors.cream,
      errorContainer: Color(0xFFF6DAD2),
      onErrorContainer: Color(0xFF5C1A0E),
      surface: AppColors.beige,
      onSurface: AppColors.espresso,
      onSurfaceVariant: AppColors.warmGrayText,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.cream,
      surfaceContainer: AppColors.cream,
      surfaceContainerHigh: Color(0xFFF6F0E6),
      surfaceContainerHighest: AppColors.beigeDeep,
      outline: AppColors.warmGray,
      outlineVariant: AppColors.line,
      inverseSurface: AppColors.espresso,
      onInverseSurface: AppColors.cream,
      shadow: Color(0x3340352E),
    );

    // Tamanhos (englishLike) + cores (black) já combinados: assim os estilos
    // usados nos temas de componentes (AppBar, chips…) têm tamanho definido.
    final typography = Typography.material2021();
    final text = typography.englishLike
        .merge(typography.black)
        .apply(
          fontFamily: bodyFont,
          bodyColor: AppColors.espresso,
          displayColor: AppColors.espresso,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: bodyFont,
      typography: typography,
      scaffoldBackgroundColor: AppColors.beige,
      visualDensity: VisualDensity.standard,
    );

    TextStyle display(TextStyle? s) =>
        s!.copyWith(fontFamily: displayFont, fontWeight: FontWeight.w400);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.m),
    );

    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: display(text.displaySmall),
        headlineLarge: display(text.headlineLarge),
        headlineMedium: display(text.headlineMedium),
        headlineSmall: display(text.headlineSmall),
        titleLarge: text.titleLarge!.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium!.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall!.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.beige,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: const BorderSide(color: AppColors.line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: shape,
          textStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: shape,
          foregroundColor: AppColors.espresso,
          side: const BorderSide(color: AppColors.warmGray),
          textStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: shape,
          textStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.cream,
        selectedColor: scheme.primaryContainer,
        side: const BorderSide(color: AppColors.line),
        labelStyle: text.labelLarge!.copyWith(
          color: AppColors.espresso,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(
            color: AppColors.terracottaDark,
            width: 1.6,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium!.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.cream,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: text.labelLarge!.copyWith(
          color: AppColors.espresso,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelLarge!.copyWith(
          color: AppColors.warmGrayText,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.cream,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.espresso,
        contentTextStyle: text.bodyMedium!.copyWith(color: AppColors.cream),
        actionTextColor: AppColors.gold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.warmGray,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.terracottaDark,
        foregroundColor: AppColors.cream,
        elevation: 2,
      ),
    );
  }
}
