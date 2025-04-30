class ShoppingItem {
  final String id;
  final String listId;
  final String name;
  final double quantity;
  final double unitPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isChecked;
  final bool isSynced;
  final bool isDeleted;

  ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    required this.updatedAt,
    this.isChecked = false,
    this.isSynced = false,
    this.isDeleted = false,
  });

  double get totalPrice => quantity * unitPrice;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      listId: json['listId'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isChecked: json['isChecked'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? true, // Par défaut synchronisé pour les données venant du backend
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isChecked': isChecked,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isChecked: (map['is_checked'] as int) == 1,
      isSynced: (map['is_synced'] as int) == 1,
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_checked': isChecked ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    double? quantity,
    double? unitPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isChecked,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isChecked: isChecked ?? this.isChecked,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}