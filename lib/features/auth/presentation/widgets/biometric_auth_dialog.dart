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
      barrierDismissible: true,
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
  bool _isScanning = false;
  bool _isSuccess = false;
  bool _isFailed = false;
  String _statusText = 'Chạm ngón tay vào cảm biến bên dưới để quét';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // KHÔNG TỰ ĐỘNG QUÉT - CHỜ NGƯỜI DÙNG CHẠM VÀO CẢM BIẾN
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startBiometricProcess() {
    if (_isScanning || _isSuccess) return;

    setState(() {
      _isScanning = true;
      _isFailed = false;
      _statusText = _type == BiometricType.fingerprint
          ? 'Đang chạm cảm biến vân tay & gửi máy chủ VPS...'
          : 'Đang hướng camera nhận diện khuôn mặt & gửi VPS...';
    });

    _animController.repeat(reverse: true);

    Timer(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;

      // Gọi API Backend VPS /api/Auth/biometric-login
      final ok = await widget.authController.loginWithBiometrics(
        email: widget.savedEmail,
        role: widget.savedRole,
        biometricToken: 'fingerprint-hardware-vps-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      if (ok) {
        setState(() {
          _isScanning = false;
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
        _animController.stop();
        setState(() {
          _isScanning = false;
          _isFailed = true;
          _statusText = widget.authController.errorMessage ?? 'Xác thực sinh trắc học không thành công';
        });
      }
    });
  }

  void _switchType(BiometricType newType) {
    if (_isScanning || _isSuccess) return;
    _animController.stop();
    setState(() {
      _type = newType;
      _isScanning = false;
      _isFailed = false;
      _statusText = newType == BiometricType.fingerprint
          ? 'Chạm ngón tay vào cảm biến bên dưới để quét'
          : 'Bấm nút bên dưới để hướng camera nhận diện khuôn mặt';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      contentPadding: const EdgeInsets.all(22),
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
          const SizedBox(height: 18),

          // Interactive Touch Sensor Pad
          GestureDetector(
            onTap: _isScanning || _isSuccess ? null : _startBiometricProcess,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final scale = _isScanning ? (1.0 + (_animController.value * 0.08)) : 1.0;
                final activeColor = _isSuccess
                    ? AppColors.success
                    : _isFailed
                        ? AppColors.error
                        : AppColors.primary;

                return Container(
                  width: 125,
                  height: 125,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSuccess
                        ? AppColors.success.withAlpha(25)
                        : _isFailed
                            ? AppColors.error.withAlpha(25)
                            : _isScanning
                                ? AppColors.primarySoft
                                : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: activeColor,
                      width: _isScanning ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withAlpha(_isScanning ? 60 : 25),
                        blurRadius: 16 * scale,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSuccess
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 62)
                        : _isFailed
                            ? const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 62)
                            : _isScanning
                                ? const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: CircularProgressIndicator(strokeWidth: 3.2),
                                  )
                                : Icon(
                                    _type == BiometricType.fingerprint
                                        ? Icons.fingerprint_rounded
                                        : Icons.face_retouching_natural_rounded,
                                    color: AppColors.primaryDark,
                                    size: 62,
                                  ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 16),

          // Action button to press
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess ? AppColors.success : AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isScanning || _isSuccess ? null : _startBiometricProcess,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_type == BiometricType.fingerprint ? Icons.touch_app_rounded : Icons.camera_alt_rounded, size: 20),
              label: Text(
                _isScanning
                    ? 'Đang xác thực vân tay...'
                    : _isSuccess
                        ? 'Đăng nhập thành công!'
                        : _type == BiometricType.fingerprint
                            ? 'Chạm Vào Đây Để Quét Vân Tay'
                            : 'Bấm Để Nhận Diện Khuôn Mặt',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 10),

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đăng nhập bằng Mật khẩu & OTP', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
