import 'dart:convert'; // Pour jsonEncode/Decode
import 'package:tobuy/models/shopping_item.dart'; // Assurez-vous que le chemin est correct
import 'package:uuid/uuid.dart'; // Pour générer des UUIDs si nécessaire

class ShoppingList {
  final String id; // UUID
  final String ownerId; // UUID du propriétaire (remplace userId)
  String name; // Ajouté pour le nom de la liste
  final List<String> collaboratorIds; // Liste des UUIDs des collaborateurs
  final DateTime createdAt;
  DateTime updatedAt;
  bool isSynced; // Flag local pour la synchro
  bool isDeleted; // Flag local pour soft delete

  // Les items ne sont PAS stockés directement dans la table List
  // Mais peuvent être chargés en mémoire ici
  List<ShoppingItem> items;

  // Calculé dynamiquement
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalItemPrice);

  ShoppingList({
    required this.id,
    required this.ownerId,
    required this.name,
    List<String>? collaboratorIds,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
    this.items = const [], // Initialiser avec une liste vide
  }) : collaboratorIds = collaboratorIds ?? [];

  // Pour l'API JSON (Dio) - Ne sérialise PAS les items ici
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String, // Utilise ownerId
      name: json['name'] as String,
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      // isSynced et isDeleted sont gérés localement
      // Les items sont chargés via une requête séparée basée sur listId
    );
  }

  // Ne sérialise PAS les items ici
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId, // Utilise ownerId
      'name': name,
      'collaboratorIds': collaboratorIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // isSynced et isDeleted ne sont pas envoyés
    };
  }

  // Pour la base de données locale SQLite - Ne stocke PAS les items ici
  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String, // Utilise ownerId
      name: map['name'] as String,
      // Décode la chaîne JSON stockée dans SQLite
      collaboratorIds: (map['collaboratorIds'] as String?) != null
          ? List<String>.from(jsonDecode(map['collaboratorIds'] as String))
          : [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int? ?? 0) == 1, // SQLite: 0 ou 1
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1, // SQLite: 0 ou 1
      // Les items sont chargés séparément
    );
  }

  // Ne stocke PAS les items ici
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId, // Utilise ownerId
      'name': name,
      'collaboratorIds': jsonEncode(collaboratorIds), // Encode en JSON string
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0, // Stocke comme entier
      'isDeleted': isDeleted ? 1 : 0, // Stocke comme entier
    };
  }

  ShoppingList copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<String>? collaboratorIds,
    List<ShoppingItem>? items, // Permet de mettre à jour les items chargés
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

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, ownerId: $ownerId, items: ${items.length}, collaborators: ${collaboratorIds.length}, synced: $isSynced, deleted: $isDeleted, updatedAt: $updatedAt)';
  }
}