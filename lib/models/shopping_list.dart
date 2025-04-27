import 'package:tobuy/models/shopping_item.dart';

class ShoppingList {
  final String id;
  final String userId;
  List<ShoppingItem> items; // Non-final pour permettre les modifications
  double totalPrice; // Non-final pour permettre les mises à jour
  final DateTime createdAt;
  DateTime updatedAt; // Non-final pour permettre les mises à jour

  ShoppingList({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => ShoppingItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalPrice: (map['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}