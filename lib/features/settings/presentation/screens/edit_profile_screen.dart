import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthController authController;

  const EditProfileScreen({
    super.key,
    required this.authController,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();

  bool _isSaving = false;
  int _selectedAvatarIndex = 0;

  final List<IconData> _avatarIcons = [
    Icons.face_retouching_natural_rounded,
    Icons.person_rounded,
    Icons.account_circle_rounded,
    Icons.sentiment_very_satisfied_rounded,
    Icons.family_restroom_rounded,
    Icons.shield_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.authController.currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? 'Hồng Hoàng Khang');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '0901234567');
    _emailCtrl = TextEditingController(text: user?.email ?? 'honghoangkhang@gmail.com');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await widget.authController.updateCurrentUserProfile(
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: Text('Đã cập nhật hồ sơ cá nhân thành công!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cập Nhật Hồ Sơ Cá Nhân', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('LƯU', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar selector
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(_avatarIcons[_selectedAvatarIndex], size: 50, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 10),
                    const Text('Chọn biểu tượng đại diện:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_avatarIcons.length, (idx) {
                        final isSel = _selectedAvatarIndex == idx;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatarIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? AppColors.primaryDark : AppColors.primarySoft,
                            ),
                            child: Icon(_avatarIcons[idx], size: 20, color: isSel ? Colors.white : AppColors.primaryDark),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form fields
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
                    const Text('Họ và tên *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Nhập họ và tên đầy đủ',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 14),

                    const Text('Số điện thoại liên hệ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Nhập số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Địa chỉ Email (Định danh)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      enabled: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        suffixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Change password card
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
                    const Row(
                      children: [
                        Icon(Icons.password_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Thay Đổi Mật Khẩu (Tùy chọn)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Mật khẩu hiện tại (Anhhung1@)',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Mật khẩu mới',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu Thay Đổi Hồ Sơ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
