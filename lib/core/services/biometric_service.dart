import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricHardwareService {
  BiometricHardwareService._();
  static final BiometricHardwareService instance = BiometricHardwareService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra xem thiết bị (như Samsung Galaxy Tab S9) có hỗ trợ sinh trắc học không
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra xem thiết bị đã đăng ký / có thể quét vân tay/khuôn mặt không
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Danh sách các loại sinh trắc học hỗ trợ trên thiết bị
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// Kiểm tra có cảm biến vân tay phần cứng không
  Future<bool> hasFingerprintHardware() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  /// Gọi hộp thoại quét vân tay gốc của máy Samsung Galaxy Tab S9
  Future<BiometricAuthResult> authenticateWithFingerprint({
    String reason = 'Chạm ngón tay vào cảm biến vân tay trên màn hình Galaxy Tab S9 để đăng nhập',
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Thiết bị không hỗ trợ cảm biến sinh trắc học hoặc chưa thiết lập vân tay trong máy.',
          isHardwareUnavailable: true,
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực vân tay Samsung Galaxy Tab S9',
            signInHint: 'Chạm ngón tay vào cảm biến vân tay trên màn hình',
            cancelButton: 'Hủy bỏ',
          ),
        ],
      );

      if (authenticated) {
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Đã hủy hoặc quét vân tay chưa đúng.',
        );
      }
    } on LocalAuthException catch (e) {
      String message;
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          message = 'Máy Galaxy Tab S9 chưa đăng ký dấu vân tay nào trong Cài Đặt của máy.';
          break;
        case LocalAuthExceptionCode.noBiometricHardware:
          message = 'Không tìm thấy phần cứng cảm biến vân tay trên thiết bị này.';
          break;
        case LocalAuthExceptionCode.temporaryLockout:
          message = 'Cảm biến vân tay bị tạm khóa do nhập sai nhiều lần. Vui lòng thử lại sau.';
          break;
        case LocalAuthExceptionCode.biometricLockout:
          message = 'Cảm biến vân tay bị khóa. Cần mở khóa thiết bị bằng mật khẩu/PIN máy.';
          break;
        case LocalAuthExceptionCode.userCanceled:
          message = 'Người dùng đã hủy quét vân tay.';
          break;
        default:
          message = e.description ?? 'Lỗi sinh trắc học: ${e.code.name}';
      }
      return BiometricAuthResult(
        success: false,
        errorMessage: message,
        errorCode: e.code.name,
      );
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Lỗi phần cứng thiết bị: ${e.message ?? e.code}',
        errorCode: e.code,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Lỗi xác thực: $e',
      );
    }
  }

  /// Gọi hộp thoại nhận diện khuôn mặt gốc của máy
  Future<BiometricAuthResult> authenticateWithFace({
    String reason = 'Hướng camera vào khuôn mặt của bạn để đăng nhập',
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Thiết bị không hỗ trợ nhận diện khuôn mặt sinh trắc học.',
          isHardwareUnavailable: true,
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Nhận diện khuôn mặt Face ID',
            signInHint: 'Hướng camera trước về phía khuôn mặt của bạn',
            cancelButton: 'Hủy bỏ',
          ),
        ],
      );

      if (authenticated) {
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Đã hủy hoặc nhận diện khuôn mặt không khớp.',
        );
      }
    } on LocalAuthException catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: e.description ?? 'Lỗi nhận diện khuôn mặt (${e.code.name})',
        errorCode: e.code.name,
      );
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Lỗi thiết bị: ${e.message ?? e.code}',
        errorCode: e.code,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Lỗi: $e',
      );
    }
  }

  /// Hủy quá trình quét
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final bool isHardwareUnavailable;

  BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.isHardwareUnavailable = false,
  });
}
