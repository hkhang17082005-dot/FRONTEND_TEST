import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../device/data/models/device_model.dart';
import '../../../device/presentation/controllers/device_controller.dart';
import '../../../order/presentation/screens/orders_screen.dart';
import '../../../settings/presentation/screens/edit_profile_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
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
      'id': 1,
      'title': 'Kiểm tra tín hiệu định vị vệ tinh GPS & trạm phát sóng SafeZone',
      'tag': 'Hạ tầng GPS',
      'done': true,
    },
    {
      'id': 2,
      'title': 'Đo kiểm bức xạ an toàn RF & dung lượng pin cho lô Kiddo Watch',
      'tag': 'Kiểm định QC',
      'done': false,
    },
    {
      'id': 3,
      'title': 'Hướng dẫn phụ huynh bé Hoàng Khôi kích hoạt khóa màn hình giờ học',
      'tag': 'CSKH Phụ huynh',
      'done': true,
    },
    {
      'id': 4,
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
      confirmText: 'Đăng xuất',
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

  void _runQcCheck(Device device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Kiểm Định QC: ${device.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQcLine(Icons.wifi_tethering_rounded, 'Chỉ số bức xạ điện từ SAR:', '< 0.8 W/kg (Chuẩn an toàn)'),
            _buildQcLine(Icons.battery_charging_full_rounded, 'Dung lượng pin thực tế:', 'Đạt chuẩn 100% dung lượng'),
            _buildQcLine(Icons.gps_fixed_rounded, 'Độ trễ định vị GPS vệ tinh:', '±3 mét (Tuyệt vời)'),
            _buildQcLine(Icons.security_rounded, 'Khóa màn hình phụ huynh:', 'Bảo mật 2 lớp an toàn'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _qcResultByDevice[device.id] = 'Chưa đạt - Cần hiệu chỉnh');
              Navigator.pop(ctx);
            },
            child: const Text('Cần Hiệu Chỉnh', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _qcResultByDevice[device.id] = 'Đạt chuẩn KidSafe');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.success,
                  content: Text('Thiết bị "${device.name}" đã Đạt chuẩn kiểm định an toàn!'),
                ),
              );
            },
            child: const Text('Phê Duyệt Đạt QC'),
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

  // ================= CRUD CA TRỰC / CHECKLIST =================
  void _openAddDutyDialog() {
    final titleCtrl = TextEditingController();
    String selectedTag = 'Kiểm định QC';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Thêm Nhiệm Vụ Ca Trực', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nội dung công việc *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              TextField(
                controller: titleCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'vd: Kiểm tra định vị GPS trạm khu vực Q.1'),
              ),
              const SizedBox(height: 12),
              const Text('Phân loại công việc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: selectedTag,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: ['Hạ tầng GPS', 'Kiểm định QC', 'CSKH Phụ huynh', 'Tổng đài LiveKit', 'Bảo trì hệ thống']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTag = v ?? 'Kiểm định QC'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
              onPressed: () {
                final txt = titleCtrl.text.trim();
                if (txt.isEmpty) return;
                setState(() {
                  _dailyDuties.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'title': txt,
                    'tag': selectedTag,
                    'done': false,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                    content: Text('Đã thêm nhiệm vụ mới vào ca trực!'),
                  ),
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDutyDialog(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title']);
    String selectedTag = item['tag'] ?? 'Kiểm định QC';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Chỉnh Sửa Nhiệm Vụ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              TextField(controller: titleCtrl, maxLines: 2),
              const SizedBox(height: 12),
              const Text('Phân loại công việc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: ['Hạ tầng GPS', 'Kiểm định QC', 'CSKH Phụ huynh', 'Tổng đài LiveKit', 'Bảo trì hệ thống'].contains(selectedTag) ? selectedTag : 'Kiểm định QC',
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: ['Hạ tầng GPS', 'Kiểm định QC', 'CSKH Phụ huynh', 'Tổng đài LiveKit', 'Bảo trì hệ thống']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTag = v ?? 'Kiểm định QC'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
              onPressed: () {
                final txt = titleCtrl.text.trim();
                if (txt.isEmpty) return;
                setState(() {
                  item['title'] = txt;
                  item['tag'] = selectedTag;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDuty(Map<String, dynamic> item) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Xóa Nhiệm Vụ',
      content: 'Bạn có chắc chắn muốn xóa "${item['title']}" khỏi ca trực?',
      confirmText: 'Xóa',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _dailyDuties.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Text('Đã xóa nhiệm vụ khỏi ca trực.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            tooltip: 'Cài đặt giao diện & Cỡ chữ',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(authController: widget.authController),
                ),
              );
            },
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
          OrdersScreen(authController: widget.authController, isEmbedded: true),
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
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryDark),
            label: 'Đơn Hàng',
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
                'Nhiệm vụ: Giám sát trạm SafeZone, kiểm định thiết bị trước khi gửi phụ huynh & Trực tổng đài LiveKit',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMiniStat('Đã hoàn tất', '$completedTasks / ${_dailyDuties.length} việc'),
                  const SizedBox(width: 10),
                  _buildMiniStat('Phiếu CSKH', '${_parentTickets.length} yêu cầu'),
                  const SizedBox(width: 10),
                  _buildMiniStat('Trực SFU', _isReceivingCalls ? 'Sẵn sàng' : 'Tạm dừng'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Checklist CRUD Section
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
                  const Text(
                    'Danh mục công việc kỹ thuật trong ca',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    tooltip: 'Thêm nhiệm vụ ca trực',
                    onPressed: _openAddDutyDialog,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ..._dailyDuties.map((item) {
                final done = item['done'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: done ? AppColors.background : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        activeColor: AppColors.primary,
                        value: done,
                        onChanged: (v) => setState(() => item['done'] = v ?? false),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: done ? TextDecoration.lineThrough : null,
                                color: done ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              item['tag'],
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _openEditDutyDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () => _deleteDuty(item),
                      ),
                    ],
                  ),
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
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
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
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: passed ? AppColors.success.withAlpha(30) : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: passed ? AppColors.success : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Model: ${d.modelNumber ?? "2026"} • Phù hợp độ tuổi: ${d.minAge}-${d.maxAge} tuổi • Tồn kho: ${d.stockQuantity}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${d.price.toStringAsFixed(0)} đ',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark, fontSize: 14),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.speed_rounded, size: 16),
                          label: const Text('Đo Kiểm An Toàn'),
                          onPressed: () => _runQcCheck(d),
                        ),
                      ],
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
      itemBuilder: (context, idx) {
        final t = _parentTickets[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t['code'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t['state'] == 'Đã hoàn tất' ? AppColors.success.withAlpha(25) : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t['state'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: t['state'] == 'Đã hoàn tất' ? AppColors.success : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t['parentName'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                Text('${t['kidInfo']} • ${t['timeAgo']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(t['problem'], style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Đánh dấu xong'),
                      onPressed: () {
                        setState(() => t['state'] = 'Đã hoàn tất');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.success,
                            content: Text('Đã cập nhật phiếu ${t['code']} thành Hoàn tất'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                      icon: const Icon(Icons.videocam_rounded, size: 16),
                      label: const Text('Gọi Video Hỗ Trợ'),
                      onPressed: () {
                        CallHubWidget.launchDirectCall(
                          context: context,
                          authController: widget.authController,
                          roomName: 'support-ticket-${t['code'].replaceAll('#', '')}',
                          description: 'Hỗ trợ kỹ thuật trực tiếp cho ${t['parentName']}',
                          callType: CallType.support,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
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
              Text(user?.fullName ?? 'Hồng Hoàng Khang (Staff)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text(user?.email ?? 'honghoangkhang.staff@gmail.com', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text('Sẵn sàng tiếp nhận cuộc gọi Video hỗ trợ phụ huynh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                value: _isReceivingCalls,
                onChanged: (v) => setState(() => _isReceivingCalls = v),
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                title: const Text('Cập nhật Hồ sơ Cá nhân (Họ tên, SĐT)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(authController: widget.authController),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.palette_rounded, color: AppColors.accent),
                title: const Text('Cài đặt Giao diện, Cỡ chữ & Chủ đề', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(authController: widget.authController),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng Xuất Khỏi Trạm Kỹ Thuật'),
          onPressed: _logoutStaff,
        ),
      ],
    );
  }
}
