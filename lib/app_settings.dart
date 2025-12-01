import 'package:flutter/material.dart';

enum AvatarShape { circle, rounded, square }

enum AppTitleFontStyle { regular, elegant, bold }

class AppSettings extends ChangeNotifier {
  bool isArabic = true;

  void toggleLanguage() {
    isArabic = !isArabic;
    notifyListeners();
  }

  bool showAppTitle = true;
  AppTitleFontStyle appTitleFontStyle = AppTitleFontStyle.elegant;
  AvatarShape avatarShape = AvatarShape.circle;
  double blurLevel = 4;
  bool isDarkMode = false;

  void setShowAppTitle(bool value) {
    showAppTitle = value;
    notifyListeners();
  }

  void setAppTitleFontStyle(AppTitleFontStyle style) {
    appTitleFontStyle = style;
    notifyListeners();
  }

  void setAvatarShape(AvatarShape shape) {
    avatarShape = shape;
    notifyListeners();
  }

  void setBlurLevel(double value) {
    blurLevel = value;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  TextStyle get appBarTitleTextStyle {
    switch (appTitleFontStyle) {
      case AppTitleFontStyle.regular:
        return const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        );
      case AppTitleFontStyle.elegant:
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        );
      case AppTitleFontStyle.bold:
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
        );
    }
  }
}
