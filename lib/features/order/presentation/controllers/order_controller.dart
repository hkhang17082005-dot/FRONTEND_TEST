import 'package:flutter/foundation.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService orderService;

  OrderController({OrderService? orderService})
      : orderService = orderService ?? OrderService();

  List<OrderModel> orders = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadOrders({String? status}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      orders = await orderService.getOrders(status: status);
    } catch (e) {
      errorMessage = _cleanError(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder({
    required String shippingAddress,
    required String phoneNumber,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    errorMessage = null;
    try {
      final newOrder = await orderService.createOrder(
        shippingAddress: shippingAddress,
        phoneNumber: phoneNumber,
        notes: notes,
        items: items,
      );
      orders.insert(0, newOrder);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    errorMessage = null;
    try {
      final updatedOrder = await orderService.updateOrderStatus(id, status);
      final index = orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        orders[index] = updatedOrder;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(int id) async {
    errorMessage = null;
    try {
      await orderService.cancelOrder(id);
      final index = orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        final current = orders[index];
        orders[index] = OrderModel(
          id: current.id,
          orderNumber: current.orderNumber,
          userId: current.userId,
          userName: current.userName,
          totalAmount: current.totalAmount,
          status: 'Cancelled',
          shippingAddress: current.shippingAddress,
          phoneNumber: current.phoneNumber,
          notes: current.notes,
          createdAt: current.createdAt,
          items: current.items,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  String _cleanError(String raw) {
    return raw
        .replaceAll('ApiException: ', '')
        .replaceAll('Exception: ', '');
  }
}
