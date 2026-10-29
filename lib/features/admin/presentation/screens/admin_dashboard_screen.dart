import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../device/data/models/device_model.dart';
import '../../../device/presentation/controllers/device_controller.dart';
import '../../../device/presentation/screens/device_form_screen.dart';

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
                onTap: () {
                  setState(() => acc['role'] = r);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryDark,
                      content: Text('Đã cập nhật quyền của ${acc['name']} thành $r'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        final count = _deviceController.devices.length;
        return RefreshIndicator(
          onRefresh: () => _deviceController.loadDevices(),
          child: ListView(
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
                    const Text(
                      'Trung Tâm Điều Hành Khang KidSafe',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'API Server: https://mobile.zeion.online/api • Trạng thái: Hoạt động 100%',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildAdminKpiBox('Kho Thiết Bị', '$count mẫu', Icons.watch_rounded),
                        const SizedBox(width: 10),
                        _buildAdminKpiBox('Tài Khoản', '${_systemAccounts.length} user', Icons.group_rounded),
                        const SizedBox(width: 10),
                        _buildAdminKpiBox('Phân Quyền', '3 Role', Icons.security_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Thêm Thiết Bị Mới'),
                      onPressed: () async {
                        final added = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeviceFormScreen(deviceController: _deviceController),
                          ),
                        );
                        if (added == true) _deviceController.loadDevices();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Làm Mới API'),
                      onPressed: () => _deviceController.loadDevices(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhật ký An toàn & Phân quyền Hệ thống',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_rounded, color: AppColors.success),
                      title: Text('Đồng bộ danh mục Thiết bị trẻ em từ Server Deploy'),
                      subtitle: Text('https://mobile.zeion.online/api/Devices'),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.verified_user_rounded, color: AppColors.primary),
                      title: Text('Xác thực 2 lớp (Email + OTP 6 số) & Google OAuth 2.0'),
                      subtitle: Text('Hoạt động ổn định cho cả 3 Role: Admin, Staff, User'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminKpiBox(String title, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(height: 6),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: QUẢN LÝ KHO THIẾT BỊ (FULL CRUD) =================
  Widget _buildDeviceCrudTab() {
    return ListenableBuilder(
      listenable: _deviceController,
      builder: (context, _) {
        final items = _deviceController.devices.where((d) {
          if (_categoryFilter != 'Tất cả' && d.category != _categoryFilter) {
            return false;
          }
          final q = _catalogQueryCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            return d.name.toLowerCase().contains(q) ||
                (d.brand?.toLowerCase().contains(q) ?? false);
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
                          decoration: const InputDecoration(
                            hintText: 'Tìm thiết bị trong kho để Sửa / Xóa...',
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm'),
                        onPressed: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceFormScreen(deviceController: _deviceController),
                            ),
                          );
                          if (created == true) _deviceController.loadDevices();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tất cả', ...Device.defaultCategories].map((c) {
                        final sel = _categoryFilter == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              c,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: sel,
                            selectedColor: AppColors.primary,
                            onSelected: (_) => setState(() => _categoryFilter = c),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _deviceController.isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: () => _deviceController.loadDevices(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final d = items[idx];
                          return Container(
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
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.devices_rounded, color: AppColors.primaryDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                                      Text('${d.category} • Tồn: ${d.stockQuantity} • ${d.price.toStringAsFixed(0)} đ',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Sửa thiết bị',
                                  icon: const Icon(Icons.edit_rounded, color: AppColors.primaryDark),
                                  onPressed: () => _openEditDevice(d),
                                ),
                                IconButton(
                                  tooltip: 'Xóa thiết bị',
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                  onPressed: () => _confirmRemoveDevice(d),
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
      },
    );
  }

  // ================= TAB 2: QUẢN LÝ PHÂN QUYỀN TÀI KHOẢN =================
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
          child: Row(
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
        ),
        Expanded(
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
                        u['name'].toString().substring(0, 1),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('${u['email']} • Quyền: ${u['role']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.manage_accounts_rounded, color: AppColors.primaryDark),
                      onPressed: () => _openRolePickerDialog(u),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất khỏi Admin Center', style: TextStyle(fontWeight: FontWeight.w800)),
          onPressed: _logoutAdmin,
        ),
      ],
    );
  }
}
