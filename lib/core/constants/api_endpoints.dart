class ApiEndpoints {
  // Auth endpoints
  static const String login = '/Auth/login';
  static const String biometricLogin = '/Auth/biometric-login';
  static const String register = '/Auth/register';
  static const String googleAuth = '/Auth/google';
  static const String sendOtp = '/Auth/send-otp';
  static const String sendLoginOtp = '/Auth/send-login-otp';
  static const String verifyOtp = '/Auth/verify-otp';
  static const String me = '/Auth/me';
  static const String profile = '/Auth/profile';
  static const String users = '/Auth/users';
  static String updateUserRole(int userId) => '/Auth/users/$userId/role';

  // Device endpoints
  static const String devices = '/Devices';
  static String deviceDetail(int id) => '/Devices/$id';

  // Order endpoints
  static const String orders = '/Orders';
  static String orderDetail(int id) => '/Orders/$id';
  static String orderStatus(int id) => '/Orders/$id/status';
  static String orderCancel(int id) => '/Orders/$id/cancel';

  // Review endpoints
  static const String reviews = '/Reviews';
  static String reviewDetail(int id) => '/Reviews/$id';

  // Video Call endpoints (LiveKit - Dành cho Phụ huynh và Kỹ thuật viên)
  static const String videoCallRooms = '/VideoCall/rooms';
  static const String videoCallCreate = '/VideoCall/create-room';
  static const String videoCallJoin = '/VideoCall/join';
  static const String videoCallLeave = '/VideoCall/leave';
  static String videoCallRoom(String roomName) => '/VideoCall/rooms/$roomName';
  static String videoCallParticipants(String roomName) => '/VideoCall/rooms/$roomName/participants';
  static String videoCallEnd(String roomName) => '/VideoCall/rooms/$roomName';
}
