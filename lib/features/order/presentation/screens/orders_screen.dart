import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../../data/models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  final AuthController authController;
  final bool isEmbedded;

  const OrdersScreen({
    super.key,
    required this.authController,
    this.isEmbedded = false,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderController _orderController = OrderController();
  String _selectedStatus = 'Tất cả';

  final List<String> _statusFilters = [
    'Tất cả',
    'Pending',
    'Confirmed',
    'Processing',
    'Shipping',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _orderController.loadOrders();
  }

  void _filterByStatus(String status) {
    setState(() => _selectedStatus = status);
    _orderController.loadOrders(status: status == 'Tất cả' ? null : status);
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Hủy Đơn Hàng / Gói Thiết Bị',
      content: 'Bạn có chắc chắn muốn hủy đơn hàng ${order.orderNumber}?',
      confirmText: 'Xác nhận hủy',
    );
    if (!ok || !mounted) return;

    final success = await _orderController.cancelOrder(order.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
          content: Text('Đã hủy đơn hàng ${order.orderNumber}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(_orderController.errorMessage ?? 'Không thể hủy đơn hàng'),
        ),
      );
    }
  }

  Future<void> _openStatusDialog(OrderModel order) async {
    final statusList = ['Pending', 'Confirmed', 'Processing', 'Shipping', 'Delivered', 'Cancelled'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đổi Trạng Thái (${order.orderNumber})',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusList.map((st) {
            final isCurrent = order.status.toLowerCase() == st.toLowerCase();
            return ListTile(
              dense: true,
              leading: Icon(
                isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isCurrent ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                _translateStatus(st),
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await _orderController.updateOrderStatus(order.id, st);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.success,
                      content: Text('Đã cập nhật đơn ${order.orderNumber} sang "${_translateStatus(st)}"'),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _translateStatus(String st) {
    switch (st.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'processing':
        return 'Đang xử lý / Kỹ thuật cấu hình';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã bàn giao cho bé';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return st;
    }
  }

  Color _getStatusColor(String st) {
    switch (st.toLowerCase()) {
      case 'pending':
        return const Color(0xFFEAB308);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'processing':
        return const Color(0xFF8B5CF6);
      case 'shipping':
        return const Color(0xFF06B6D4);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaffOrAdmin = widget.authController.isAdmin || widget.authController.isStaff;

    Widget body = Column(
      children: [
        // Filter horizontal bar
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _statusFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final st = _statusFilters[i];
              final isSel = _selectedStatus == st;
              return ChoiceChip(
                label: Text(
                  st == 'Tất cả' ? 'Tất cả' : _translateStatus(st),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSel ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isSel,
                selectedColor: AppColors.primaryDark,
                onSelected: (_) => _filterByStatus(st),
              );
            },
          ),
        ),

        // Orders List
        Expanded(
          child: ListenableBuilder(
            listenable: _orderController,
            builder: (context, _) {
              if (_orderController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_orderController.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        isStaffOrAdmin ? 'Chưa có đơn hàng nào trong hệ thống' : 'Bạn chưa có yêu cầu trang bị thiết bị nào',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Các đơn đặt mua thiết bị hoặc kích hoạt SafeZone sẽ hiển thị ở đây.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tải lại'),
                        onPressed: () => _orderController.loadOrders(),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _orderController.loadOrders(
                  status: _selectedStatus == 'Tất cả' ? null : _selectedStatus,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orderController.orders.length,
                  itemBuilder: (context, idx) {
                    final order = _orderController.orders[idx];
                    final stColor = _getStatusColor(order.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Order Number + Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      order.orderNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: stColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: stColor.withAlpha(80)),
                                  ),
                                  child: Text(
                                    order.statusDisplay,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: stColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Customer & Address
                            if (isStaffOrAdmin) ...[
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Phụ huynh: ${order.userName}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SĐT: ${order.phoneNumber}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (order.shippingAddress != null && order.shippingAddress!.isNotEmpty) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Địa chỉ: ${order.shippingAddress}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (order.notes != null && order.notes!.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.note_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Ghi chú: ${order.notes}',
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],

                            // Items List
                            if (order.items.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: order.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '• ${item.deviceName} (x${item.quantity})',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Text(
                                            '${item.totalPrice.toStringAsFixed(0)} đ',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),

                            // Total & Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(
                                      '${order.totalAmount.toStringAsFixed(0)} VNĐ',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (order.isCancellable)
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => _cancelOrder(order),
                                        child: const Text('Hủy Đơn', style: TextStyle(fontSize: 12)),
                                      ),
                                    if (isStaffOrAdmin) ...[
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                                        label: const Text('Đổi Trạng Thái', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryDark,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => _openStatusDialog(order),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isStaffOrAdmin ? 'Quản Lý Đơn Hàng & Gói Thiết Bị' : 'Đơn Hàng Của Tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _orderController.loadOrders(
              status: _selectedStatus == 'Tất cả' ? null : _selectedStatus,
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
