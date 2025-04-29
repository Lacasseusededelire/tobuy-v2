import 'package:uuid/uuid.dart'; // Pour générer des UUIDs si nécessaire

class ShoppingItem {
  final String id; // UUID
  final String listId; // *AJOUT CRUCIAL*: UUID de la liste parente
  String name;
  double quantity;
  double? unitPrice; // Rendu nullable
  bool isChecked; // *AJOUT*: Pour marquer comme acheté
  final DateTime createdAt; // *AJOUT*
  DateTime updatedAt; // *AJOUT*
  bool isSynced; // *AJOUT*: Flag local pour la synchro
  bool isDeleted; // *AJOUT*: Flag local pour soft delete

  // Calculé dynamiquement
  double get totalItemPrice => (unitPrice ?? 0.0) * quantity;

  ShoppingItem({
    required this.id,
    required this.listId, // Requis
    required this.name,
    this.quantity = 1.0,
    this.unitPrice, // Nullable
    this.isChecked = false, // Défaut à false
    required this.createdAt, // Requis
    required this.updatedAt, // Requis
    this.isSynced = false,
    this.isDeleted = false,
  });

  // Pour l'API JSON (Dio)
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      listId: json['listId'] as String, // Ajouté
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(), // Gère null
      isChecked: json['isChecked'] as bool? ?? false, // Ajouté
      createdAt: DateTime.parse(json['createdAt'] as String), // Ajouté
      updatedAt: DateTime.parse(json['updatedAt'] as String), // Ajouté
      // isSynced et isDeleted sont gérés localement
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId, // Ajouté
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice, // Peut être null
      'isChecked': isChecked, // Ajouté
      'createdAt': createdAt.toIso8601String(), // Ajouté
      'updatedAt': updatedAt.toIso8601String(), // Ajouté
      // isSynced et isDeleted ne sont pas envoyés
    };
  }

  // Pour la base de données locale SQLite
  // Correction: fromMap ne prend plus 'id' en paramètre séparé
  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as String,
      listId: map['listId'] as String, // Ajouté
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble(), // Gère null
      isChecked: (map['isChecked'] as int? ?? 0) == 1, // Ajouté (SQLite: 0 ou 1)
      createdAt: DateTime.parse(map['createdAt'] as String), // Ajouté
      updatedAt: DateTime.parse(map['updatedAt'] as String), // Ajouté
      isSynced: (map['isSynced'] as int? ?? 0) == 1, // Ajouté (SQLite: 0 ou 1)
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1, // Ajouté (SQLite: 0 ou 1)
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId, // Ajouté
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice, // Peut être null
      'isChecked': isChecked ? 1 : 0, // Ajouté (Stocke comme entier)
      'createdAt': createdAt.toIso8601String(), // Ajouté (Stocke comme String)
      'updatedAt': updatedAt.toIso8601String(), // Ajouté (Stocke comme String)
      'isSynced': isSynced ? 1 : 0, // Ajouté (Stocke comme entier)
      'isDeleted': isDeleted ? 1 : 0, // Ajouté (Stocke comme entier)
      // totalItemPrice n'est pas stocké, il est calculé
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? listId, // Ajouté
    String? name,
    double? quantity,
    // Utiliser double? pour permettre la mise à null explicitement si besoin
    // Ou une valeur spéciale pour indiquer "ne pas changer" vs "mettre à null"
    double? unitPrice,
    bool? isChecked, // Ajouté
    DateTime? createdAt, // Ajouté
    DateTime? updatedAt, // Ajouté
    bool? isSynced, // Ajouté
    bool? isDeleted, // Ajouté
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId, // Ajouté
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice, // Gère la mise à jour, mais pas la mise à null facile
      isChecked: isChecked ?? this.isChecked, // Ajouté
      createdAt: createdAt ?? this.createdAt, // Ajouté
      updatedAt: updatedAt ?? this.updatedAt, // Ajouté
      isSynced: isSynced ?? this.isSynced, // Ajouté
      isDeleted: isDeleted ?? this.isDeleted, // Ajouté
    );
  }

   @override
  String toString() {
    return 'ShoppingItem(id: $id, listId: $listId, name: $name, qty: $quantity, price: $unitPrice, checked: $isChecked, synced: $isSynced, deleted: $isDeleted, updatedAt: $updatedAt)';
  }
}