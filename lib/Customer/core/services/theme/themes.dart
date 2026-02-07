// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Cairo',

    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF42A5F5),
      surface: Colors.grey.shade200,
      onPrimary: Colors.white,
      onSecondary: Colors.grey.shade300,
      onSurface: Colors.black,
      error: Colors.redAccent,
    ),

    textTheme: ThemeData.light().textTheme
        .apply(
          fontFamily: 'Cairo',
          bodyColor: Colors.black,
          displayColor: Colors.black,
          decorationColor: Colors.black,
        )
        .copyWith(
          bodyLarge: const TextStyle(color: Colors.black, fontFamily: 'Cairo'),
          bodyMedium: const TextStyle(color: Colors.black, fontFamily: 'Cairo'),
          bodySmall: const TextStyle(color: Colors.black, fontFamily: 'Cairo'),
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.whiteBold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      hintStyle: AppTextStyles.small,
      labelStyle: const TextStyle(color: Colors.black87, fontFamily: 'Cairo'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,

      titleTextStyle: AppTextStyles.title.copyWith(
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey.shade100,
    ),
    dividerTheme: const DividerThemeData(color: Colors.grey, thickness: 0.8),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF1976D2),
      selectionColor: Color(0xFF42A5F5),
      selectionHandleColor: Color(0xFF42A5F5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.grey.shade200,
      indicatorColor: const Color(0xFF1976D2).withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.black,
          fontSize: 12.0,
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',

    scaffoldBackgroundColor: const Color(0xFF050816),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF0B1020),
      surface: Color(0xFF0B1020),
      onPrimary: Colors.black,
      onSecondary: Color(0xFF0B1020),
      onSurface: Colors.white,
      error: Colors.redAccent,
    ),

    textTheme: ThemeData.dark().textTheme
        .apply(
          fontFamily: 'Cairo',
          bodyColor: Colors.white,
          displayColor: Colors.white,
          decorationColor: Colors.white,
        )
        .copyWith(
          bodyLarge: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          bodyMedium: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          bodySmall: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.black,
        textStyle: AppTextStyles.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0B1020),
      indicatorColor: const Color(0xFF2563EB).withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white,
          fontSize: 12.0,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B1020),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.lightBlueAccent,
      selectionColor: Color(0xFF64B5F6),
      selectionHandleColor: Color(0xFF64B5F6),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF050816),
      elevation: 0,
      titleTextStyle: AppTextStyles.title.copyWith(
        color: Colors.white,
        fontFamily: 'Cairo',
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
    ),
    dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 0.8),
  );
}

