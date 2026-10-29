import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../device/data/models/device_model.dart';
import '../../../device/presentation/controllers/device_controller.dart';
import '../../../video_call/presentation/screens/video_call_screen.dart';
import '../../../video_call/presentation/widgets/call_hub_widget.dart';

class StaffDashboardScreen extends StatefulWidget {
  final AuthController authController;

  const StaffDashboardScreen({
    super.key,
    required this.authController,
  });

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedTab = 0;
  final DeviceController _deviceController = DeviceController();
  final TextEditingController _shiftNoteCtrl = TextEditingController();

  bool _isReceivingCalls = true;
  final Map<int, String> _qcResultByDevice = {};

  final List<Map<String, dynamic>> _dailyDuties = [
    {
      'title': 'Kiểm tra tín hiệu định vị vệ tinh GPS & trạm phát sóng SafeZone',
      'tag': 'Hạ tầng GPS',
      'done': true,
    },
    {
      'title': 'Đo kiểm bức xạ an toàn RF & dung lượng pin cho lô Kiddo Watch',
      'tag': 'Kiểm định QC',
      'done': false,
    },
    {
      'title': 'Hướng dẫn phụ huynh bé Hoàng Khôi kích hoạt khóa màn hình giờ học',
      'tag': 'CSKH Phụ huynh',
      'done': true,
    },
    {
      'title': 'Trực phòng gọi Video Call hỗ trợ kỹ thuật thiết bị trẻ em',
      'tag': 'Tổng đài LiveKit',
      'done': false,
    },
  ];

  final List<Map<String, dynamic>> _parentTickets = [
    {
      'code': '#KS-2041',
      'parentName': 'Phụ huynh Nguyễn Thanh Tùng',
      'kidInfo': 'Bé Gia Bảo (Lớp 2)',
      'problem': 'Cần hỗ trợ cài đặt bán kính vùng an toàn GPS quanh trường học',
      'level': 'Khẩn cấp',
      'state': 'Đang xử lý',
      'timeAgo': '10 phút trước',
    },
    {
      'code': '#KS-2042',
      'parentName': 'Phụ huynh Phạm Thu Hà',
      'kidInfo': 'Bé Minh Châu (Lớp 4)',
      'problem': 'Nhờ kỹ thuật viên gọi Video hướng dẫn ghép đôi mã QR đồng hồ mới',
      'level': 'Ưu tiên',
      'state': 'Chờ kết nối',
      'timeAgo': '25 phút trước',
    },
    {
      'code': '#KS-2043',
      'parentName': 'Phụ huynh Lê Hoàng Nam',
      'kidInfo': 'Bé An Nhiên (Mầm non)',
      'problem': 'Kiểm tra cảm biến nhiệt độ phòng trên Camera SafeBaby Monitor',
      'level': 'Bình thường',
      'state': 'Đã hoàn tất',
      'timeAgo': '1 giờ trước',
    },
  ];

  @override
  void initState() {
    super.initState();
    _deviceController.loadDevices();
  }

