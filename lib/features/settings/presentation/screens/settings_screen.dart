import 'package:flutter/material.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AuthController authController;

  const SettingsScreen({
    super.key,
    required this.authController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettingsController.instance;

  final List<({String label, double scale, String desc})> _fontOptions = [
    (label: 'Nhỏ', scale: 0.85, desc: '85% - Hiển thị nhiều nội dung'),
    (label: 'Chuẩn', scale: 1.0, desc: '100% - Kích thước mặc định'),
    (label: 'Lớn', scale: 1.15, desc: '115% - Dễ đọc hơn cho mắt'),
    (label: 'Rất Lớn', scale: 1.30, desc: '130% - Chữ to rõ ràng'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.currentUser;

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final cardBg = _settings.currentCardColor;
        final borderCol = _settings.currentBorderColor;
        final textCol = _settings.currentTextColor;
        final subCol = _settings.currentSubtextColor;

        return Scaffold(
          backgroundColor: _settings.currentBackgroundColor,
          appBar: AppBar(
            backgroundColor: cardBg,
            foregroundColor: textCol,
            title: const Text('Cài Đặt Hệ Thống & Giao Diện', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _settings.currentPrimarySoft,
                      child: Text(
                        (user?.fullName ?? 'K').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _settings.currentPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Hồng Hoàng Khang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textCol),
                          ),
                          Text(
                            user?.email ?? 'honghoangkhang@gmail.com',
                            style: TextStyle(fontSize: 12, color: subCol),
                          ),
                          Text(
                            'Vai trò: ${user?.role ?? "USER"}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _settings.currentPrimaryDark),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _settings.currentPrimaryDark,
                        side: BorderSide(color: _settings.currentPrimaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Sửa hồ sơ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(authController: widget.authController),
                          ),
                        );
                        if (ok == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Font Size Setting Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_size_rounded, color: _settings.currentPrimaryColor, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Tùy Chỉnh Cỡ Chữ Ứng Dụng',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textCol),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thay đổi kích thước chữ hiển thị trên toàn bộ các màn hình của ứng dụng:',
                      style: TextStyle(fontSize: 12, color: subCol),
                    ),
                    const SizedBox(height: 14),

                    // Demo text box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _settings.currentPrimarySoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xem trước kích thước chữ:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subCol),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khang KidSafe: Bảo vệ an toàn trẻ em mọi lúc mọi nơi.',
                            style: TextStyle(
                              fontSize: 14 * _settings.fontScale,
                              fontWeight: FontWeight.w800,
                              color: _settings.currentPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Choice chips for font scale
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _fontOptions.map((opt) {
                        final isSelected = (_settings.fontScale - opt.scale).abs() < 0.05;
                        return ChoiceChip(
                          label: Text(
                            opt.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isSelected ? Colors.white : textCol,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: _settings.currentPrimaryDark,
                          onSelected: (_) => _settings.setFontScale(opt.scale),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Background Color & Theme Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_rounded, color: _settings.currentPrimaryColor, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Màu Nền Toàn Bộ Ứng Dụng',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textCol),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chọn màu nền áp dụng cho toàn bộ các màn hình, thanh điều hướng và khung nền ứng dụng:',
                      style: TextStyle(fontSize: 12, color: subCol),
                    ),
                    const SizedBox(height: 14),

                    // Live Preview Box of Background Color
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _settings.currentBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _settings.currentPrimaryColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _settings.currentBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Màu nền đang kích hoạt:',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: subCol),
                                ),
                                Text(
                                  _settings.currentPreset.name,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textCol),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _settings.currentPrimaryDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ĐANG ÁP DỤNG',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dark Mode Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: _settings.currentPrimaryColor,
                      title: Text('Chế độ Tối (Dark / AMOLED Night Mode)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textCol)),
                      subtitle: Text('Đổi toàn bộ nền app sang đen tuyền bảo vệ mắt ban đêm', style: TextStyle(fontSize: 11.5, color: subCol)),
                      value: _settings.isDarkMode,
                      onChanged: (v) => _settings.toggleDarkMode(v),
                    ),
                    const Divider(height: 20),

                    Text(
                      'Chọn bảng màu nền toàn diện (Toàn bộ app):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textCol),
                    ),
                    const SizedBox(height: 10),

                    // List of all 7 Background Presets
                    Column(
                      children: List.generate(AppSettingsController.backgroundPresets.length, (idx) {
                        final preset = AppSettingsController.backgroundPresets[idx];
                        final isSel = _settings.currentPreset.id == preset.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSel ? preset.primarySoft : cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel ? preset.primaryColor : borderCol,
                              width: isSel ? 2.0 : 1.0,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: preset.primaryColor.withAlpha(35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: preset.backgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: preset.primaryColor, width: 2.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: preset.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              preset.name,
                              style: TextStyle(
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                                fontSize: 13.5,
                                color: isSel ? preset.primaryDark : textCol,
                              ),
                            ),
                            subtitle: Text(
                              preset.description,
                              style: TextStyle(fontSize: 11, color: subCol),
                            ),
                            trailing: isSel
                                ? Icon(Icons.check_circle_rounded, color: preset.primaryColor, size: 24)
                                : null,
                            onTap: () => _settings.setBackgroundTheme(idx),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Sinh Trắc Học Phần Cứng
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fingerprint_rounded, color: _settings.currentPrimaryDark, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Sinh Trắc Học Máy (Samsung Galaxy Tab S9)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textCol),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kiểm tra cảm biến vân tay màn hình phần cứng trên máy tính bảng Samsung Galaxy Tab S9.',
                      style: TextStyle(fontSize: 12, color: subCol),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _settings.currentPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final res = await BiometricHardwareService.instance.authenticateWithFingerprint(
                            reason: 'Chạm ngón tay vào cảm biến vân tay trên Samsung Galaxy Tab S9 để kiểm tra',
                          );
                          if (!context.mounted) return;
                          if (res.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green,
                                content: Text('Cảm biến vân tay máy Samsung Galaxy Tab S9 hoạt động chuẩn xác 100%!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.orange,
                                content: Text(res.errorMessage ?? 'Chưa xác thực được vân tay.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.fingerprint_rounded, size: 18),
                        label: const Text('Kiểm Tra Cảm Biến Vân Tay Máy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // System Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ứng Dụng Khang KidSafe v1.0.0+1', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textCol)),
                    const SizedBox(height: 4),
                    Text('Tác giả: Hồng Hoàng Khang • MSSV: HUTECH', style: TextStyle(fontSize: 12, color: subCol)),
                    Text('Máy chủ: https://mobile.zeion.online/api (VPS Hosted)', style: TextStyle(fontSize: 12, color: subCol)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
