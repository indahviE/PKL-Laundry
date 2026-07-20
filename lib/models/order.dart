import 'base_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  washing,
  drying,
  ironing,
  qualityCheck,
  ready,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  partial,
  paid,
  refunded,
}

/// FIX: sebelumnya `card`, sekarang `debit` — mengikuti metode yang
/// benar-benar dipakai di CreateOrderScreen (cash, transfer, debit,
/// ewallet). `ewallet` ditambahkan sebagai opsi baru.
enum PaymentMethod {
  cash,
  transfer,
  debit,
  ewallet,
}

enum PriorityLevel {
  low,
  normal,
  high,
  urgent,
}

/// Cara baju MASUK ke laundry.
/// walkIn  -> pelanggan datang & taruh baju sendiri ke counter
/// pickup  -> baju dijemput oleh kurir/driver ke lokasi pelanggan
enum OrderType {
  walkIn,
  pickup,
}

/// Cara baju KELUAR dari laundry.
/// selfPickup -> pelanggan ambil sendiri ke counter
/// delivery   -> diantar oleh kurir/driver ke lokasi pelanggan
enum DeliveryType {
  selfPickup,
  delivery,
}

/// Firestore nyimpen orderType/deliveryType pake snake_case
/// ('walk_in', 'self_pickup') sesuai yang ditulis CreateOrderScreen,
/// SEDANGKAN enum.name Dart hasilnya camelCase ('walkIn', 'selfPickup').
/// Dua helper ini yang jadi jembatan eksplisit antara keduanya, supaya
/// tidak diam-diam salah baca / nyasar ke default value.
String _orderTypeToFirestore(OrderType type) {
  switch (type) {
    case OrderType.walkIn:
      return 'walk_in';
    case OrderType.pickup:
      return 'pickup';
  }
}

OrderType _orderTypeFromFirestore(dynamic value) {
  switch (value) {
    case 'pickup':
      return OrderType.pickup;
    case 'walk_in':
      return OrderType.walkIn;
    default:
      // Dokumen lama / value tak dikenal -> default aman: walk-in.
      return OrderType.walkIn;
  }
}

String _deliveryTypeToFirestore(DeliveryType type) {
  switch (type) {
    case DeliveryType.selfPickup:
      return 'self_pickup';
    case DeliveryType.delivery:
      return 'delivery';
  }
}

DeliveryType _deliveryTypeFromFirestore(dynamic value) {
  switch (value) {
    case 'delivery':
      return DeliveryType.delivery;
    case 'self_pickup':
      return DeliveryType.selfPickup;
    default:
      // Dokumen lama / value tak dikenal -> default aman: self-pickup.
      return DeliveryType.selfPickup;
  }
}

class StatusHistory {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'timestamp': timestamp,
    'note': note,
  };

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      timestamp: dateTimeFromSnapshot(json['timestamp']),
      note: json['note'],
    );
  }
}

class OrderItem {
  final String serviceTypeId;
  final String serviceName;
  final int quantity;
  final double weight;
  final double pricePerUnit;
  final double totalPrice;
  final String? notes;

