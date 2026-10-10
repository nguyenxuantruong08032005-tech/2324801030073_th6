import 'package:flutter/material.dart';

class MelodyColors {
  MelodyColors._();

  static const primary = Color(0xFF7757B9);
  static const ink = Color(0xFF292136);
  static const muted = Color(0xFF7C7488);
  static const background = Color(0xFFF8F7FB);
  static const lavender = Color(0xFFF0EBF8);
  static const border = Color(0xFFE9E5EF);
  static const dark = Color(0xFF251A39);
  static const rose = Color(0xFFCB6486);
}

class MelodyTheme {
  MelodyTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: MelodyColors.primary,
      surface: Colors.white,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: MelodyColors.border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: MelodyColors.background,
      textTheme: base.textTheme.apply(
        bodyColor: MelodyColors.ink,
        displayColor: MelodyColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: MelodyColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: MelodyColors.ink,
        titleTextStyle: base.textTheme.titleLarge!.copyWith(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: MelodyColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFCFBFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: const TextStyle(color: MelodyColors.muted, fontSize: 14),
        hintStyle: const TextStyle(color: MelodyColors.muted, fontSize: 14),
        prefixIconColor: MelodyColors.muted,
        suffixIconColor: MelodyColors.muted,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: MelodyColors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MelodyColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          textStyle: base.textTheme.labelLarge!.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MelodyColors.ink,
          backgroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          side: const BorderSide(color: MelodyColors.border),
          textStyle: base.textTheme.labelLarge!.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MelodyColors.primary,
          textStyle: base.textTheme.labelLarge!.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        indicatorColor: MelodyColors.lavender,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return base.textTheme.labelMedium!.copyWith(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? MelodyColors.primary : MelodyColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? MelodyColors.primary
                : MelodyColors.muted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: MelodyColors.border,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MelodyColors.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
