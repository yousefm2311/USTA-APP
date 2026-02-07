// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  static const _font = 'Cairo';

  /// ☀️ Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF42A5F5),
      surface: Colors.grey.shade200,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      error: Colors.redAccent,
    ),

    // Global TextTheme (Cairo + colors)
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: _font,
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),

    // 🔘 Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          inherit: false,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),

    // ✏️ Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      hintStyle: TextStyle(
        fontFamily: _font,
        fontSize: 14,
        color: Colors.black.withOpacity(0.55),
      ),
      labelStyle: const TextStyle(fontFamily: _font, color: Colors.black87),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.2),
      ),
    ),

    // 📱 AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        fontFamily: _font,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),

    // 📜 BottomSheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey.shade100,
    ),

    // 🧱 Divider
    dividerTheme: const DividerThemeData(color: Colors.grey, thickness: 0.8),

    // Text selection
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF1976D2),
      selectionColor: Color(0xFF42A5F5),
      selectionHandleColor: Color(0xFF42A5F5),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.grey.shade200,
      indicatorColor: const Color(0xFF1976D2).withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontFamily: _font, color: Colors.black, fontSize: 12.0),
      ),
    ),
  );

  /// 🌙 Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: const Color(0xFF050816),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF0B1020),
      surface: Color(0xFF0B1020),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: Colors.redAccent,
    ),

    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: _font,
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          inherit: false,
          fontSize: 18,
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
        const TextStyle(fontFamily: _font, color: Colors.white, fontSize: 12.0),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B1020),
      hintStyle: TextStyle(
        fontFamily: _font,
        fontSize: 14,
        color: Colors.white.withOpacity(0.55),
      ),
      labelStyle: TextStyle(
        fontFamily: _font,
        color: Colors.white.withOpacity(0.85),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.lightBlueAccent,
      selectionColor: Color(0xFF64B5F6),
      selectionHandleColor: Color(0xFF64B5F6),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF050816),
      elevation: 0,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: _font,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
    ),

    dividerTheme: const DividerThemeData(color: Colors.white24, thickness: 0.8),
  );
}
