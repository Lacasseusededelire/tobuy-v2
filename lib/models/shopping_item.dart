class ShoppingItem {
  final String id;
  final String listId;
  final String name;
  final double quantity;
  final double? unitPrice;
  final bool isChecked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;

  ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.quantity,
    this.unitPrice,
    this.isChecked = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  double? get totalPrice {
    if (unitPrice == null) return null;
    return quantity * unitPrice!;
  }

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    double? quantity,
    double? unitPrice,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}