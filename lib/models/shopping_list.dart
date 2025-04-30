import 'dart:convert'; // Ajouté pour jsonDecode
import 'package:tobuy/models/shopping_item.dart';

class ShoppingList {
  final String id;
  final String name;
  final String userId;
  List<String> collaboratorIds;
  List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.userId,
    required this.collaboratorIds,
    required this.items,
  });

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    // Parser items comme une chaîne JSON
    final itemsJson = json['items'] as String?;
    final itemsList = itemsJson != null && itemsJson.isNotEmpty
        ? (jsonDecode(itemsJson) as List<dynamic>)
        : [];

    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      collaboratorIds: (json['collaboratorIds'] as List<dynamic>?)?.cast<String>() ?? [],
      items: itemsList.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'collaboratorIds': collaboratorIds,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as String,
      name: map['name'] as String,
      userId: map['user_id'] as String,
      collaboratorIds: (map['collaborator_ids'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      items: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'collaborator_ids': collaboratorIds.join(','),
    };
  }
}