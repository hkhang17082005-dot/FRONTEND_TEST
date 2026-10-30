import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBackgroundPreset {
  final String id;
  final String name;
  final String description;
  final Color backgroundColor; // Nền toàn bộ màn hình ứng dụng
  final Color cardColor;       // Nền các hộp / Card nội dung
  final Color primaryColor;    // Màu nút bấm và điểm nhấn
  final Color primaryDark;     // Màu nhấn tiêu đề
  final Color primarySoft;     // Màu nền nhạt cho chip/badge
  final Color textColor;       // Màu chữ chính
  final Color subtextColor;    // Màu chữ phụ
  final Color borderColor;     // Màu đường kẻ viền
  final bool isDark;

  const AppBackgroundPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.cardColor,
    required this.primaryColor,
    required this.primaryDark,
    required this.primarySoft,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    this.isDark = false,
  });
}

class AppSettingsController extends ChangeNotifier {
  static final AppSettingsController instance = AppSettingsController._internal();
  AppSettingsController._internal();

  double _fontScale = 1.0;
  bool _isDarkMode = false;
  int _backgroundThemeIndex = 0;

  double get fontScale => _fontScale;
  bool get isDarkMode => _isDarkMode;
  int get backgroundThemeIndex => _backgroundThemeIndex;

  static const List<AppBackgroundPreset> backgroundPresets = [
    AppBackgroundPreset(
      id: 'clean_white',
      name: 'Trắng Sáng Tối Giản',
      description: 'Nền trắng kem thanh lịch, hiện đại chuẩn Minimalist',
      backgroundColor: Color(0xFFF8FAFC),
      cardColor: Colors.white,
      primaryColor: Color(0xFF2563EB),
      primaryDark: Color(0xFF1E40AF),
      primarySoft: Color(0xFFEFF6FF),
      textColor: Color(0xFF0F172A),
      subtextColor: Color(0xFF64748B),
      borderColor: Color(0xFFE2E8F0),
    ),
    AppBackgroundPreset(
      id: 'ocean_blue',
      name: 'Xanh Biển Dịu Mát (Ocean Blue)',
      description: 'Nền xanh dương pastel tươi mát phủ toàn bộ màn hình',
      backgroundColor: Color(0xFFE0F2FE),
      cardColor: Colors.white,
      primaryColor: Color(0xFF0284C7),
      primaryDark: Color(0xFF0369A1),
      primarySoft: Color(0xFFBAE6FD),
      textColor: Color(0xFF0C4A6E),
      subtextColor: Color(0xFF075985),
      borderColor: Color(0xFFBAE6FD),
    ),
    AppBackgroundPreset(
      id: 'mint_green',
      name: 'Xanh Lá Thiên Nhiên (Mint Green)',
      description: 'Nền xanh ngọc dịu mát, bảo vệ mắt phụ huynh & bé',
      backgroundColor: Color(0xFFDCFCE7),
      cardColor: Colors.white,
      primaryColor: Color(0xFF059669),
      primaryDark: Color(0xFF047857),
      primarySoft: Color(0xFFA7F3D0),
      textColor: Color(0xFF064E3B),
      subtextColor: Color(0xFF065F46),
      borderColor: Color(0xFFA7F3D0),
    ),
    AppBackgroundPreset(
      id: 'lavender_purple',
      name: 'Tím Thư Thái (Lavender Purple)',
      description: 'Nền tím pastel thư giãn, sang trọng',
      backgroundColor: Color(0xFFF3E8FF),
      cardColor: Colors.white,
      primaryColor: Color(0xFF7C3AED),
      primaryDark: Color(0xFF6D28D9),
      primarySoft: Color(0xFFDDD6FE),
      textColor: Color(0xFF4C1D95),
      subtextColor: Color(0xFF5B21B6),
      borderColor: Color(0xFFDDD6FE),
    ),
    AppBackgroundPreset(
      id: 'warm_amber',
      name: 'Vàng Cam Nắng Ấm (Warm Amber)',
      description: 'Nền cam đào dịu ấm, kích thích năng lượng học tập',
      backgroundColor: Color(0xFFFFEDD5),
      cardColor: Colors.white,
      primaryColor: Color(0xFFEA580C),
      primaryDark: Color(0xFFC2410C),
      primarySoft: Color(0xFFFED7AA),
      textColor: Color(0xFF7C2D12),
      subtextColor: Color(0xFF9A3412),
      borderColor: Color(0xFFFED7AA),
    ),
    AppBackgroundPreset(
      id: 'sweet_rose',
      name: 'Hồng Phấn Dễ Thương (Sweet Rose)',
      description: 'Nền hồng pastel dễ thương, phù hợp cho trẻ em',
      backgroundColor: Color(0xFFFFE4E6),
      cardColor: Colors.white,
      primaryColor: Color(0xFFE11D48),
      primaryDark: Color(0xFFBE123C),
      primarySoft: Color(0xFFFECDD3),
      textColor: Color(0xFF881337),
      subtextColor: Color(0xFF9F1239),
      borderColor: Color(0xFFFECDD3),
    ),
    AppBackgroundPreset(
      id: 'night_dark',
      name: 'Đen AMOLED (Dark Mode)',
      description: 'Nền đen sâu tuyền tối ưu pin OLED và dùng ban đêm',
      backgroundColor: Color(0xFF09090B),
      cardColor: Color(0xFF18181B),
      primaryColor: Color(0xFF3B82F6),
      primaryDark: Color(0xFF60A5FA),
      primarySoft: Color(0xFF27272A),
      textColor: Colors.white,
      subtextColor: Color(0xFFA1A1AA),
      borderColor: Color(0xFF27272A),
      isDark: true,
    ),
  ];

