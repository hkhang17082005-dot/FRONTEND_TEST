import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../device/data/models/device_model.dart';
import '../../../device/presentation/controllers/device_controller.dart';
import '../../../device/presentation/screens/device_form_screen.dart';
import '../../../order/presentation/screens/orders_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AuthController authController;

  const AdminDashboardScreen({
    super.key,
    required this.authController,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tabIndex = 0;
  final DeviceController _deviceController = DeviceController();
  final TextEditingController _catalogQueryCtrl = TextEditingController();
  final TextEditingController _accountQueryCtrl = TextEditingController();

  String _categoryFilter = 'Tất cả';
  String _roleFilter = 'ALL';
  bool _strictChildSafetyMode = true;
  bool _isLoadingUsers = false;

  late List<Map<String, dynamic>> _systemAccounts;

  @override
  void initState() {
    super.initState();
    _deviceController.loadDevices();

    _systemAccounts = [
      {
        'id': 1,
        'name': 'Hồng Hoàng Khang (Admin)',
        'email': 'honghoangkhang.admin@gmail.com',
        'role': 'ADMIN',
        'active': true,
      },
      {
        'id': 2,
        'name': 'Hồng Hoàng Khang (Staff)',
        'email': 'honghoangkhang.staff@gmail.com',
        'role': 'STAFF',
        'active': true,
      },
      {
        'id': 3,
        'name': 'Hồng Hoàng Khang (User)',
        'email': 'honghoangkhang@gmail.com',
        'role': 'USER',
        'active': true,
      },
      {
        'id': 4,
        'name': 'Kỹ thuật viên Đặng Quốc Bảo',
        'email': 'quocbao.qc@kidsafe.vn',
        'role': 'STAFF',
        'active': true,
      },
      {
        'id': 5,
        'name': 'Phụ huynh Nguyễn Thanh Tùng',
        'email': 'thanhtung.family@gmail.com',
        'role': 'USER',
        'active': true,
      },
    ];

    _loadUsersFromApi();
  }

  Future<void> _loadUsersFromApi() async {
    setState(() => _isLoadingUsers = true);
    final users = await widget.authController.loadAllUsers();
    if (!mounted) return;
    if (users.isNotEmpty) {
      setState(() {
        _systemAccounts = users.map((u) {
          return {
            'id': u.id,
            'name': u.fullName.isNotEmpty ? u.fullName : u.email.split('@').first,
            'email': u.email,
            'role': u.role.toUpperCase(),
            'active': true,
          };
        }).toList();
        _isLoadingUsers = false;
      });
    } else {
      setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    _catalogQueryCtrl.dispose();
    _accountQueryCtrl.dispose();
    super.dispose();
  }

  Future<void> _logoutAdmin() async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Đăng xuất Trung tâm Quản trị',
      content: 'Bạn muốn thoát khỏi phiên Quản trị viên (ADMIN)?',
      confirmText: 'Đăng xuất',
      isDestructive: true,
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

  Future<void> _openEditDevice(Device item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceFormScreen(
          deviceController: _deviceController,
          initialDevice: item,
        ),
      ),
    );
    if (changed == true) {
      _deviceController.loadDevices();
    }
  }

  Future<void> _confirmRemoveDevice(Device item) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Xóa Thiết bị khỏi Hệ thống',
      content: 'Xác nhận xóa vĩnh viễn "${item.name}" khỏi cơ sở dữ liệu?',
      confirmText: 'Xóa vĩnh viễn',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    final deleted = await _deviceController.deleteDevice(item.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: deleted ? AppColors.success : AppColors.error,
        content: Text(
          deleted
              ? 'Đã xóa "${item.name}" thành công'
              : (_deviceController.errorMessage ?? 'Không thể xóa thiết bị'),
        ),
      ),
    );
  }

  void _openRolePickerDialog(Map<String, dynamic> acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Phân Quyền Tài Khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(acc['email'], style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const Divider(height: 20),
            ...['ADMIN', 'STAFF', 'USER'].map((r) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.verified_user_rounded, color: AppColors.primary),
                title: Text('Chuyển sang quyền $r', style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final roleType = UserRoleType.fromString(r);
                  final ok = await widget.authController.updateUserRole(acc['id'], roleType);
                  setState(() => acc['role'] = r);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primaryDark,
                      content: Text(
                        ok
                            ? 'Đã cập nhật quyền của ${acc['name']} thành $r trên cơ sở dữ liệu!'
                            : 'Đã đổi quyền ${acc['name']} thành $r',
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openAddAccountDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'STAFF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Thêm Tài Khoản Mới', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Họ và tên *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'vd: Nguyễn Văn A')),
                const SizedBox(height: 10),
                const Text('Email *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'vd: nva@gmail.com')),
                const SizedBox(height: 10),
                const Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(hintText: '090...')),
                const SizedBox(height: 12),
                const Text('Phân quyền ban đầu *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ['ADMIN', 'STAFF', 'USER'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v ?? 'USER'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
              onPressed: () {
                final email = emailCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (email.isEmpty || name.isEmpty) return;

                final newAcc = {
                  'id': DateTime.now().millisecondsSinceEpoch % 100000,
                  'name': name,
                  'email': email,
                  'role': selectedRole,
                  'active': true,
                };
                setState(() => _systemAccounts.insert(0, newAcc));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                    content: Text('Đã tạo tài khoản $name ($selectedRole) thành công!'),
                  ),
                );
              },
              child: const Text('Thêm Tài Khoản'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveAccount(Map<String, dynamic> acc) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Xóa Tài Khoản',
      content: 'Bạn có chắc chắn muốn xóa tài khoản "${acc['name']}" (${acc['email']})?',
      confirmText: 'Xóa tài khoản',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _systemAccounts.removeWhere((item) => item['id'] == acc['id']));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Text('Đã xóa tài khoản "${acc['name']}"'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KIDSAFE ADMIN CENTER',
                    style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Quản trị Thiết bị Trẻ em & Phân quyền Hệ thống',
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
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: const Text(
              'ROLE: ADMIN',
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
            onPressed: _logoutAdmin,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildExecutiveSummaryTab(),
          _buildDeviceCrudTab(),
          OrdersScreen(authController: widget.authController, isEmbedded: true),
          _buildRoleManagementTab(),
          _buildAdminSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primaryDark),
            label: 'Thống Kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other_rounded, color: AppColors.primaryDark),
            label: 'CRUD Thiết Bị',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryDark),
            label: 'Đơn Hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded, color: AppColors.primaryDark),
            label: 'Phân Quyền',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_suggest_outlined),
            selectedIcon: Icon(Icons.settings_suggest_rounded, color: AppColors.primaryDark),
            label: 'Hệ Thống',
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryTab() {
    return ListenableBuilder(
      listenable: _deviceController,
      builder: (context, _) {
        final totalDevices = _deviceController.devices.length;
        final totalStock = _deviceController.devices.fold<int>(0, (s, d) => s + d.stockQuantity);
        final averagePrice = totalDevices == 0
            ? 0.0
            : _deviceController.devices.fold<double>(0.0, (s, d) => s + d.price) / totalDevices;

        return RefreshIndicator(
          onRefresh: () async {
            await _deviceController.loadDevices();
            await _loadUsersFromApi();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF09090B), Color(0xFF27272A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'TỔNG QUAN HỆ THỐNG AN TOÀN TRẺ EM',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalDevices Mẫu Thiết Bị & Điện Thoại Trẻ Em',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tồn kho khả dụng: $totalStock cái • Giá trung bình: ${averagePrice.toStringAsFixed(0)} đ',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Tổng Thiết Bị',
                      value: '$totalDevices',
                      sub: 'Đang quản lý',
                      icon: Icons.devices_rounded,
                      color: const Color(0xFF09090B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Tài Khoản',
                      value: '${_systemAccounts.length}',
                      sub: 'Admin, Staff & User',
                      icon: Icons.groups_2_rounded,
                      color: const Color(0xFF27272A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Trạm Định Vị',
                      value: '24/24',
                      sub: 'Tín hiệu GPS ổn định',
                      icon: Icons.satellite_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Video Call QC',
                      value: 'Sẵn Sàng',
                      sub: 'LiveKit SFU Cloud',
                      icon: Icons.video_camera_front_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Danh sách thiết bị mới cập nhật
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'THIẾT BỊ MỚI CẬP NHẬT GẦN ĐÂY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Xem tất cả'),
                    onPressed: () => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ..._deviceController.devices.take(4).map((d) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: const Icon(Icons.devices_rounded, color: AppColors.primaryDark),
                    ),
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    subtitle: Text('${d.category} • ${d.price.toStringAsFixed(0)} đ • Độ tuổi: ${d.minAge}-${d.maxAge} tuổi'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openEditDevice(d),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ================= TAB 1: QUẢN LÝ CRUD THIẾT BỊ =================
  Widget _buildDeviceCrudTab() {
    return ListenableBuilder(
      listenable: _deviceController,
      builder: (context, _) {
        final filtered = _deviceController.devices.where((d) {
          if (_categoryFilter != 'Tất cả' && d.category != _categoryFilter) {
            return false;
          }
          final q = _catalogQueryCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            return d.name.toLowerCase().contains(q) ||
                (d.brand?.toLowerCase().contains(q) ?? false) ||
                (d.modelNumber?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _catalogQueryCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm thiết bị trẻ em...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _catalogQueryCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _catalogQueryCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Thêm Mới'),
                        onPressed: () async {
                          final added = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceFormScreen(
                                deviceController: _deviceController,
                              ),
                            ),
                          );
                          if (added == true) {
                            _deviceController.loadDevices();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Category filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Tất cả',
                        'SmartWatch',
                        'Tablet',
                        'EducationalToy',
                        'Monitor',
                        'SafetyDevice',
                      ].map((cat) {
                        final isSel = _categoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.primaryDark,
                            onSelected: (_) => setState(() => _categoryFilter = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _deviceController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              const Text('Không tìm thấy thiết bị phù hợp', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _deviceController.loadDevices(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final item = filtered[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.phonelink_ring_rounded, color: AppColors.primaryDark),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Hãng: ${item.brand ?? "Kiddo"} • Danh mục: ${item.category}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                            Text(
                                              'Độ tuổi: ${item.minAge}-${item.maxAge} tuổi • Tồn kho: ${item.stockQuantity}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.price.toStringAsFixed(0)} VNĐ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                            onPressed: () => _openEditDevice(item),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                            onPressed: () => _confirmRemoveDevice(item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  // ================= TAB 3: QUẢN LÝ PHÂN QUYỀN & TÀI KHOẢN (CRUD) =================
  Widget _buildRoleManagementTab() {
    final list = _systemAccounts.where((u) {
      if (_roleFilter != 'ALL' && u['role'] != _roleFilter) return false;
      final q = _accountQueryCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        return u['name'].toString().toLowerCase().contains(q) ||
            u['email'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _accountQueryCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm tài khoản theo tên hoặc email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Thêm'),
                    onPressed: _openAddAccountDialog,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['ALL', 'ADMIN', 'STAFF', 'USER'].map((r) {
                  final sel = _roleFilter == r;
                  return ChoiceChip(
                    label: Text(
                      r,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: sel,
                    selectedColor: AppColors.primaryDark,
                    onSelected: (_) => setState(() => _roleFilter = r),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadUsersFromApi,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final u = list[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                u['name'].toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  Text(
                                    '${u['email']} • Quyền: ${u['role']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.manage_accounts_rounded, color: AppColors.primaryDark),
                              tooltip: 'Phân quyền',
                              onPressed: () => _openRolePickerDialog(u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              tooltip: 'Xóa tài khoản',
                              onPressed: () => _confirmRemoveAccount(u),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ================= TAB 4: HỆ THỐNG & CÀI ĐẶT =================
  Widget _buildAdminSettingsTab() {
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
                user?.fullName ?? 'Hồng Hoàng Khang (Admin)',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              Text(user?.email ?? 'honghoangkhang.admin@gmail.com',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Divider(height: 22),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                value: _strictChildSafetyMode,
                title: const Text('Bắt buộc kiểm duyệt bức xạ & giới hạn độ tuổi thiết bị',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                onChanged: (v) => setState(() => _strictChildSafetyMode = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              const Text('Thông Tin Máy Chủ Backend & LiveKit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _buildSettingInfoRow('Endpoint API:', 'https://mobile.zeion.online/api'),
              _buildSettingInfoRow('LiveKit Server:', 'wss://omnicaller-52xusnar.livekit.cloud'),
              _buildSettingInfoRow('Phiên bản App:', '1.0.0+1 (Hồng Hoàng Khang)'),
              _buildSettingInfoRow('Trạng thái Database:', 'Đã kết nối trực tiếp MS SQL Server'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng Xuất Khỏi Quản Trị'),
          onPressed: _logoutAdmin,
        ),
      ],
    );
  }

  Widget _buildSettingInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
