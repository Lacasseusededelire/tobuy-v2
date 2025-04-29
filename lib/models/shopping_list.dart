import 'package:tobuy/models/shopping_item.dart';

class ShoppingList {
  final String id;
  final String ownerId;
  final String name;
  final List<String> collaboratorIds;
  final List<ShoppingItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;

  ShoppingList({
    required this.id,
    required this.ownerId,
    required this.name,
    this.collaboratorIds = const [],
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0.0));
  }

  ShoppingList copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<String>? collaboratorIds,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}