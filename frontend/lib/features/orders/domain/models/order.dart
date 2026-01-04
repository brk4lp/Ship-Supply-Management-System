/// Order Status - State Machine
enum OrderStatus {
  newOrder('NEW', 'Yeni'),
  quoted('QUOTED', 'Fiyat Verildi'),
  agreed('AGREED', 'Onaylandı'),
  waitingGoods('WAITING_GOODS', 'Mal Bekleniyor'),
  prepared('PREPARED', 'Hazırlandı'),
  onWay('ON_WAY', 'Yolda'),
  delivered('DELIVERED', 'Teslim Edildi'),
  invoiced('INVOICED', 'Faturalandı'),
  cancelled('CANCELLED', 'İptal');

  final String value;
  final String displayName;

  const OrderStatus(this.value, this.displayName);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.newOrder,
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final int shipId;
  final String? shipName;
  final int supplierId;
  final String? supplierName;
  final OrderStatus status;
  final double totalAmount;
  final String currency;
  final String? deliveryPort;
  final DateTime? deliveryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.shipId,
    this.shipName,
    required this.supplierId,
    this.supplierName,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.deliveryPort,
    this.deliveryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      shipId: json['ship_id'] as int,
      shipName: json['ship_name'] as String?,
      supplierId: json['supplier_id'] as int,
      supplierName: json['supplier_name'] as String?,
      status: OrderStatus.fromString(json['status'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      deliveryPort: json['delivery_port'] as String?,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'ship_id': shipId,
      'supplier_id': supplierId,
      'status': status.value,
      'total_amount': totalAmount,
      'currency': currency,
      'delivery_port': deliveryPort,
      'delivery_date': deliveryDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Calculate gross profit for entire order
  double get grossProfit {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(0, (sum, item) => sum + item.grossProfit);
  }

  /// Calculate average margin percentage
  double? get marginPercent {
    if (items == null || items!.isEmpty) return null;
    final totalRevenue = items!.fold(0.0, (sum, item) => sum + item.totalRevenue);
    if (totalRevenue == 0) return null;
    final totalCost = items!.fold(0.0, (sum, item) => sum + item.totalCost);
    return ((totalRevenue - totalCost) / totalRevenue) * 100;
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final String productName;
  final String? impaCode;
  final String? description;
  final double quantity;
  final String unit;
  final double buyingPrice;
  final double sellingPrice;
  final String currency;
  final String? notes;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productName,
    this.impaCode,
    this.description,
    required this.quantity,
    required this.unit,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.currency,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productName: json['product_name'] as String,
      impaCode: json['impa_code'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      buyingPrice: (json['buying_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      currency: json['currency'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_name': productName,
      'impa_code': impaCode,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'currency': currency,
      'notes': notes,
    };
  }

  /// Gross Profit: (Selling Price - Buying Price) * Quantity
  double get grossProfit => (sellingPrice - buyingPrice) * quantity;

  /// Margin (%): ((Selling Price - Buying Price) / Selling Price) * 100
  double? get marginPercent {
    if (sellingPrice == 0) return null;
    return ((sellingPrice - buyingPrice) / sellingPrice) * 100;
  }

  /// Total cost (buying_price * quantity)
  double get totalCost => buyingPrice * quantity;

  /// Total revenue (selling_price * quantity)
  double get totalRevenue => sellingPrice * quantity;
}
