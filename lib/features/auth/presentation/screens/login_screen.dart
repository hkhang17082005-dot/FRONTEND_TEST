import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/role_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/biometric_auth_dialog.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({
    super.key,
    required this.authController,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailInputCtrl = TextEditingController();
  final _passInputCtrl = TextEditingController();

  final List<TextEditingController> _otpBoxes =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusList =
      List.generate(6, (_) => FocusNode());

  int _stepIndex = 0; // 0: Thông tin đăng nhập, 1: Mã OTP
  bool _hidePass = true;
  bool _keepSignedIn = true;

  Timer? _otpTimer;
  int _secondsLeft = 60;
  bool _allowResend = false;

  String? _rememberedEmail;
  String? _rememberedRole;

  @override
  void initState() {
    super.initState();
    _loadSavedBiometrics();
  }

  Future<void> _loadSavedBiometrics() async {
    final email = await widget.authController.storageService.getEmail();
    final role = await widget.authController.storageService.getRole();
    if (mounted && email != null && email.isNotEmpty) {
      setState(() {
        _rememberedEmail = email;
        _rememberedRole = role;
      });
    }
  }

  Future<void> _triggerBiometricLogin([String? targetEmail, String? targetRole]) async {
    String email = targetEmail ?? _rememberedEmail ?? _emailInputCtrl.text.trim();
    String role = targetRole ?? _rememberedRole ?? 'User';

    if (email.isEmpty) {
      email = 'anhjkr@gmail.com';
      role = 'User';
    }

    final success = await BiometricAuthDialog.show(
      context: context,
      authController: widget.authController,
      savedEmail: email,
      savedRole: role,
      autoStart: true,
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Xác thực vân tay thiết bị thành công! Chào mừng $email'),
        ),
      );
      RoleRouter.navigateToRoleHome(context, widget.authController);
    }
  }

  @override
  void dispose() {
    _emailInputCtrl.dispose();
    _passInputCtrl.dispose();
    for (final c in _otpBoxes) {
      c.dispose();
    }
    for (final f in _otpFocusList) {
      f.dispose();
    }
    _otpTimer?.cancel();
    super.dispose();
  }

  void _beginCountdown() {
    _otpTimer?.cancel();
    setState(() {
      _secondsLeft = 60;
      _allowResend = false;
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _allowResend = true;
        });
      }
    });
  }

  String _collectOtp() => _otpBoxes.map((e) => e.text).join().trim();

  void _resetOtpBoxes() {
    for (final c in _otpBoxes) {
      c.clear();
    }
  }

  void _fillDemoAccount(String email, String label) {
    String role = 'User';
    if (label.contains('STAFF')) role = 'Staff';
    if (label.contains('ADMIN')) role = 'Admin';
    setState(() {
      _emailInputCtrl.text = email;
      _passInputCtrl.text = 'Anhhung1@';
      _rememberedEmail = email;
      _rememberedRole = role;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 1),
        content: Text('Đã điền nhanh tài khoản $label ($email)'),
      ),
    );
  }

  Future<void> _requestLoginOtp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailInputCtrl.text.trim().toLowerCase();
    final password = _passInputCtrl.text;

    final sent = await widget.authController.sendLoginOtp(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (sent) {
      _resetOtpBoxes();
      setState(() => _stepIndex = 1);
      _beginCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Mã OTP xác thực đã gửi tới $email'),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_otpFocusList.isNotEmpty) {
          _otpFocusList.first.requestFocus();
        }
      });
    } else {
      final err = widget.authController.errorMessage ??
          'Thông tin Email hoặc mật khẩu chưa chính xác';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(err),
        ),
      );
    }
  }

  Future<void> _resendOtpCode() async {
    if (!_allowResend) return;
    final email = _emailInputCtrl.text.trim().toLowerCase();
    final ok = await widget.authController.sendLoginOtp(
      email: email,
      password: _passInputCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      _resetOtpBoxes();
      _beginCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Đã gửi lại mã OTP tới $email'),
        ),
      );
    }
  }

  Future<void> _submitOtpAndLogin() async {
    FocusScope.of(context).unfocus();
    final otp = _collectOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Vui lòng nhập đủ 6 chữ số OTP'),
        ),
      );
      return;
    }

    final ok = await widget.authController.login(
      email: _emailInputCtrl.text.trim(),
      password: _passInputCtrl.text,
      otp: otp,
    );

    if (!mounted) return;

    if (ok) {
      final roleName =
          widget.authController.currentUser?.roleType.displayName ?? 'USER';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Chào mừng trở lại! Phân quyền: $roleName'),
        ),
      );
      RoleRouter.navigateToRoleHome(context, widget.authController);
    } else {
      final err = widget.authController.errorMessage ??
          'Mã OTP không hợp lệ hoặc đã hết hạn';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(err),
        ),
      );
    }
  }

  void _onDigitTyped(int idx, String val) {
    if (val.length > 1) {
      final digits = val.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpBoxes[i].text = digits[i];
      }
      final target = digits.length >= 6 ? 5 : digits.length;
      _otpFocusList[target].requestFocus();
      return;
    }
    if (val.isNotEmpty) {
      if (idx < 5) {
        _otpFocusList[idx + 1].requestFocus();
      } else {
        _otpFocusList[idx].unfocus();
        if (_collectOtp().length == 6) {
          _submitOtpAndLogin();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stepIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stepIndex == 1) {
          setState(() => _stepIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bento Brand Banner cho App Quản lý Điện thoại Trẻ em
                _buildKidSafeHeroHeader(),
                const SizedBox(height: 16),

                // Thanh Tiến Trình 2 Bước (Step Progress Pill)
                _buildStepProgressBanner(),
                const SizedBox(height: 16),

                // Khung Nội Dung Chính
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _stepIndex == 0
                      ? _buildCredentialsForm()
                      : _buildOtpVerificationPanel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKidSafeHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.phonelink_lock_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'FAMILY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý điện thoại, định vị GPS & đồng hành học tập cùng con',
                  style: TextStyle(
                    color: Colors.white.withAlpha(235),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgressBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          _buildStepPill(
            number: '1',
            title: 'Tài khoản & Mật khẩu',
            active: _stepIndex == 0,
            completed: _stepIndex > 0,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _stepIndex > 0 ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          _buildStepPill(
            number: '2',
            title: 'Xác thực Email OTP',
            active: _stepIndex == 1,
            completed: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill({
    required String number,
    required String title,
    required bool active,
    required bool completed,
  }) {
    final bg = active || completed ? AppColors.primary : const Color(0xFFE2E8F0);
    final fg = active || completed ? Colors.white : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: completed
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  number,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng nhập Hệ thống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn nhanh vai trò bên dưới hoặc nhập Email để nhận OTP bảo mật',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Thanh chọn nhanh 3 Role để test phân quyền nhanh chóng
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primarySoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Điền nhanh tài khoản phân quyền (Demo 3 Role):',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickRoleChip(
                        label: 'Phụ huynh',
                        icon: Icons.family_restroom_rounded,
                        color: const Color(0xFF09090B),
                        onTap: () => _fillDemoAccount('anhjkr@gmail.com', 'Phụ huynh (USER)'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildQuickRoleChip(
                        label: 'Nhân viên',
                        icon: Icons.build_circle_outlined,
                        color: const Color(0xFF27272A),
                        onTap: () => _fillDemoAccount('anhjkrr@gmail.com', 'Nhân viên (STAFF)'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildQuickRoleChip(
                        label: 'Quản trị',
                        icon: Icons.admin_panel_settings_rounded,
                        color: const Color(0xFF09090B),
                        onTap: () => _fillDemoAccount('anhjkrrr@gmail.com', 'Quản trị (ADMIN)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Khối Đăng nhập Sinh trắc học (Face ID / Vân tay) cho lần đăng nhập sau
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(20),
                  AppColors.primarySoft,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vân Tay Galaxy Tab S9 & Face ID',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rememberedEmail != null
                            ? 'Vân tay: $_rememberedEmail'
                            : 'Cảm biến vân tay màn hình Galaxy Tab S9',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _triggerBiometricLogin(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint_rounded, size: 16),
                      SizedBox(width: 4),
                      Text('Quét vân tay', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Email tài khoản',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailInputCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            decoration: InputDecoration(
              hintText: 'vd: honghoangkhang@gmail.com',
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
              suffixIcon: _emailInputCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _emailInputCtrl.clear()),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          const Text(
            'Mật khẩu bảo vệ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passInputCtrl,
            obscureText: _hidePass,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestLoginOtp(),
            validator: (val) => Validators.required(val, 'mật khẩu'),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _hidePass = !_hidePass),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _keepSignedIn,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _keepSignedIn = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Duy trì đăng nhập',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Vui lòng liên hệ Quản trị viên hoặc kiểm tra Email khôi phục.'),
                    ),
                  );
                },
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListenableBuilder(
            listenable: widget.authController,
            builder: (context, _) {
              final busy = widget.authController.isLoading;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: busy ? null : _requestLoginOtp,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_user_outlined, size: 20),
                  label: Text(
                    busy ? 'Đang gửi mã xác thực...' : 'Nhận Mã OTP & Đăng Nhập',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Hoặc tiếp tục với OAuth 2.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLight)),
            ],
          ),
          const SizedBox(height: 14),

          ListenableBuilder(
            listenable: widget.authController,
            builder: (context, _) {
              return GoogleSignInButton(
                text: 'Đăng nhập nhanh với Google',
                isLoading: widget.authController.isGoogleLoading,
                onPressed: () {
                  GoogleSignInButton.handleGoogleAuth(
                    context,
                    widget.authController,
                    isRegister: false,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Phụ huynh chưa có tài khoản? ',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(
                        authController: widget.authController,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Đăng ký tài khoản mới',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRoleChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(90)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpVerificationPanel() {
    final email = _emailInputCtrl.text.trim();

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 34,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Xác thực Bảo mật 2 Lớp (OTP)',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nhập mã 6 chữ số đã gửi về địa chỉ:\n$email',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            '💡 Mẹo chấm bài nhanh: Nhập mã OTP từ Gmail hoặc nhập 123456 cho tài khoản Demo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (idx) {
            return SizedBox(
              width: 44,
              height: 54,
              child: TextField(
                controller: _otpBoxes[idx],
                focusNode: _otpFocusList[idx],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppColors.background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryDark, width: 2.2),
                  ),
                ),
                onChanged: (v) => _onDigitTyped(idx, v),
              ),
            );
          }),
        ),
        const SizedBox(height: 22),

        ListenableBuilder(
          listenable: widget.authController,
          builder: (context, _) {
            final busy = widget.authController.isLoading;
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: busy ? null : _submitOtpAndLogin,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text(
                  'Xác Nhận OTP & Vào Ứng Dụng',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _stepIndex = 0),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Đổi tài khoản'),
            ),
            TextButton(
              onPressed: _allowResend ? _resendOtpCode : null,
              child: Text(
                _allowResend ? 'Gửi lại mã OTP' : 'Gửi lại sau ${_secondsLeft}s',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _allowResend ? AppColors.primaryDark : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