  AppBackgroundPreset get currentPreset {
    if (_isDarkMode) {
      return backgroundPresets.last; // night_dark
    }
    return backgroundPresets[_backgroundThemeIndex.clamp(0, backgroundPresets.length - 2)];
  }

  Color get currentBackgroundColor => currentPreset.backgroundColor;
  Color get currentCardColor => currentPreset.cardColor;
  Color get currentPrimaryColor => currentPreset.primaryColor;
  Color get currentPrimaryDark => currentPreset.primaryDark;
  Color get currentPrimarySoft => currentPreset.primarySoft;
  Color get currentTextColor => currentPreset.textColor;
  Color get currentSubtextColor => currentPreset.subtextColor;
  Color get currentBorderColor => currentPreset.borderColor;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
    _isDarkMode = prefs.getBool('app_dark_mode') ?? false;
    _backgroundThemeIndex = (prefs.getInt('app_background_theme') ?? 0).clamp(0, backgroundPresets.length - 1);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_font_scale', scale);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_dark_mode', enabled);
  }

  Future<void> setBackgroundTheme(int index) async {
    if (index < 0 || index >= backgroundPresets.length) return;
    _backgroundThemeIndex = index;
    if (backgroundPresets[index].isDark) {
      _isDarkMode = true;
    } else {
      _isDarkMode = false;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_background_theme', index);
    await prefs.setBool('app_dark_mode', _isDarkMode);
  }

  ThemeData getTheme() {
    final preset = currentPreset;

    if (preset.isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: preset.primaryColor,
          surface: preset.cardColor,
          error: const Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: preset.backgroundColor,
        canvasColor: preset.backgroundColor,
        dialogTheme: DialogThemeData(backgroundColor: preset.cardColor),
        appBarTheme: AppBarTheme(
          backgroundColor: preset.cardColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: preset.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: preset.borderColor),
          ),
        ),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: preset.primaryColor,
        surface: preset.cardColor,
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: preset.backgroundColor,
      canvasColor: preset.backgroundColor,
      dialogTheme: DialogThemeData(backgroundColor: preset.cardColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: preset.textColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: preset.textColor,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: preset.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: preset.borderColor),
        ),
      ),
    );
  }
}
