import 'package:flutter/material.dart';

class AppColors {
  // Bảng màu Trắng - Đen Tương Phản Hiện Đại (Modern High-Contrast Monochrome)
  static const Color primary = Color(0xFF09090B); // Đen Obsidian nguyên bản
  static const Color primaryDark = Color(0xFF000000); // Đen tuyệt đối
  static const Color primaryLight = Color(0xFF27272A); // Xám than chì (Zinc 800)
  static const Color primarySoft = Color(0xFFF4F4F5); // Xám trắng nhạt (Zinc 100)
  static const Color accent = Color(0xFF18181B); // Đen ánh kim (Zinc 900)
  static const Color background = Color(0xFFFAFAFA); // Trắng Gallery hiện đại
  static const Color surface = Colors.white;
  static const Color inputFill = Color(0xFFF4F4F5);
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color success = Color(0xFF18181B);
  static const Color error = Color(0xFFDC2626);
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderLight = Color(0xFFF4F4F5);

  // Gradients Trắng - Đen hiện đại
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF18181B), Color(0xFF27272A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
