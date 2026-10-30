import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../device/data/models/device_model.dart';
import '../controllers/order_controller.dart';

class CreateOrderDialog extends StatefulWidget {
  final Device device;
  final AuthController authController;
  final OrderController orderController;

  const CreateOrderDialog({
    super.key,
    required this.device,
    required this.authController,
    required this.orderController,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Device device,
    required AuthController authController,
    required OrderController orderController,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CreateOrderDialog(
        device: device,
        authController: authController,
        orderController: orderController,
      ),
    );
  }

  @override
  State<CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<CreateOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  final TextEditingController _notesCtrl = TextEditingController();
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.authController.currentUser;
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '0901234567');
    _addressCtrl = TextEditingController(
      text: 'Số 475A Điện Biên Phủ, Phường 25, Quận Bình Thạnh, TP.HCM',
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.orderController.createOrder(
      shippingAddress: _addressCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: [
        {
          'deviceId': widget.device.id,
          'quantity': _quantity,
        }
      ],
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text('Đã đặt trang bị "${widget.device.name}" thành công!'),
        ),
      );
    } else {
      final err = widget.orderController.errorMessage ?? 'Không thể gửi đơn hàng';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(err),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.device.price * _quantity;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Trang Bị Thiết Bị Cho Bé',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phonelink_setup_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.device.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          Text(
                            '${widget.device.price.toStringAsFixed(0)} đ / gói',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Số lượng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số lượng thiết bị:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),

              // Số điện thoại liên hệ
              const Text('Số điện thoại phụ huynh *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Nhập số điện thoại liên hệ',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập SĐT' : null,
              ),
              const SizedBox(height: 12),

              // Địa chỉ nhận / cấu hình
              const Text('Địa chỉ nhận thiết bị / Kích hoạt SafeZone *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Địa chỉ nhà riêng hoặc trường học của bé',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),

              // Ghi chú cho kỹ thuật viên
              const Text('Ghi chú cấu hình cho Kỹ thuật viên (STAFF)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  hintText: 'vd: Cài sẵn giờ giới nghiêm 21h, cài bán kính an toàn',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Tổng tiền
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng chi phí:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text(
                      '${total.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submitOrder,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Xác Nhận Đặt Hàng'),
        ),
      ],
    );
  }
}
