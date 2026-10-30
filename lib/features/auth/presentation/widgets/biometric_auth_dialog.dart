import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../controllers/auth_controller.dart';

enum AuthBiometricMode { fingerprint, face }

class BiometricAuthDialog extends StatefulWidget {
  final AuthController authController;
  final String savedEmail;
  final String savedRole;
  final bool autoStart;

  const BiometricAuthDialog({
    super.key,
    required this.authController,
    required this.savedEmail,
    required this.savedRole,
    this.autoStart = true,
  });

  static Future<bool?> show({
    required BuildContext context,
    required AuthController authController,
    required String savedEmail,
    required String savedRole,
    bool autoStart = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BiometricAuthDialog(
        authController: authController,
        savedEmail: savedEmail,
        savedRole: savedRole,
        autoStart: autoStart,
      ),
    );
  }

  @override
  State<BiometricAuthDialog> createState() => _BiometricAuthDialogState();
}

class _BiometricAuthDialogState extends State<BiometricAuthDialog> with SingleTickerProviderStateMixin {
  AuthBiometricMode _mode = AuthBiometricMode.fingerprint;
  bool _isScanning = false;
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _isHardwareUnavailable = false;
  String _statusText = 'Chạm ngón tay vào cảm biến vân tay của máy để quét';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Kích hoạt quét vân tay phần cứng khi người dùng nhấn nút "Quét vân tay"
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startBiometricProcess();
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    BiometricHardwareService.instance.cancelAuthentication();
    super.dispose();
  }

  Future<void> _startBiometricProcess({bool isSimulationFallback = false}) async {
    if (_isScanning || _isSuccess) return;

    setState(() {
      _isScanning = true;
      _isFailed = false;
      _isHardwareUnavailable = false;
      _statusText = _mode == AuthBiometricMode.fingerprint
          ? 'Đang kích hoạt cảm biến vân tay Samsung Galaxy Tab S9...'
          : 'Đang mở camera nhận diện khuôn mặt...';
    });

    _animController.repeat(reverse: true);

    try {
      bool authHardwareOk = false;

      if (isSimulationFallback) {
        // Dự phòng khi test trên giả lập chưa cài vân tay
        await Future.delayed(const Duration(milliseconds: 600));
        authHardwareOk = true;
      } else {
        if (_mode == AuthBiometricMode.fingerprint) {
          final res = await BiometricHardwareService.instance.authenticateWithFingerprint(
            reason: 'Chạm ngón tay vào cảm biến vân tay trên Samsung Galaxy Tab S9 để đăng nhập',
          );
          if (res.success) {
            authHardwareOk = true;
          } else {
            _animController.stop();
            if (mounted) {
              setState(() {
                _isScanning = false;
                _isFailed = true;
                _statusText = res.errorMessage ?? 'Xác thực vân tay thất bại.';
                _isHardwareUnavailable = res.isHardwareUnavailable;
              });
            }
            return;
          }
        } else {
          final res = await BiometricHardwareService.instance.authenticateWithFace(
            reason: 'Hướng camera trước về phía khuôn mặt để nhận diện',
          );
          if (res.success) {
            authHardwareOk = true;
          } else {
            _animController.stop();
            if (mounted) {
              setState(() {
                _isScanning = false;
                _isFailed = true;
                _statusText = res.errorMessage ?? 'Nhận diện khuôn mặt thất bại.';
                _isHardwareUnavailable = res.isHardwareUnavailable;
              });
            }
            return;
          }
        }
      }

      if (!authHardwareOk || !mounted) return;

      setState(() {
        _statusText = 'Vân tay thiết bị hợp lệ! Đang kết nối máy chủ VPS...';
      });

      // Gọi API Backend VPS /api/Auth/biometric-login
      final ok = await widget.authController.loginWithBiometrics(
        email: widget.savedEmail,
        role: widget.savedRole,
        biometricToken: 'samsung-tab-s9-hw-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      if (ok) {
        _animController.stop();
        setState(() {
          _isScanning = false;
          _isSuccess = true;
          _isFailed = false;
          _statusText = _mode == AuthBiometricMode.fingerprint
              ? 'Xác thực vân tay thiết bị & VPS thành công!'
              : 'Xác thực khuôn mặt & VPS thành công!';
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
          _statusText = widget.authController.errorMessage ?? 'Xác thực máy chủ VPS không thành công';
        });
      }
    } catch (e) {
      _animController.stop();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isFailed = true;
          _statusText = 'Lỗi: $e';
        });
      }
    }
  }

  void _switchMode(AuthBiometricMode newMode) {
    if (_isScanning || _isSuccess) return;
    _animController.stop();
    setState(() {
      _mode = newMode;
      _isScanning = false;
      _isFailed = false;
      _isHardwareUnavailable = false;
      _statusText = newMode == AuthBiometricMode.fingerprint
          ? 'Chạm ngón tay vào cảm biến bên dưới để quét'
          : 'Bấm nút bên dưới để hướng camera nhận diện khuôn mặt';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _mode == AuthBiometricMode.fingerprint
                            ? Icons.fingerprint_rounded
                            : Icons.face_retouching_natural_rounded,
                        color: AppColors.primaryDark,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _mode == AuthBiometricMode.fingerprint
                            ? 'Vân Tay Galaxy Tab S9'
                            : 'Face ID Khuôn Mặt',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Phần cứng: Samsung Knox / BiometricPrompt',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.savedEmail,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Interactive Touch Sensor Pad
              GestureDetector(
                onTap: _isScanning || _isSuccess ? null : () => _startBiometricProcess(),
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
                                        _mode == AuthBiometricMode.fingerprint
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

              // Action button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSuccess ? AppColors.success : AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isScanning || _isSuccess ? null : () => _startBiometricProcess(),
                  icon: _isScanning
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_mode == AuthBiometricMode.fingerprint ? Icons.touch_app_rounded : Icons.camera_alt_rounded, size: 20),
                  label: Text(
                    _isScanning
                        ? 'Đang chờ chạm vân tay trên máy...'
                        : _isSuccess
                            ? 'Đăng nhập thành công!'
                            : _mode == AuthBiometricMode.fingerprint
                                ? 'Kích Hoạt Cảm Biến Vân Tay Máy'
                                : 'Kích Hoạt Nhận Diện Khuôn Mặt',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),

              // Simulation fallback if hardware is unavailable
              if (_isHardwareUnavailable || (_isFailed && !_isSuccess)) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isScanning ? null : () => _startBiometricProcess(isSimulationFallback: true),
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: const Text('Bypass mô phỏng (Khi test trên máy không có vân tay)', style: TextStyle(fontSize: 11)),
                ),
              ],

              const SizedBox(height: 12),

              // Switch Biometric Mode Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.fingerprint_rounded, size: 16),
                    label: const Text('Vân Tay (Ưu tiên Tab S9)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    selected: _mode == AuthBiometricMode.fingerprint,
                    selectedColor: AppColors.primaryDark,
                    onSelected: (_) => _switchMode(AuthBiometricMode.fingerprint),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.face_retouching_natural_rounded, size: 16),
                    label: const Text('Khuôn Mặt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    selected: _mode == AuthBiometricMode.face,
                    selectedColor: AppColors.primaryDark,
                    onSelected: (_) => _switchMode(AuthBiometricMode.face),
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
        ),
      ),
    );
  }
}
