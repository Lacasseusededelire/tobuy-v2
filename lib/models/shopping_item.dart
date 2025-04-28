class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalItemPrice;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalItemPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_item_price': totalItemPrice,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalItemPrice: (map['total_item_price'] as num).toDouble(),
    );
  }
}
