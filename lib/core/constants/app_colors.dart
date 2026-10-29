import 'package:flutter/material.dart';

class AppColors {
  // Bảng màu Trắng - Đen Tối Giản (Minimalist Monochrome Black & White)
  static const Color primary = Color(0xFF09090B); // Đen nguyên bản (Zinc 950)
  static const Color primaryDark = Color(0xFF000000); // Đen tuyệt đối
  static const Color primaryLight = Color(0xFF27272A); // Xám đen (Zinc 800)
  static const Color primarySoft = Color(0xFFF4F4F5); // Trắng xám nhẹ (Zinc 100)
  static const Color accent = Color(0xFF3F3F46); // Xám chì (Zinc 700)
  static const Color background = Color(0xFFFAFAFA); // Trắng tối giản
  static const Color surface = Colors.white;
  static const Color inputFill = Color(0xFFF4F4F5);
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color success = Color(0xFF18181B);
  static const Color error = Color(0xFFDC2626);
  static const Color border = Color(0xFFD4D4D8);
  static const Color borderLight = Color(0xFFE4E4E7);

  // Gradients Trắng - Đen Tối Giản
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF18181B), Color(0xFF27272A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmAccentGradient = LinearGradient(
    colors: [Color(0xFF18181B), Color(0xFF3F3F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
