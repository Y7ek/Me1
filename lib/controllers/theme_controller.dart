// lib/controllers/theme_controller.dart
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  /// ثيم فاتح للتطبيق
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        backgroundColor: const Color(0xFFF5F5F5),
      ).copyWith(
        secondary: const Color(0xFF007AFF),
      ),
      useMaterial3: true,
    );
  }

  /// ثيم داكن للتطبيق
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFF0EA5E9),
        background: Color(0xFF000000),
      ),
      useMaterial3: true,
    );
  }

  /// Gradient عام نستخدمه في شاشات مثل chats
  List<Color> get currentGradient {
    if (_isDark) {
      return const [
        Color(0xFF020617),
        Color(0xFF0F172A),
      ];
    } else {
      return const [
        Color(0xFFF9FAFB),
        Color(0xFFE5E7EB),
      ];
    }
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}