  OrderItem({
    required this.serviceTypeId,
    required this.serviceName,
    required this.quantity,
    required this.weight,
    required this.pricePerUnit,
    required this.totalPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'service_type_id': serviceTypeId,
    'service_name': serviceName,
    'quantity': quantity,
    'weight': weight,
    'price_per_unit': pricePerUnit,
    'total_price': totalPrice,
    'notes': notes,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      serviceTypeId: json['service_type_id'] ?? '',
      serviceName: json['service_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      pricePerUnit: (json['price_per_unit'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }
}

class Order extends BaseModel {
  final String companyId;
  final String laundryId;
  final String customerId;
  /// Denormalized dari customers/{customerId} - field ini yang beneran
  /// ditulis oleh CreateOrderScreen ('customer_name', 'customer_phone'),
  /// disimpan di sini juga supaya layar lain (mis. Antar Jemput) tidak perlu
  /// fetch ulang ke koleksi customers hanya buat nampilin nama & telepon.
  final String? customerName;
  final String? customerPhone;
  final String? employeeId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalWeight;
  final int totalItems;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final OrderStatus status;
  final List<StatusHistory> statusHistory;
  final DateTime orderDate;
  final DateTime? pickupDate;
  final DateTime? estimatedCompletion;
  final DateTime? actualCompletion;
  final DateTime? deliveryDate;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final double paidAmount;
  final String? notes;
  final String? specialInstructions;
  final PriorityLevel priorityLevel;

  /// Cara baju masuk. Default walkIn supaya dokumen lama (belum punya
  /// field ini) tetap kebaca aman lewat fromJson.
  final OrderType orderType;

  /// Cara baju keluar. Default selfPickup dengan alasan yang sama.
  final DeliveryType deliveryType;

  Order({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.laundryId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.employeeId,
    required this.orderNumber,
    required this.items,
    required this.totalWeight,
    required this.totalItems,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.statusHistory,
    required this.orderDate,
    this.pickupDate,
    this.estimatedCompletion,
    this.actualCompletion,
    this.deliveryDate,
    required this.paymentStatus,
    this.paymentMethod,
    required this.paidAmount,
    this.notes,
    this.specialInstructions,
    required this.priorityLevel,
    this.orderType = OrderType.walkIn,
    this.deliveryType = DeliveryType.selfPickup,
  });

  /// True kalau order ini butuh driver buat jemput baju ke lokasi pelanggan.
  bool get needsPickup => orderType == OrderType.pickup;

  /// True kalau order ini butuh driver buat nganterin baju ke pelanggan.
  bool get needsDelivery => deliveryType == DeliveryType.delivery;

  /// True kalau dari awal sampai akhir pelanggan yang urus sendiri
  /// (datang ke counter & ambil ke counter) -> tidak perlu driver sama sekali.
  bool get isFullySelfService => !needsPickup && !needsDelivery;

  /// Sisa tagihan yang belum dibayar. Tidak pernah negatif.
  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  Order copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyId,
    String? laundryId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? employeeId,
    String? orderNumber,
    List<OrderItem>? items,
    double? totalWeight,
    int? totalItems,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    OrderStatus? status,
    List<StatusHistory>? statusHistory,
    DateTime? orderDate,
    DateTime? pickupDate,
    DateTime? estimatedCompletion,
    DateTime? actualCompletion,
    DateTime? deliveryDate,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    double? paidAmount,
    String? notes,
    String? specialInstructions,
    PriorityLevel? priorityLevel,
    OrderType? orderType,
    DeliveryType? deliveryType,
  }) {
    return Order(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyId: companyId ?? this.companyId,
      laundryId: laundryId ?? this.laundryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      employeeId: employeeId ?? this.employeeId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      totalWeight: totalWeight ?? this.totalWeight,
      totalItems: totalItems ?? this.totalItems,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      orderDate: orderDate ?? this.orderDate,
      pickupDate: pickupDate ?? this.pickupDate,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      actualCompletion: actualCompletion ?? this.actualCompletion,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      orderType: orderType ?? this.orderType,
      deliveryType: deliveryType ?? this.deliveryType,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'laundry_id': laundryId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'employee_id': employeeId,
      'order_number': orderNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'total_weight': totalWeight,
      'total_items': totalItems,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': status.name,
      'status_history': statusHistory.map((e) => e.toJson()).toList(),
      'order_date': orderDate,
      'pickup_date': pickupDate,
      'estimated_completion': estimatedCompletion,
      'actual_completion': actualCompletion,
      'delivery_date': deliveryDate,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod?.name,
      'paid_amount': paidAmount,
      'notes': notes,
      'special_instructions': specialInstructions,
      'priority_level': priorityLevel.name,
      // Ditulis snake_case supaya konsisten dengan yang ditulis
      // CreateOrderScreen langsung ke Firestore ('walk_in', 'self_pickup').
      'order_type': _orderTypeToFirestore(orderType),
      'delivery_type': _deliveryTypeToFirestore(deliveryType),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json, String documentId) {
    return Order(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      companyId: json['company_id'] ?? '',
      laundryId: json['laundry_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      employeeId: json['employee_id'],
      orderNumber: json['order_number'] ?? '',
      items: (json['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      totalWeight: (json['total_weight'] ?? 0.0).toDouble(),
      totalItems: json['total_items'] ?? 0,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0.0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      statusHistory: (json['status_history'] as List?)?.map((e) => StatusHistory.fromJson(e)).toList() ?? [],
      orderDate: dateTimeFromSnapshot(json['order_date']),
      pickupDate: dateTimeFromSnapshotOrNull(json['pickup_date']),
      estimatedCompletion: dateTimeFromSnapshotOrNull(json['estimated_completion']),
      actualCompletion: dateTimeFromSnapshotOrNull(json['actual_completion']),
      deliveryDate: dateTimeFromSnapshotOrNull(json['delivery_date']),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.values.firstWhere((e) => e.name == json['payment_method'], orElse: () => PaymentMethod.cash)
          : null,
      paidAmount: (json['paid_amount'] ?? 0.0).toDouble(),
      notes: json['notes'],
      specialInstructions: json['special_instructions'],
      priorityLevel: PriorityLevel.values.firstWhere(
        (e) => e.name == json['priority_level'],
        orElse: () => PriorityLevel.normal,
      ),
      orderType: _orderTypeFromFirestore(json['order_type']),
      deliveryType: _deliveryTypeFromFirestore(json['delivery_type']),
    );
  }
}