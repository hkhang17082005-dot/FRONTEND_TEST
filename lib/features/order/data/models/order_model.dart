class OrderItemModel {
  final int id;
  final int deviceId;
  final String deviceName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      deviceId: json['deviceId'] is int ? json['deviceId'] : int.tryParse(json['deviceId']?.toString() ?? '0') ?? 0,
      deviceName: json['deviceName']?.toString() ?? 'Thiết bị trẻ em',
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final int userId;
  final String userName;
  final double totalAmount;
  final String status;
  final String? shippingAddress;
  final String? phoneNumber;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.phoneNumber,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList();
    }

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderNumber: json['orderNumber']?.toString() ?? '#KS-ORD',
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      userName: json['userName']?.toString() ?? 'Phụ huynh',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      shippingAddress: json['shippingAddress']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
      items: parsedItems,
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'processing':
        return 'Đang cấu hình thiết bị';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã bàn giao cho bé';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  bool get isCancellable =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed';
}
