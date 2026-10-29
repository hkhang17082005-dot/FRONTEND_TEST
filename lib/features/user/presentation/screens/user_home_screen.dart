import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../device/data/models/device_model.dart';
import '../../../device/presentation/controllers/device_controller.dart';
import '../../../translator/presentation/screens/smart_translator_screen.dart';
import '../../../video_call/presentation/screens/video_call_screen.dart';
import '../../../video_call/presentation/widgets/call_hub_widget.dart';

class UserHomeScreen extends StatefulWidget {
  final AuthController authController;

  const UserHomeScreen({
    super.key,
    required this.authController,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _activeTab = 0;
  final DeviceController _deviceController = DeviceController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _activeCategory = 'Tất cả';
  int _ageGroupIndex = 0;
  final Set<int> _bookmarkedIds = {};

  // Trạng thái Quản lý Điện thoại Trẻ em (Parental Control)
  bool _studyModeLock = true;
  bool _bedtimeAutoLock = true;
  bool _safeZoneAlert = true;
  double _dailyScreenLimitMinutes = 90;

  @override
  void initState() {
    super.initState();
    _deviceController.loadDevices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndLogout() async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Rời khỏi Cổng Phụ Huynh',
      content: 'Bạn có muốn đăng xuất khỏi ứng dụng Khang KidSafe không?',
      confirmText: 'Đăng xuất',
    );
    if (!ok || !mounted) return;

    await widget.authController.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(authController: widget.authController),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildFamilyAppBar(),
      body: IndexedStack(
        index: _activeTab,
        children: [
          _buildParentalControlHubTab(),
          _buildDeviceStoreTab(),
          CallHubWidget(authController: widget.authController),
          SmartTranslatorScreen(
            isEmbeddedInTab: true,
            isActiveTab: _activeTab == 3,
          ),
          _buildFamilySettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeTab,
        onDestinationSelected: (idx) => setState(() => _activeTab = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.phonelink_lock_outlined),
            selectedIcon: Icon(Icons.phonelink_lock_rounded, color: AppColors.primaryDark),
            label: 'Quản lý Bé',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primaryDark),
            label: 'Kho Thiết Bị',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam_rounded, color: AppColors.primaryDark),
            label: 'Gọi Gia Đình',
          ),
          NavigationDestination(
            icon: Icon(Icons.translate_outlined),
            selectedIcon: Icon(Icons.translate_rounded, color: AppColors.primaryDark),
            label: 'Dịch Học Tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom_rounded, color: AppColors.primaryDark),
            label: 'Gia Đình',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildFamilyAppBar() {
    final user = widget.authController.currentUser;
    final fullName = user?.fullName ?? 'Hồng Hoàng Khang';

    return AppBar(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gia đình $fullName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Khang KidSafe • Giám sát & Bảo vệ Trẻ em',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryDark),
              SizedBox(width: 4),
              Text(
                'PHỤ HUYNH',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
          onPressed: _confirmAndLogout,
        ),
      ],
    );
  }

  // ================= TAB 0: TRUNG TÂM QUẢN LÝ ĐIỆN THOẠI & ĐỊNH VỊ BÉ =================
  Widget _buildParentalControlHubTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Card: Trạng thái An toàn Gia đình
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(55),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2 Thiết Bị Trẻ Em Đang Trong Vùng An Toàn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tín hiệu GPS vệ tinh ổn định • Cập nhật 10 giây trước',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_location_rounded, size: 18),
                      label: const Text('Chia sẻ Vị trí Đón Bé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      onPressed: _openGpsAndQrSheet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Quét QR Ghép Đôi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      onPressed: _openGpsAndQrSheet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Bảng Điều Khiển Điện Thoại Từ Xa (Screen Time & App Lock)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.app_blocking_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Kiểm Soát Điện Thoại Của Bé Từ Xa',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Giới hạn: ${_dailyScreenLimitMinutes.toInt()} phút/ngày',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _dailyScreenLimitMinutes,
                min: 30,
                max: 180,
                divisions: 6,
                activeColor: AppColors.primary,
                label: '${_dailyScreenLimitMinutes.toInt()} phút',
                onChanged: (v) => setState(() => _dailyScreenLimitMinutes = v),
              ),
              const Divider(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeThumbColor: AppColors.primary,
                value: _studyModeLock,
                title: const Text('Chế độ Tập trung Học tập (Chặn Game & Mạng xã hội)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Chỉ cho phép ứng dụng Học tập, Dịch AI và Gọi cho Ba Mẹ', style: TextStyle(fontSize: 11.5)),
                onChanged: (v) => setState(() => _studyModeLock = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeThumbColor: AppColors.primary,
                value: _bedtimeAutoLock,
                title: const Text('Tự động Khóa màn hình Giờ đi ngủ (21:30 - 06:00)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Bảo vệ giấc ngủ và thị lực của trẻ', style: TextStyle(fontSize: 11.5)),
                onChanged: (v) => setState(() => _bedtimeAutoLock = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'DANH SÁCH THIẾT BỊ CỦA BÉ ĐANG KẾT NỐI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        _buildChildDeviceStatusCard(
          childName: 'Bé Hoàng Khôi',
          gradeInfo: '8 tuổi • Lớp 3A Trường Chu Văn An',
          deviceTitle: 'Đồng Hồ Định Vị GPS Kiddo Watch Pro',
          addressText: 'Khuôn viên Trường Tiểu học Chu Văn An (Bán kính an toàn 150m)',
          batteryPercent: 88,
          screenUsedText: 'Đã dùng 35 / ${_dailyScreenLimitMinutes.toInt()} phút hôm nay',
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 14),

        _buildChildDeviceStatusCard(
          childName: 'Bé Bảo Ngọc',
          gradeInfo: '5 tuổi • Lớp Lá Mầm Non Hoa Mai',
          deviceTitle: 'Máy Tính Bảng Học Tập Samsung Kids Tab',
          addressText: 'Nhà riêng Gia đình (Phòng học tầng 2 - Đang bật Chế độ Học tập)',
          batteryPercent: 94,
          screenUsedText: 'Đã dùng 20 / ${_dailyScreenLimitMinutes.toInt()} phút hôm nay',
          accentColor: const Color(0xFF27272A),
        ),
        const SizedBox(height: 16),

        // Quick AI Study Card
        _buildQuickTranslatorBanner(),
      ],
    );
  }

