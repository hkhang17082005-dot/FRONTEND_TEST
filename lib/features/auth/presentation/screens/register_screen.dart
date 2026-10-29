import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/role_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../../data/models/user_model.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  final AuthController authController;

  const RegisterScreen({
    super.key,
    required this.authController,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final UserRoleType _defaultRole = UserRoleType.user;

  final List<TextEditingController> _otpInputs =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes =
      List.generate(6, (_) => FocusNode());

  int _step = 0;
  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _acceptedPolicy = true;

  Timer? _timer;
  int _remainingSeconds = 60;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpInputs) {
      c.dispose();
    }
    for (final f in _otpNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
      }
    });
  }

  String _readOtp() => _otpInputs.map((c) => c.text).join().trim();

  Future<void> _sendOtpStep() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Vui lòng đồng ý điều khoản bảo vệ trẻ em của ứng dụng'),
        ),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final sent = await widget.authController.sendOtp(email: email);
    if (!mounted) return;

    if (sent) {
      setState(() => _step = 1);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Đã gửi mã OTP kích hoạt tới $email'),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_otpNodes.isNotEmpty) _otpNodes.first.requestFocus();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(
            widget.authController.errorMessage ?? 'Không thể gửi mã OTP',
          ),
        ),
      );
    }
  }

  Future<void> _completeRegistration() async {
    FocusScope.of(context).unfocus();
    final otp = _readOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Vui lòng nhập đủ 6 số OTP'),
        ),
      );
      return;
    }

    final ok = await widget.authController.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      otp: otp,
      role: _defaultRole.label,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Đăng ký tài khoản Phụ huynh thành công!'),
        ),
      );
      RoleRouter.navigateToRoleHome(context, widget.authController);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(
            widget.authController.errorMessage ?? 'Xác thực OTP thất bại',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Tạo Tài Khoản Gia Đình'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _step == 0 ? _buildStep1InfoForm() : _buildStep2OtpConfirm(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1InfoForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.family_restroom_rounded, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đăng ký Hồ sơ Phụ huynh',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Kết nối đồng hồ GPS & quản lý điện thoại của bé',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _nameCtrl,
            validator: (v) => Validators.required(v, 'họ và tên'),
            decoration: const InputDecoration(
              labelText: 'Họ và tên Phụ huynh',
              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            decoration: const InputDecoration(
              labelText: 'Email nhận mã OTP',
              prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _passCtrl,
            obscureText: _hidePass,
            validator: (v) => Validators.minLength(v, 6, 'Mật khẩu'),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hidePass = !_hidePass),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _confirmCtrl,
            obscureText: _hideConfirm,
            validator: (val) => Validators.confirmPassword(val, _passCtrl.text),
            decoration: InputDecoration(
              labelText: 'Nhập lại mật khẩu',
              prefixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: _acceptedPolicy,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _acceptedPolicy = v ?? true),
              ),
              const Expanded(
                child: Text(
                  'Tôi đồng ý với chính sách bảo mật vị trí & dữ liệu trẻ em.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListenableBuilder(
            listenable: widget.authController,
            builder: (context, _) {
              final loading = widget.authController.isLoading;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _sendOtpStep,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    loading ? 'Đang gửi mã OTP...' : 'Gửi Mã OTP Xác Thực Email',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          ListenableBuilder(
            listenable: widget.authController,
            builder: (context, _) {
              return GoogleSignInButton(
                text: 'Đăng ký nhanh bằng Google (OAuth 2.0)',
                isLoading: widget.authController.isGoogleLoading,
                onPressed: () {
                  GoogleSignInButton.handleGoogleAuth(
                    context,
                    widget.authController,
                    isRegister: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2OtpConfirm() {
    return Column(
      children: [
        const Icon(Icons.mark_email_unread_rounded, size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text(
          'Nhập mã OTP kích hoạt',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Mã xác thực gồm 6 chữ số đã gửi tới ${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (idx) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _otpInputs[idx],
                focusNode: _otpNodes[idx],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
                onChanged: (v) {
                  if (v.isNotEmpty && idx < 5) {
                    _otpNodes[idx + 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _completeRegistration,
            child: const Text(
              'Hoàn Tất Đăng Ký',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Quay lại sửa thông tin'),
        ),
      ],
    );
  }
}
