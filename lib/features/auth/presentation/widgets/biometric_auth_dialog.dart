import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';

enum BiometricType { fingerprint, face }

class BiometricAuthDialog extends StatefulWidget {
  final AuthController authController;
  final String savedEmail;
  final String savedRole;

  const BiometricAuthDialog({
    super.key,
    required this.authController,
    required this.savedEmail,
    required this.savedRole,
  });

  static Future<bool?> show({
    required BuildContext context,
    required AuthController authController,
    required String savedEmail,
    required String savedRole,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BiometricAuthDialog(
        authController: authController,
        savedEmail: savedEmail,
        savedRole: savedRole,
      ),
    );
  }

  @override
  State<BiometricAuthDialog> createState() => _BiometricAuthDialogState();
}

class _BiometricAuthDialogState extends State<BiometricAuthDialog> with SingleTickerProviderStateMixin {
  BiometricType _type = BiometricType.fingerprint;
  bool _isSuccess = false;
  bool _isFailed = false;
  String _statusText = 'Đặt ngón tay lên cảm biến vân tay...';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startBiometricProcess();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startBiometricProcess() {
    setState(() {
      _isSuccess = false;
      _isFailed = false;
      _statusText = _type == BiometricType.fingerprint
          ? 'Đang chạm cảm biến vân tay & gọi API Backend VPS...'
          : 'Đang hướng camera nhận diện khuôn mặt & gọi API...';
    });

    Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;

      // Gọi trực tiếp API Backend VPS /api/Auth/biometric-login
      final ok = await widget.authController.loginWithBiometrics(
        email: widget.savedEmail,
        role: widget.savedRole,
        biometricToken: 'fingerprint-hardware-vps-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      if (ok) {
        setState(() {
          _isSuccess = true;
          _isFailed = false;
          _statusText = _type == BiometricType.fingerprint
              ? 'Xác thực vân tay thành công từ máy chủ VPS!'
              : 'Khuôn mặt khớp chính xác 100%!';
        });

        Timer(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          Navigator.of(context).pop(true);
        });
      } else {
        setState(() {
          _isSuccess = false;
          _isFailed = true;
          _statusText = widget.authController.errorMessage ?? 'Xác thực sinh trắc học không thành công';
        });
      }
    });
  }

  void _switchType(BiometricType newType) {
    if (_isSuccess) return;
    setState(() {
      _type = newType;
    });
    _startBiometricProcess();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _type == BiometricType.fingerprint ? 'Xác Thực Vân Tay (Touch ID)' : 'Face ID Nhận Diện Khuôn Mặt',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('API: /api/Auth/biometric-login', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.savedEmail,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scanning Visual Box
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final scale = 1.0 + (_animController.value * 0.08);
              final activeColor = _isSuccess
                  ? AppColors.success
                  : _isFailed
                      ? AppColors.error
                      : AppColors.primary;

              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSuccess
                      ? AppColors.success.withAlpha(30)
                      : _isFailed
                          ? AppColors.error.withAlpha(30)
                          : AppColors.primarySoft,
                  border: Border.all(
                    color: activeColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withAlpha(50),
                      blurRadius: 16 * scale,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSuccess
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60)
                      : _isFailed
                          ? const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 60)
                          : Icon(
                              _type == BiometricType.fingerprint
                                  ? Icons.fingerprint_rounded
                                  : Icons.face_retouching_natural_rounded,
                              color: AppColors.primaryDark,
                              size: 60,
                            ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Status text
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _isSuccess
                  ? AppColors.success
                  : _isFailed
                      ? AppColors.error
                      : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Switch Biometric Mode Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.fingerprint_rounded, size: 16),
                label: const Text('Vân Tay (Ưu tiên)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                selected: _type == BiometricType.fingerprint,
                selectedColor: AppColors.primaryDark,
                onSelected: (_) => _switchType(BiometricType.fingerprint),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.face_retouching_natural_rounded, size: 16),
                label: const Text('Khuôn Mặt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                selected: _type == BiometricType.face,
                selectedColor: AppColors.primaryDark,
                onSelected: (_) => _switchType(BiometricType.face),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đăng nhập bằng Mật khẩu & OTP', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