  Widget _buildChildDeviceStatusCard({
    required String childName,
    required String gradeInfo,
    required String deviceTitle,
    required String addressText,
    required int batteryPercent,
    required String screenUsedText,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accentColor.withAlpha(30),
                child: Icon(Icons.face_retouching_natural_rounded, color: accentColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      gradeInfo,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.battery_charging_full_rounded, size: 14, color: AppColors.primaryDark),
                    const SizedBox(width: 3),
                    Text(
                      '$batteryPercent%',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.watch_rounded, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  deviceTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  addressText,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.timelapse_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                screenUsedText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: const Text('Gọi Thoại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () {
                    final slug = childName.toLowerCase().replaceAll(' ', '-');
                    CallHubWidget.launchDirectCall(
                      context: context,
                      authController: widget.authController,
                      roomName: 'kid-$slug',
                      description: 'Đàm thoại 2 chiều với $childName ($deviceTitle)',
                      callType: CallType.oneToOne,
                      isAudioOnly: true,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam_rounded, size: 17),
                  label: const Text('Video Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () {
                    final slug = childName.toLowerCase().replaceAll(' ', '-');
                    CallHubWidget.launchDirectCall(
                      context: context,
                      authController: widget.authController,
                      roomName: 'kid-$slug',
                      description: 'Gọi Video trực tiếp với $childName ($deviceTitle)',
                      callType: CallType.oneToOne,
                      isAudioOnly: false,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Báo Nhân viên Kỹ thuật hỗ trợ thiết bị này',
                icon: const Icon(Icons.support_agent_rounded, color: AppColors.primaryDark),
                onPressed: () {
                  CallHubWidget.launchDirectCall(
                    context: context,
                    authController: widget.authController,
                    roomName: 'phong-ho-tro-ky-thuat',
                    description: 'Phụ huynh cần hỗ trợ thiết bị $deviceTitle của $childName',
                    callType: CallType.support,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTranslatorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trợ Lý Học Tập AI Cùng Bé (Camera OCR & Dịch Giọng Nói)',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Chụp sách Tiếng Anh hoặc hướng dẫn sử dụng thiết bị để dịch sang Tiếng Việt và nghe phát âm chuẩn.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Quét Chữ Camera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => SmartTranslatorScreen.open(context, initialTabIndex: 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded, size: 16),
                  label: const Text('Dịch Hội Thoại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => SmartTranslatorScreen.open(context, initialTabIndex: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGpsAndQrSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location_rounded, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Chia Sẻ Vị Trí GPS & Mã Ghép Đôi QR',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primarySoft),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông số Định vị Trực tiếp (API /api/Location):',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryDark),
                    ),
                    SizedBox(height: 6),
                    Text('• Tọa độ Phụ huynh: 10.776889° N, 106.700981° E', style: TextStyle(fontSize: 12.5)),
                    Text('• Khoảng cách tới Bé Hoàng Khôi: 295m (Hướng Tây Bắc)', style: TextStyle(fontSize: 12.5)),
                    Text('• Trạng thái vùng an toàn: Trong bán kính 150m (An toàn)', style: TextStyle(fontSize: 12.5)),
                    Text('• Mã định danh QR / ShareCode: GPS-KHANG-8821', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Gửi Tọa Độ Điểm Đón Tới Thiết Bị Của Bé', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primaryDark,
                        content: Text('Đã phát sóng tọa độ điểm đón (Mã: GPS-KHANG-8821) tới đồng hồ của bé!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TAB 1: CỬA HÀNG & TRA CỨU THIẾT BỊ TRẺ EM =================
  Widget _buildDeviceStoreTab() {
    return ListenableBuilder(
      listenable: _deviceController,
      builder: (context, _) {
        final filtered = _deviceController.devices.where((d) {
          if (_activeCategory != 'Tất cả' && d.category != _activeCategory) {
            return false;
          }
          if (_ageGroupIndex == 1 && (d.minAge > 5 || d.maxAge < 3)) return false;
          if (_ageGroupIndex == 2 && (d.minAge > 10 || d.maxAge < 6)) return false;
          if (_ageGroupIndex == 3 && d.maxAge < 11) return false;

          final q = _searchCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            return d.name.toLowerCase().contains(q) ||
                (d.brand?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: () => _deviceController.loadDevices(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Box
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm đồng hồ GPS, máy tính bảng học tập, camera...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Lọc theo độ tuổi của bé
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAgeFilterPill('Mọi độ tuổi', 0),
                    _buildAgeFilterPill('Mầm non (3-5 tuổi)', 1),
                    _buildAgeFilterPill('Tiểu học (6-10 tuổi)', 2),
                    _buildAgeFilterPill('THCS (11+ tuổi)', 3),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Lọc danh mục
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Tất cả', ...Device.defaultCategories].map((cat) {
                    final selected = _activeCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        onSelected: (_) => setState(() => _activeCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              if (_deviceController.isLoading && _deviceController.devices.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child: Text('Không có thiết bị nào khớp bộ lọc'),
                  ),
                )
              else
                ...filtered.map(_buildStoreDeviceItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgeFilterPill(String text, int idx) {
    final active = _ageGroupIndex == idx;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
        selected: active,
        selectedColor: AppColors.primarySoft,
        backgroundColor: Colors.white,
        onSelected: (_) => setState(() => _ageGroupIndex = idx),
      ),
    );
  }

  Widget _buildStoreDeviceItem(Device device) {
    final fav = _bookmarkedIds.contains(device.id);
    return InkWell(
      onTap: () => _openDeviceSpecSheet(device),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.watch_rounded, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Độ tuổi: ${device.minAge}-${device.maxAge} tuổi • ${device.brand ?? "Chính hãng"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${device.price.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          device.category,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: fav ? AppColors.accent : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  if (fav) {
                    _bookmarkedIds.remove(device.id);
                  } else {
                    _bookmarkedIds.add(device.id);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDeviceSpecSheet(Device device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Thương hiệu: ${device.brand ?? "Kiddo"} • Model: ${device.modelNumber ?? "2026"} • Lứa tuổi: ${device.minAge}-${device.maxAge}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const Divider(height: 22),
              Text(
                device.description ?? 'Thiết bị thông minh hỗ trợ định vị GPS, gọi SOS và kiểm soát thời gian sử dụng màn hình cho trẻ em.',
                style: const TextStyle(fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${device.price.toStringAsFixed(0)} VNĐ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Đăng ký Trang bị cho Bé'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryDark,
                          content: Text('Đã gửi yêu cầu trang bị "${device.name}" cho bé!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TAB 4: HỒ SƠ GIA ĐÌNH & CÀI ĐẶT AN TOÀN =================
  Widget _buildFamilySettingsTab() {
    final user = widget.authController.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  (user?.fullName ?? 'K').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Hồng Hoàng Khang (User)',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'honghoangkhang@gmail.com',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CHỦ HỘ GIA ĐÌNH • ROLE: USER',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cấu hình Vùng An Toàn & SOS Khẩn Cấp',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                value: _safeZoneAlert,
                title: const Text('Báo động tức thì khi bé rời khỏi Trường / Nhà', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                onChanged: (v) => setState(() => _safeZoneAlert = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                title: const Text('Gọi Tổng đài Kỹ thuật viên (STAFF)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('Kết nối LiveKit Video Call trực tiếp với nhân viên trực ca', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  CallHubWidget.launchDirectCall(
                    context: context,
                    authController: widget.authController,
                    roomName: 'phong-ho-tro-ky-thuat',
                    description: 'Phụ huynh kết nối trực tiếp Kỹ thuật viên (STAFF)',
                    callType: CallType.support,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất khỏi thiết bị', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          onPressed: _confirmAndLogout,
        ),
      ],
    );
  }
}