  @override
  void dispose() {
    _shiftNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _logoutStaff() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Kết thúc Ca trực Kỹ thuật',
      content: 'Bạn có chắc chắn muốn đăng xuất khỏi Bàn điều hành Nhân viên (STAFF)?',
      confirmText: 'Kết thúc ca',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

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

  void _openQcModal(Device d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.biotech_rounded, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Expanded(child: Text('Phiếu Kiểm Định An Toàn Trẻ Em')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            Text('Model: ${d.modelNumber ?? "KS-2026"} • Hãng: ${d.brand ?? "Chính hãng"}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Divider(height: 20),
            _buildQcLine(Icons.gps_fixed_rounded, 'Sai số chip định vị GPS', '±2.8m (Chuẩn)'),
            _buildQcLine(Icons.health_and_safety_rounded, 'Mức bức xạ sóng RF trẻ em', 'An toàn CE'),
            _buildQcLine(Icons.battery_charging_full_rounded, 'Chu kỳ bảo vệ pin chống nóng', 'Đạt 100%'),
            _buildQcLine(Icons.mic_rounded, 'Đàm thoại 2 chiều SOS', 'Rõ nét'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _qcResultByDevice[d.id] = 'Cần hiệu chỉnh');
              Navigator.pop(ctx);
            },
            child: const Text('Báo bảo trì', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _qcResultByDevice[d.id] = 'Đạt chuẩn KidSafe');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Đã cấp tem Đạt chuẩn KidSafe cho "${d.name}"'),
                ),
              );
            },
            child: const Text('Cấp Tem An Toàn'),
          ),
        ],
      ),
    );
  }

  Widget _buildQcLine(IconData icon, String label, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
          Text(badge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.engineering_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRẠM KỸ THUẬT KIDSAFE',
                    style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Dashboard Nhân viên Kiểm định & Hỗ trợ Phụ huynh',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ROLE: STAFF',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logoutStaff,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildShiftOverviewTab(),
          _buildHardwareQcTab(),
          CallHubWidget(authController: widget.authController),
          _buildParentSupportTicketsTab(),
          _buildStaffProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded, color: AppColors.primaryDark),
            label: 'Ca Trực',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech_rounded, color: AppColors.primaryDark),
            label: 'Kiểm Định QC',
          ),
          NavigationDestination(
            icon: Icon(Icons.headset_mic_outlined),
            selectedIcon: Icon(Icons.headset_mic_rounded, color: AppColors.primaryDark),
            label: 'Trực Gọi',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number_rounded, color: AppColors.primaryDark),
            label: 'Phiếu Hỗ Trợ',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded, color: AppColors.primaryDark),
            label: 'Nhân Viên',
          ),
        ],
      ),
    );
  }

  Widget _buildShiftOverviewTab() {
    final completedTasks = _dailyDuties.where((e) => e['done'] == true).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ca Trực Kỹ Thuật: Hồng Hoàng Khang',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhiệm vụ trọng tâm: Kiểm định an toàn bức xạ đồng hồ GPS & hỗ trợ phụ huynh cài đặt vùng an toàn cho bé.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMiniStat('Đã kiểm định', '${_qcResultByDevice.length} máy'),
                  const SizedBox(width: 10),
                  _buildMiniStat('Phiếu phụ huynh', '${_parentTickets.length} phiếu'),
                  const SizedBox(width: 10),
                  _buildMiniStat('Tiến độ ca', '$completedTasks/${_dailyDuties.length} việc'),
                ],
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
                'Danh mục công việc kỹ thuật trong ca',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ..._dailyDuties.map((item) {
                final done = item['done'] as bool;
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  value: done,
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(item['tag'], style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark)),
                  onChanged: (v) => setState(() => item['done'] = v ?? false),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareQcTab() {
    return ListenableBuilder(
      listenable: _deviceController,
      builder: (context, _) {
        final list = _deviceController.devices;
        if (_deviceController.isLoading && list.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          onRefresh: () => _deviceController.loadDevices(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final d = list[idx];
              final status = _qcResultByDevice[d.id] ?? 'Chờ đo kiểm QC';
              final passed = status == 'Đạt chuẩn KidSafe';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: passed ? AppColors.primary : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.verified_outlined, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('Tồn kho: ${d.stockQuantity} • Độ tuổi: ${d.minAge}-${d.maxAge}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: passed ? AppColors.success : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _openQcModal(d),
                      child: const Text('Đo QC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildParentSupportTicketsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _parentTickets.length,
      itemBuilder: (context, index) {
        final t = _parentTickets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t['code'], style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                  Text(t['timeAgo'], style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              Text('${t['parentName']} • ${t['kidInfo']}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 4),
              Text(t['problem'], style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trạng thái: ${t['state']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text('Gọi Hỗ Trợ Ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final clean = t['code'].toString().replaceAll('#', '').toLowerCase();
                      CallHubWidget.launchDirectCall(
                        context: context,
                        authController: widget.authController,
                        roomName: 'support-$clean',
                        description: 'Hỗ trợ ${t['parentName']}: ${t['problem']}',
                        callType: CallType.support,
                        isHost: true,
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

  Widget _buildStaffProfileTab() {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.fullName ?? 'Hồng Hoàng Khang (Staff)',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(user?.email ?? 'honghoangkhang.staff@gmail.com',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Divider(height: 22),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                value: _isReceivingCalls,
                title: const Text('Sẵn sàng nhận cuộc gọi SOS & Hỗ trợ kỹ thuật',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                onChanged: (v) => setState(() => _isReceivingCalls = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _shiftNoteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ghi chú bàn giao ca kỹ thuật (số thiết bị đã đo QC, phiếu tồn)...',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Đã lưu biên bản bàn giao ca trực kỹ thuật!'),
                      ),
                    );
                  },
                  child: const Text('Lưu Báo Cáo Ca Trực'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Kết thúc ca & Đăng xuất', style: TextStyle(fontWeight: FontWeight.w800)),
          onPressed: _logoutStaff,
        ),
      ],
    );
  }
}
