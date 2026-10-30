import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  final ApiClient apiClient;

  OrderService({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  /// Lấy danh sách đơn hàng (User chỉ thấy đơn của mình, Admin/Staff thấy tất cả)
  Future<List<OrderModel>> getOrders({
    int pageNumber = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'Tất cả') {
      queryParams['status'] = status;
    }

    final query = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final path = '${ApiEndpoints.orders}?$query';

    final response = await apiClient.get(path, auth: true);
    final data = response['data'];
    if (data is Map<String, dynamic> && data['items'] is List) {
      final list = data['items'] as List;
      return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy chi tiết đơn hàng theo ID
  Future<OrderModel?> getOrderById(int id) async {
    final response = await apiClient.get(ApiEndpoints.orderDetail(id), auth: true);
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return OrderModel.fromJson(data);
    }
    return null;
  }

  /// Tạo đơn hàng / Đăng ký trang bị thiết bị cho bé
  Future<OrderModel> createOrder({
    required String shippingAddress,
    required String phoneNumber,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items,
    };

    final response = await apiClient.post(ApiEndpoints.orders, body: body, auth: true);
    final data = response['data'];
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật trạng thái đơn hàng (Dành cho Admin & Staff)
  Future<OrderModel> updateOrderStatus(int id, String status) async {
    final body = {'status': status};
    final response = await apiClient.patch(ApiEndpoints.orderStatus(id), body: body, auth: true);
    final data = response['data'];
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Hủy đơn hàng
  Future<bool> cancelOrder(int id) async {
    await apiClient.post(ApiEndpoints.orderCancel(id), auth: true);
    return true;
  }
}
